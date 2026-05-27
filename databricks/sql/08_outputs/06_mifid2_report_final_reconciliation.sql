-- Step 12B4: Final validation and reconciliation package (read-only).
--
-- Scope in this file:
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_report
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
--
-- This file is SELECT-only validation SQL.
-- Do not add CREATE / INSERT / UPDATE / DELETE / MERGE / DROP in this package.
--
-- Dependencies:
-- - Step 12B1 schema baselines:
--     databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql
-- - Step 12B2 boundary/intermediate validations:
--     databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql
-- - Step 12B3 final branch validations:
--     databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql

-- -----------------------------------------------------------------------------
-- 1) Run parameters and gate summary
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
required_placeholders AS (
  SELECT *
  FROM VALUES
    ('{{trades_final_source}}', 'gated', 'Step 12B2 unified trade pool source is required for source-to-output reconciliation.'),
    ('{{report_metadata_source}}', 'gated', 'Pre-output metadata source with IsFuture/IsMifid/IsMifidByFCA is required for category-aware coverage checks.'),
    ('{{removed_partial_candidates_source}}', 'gated', 'Step 12B2 removed-partials candidate source is required for candidate-vs-output reconciliation.'),
    ('{{mifid2_instruments_to_exclude_source}}', 'gated', 'Optional exclusion source check; run only after mapped source confirmation.'),
    ('{{isin_for_instrumentid_341_source}}', 'gated', 'InstrumentID 341 override source validation; run only after source contract is confirmed.')
  AS t(required_placeholder, gate_status, gate_reason)
),
upstream_gates AS (
  SELECT *
  FROM VALUES
    ('step5_price_split_sources', 'pending', 'Step 5B1/5B2 price-split source contracts must pass before B4 signoff.'),
    ('step6_movement_regchange', 'pending', 'Step 6 movement/reg-change parity gates must pass before B4 signoff.'),
    ('step9_position_staging', 'pending', 'Step 9 position/reg-change staging contracts must pass before B4 signoff.'),
    ('step10_11_customer_outputs', 'pending', 'Step 10/11 customer output readiness must pass before B4 signoff.'),
    ('step12b2_checkpoint_optional', 'pending', 'Optional B2 checkpoint-dependent checks remain gated unless checkpoints are materialized.'),
    ('step12b2_split_gbx_audit_fields', 'pending', 'Split/GBX audit checks remain gated until required audit fields are materialized.'),
    ('step12b3_futuresmetadata_profile', 'pending', 'FuturesMetaData required-column profiling is still required.'),
    ('step12b3_instrumentclassification_exact_mapping', 'pending', 'Exact branch-specific InstrumentClassification/CFI mapping remains hard-gated.'),
    ('step12b3_exclusion_sources', 'pending', 'Exclusion parity sources (including optional mapped source) must be confirmed.'),
    ('step12b3_removed_partials_source', 'pending', 'Removed-partials candidate source contract must be confirmed.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  ph.required_placeholder,
  ph.gate_status AS placeholder_status,
  ph.gate_reason AS placeholder_reason,
  ug.gate_name,
  ug.gate_status,
  ug.gate_reason,
  'Run Step 12B4 only after Step 12B1/B2/B3 templates are activated and required upstream gates pass.' AS execution_note
FROM run_parameters rp
CROSS JOIN required_placeholders ph
CROSS JOIN upstream_gates ug
ORDER BY ph.required_placeholder, ug.gate_name;

-- -----------------------------------------------------------------------------
-- 2) Schema contract summary (concise B4 summary)
-- Detailed column-level schema contract checks remain in:
-- - 03_mifid2_report_validation_foundation.sql
-- - 05_mifid2_report_branch_projection_validation.sql
-- -----------------------------------------------------------------------------
WITH expected_tables AS (
  SELECT *
  FROM VALUES
    ('bi_output_regtechops_mifid2_report', 100),
    ('bi_output_regtechops_mifid2_me_report', 100),
    ('bi_output_regtechops_mifid2_removed_op_partials', 26)
  AS t(table_name, expected_column_count)
),
actual_tables AS (
  SELECT
    lower(table_name) AS table_name,
    COUNT(*) AS actual_column_count
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) IN (
      'bi_output_regtechops_mifid2_report',
      'bi_output_regtechops_mifid2_me_report',
      'bi_output_regtechops_mifid2_removed_op_partials'
    )
  GROUP BY lower(table_name)
)
SELECT
  e.table_name,
  e.expected_column_count,
  a.actual_column_count,
  CASE
    WHEN a.table_name IS NULL THEN 'missing_table'
    WHEN e.expected_column_count <> a.actual_column_count THEN 'column_count_mismatch'
    ELSE 'ok'
  END AS schema_summary_status
FROM expected_tables e
LEFT JOIN actual_tables a
  ON lower(e.table_name) = a.table_name
ORDER BY e.table_name;

-- -----------------------------------------------------------------------------
-- 3) Output row-count reconciliation
-- - by ReportDate
-- - by RegulationReportID
-- - by RegulationID
-- - by RegChange
-- - by branch (EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, ME)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_branch_rows AS (
  SELECT
    r.ReportDate,
    r.RegulationReportID,
    r.RegulationID,
    r.RegChange,
    CASE
      WHEN r.RegulationReportID = 1
       AND r.RegulationID = 1
       AND r.TransactionReferenceNumber NOT RLIKE 'SC[0-9]{8}$'
       AND r.TransactionReferenceNumber NOT RLIKE 'ME[0-9]{8}$'
       AND r.TransactionReferenceNumber NOT RLIKE 'UK[OC]$'
      THEN 'EU_CYSEC'
      WHEN r.RegulationReportID = 2
       AND r.RegulationID = 2
      THEN 'UK_FCA'
      WHEN r.RegulationReportID = 1
       AND r.RegulationID = 2
       AND r.TransactionReferenceNumber RLIKE 'UK[OC]$'
      THEN 'FCA_FLOW_IN_EU'
      WHEN r.RegulationReportID = 1
       AND r.RegulationID = 9
       AND r.TransactionReferenceNumber RLIKE 'SC[0-9]{8}$'
      THEN 'SEYCHELLES'
      ELSE 'UNCLASSIFIED'
    END AS BranchName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
  WHERE r.ReportDate = (SELECT report_date FROM run_parameters)
),
me_branch_rows AS (
  SELECT
    m.ReportDate,
    m.RegulationReportID,
    m.RegulationID,
    m.RegChange,
    CASE
      WHEN m.RegulationReportID = 1
       AND m.RegulationID = 11
       AND m.TransactionReferenceNumber RLIKE 'ME[0-9]{8}$'
      THEN 'ME'
      ELSE 'UNCLASSIFIED'
    END AS BranchName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report m
  WHERE m.ReportDate = (SELECT report_date FROM run_parameters)
),
removed_rows AS (
  SELECT ReportDate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  'REPORT_BY_REPORTDATE' AS metric_name,
  CAST(ReportDate AS STRING) AS metric_key_1,
  CAST(NULL AS STRING) AS metric_key_2,
  COUNT(*) AS row_count
FROM report_branch_rows
GROUP BY ReportDate
UNION ALL
SELECT
  'ME_BY_REPORTDATE',
  CAST(ReportDate AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM me_branch_rows
GROUP BY ReportDate
UNION ALL
SELECT
  'REMOVED_PARTIALS_BY_REPORTDATE',
  CAST(ReportDate AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM removed_rows
GROUP BY ReportDate
UNION ALL
SELECT
  'REPORT_BY_REGULATION_REPORT_ID',
  CAST(RegulationReportID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM report_branch_rows
GROUP BY RegulationReportID
UNION ALL
SELECT
  'ME_BY_REGULATION_REPORT_ID',
  CAST(RegulationReportID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM me_branch_rows
GROUP BY RegulationReportID
UNION ALL
SELECT
  'REPORT_BY_REGULATION_ID',
  CAST(RegulationID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM report_branch_rows
GROUP BY RegulationID
UNION ALL
SELECT
  'ME_BY_REGULATION_ID',
  CAST(RegulationID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM me_branch_rows
GROUP BY RegulationID
UNION ALL
SELECT
  'REPORT_BY_REGCHANGE',
  CAST(RegChange AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM report_branch_rows
GROUP BY RegChange
UNION ALL
SELECT
  'ME_BY_REGCHANGE',
  CAST(RegChange AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM me_branch_rows
GROUP BY RegChange
UNION ALL
SELECT
  'REPORT_BY_BRANCH',
  BranchName,
  CAST(NULL AS STRING),
  COUNT(*)
FROM report_branch_rows
GROUP BY BranchName
UNION ALL
SELECT
  'ME_BY_BRANCH',
  BranchName,
  CAST(NULL AS STRING),
  COUNT(*)
FROM me_branch_rows
GROUP BY BranchName
ORDER BY metric_name, metric_key_1;

-- -----------------------------------------------------------------------------
-- 4) OPTIONAL - Source-to-output reconciliation ({{trades_final_source}})
-- OPTIONAL - run only after {{trades_final_source}} is available/materialized.
-- -----------------------------------------------------------------------------
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_metadata AS (
  -- Required normalized columns:
  -- InstrumentID, IsMifid, IsMifidByFCA, IsFuture
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsMifid AS INT) AS IsMifid,
    CAST(IsMifidByFCA AS INT) AS IsMifidByFCA,
    CAST(IsFuture AS INT) AS IsFuture
  FROM {{report_metadata_source}}
),
source_enriched AS (
  SELECT
    CAST(t.CID AS INT) AS CID,
    CAST(t.PositionID AS BIGINT) AS PositionID,
    CAST(t.OpenORClose AS STRING) AS OpenORClose,
    CAST(t.RegChange AS INT) AS RegChange,
    CAST(t.OrigRegulationID AS INT) AS OrigRegulationID,
    CAST(t.InstrumentID AS INT) AS InstrumentID,
    CASE
      WHEN t.OrigRegulationID = 1 THEN 'EU_CYSEC'
      WHEN t.OrigRegulationID = 2 THEN 'UK_OR_FCA_FLOW'
      WHEN t.OrigRegulationID = 9 THEN 'SEYCHELLES'
      WHEN t.OrigRegulationID = 11 THEN 'ME'
      ELSE 'OUT_OF_SCOPE'
    END AS branch_hint,
    CASE
      WHEN t.OrigRegulationID = 1 THEN 1
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 2
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 1
      WHEN t.OrigRegulationID = 9 THEN 1
      WHEN t.OrigRegulationID = 11 THEN 1
      ELSE NULL
    END AS expected_regulation_report_id,
    CASE
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 'FCA_FLOW_IN_EU'
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 'UK_FCA'
      WHEN t.OrigRegulationID = 1 THEN 'EU_CYSEC'
      WHEN t.OrigRegulationID = 9 THEN 'SEYCHELLES'
      WHEN t.OrigRegulationID = 11 THEN 'ME'
      ELSE 'OUT_OF_SCOPE'
    END AS expected_branch_name
  FROM {{trades_final_source}} t
  LEFT JOIN report_metadata m
    ON m.InstrumentID = t.InstrumentID
  WHERE t.OrigRegulationID IN (1,2,9,11)
),
expected_report_rows AS (
  SELECT
    CID, PositionID, OpenORClose, RegChange,
    CAST(OrigRegulationID AS INT) AS RegulationID,
    expected_regulation_report_id AS RegulationReportID,
    expected_branch_name AS BranchName
  FROM source_enriched
  WHERE OrigRegulationID IN (1,2,9)
    AND expected_regulation_report_id IS NOT NULL
),
expected_me_rows AS (
  SELECT
    CID, PositionID, OpenORClose, RegChange,
    CAST(OrigRegulationID AS INT) AS RegulationID,
    expected_regulation_report_id AS RegulationReportID,
    expected_branch_name AS BranchName
  FROM source_enriched
  WHERE OrigRegulationID = 11
    AND expected_regulation_report_id IS NOT NULL
),
actual_report_rows AS (
  SELECT
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    CAST(RegulationID AS INT) AS RegulationID,
    CAST(RegulationReportID AS INT) AS RegulationReportID,
    CASE
      WHEN RegulationReportID = 1 AND RegulationID = 1 THEN 'EU_CYSEC'
      WHEN RegulationReportID = 2 AND RegulationID = 2 THEN 'UK_FCA'
      WHEN RegulationReportID = 1 AND RegulationID = 2 THEN 'FCA_FLOW_IN_EU'
      WHEN RegulationReportID = 1 AND RegulationID = 9 THEN 'SEYCHELLES'
      ELSE 'UNCLASSIFIED'
    END AS BranchName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
actual_me_rows AS (
  SELECT
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    CAST(RegulationID AS INT) AS RegulationID,
    CAST(RegulationReportID AS INT) AS RegulationReportID,
    'ME' AS BranchName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
missing_in_report_output AS (
  SELECT e.*
  FROM expected_report_rows e
  LEFT JOIN actual_report_rows a
    ON a.CID = e.CID
   AND a.PositionID = e.PositionID
   AND a.OpenORClose = e.OpenORClose
   AND a.RegChange = e.RegChange
   AND a.RegulationID = e.RegulationID
   AND a.RegulationReportID = e.RegulationReportID
  WHERE a.PositionID IS NULL
),
extra_in_report_output AS (
  SELECT a.*
  FROM actual_report_rows a
  LEFT JOIN expected_report_rows e
    ON e.CID = a.CID
   AND e.PositionID = a.PositionID
   AND e.OpenORClose = a.OpenORClose
   AND e.RegChange = a.RegChange
   AND e.RegulationID = a.RegulationID
   AND e.RegulationReportID = a.RegulationReportID
  WHERE e.PositionID IS NULL
),
missing_in_me_output AS (
  SELECT e.*
  FROM expected_me_rows e
  LEFT JOIN actual_me_rows a
    ON a.CID = e.CID
   AND a.PositionID = e.PositionID
   AND a.OpenORClose = e.OpenORClose
   AND a.RegChange = e.RegChange
   AND a.RegulationID = e.RegulationID
   AND a.RegulationReportID = e.RegulationReportID
  WHERE a.PositionID IS NULL
),
extra_in_me_output AS (
  SELECT a.*
  FROM actual_me_rows a
  LEFT JOIN expected_me_rows e
    ON e.CID = a.CID
   AND e.PositionID = a.PositionID
   AND e.OpenORClose = a.OpenORClose
   AND e.RegChange = a.RegChange
   AND e.RegulationID = a.RegulationID
   AND e.RegulationReportID = a.RegulationReportID
  WHERE e.PositionID IS NULL
)
SELECT 'report_expected_missing_in_output' AS reconciliation_type, COUNT(*) AS mismatch_rows
FROM missing_in_report_output
UNION ALL
SELECT 'report_output_missing_in_expected', COUNT(*)
FROM extra_in_report_output
UNION ALL
SELECT 'me_expected_missing_in_output', COUNT(*)
FROM missing_in_me_output
UNION ALL
SELECT 'me_output_missing_in_expected', COUNT(*)
FROM extra_in_me_output;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_metadata AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsMifid AS INT) AS IsMifid,
    CAST(IsMifidByFCA AS INT) AS IsMifidByFCA
  FROM {{report_metadata_source}}
),
source_branch_counts AS (
  SELECT
    CASE
      WHEN t.OrigRegulationID = 1 THEN 'EU_CYSEC'
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 'UK_FCA'
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 'FCA_FLOW_IN_EU'
      WHEN t.OrigRegulationID = 9 THEN 'SEYCHELLES'
      WHEN t.OrigRegulationID = 11 THEN 'ME'
      ELSE 'OUT_OF_SCOPE'
    END AS BranchName,
    COUNT(*) AS source_row_count
  FROM {{trades_final_source}} t
  LEFT JOIN report_metadata m
    ON m.InstrumentID = t.InstrumentID
  WHERE t.OrigRegulationID IN (1,2,9,11)
  GROUP BY
    CASE
      WHEN t.OrigRegulationID = 1 THEN 'EU_CYSEC'
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 'UK_FCA'
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 'FCA_FLOW_IN_EU'
      WHEN t.OrigRegulationID = 9 THEN 'SEYCHELLES'
      WHEN t.OrigRegulationID = 11 THEN 'ME'
      ELSE 'OUT_OF_SCOPE'
    END
),
output_branch_counts AS (
  SELECT BranchName, COUNT(*) AS output_row_count
  FROM (
    SELECT
      CASE
        WHEN RegulationReportID = 1 AND RegulationID = 1 THEN 'EU_CYSEC'
        WHEN RegulationReportID = 2 AND RegulationID = 2 THEN 'UK_FCA'
        WHEN RegulationReportID = 1 AND RegulationID = 2 THEN 'FCA_FLOW_IN_EU'
        WHEN RegulationReportID = 1 AND RegulationID = 9 THEN 'SEYCHELLES'
        ELSE 'UNCLASSIFIED'
      END AS BranchName
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
    UNION ALL
    SELECT
      CASE
        WHEN RegulationReportID = 1 AND RegulationID = 11 THEN 'ME'
        ELSE 'UNCLASSIFIED'
      END AS BranchName
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
  ) x
  GROUP BY BranchName
)
SELECT
  COALESCE(s.BranchName, o.BranchName) AS BranchName,
  COALESCE(s.source_row_count, 0) AS source_row_count,
  COALESCE(o.output_row_count, 0) AS output_row_count,
  COALESCE(o.output_row_count, 0) - COALESCE(s.source_row_count, 0) AS count_delta
FROM source_branch_counts s
FULL OUTER JOIN output_branch_counts o
  ON s.BranchName = o.BranchName
ORDER BY BranchName;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_metadata AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsMifid AS INT) AS IsMifid,
    CAST(IsMifidByFCA AS INT) AS IsMifidByFCA
  FROM {{report_metadata_source}}
),
source_regreport_counts AS (
  SELECT
    CASE
      WHEN t.OrigRegulationID = 1 THEN 1
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 2
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 1
      WHEN t.OrigRegulationID = 9 THEN 1
      WHEN t.OrigRegulationID = 11 THEN 1
      ELSE NULL
    END AS RegulationReportID,
    COUNT(*) AS source_row_count
  FROM {{trades_final_source}} t
  LEFT JOIN report_metadata m
    ON m.InstrumentID = t.InstrumentID
  WHERE t.OrigRegulationID IN (1,2,9,11)
  GROUP BY
    CASE
      WHEN t.OrigRegulationID = 1 THEN 1
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 0 THEN 2
      WHEN t.OrigRegulationID = 2 AND m.IsMifidByFCA = 1 AND m.IsMifid = 1 THEN 1
      WHEN t.OrigRegulationID = 9 THEN 1
      WHEN t.OrigRegulationID = 11 THEN 1
      ELSE NULL
    END
),
output_regreport_counts AS (
  SELECT RegulationReportID, COUNT(*) AS output_row_count
  FROM (
    SELECT RegulationReportID
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
    UNION ALL
    SELECT RegulationReportID
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
  ) x
  GROUP BY RegulationReportID
)
SELECT
  COALESCE(CAST(s.RegulationReportID AS STRING), CAST(o.RegulationReportID AS STRING)) AS RegulationReportID,
  COALESCE(s.source_row_count, 0) AS source_row_count,
  COALESCE(o.output_row_count, 0) AS output_row_count,
  COALESCE(o.output_row_count, 0) - COALESCE(s.source_row_count, 0) AS count_delta
FROM source_regreport_counts s
FULL OUTER JOIN output_regreport_counts o
  ON s.RegulationReportID = o.RegulationReportID
ORDER BY RegulationReportID;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_regchange_counts AS (
  SELECT CAST(t.RegChange AS INT) AS RegChange, COUNT(*) AS source_row_count
  FROM {{trades_final_source}} t
  WHERE t.OrigRegulationID IN (1,2,9,11)
  GROUP BY CAST(t.RegChange AS INT)
),
output_regchange_counts AS (
  SELECT RegChange, COUNT(*) AS output_row_count
  FROM (
    SELECT RegChange
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
    UNION ALL
    SELECT RegChange
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
    WHERE ReportDate = (SELECT report_date FROM run_parameters)
  ) x
  GROUP BY RegChange
)
SELECT
  COALESCE(CAST(s.RegChange AS STRING), CAST(o.RegChange AS STRING)) AS RegChange,
  COALESCE(s.source_row_count, 0) AS source_row_count,
  COALESCE(o.output_row_count, 0) AS output_row_count,
  COALESCE(o.output_row_count, 0) - COALESCE(s.source_row_count, 0) AS count_delta
FROM source_regchange_counts s
FULL OUTER JOIN output_regchange_counts o
  ON s.RegChange = o.RegChange
ORDER BY RegChange;
*/

-- -----------------------------------------------------------------------------
-- 5) OPTIONAL - Removed partials reconciliation
-- OPTIONAL - run only after {{removed_partial_candidates_source}} is available.
-- -----------------------------------------------------------------------------
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
candidate_counts AS (
  SELECT COUNT(*) AS candidate_count
  FROM {{removed_partial_candidates_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_counts AS (
  SELECT COUNT(*) AS output_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  candidate_count,
  output_count,
  output_count - candidate_count AS count_delta
FROM candidate_counts
CROSS JOIN output_counts;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
candidate_keys AS (
  SELECT
    ReportDate, CID, PositionID, OriginalPositionID, OpenORClose
  FROM {{removed_partial_candidates_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_keys AS (
  SELECT
    ReportDate, CID, PositionID, OriginalPositionID, OpenORClose
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
missing_in_output AS (
  SELECT c.*
  FROM candidate_keys c
  LEFT JOIN output_keys o
    ON c.ReportDate = o.ReportDate
   AND c.CID = o.CID
   AND c.PositionID = o.PositionID
   AND c.OriginalPositionID = o.OriginalPositionID
   AND c.OpenORClose = o.OpenORClose
  WHERE o.PositionID IS NULL
),
extra_in_output AS (
  SELECT o.*
  FROM output_keys o
  LEFT JOIN candidate_keys c
    ON c.ReportDate = o.ReportDate
   AND c.CID = o.CID
   AND c.PositionID = o.PositionID
   AND c.OriginalPositionID = o.OriginalPositionID
   AND c.OpenORClose = o.OpenORClose
  WHERE c.PositionID IS NULL
)
SELECT 'candidate_missing_in_output' AS reconciliation_type, COUNT(*) AS mismatch_rows
FROM missing_in_output
UNION ALL
SELECT 'output_missing_in_candidate', COUNT(*)
FROM extra_in_output;
*/

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  PositionID,
  OpenORClose,
  OriginalPositionID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, PositionID, OpenORClose, OriginalPositionID
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR length(trim(OpenORClose)) = 0 THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN OriginalPositionID IS NULL THEN 1 ELSE 0 END) AS null_originalpositionid_count,
  SUM(CASE WHEN AmountInUnitsDecimal IS NULL THEN 1 ELSE 0 END) AS null_amount_count,
  SUM(CASE WHEN InitForexRate IS NULL THEN 1 ELSE 0 END) AS null_initforexrate_count,
  SUM(CASE WHEN EndForexRate IS NULL THEN 1 ELSE 0 END) AS null_endforexrate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS row_count,
  SUM(TRY_CAST(AmountInUnitsDecimal AS DOUBLE)) AS amount_sum,
  SUM(TRY_CAST(InitForexRate AS DOUBLE)) AS init_rate_sum,
  SUM(TRY_CAST(EndForexRate AS DOUBLE)) AS end_rate_sum,
  SUM(TRY_CAST(LastOpPriceRate AS DOUBLE)) AS last_op_rate_sum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS same_day_open_close_rows_in_removed_partials
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND DATE(OpenOccurred) = DATE(CloseOccurred);

-- Manual/static review checklist (non-executable):
-- - Confirm Step 12B3 branch projection SQL keeps explicit target column list for
--   bi_output_regtechops_mifid2_removed_op_partials final insert.
-- - Confirm explicit list matches all 26 DDL columns in ordinal order.

-- -----------------------------------------------------------------------------
-- 6) Data-quality checks for final outputs
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR length(trim(OpenORClose)) = 0 THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transactionref_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR length(trim(OpenORClose)) = 0 THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transactionref_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN BackReportingIndicator IS NULL THEN 1 ELSE 0 END) AS null_backreporting_rows,
  SUM(CASE WHEN BackReportingIndicator <> 0 THEN 1 ELSE 0 END) AS non_zero_backreporting_rows
FROM (
  SELECT BackReportingIndicator
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT BackReportingIndicator
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
) x;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN UpdateDate IS NOT NULL THEN 1 ELSE 0 END) AS report_non_null_updatedate_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN UpdateDate IS NOT NULL THEN 1 ELSE 0 END) AS me_non_null_updatedate_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN RegulationID = 1 AND TransactionReferenceNumber RLIKE 'UK[OC]$' THEN 1 ELSE 0 END) AS eu_rows_with_unexpected_uk_suffix,
  SUM(CASE WHEN RegulationID = 2 AND RegulationReportID = 2 AND TransactionReferenceNumber RLIKE 'UK[OC]$' THEN 1 ELSE 0 END) AS uk_rows_with_unexpected_uk_suffix,
  SUM(CASE WHEN RegulationID = 2 AND RegulationReportID = 1 AND TransactionReferenceNumber NOT RLIKE 'UK[OC]$' THEN 1 ELSE 0 END) AS fca_flow_rows_missing_uk_suffix,
  SUM(CASE WHEN RegulationID = 9 AND TransactionReferenceNumber NOT RLIKE 'SC[0-9]{8}$' THEN 1 ELSE 0 END) AS seychelles_rows_missing_sc_suffix
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN RegulationID = 11 AND TransactionReferenceNumber NOT RLIKE 'ME[0-9]{8}$' THEN 1 ELSE 0 END) AS me_rows_missing_me_suffix
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 7) Instrument / futures / exclusion checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_union AS (
  SELECT
    'REPORT' AS table_group,
    InstrumentID,
    IsRealStockETF,
    InstrumentIdentificationCode,
    InstrumentClassification
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'ME' AS table_group,
    InstrumentID,
    IsRealStockETF,
    InstrumentIdentificationCode,
    InstrumentClassification
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  table_group,
  SUM(
    CASE
      WHEN IsRealStockETF = 1
       AND (InstrumentIdentificationCode IS NULL OR length(trim(InstrumentIdentificationCode)) = 0)
      THEN 1 ELSE 0
    END
  ) AS real_stock_etf_missing_isin_count,
  SUM(
    CASE
      WHEN IsRealStockETF = 1
       AND InstrumentClassification IS NOT NULL
       AND length(trim(InstrumentClassification)) > 0
      THEN 1 ELSE 0
    END
  ) AS real_stock_etf_unexpected_cfi_count
FROM report_union
GROUP BY table_group
ORDER BY table_group;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_union AS (
  SELECT InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  SUM(CASE WHEN scd.InstrumentID IS NULL THEN 1 ELSE 0 END) AS missing_in_scd_count,
  SUM(CASE WHEN fd.InstrumentID IS NULL THEN 1 ELSE 0 END) AS missing_in_full_description_count,
  SUM(CASE WHEN conv.InstrumentID IS NULL THEN 1 ELSE 0 END) AS missing_in_specialchar_conversion_count
FROM report_union r
LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
  ON scd.InstrumentID = r.InstrumentID
LEFT JOIN main.regtech.gold_regtech_reg_instruments_full_description fd
  ON fd.InstrumentID = r.InstrumentID
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion conv
  ON conv.InstrumentID = r.InstrumentID;

-- OPTIONAL - run only after {{report_metadata_source}} (or equivalent pre-output
-- IsFuture classification source) is available/materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_union AS (
  SELECT
    'REPORT' AS table_group,
    InstrumentID,
    IsRealStockETF,
    InstrumentClassification
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'ME' AS table_group,
    InstrumentID,
    IsRealStockETF,
    InstrumentClassification
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
pre_output_metadata AS (
  -- Required normalized columns: InstrumentID, IsFuture
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsFuture AS INT) AS IsFuture
  FROM {{report_metadata_source}}
),
futures_required_columns AS (
  SELECT
    InstrumentID,
    CFICode,
    ExpirationDateTime,
    Multiplier
  FROM main.trading.bronze_etoro_trade_futuresmetadata
)
SELECT
  SUM(CASE WHEN m.IsFuture = 1 THEN 1 ELSE 0 END) AS futures_candidate_rows,
  SUM(CASE WHEN m.IsFuture = 1 AND f.InstrumentID IS NULL THEN 1 ELSE 0 END) AS futures_missing_source_rows,
  SUM(CASE WHEN m.IsFuture = 1 AND (f.CFICode IS NULL OR length(trim(CAST(f.CFICode AS STRING))) = 0) THEN 1 ELSE 0 END) AS futures_missing_cfi_count,
  SUM(CASE WHEN m.IsFuture = 1 AND f.ExpirationDateTime IS NULL THEN 1 ELSE 0 END) AS futures_missing_expiration_count,
  SUM(CASE WHEN m.IsFuture = 1 AND f.Multiplier IS NULL THEN 1 ELSE 0 END) AS futures_missing_multiplier_count,
  SUM(
    CASE
      WHEN m.IsFuture = 0 AND ru.IsRealStockETF = 0
       AND (ru.InstrumentClassification IS NULL OR length(trim(ru.InstrumentClassification)) = 0)
      THEN 1 ELSE 0
    END
  ) AS cfd_missing_cfi_count
FROM report_union ru
JOIN pre_output_metadata m
  ON m.InstrumentID = ru.InstrumentID
LEFT JOIN futures_required_columns f
  ON f.InstrumentID = ru.InstrumentID;
*/

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_instrument_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  ON CAST(r.InstrumentID AS STRING) = CAST(e.instrument_id AS STRING)
WHERE r.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_Report]';

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_position_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids e
  ON CAST(r.PositionID AS STRING) = CAST(e.position_id AS STRING)
WHERE r.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_Report]';

-- OPTIONAL - run only after mapped source {{mifid2_instruments_to_exclude_source}}
-- is confirmed/materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS mapped_exclusion_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN {{mifid2_instruments_to_exclude_source}} x
  ON CAST(r.InstrumentID AS STRING) = CAST(x.InstrumentID AS STRING)
WHERE r.ReportDate = (SELECT report_date FROM run_parameters);
*/

-- OPTIONAL - InstrumentID 341 override source profile/contract gate:
-- run only after {{isin_for_instrumentid_341_source}} is confirmed/materialized
-- with normalized logical columns (InstrumentID, OverrideISIN).
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
uk_rows_for_341 AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    UnderlyingInstrumentCode
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND RegulationReportID = 2
    AND RegulationID = 2
    AND InstrumentID = 341
),
source_override AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(OverrideISIN AS STRING) AS OverrideISIN
  FROM {{isin_for_instrumentid_341_source}}
)
SELECT
  COUNT(*) AS uk_rows_for_341,
  SUM(CASE WHEN u.UnderlyingInstrumentCode IS NULL OR length(trim(u.UnderlyingInstrumentCode)) = 0 THEN 1 ELSE 0 END) AS uk_rows_missing_underlying_code,
  SUM(CASE WHEN s.InstrumentID IS NULL THEN 1 ELSE 0 END) AS uk_rows_missing_override_source_match
FROM uk_rows_for_341 u
LEFT JOIN source_override s
  ON s.InstrumentID = u.InstrumentID;
*/

-- -----------------------------------------------------------------------------
-- 8) Aggregate checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_agg AS (
  SELECT
    ReportDate,
    RegulationReportID,
    RegulationID,
    RegChange,
    OpenORClose,
    CASE
      WHEN RegulationReportID = 1 AND RegulationID = 1 THEN 'EU_CYSEC'
      WHEN RegulationReportID = 2 AND RegulationID = 2 THEN 'UK_FCA'
      WHEN RegulationReportID = 1 AND RegulationID = 2 THEN 'FCA_FLOW_IN_EU'
      WHEN RegulationReportID = 1 AND RegulationID = 9 THEN 'SEYCHELLES'
      ELSE 'UNCLASSIFIED'
    END AS BranchName,
    TRY_CAST(Quantity AS DOUBLE) AS QuantityAsDouble,
    TRY_CAST(Price AS DOUBLE) AS PriceAsDouble
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
me_agg AS (
  SELECT
    ReportDate,
    RegulationReportID,
    RegulationID,
    RegChange,
    OpenORClose,
    'ME' AS BranchName,
    TRY_CAST(Quantity AS DOUBLE) AS QuantityAsDouble,
    TRY_CAST(Price AS DOUBLE) AS PriceAsDouble
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
report_me_union AS (
  SELECT * FROM report_agg
  UNION ALL
  SELECT * FROM me_agg
)
SELECT
  ReportDate,
  BranchName,
  RegulationReportID,
  RegulationID,
  RegChange,
  OpenORClose,
  COUNT(*) AS row_count,
  SUM(QuantityAsDouble) AS quantity_sum,
  SUM(PriceAsDouble) AS price_sum
FROM report_me_union
GROUP BY ReportDate, BranchName, RegulationReportID, RegulationID, RegChange, OpenORClose
ORDER BY BranchName, RegulationReportID, RegulationID, RegChange, OpenORClose;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  COUNT(*) AS row_count,
  SUM(TRY_CAST(AmountInUnitsDecimal AS DOUBLE)) AS amount_sum,
  SUM(TRY_CAST(InitForexRate AS DOUBLE)) AS init_rate_sum,
  SUM(TRY_CAST(EndForexRate AS DOUBLE)) AS end_rate_sum,
  SUM(TRY_CAST(ChangeLogLastOpPriceRate AS DOUBLE)) AS changelog_lastop_sum,
  SUM(TRY_CAST(LastOpPriceRate AS DOUBLE)) AS lastop_sum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate;

-- OPTIONAL - split/GBX aggregate checks
-- run only after split/GBX audit fields are materialized in the validated source.
-- Required fields:
-- - AmountRatioSplit
-- - IsSplitAdjusted
-- - IsGBX
-- - InitForexRateBeforeGBX
-- - InitForexRateAfterGBX
-- - EndForexRateBeforeGBX
-- - EndForexRateAfterGBX
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN IsSplitAdjusted = 1 THEN 1 ELSE 0 END) AS split_adjusted_rows,
  SUM(CASE WHEN IsGBX = 1 THEN 1 ELSE 0 END) AS gbx_rows,
  SUM(CASE WHEN IsGBX = 1 AND ABS(InitForexRateAfterGBX - InitForexRateBeforeGBX / 100.0) > 0.00000001 THEN 1 ELSE 0 END) AS gbx_init_rate_mismatch_rows,
  SUM(CASE WHEN IsGBX = 1 AND ABS(EndForexRateAfterGBX - EndForexRateBeforeGBX / 100.0) > 0.00000001 THEN 1 ELSE 0 END) AS gbx_end_rate_mismatch_rows
FROM {{trades_final_source}}
WHERE DATE(COALESCE(OpenOccurred, CloseOccurred)) = (SELECT report_date FROM run_parameters);
*/
