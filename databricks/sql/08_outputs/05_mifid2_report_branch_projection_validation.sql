-- Step 12B3 validation templates:
-- final branch projections for MIFID2_Report / MIFID2_ME_Report /
-- MIFID2_Removed_OP_Partials.
--
-- IMPORTANT:
-- - Run after Step 12B3 branch templates are activated for a report date.
-- - Keep this as validation-only SQL; no writes.
-- - Use with:
--     03_mifid2_report_validation_foundation.sql (schema contract baseline)
--     04_mifid2_report_position_population_validation.sql (Step 12B2 boundary checks)

-- -----------------------------------------------------------------------------
-- 0) Run parameters + activation gates
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
validation_gates AS (
  SELECT *
  FROM VALUES
    ('step12b3_branch_templates_activated', 'pending', 'Final branch insert templates must be activated for the run date.'),
    ('step12b3_futuresmetadata_profiled', 'pending', 'FuturesMetaData required columns must be profiled.'),
    ('step12b3_removed_partials_source_available', 'pending', 'Step 12B2 removed-partial candidates source is required.'),
    ('step12b3_exclusion_sources_ready', 'pending', 'Excluded instruments/positions and optional MIFID2_Instruments_To_Exclude source must be available.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  vg.gate_name,
  vg.gate_status,
  vg.gate_reason
FROM run_parameters rp
CROSS JOIN validation_gates vg
ORDER BY vg.gate_name;

-- -----------------------------------------------------------------------------
-- 1) Schema parity (high-level existence + width checks)
-- Detailed column-level parity is already defined in:
--   databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql
-- -----------------------------------------------------------------------------
WITH expected_tables AS (
  SELECT *
  FROM VALUES
    ('bi_output_regtechops_mifid2_report', 100),
    ('bi_output_regtechops_mifid2_me_report', 100),
    ('bi_output_regtechops_mifid2_removed_op_partials', 26)
  AS t(table_name, expected_column_count)
),
actual_counts AS (
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
  CASE WHEN e.expected_column_count = a.actual_column_count THEN 'ok' ELSE 'mismatch' END AS status
FROM expected_tables e
LEFT JOIN actual_counts a
  ON lower(e.table_name) = lower(a.table_name)
ORDER BY e.table_name;

-- -----------------------------------------------------------------------------
-- 2) Branch classification for Step 12B3 output checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_branch_classification AS (
  SELECT
    r.*,
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
me_branch_classification AS (
  SELECT
    m.*,
    CASE
      WHEN m.RegulationReportID = 1
       AND m.RegulationID = 11
       AND m.TransactionReferenceNumber RLIKE 'ME[0-9]{8}$'
      THEN 'ME'
      ELSE 'UNCLASSIFIED'
    END AS BranchName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report m
  WHERE m.ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  'report' AS table_group,
  BranchName,
  COUNT(*) AS row_count
FROM report_branch_classification
GROUP BY BranchName
UNION ALL
SELECT
  'me_report' AS table_group,
  BranchName,
  COUNT(*) AS row_count
FROM me_branch_classification
GROUP BY BranchName
ORDER BY table_group, BranchName;

-- -----------------------------------------------------------------------------
-- 3) Row-count checks by ReportDate/RegulationReportID/RegulationID/RegChange/branch
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  RegulationID,
  RegChange,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, RegulationID, RegChange
ORDER BY RegulationReportID, RegulationID, RegChange;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  RegulationID,
  RegChange,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, RegulationID, RegChange
ORDER BY RegulationReportID, RegulationID, RegChange;

-- -----------------------------------------------------------------------------
-- 4) Duplicate checks
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
  ReportDate,
  CID,
  PositionID,
  OriginalPositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, CID, PositionID, OriginalPositionID, OpenORClose
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 5) Required null checks (including BackReportingIndicator where required)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_ReportDate,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_DateID,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_CID,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_PositionID,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_InstrumentID,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_TransactionReferenceNumber,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_TradingDateTime,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_Quantity,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_Price,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_RegulationReportID,
  SUM(CASE WHEN BackReportingIndicator IS NULL THEN 1 ELSE 0 END) AS null_BackReportingIndicator
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_ReportDate,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_DateID,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_CID,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_PositionID,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_InstrumentID,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_TransactionReferenceNumber,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_TradingDateTime,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_Quantity,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_Price,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_RegulationReportID,
  SUM(CASE WHEN BackReportingIndicator IS NULL THEN 1 ELSE 0 END) AS null_BackReportingIndicator
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 6) Branch-specific validation checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN RegulationReportID = 1 AND RegulationID = 1 THEN 1 ELSE 0 END) AS eu_cysec_count,
  SUM(CASE WHEN RegulationReportID = 2 AND RegulationID = 2 THEN 1 ELSE 0 END) AS uk_fca_count,
  SUM(CASE WHEN RegulationReportID = 1 AND RegulationID = 2 AND TransactionReferenceNumber RLIKE 'UK[OC]$' THEN 1 ELSE 0 END) AS fca_flow_in_eu_count,
  SUM(CASE WHEN RegulationReportID = 1 AND RegulationID = 9 THEN 1 ELSE 0 END) AS seychelles_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN RegulationReportID = 1 AND RegulationID = 11 THEN 1 ELSE 0 END) AS me_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- Transaction-reference behavior checks by branch.
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
-- 7) Instrument coverage checks (category-specific ISIN/CFI + SCD/full-description/
--    special-char coverage)
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

-- HARD GATE - category-specific CFI and futures coverage must be validated from a
-- pre-output source that contains IsFuture classification (for example:
-- {{report_metadata_source}} or {{trades_final_source}} enrichment), not from
-- already-projected output fields.
-- Keep this block optional/commented until the pre-output source is materialized
-- and its required columns are confirmed.
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
  -- Required normalized logical columns:
  --   InstrumentID, IsFuture
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

-- -----------------------------------------------------------------------------
-- 8) Exclusion validation (instrument/position + optional source + 341 override)
-- -----------------------------------------------------------------------------
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

-- Optional: MIFID2_Instruments_To_Exclude validation once mapping is confirmed.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS mifid2_instruments_to_exclude_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN {{mifid2_instruments_to_exclude_source}} x
  ON CAST(r.InstrumentID AS STRING) = CAST(x.InstrumentID AS STRING)
WHERE r.ReportDate = (SELECT report_date FROM run_parameters);
*/

-- InstrumentID 341 override coverage (UK branch).
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS uk_rows_for_341,
  SUM(CASE WHEN r.UnderlyingInstrumentCode IS NULL OR length(trim(r.UnderlyingInstrumentCode)) = 0 THEN 1 ELSE 0 END) AS uk_rows_for_341_missing_override
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
WHERE r.ReportDate = (SELECT report_date FROM run_parameters)
  AND r.RegulationReportID = 2
  AND r.RegulationID = 2
  AND r.InstrumentID = 341;

-- -----------------------------------------------------------------------------
-- 9) Removed partials validation (counts, reconciliation, explicit-column checklist)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS removed_partials_output_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- Candidate vs final count check (requires scoped/materialized Step 12B2 source).
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
*/

-- Candidate vs final business-key reconciliation.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
candidate_keys AS (
  SELECT
    ReportDate,
    CID,
    PositionID,
    OriginalPositionID,
    OpenORClose
  FROM {{removed_partial_candidates_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_keys AS (
  SELECT
    ReportDate,
    CID,
    PositionID,
    OriginalPositionID,
    OpenORClose
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
key_diff AS (
  SELECT 'candidate_missing_in_output' AS mismatch_type, c.*
  FROM candidate_keys c
  LEFT JOIN output_keys o
    ON c.ReportDate = o.ReportDate
   AND c.CID = o.CID
   AND c.PositionID = o.PositionID
   AND c.OriginalPositionID = o.OriginalPositionID
   AND c.OpenORClose = o.OpenORClose
  WHERE o.PositionID IS NULL
  UNION ALL
  SELECT 'output_missing_in_candidate' AS mismatch_type, o.*
  FROM output_keys o
  LEFT JOIN candidate_keys c
    ON c.ReportDate = o.ReportDate
   AND c.CID = o.CID
   AND c.PositionID = o.PositionID
   AND c.OriginalPositionID = o.OriginalPositionID
   AND c.OpenORClose = o.OpenORClose
  WHERE c.PositionID IS NULL
)
SELECT *
FROM key_diff
ORDER BY mismatch_type, CID, PositionID, OriginalPositionID, OpenORClose;
*/

-- Explicit-column insert structure check:
-- Manual review requirement:
-- - Confirm Step 12B3 SQL uses explicit target column list for
--   bi_output_regtechops_mifid2_removed_op_partials insert.
-- - Confirm the list matches all 26 DDL columns in ordinal order.

-- -----------------------------------------------------------------------------
-- 10) Aggregate checks (quantity/price/economic fields by branch)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
report_with_branch AS (
  SELECT
    CASE
      WHEN RegulationReportID = 1 AND RegulationID = 1 THEN 'EU_CYSEC'
      WHEN RegulationReportID = 2 AND RegulationID = 2 THEN 'UK_FCA'
      WHEN RegulationReportID = 1 AND RegulationID = 2 THEN 'FCA_FLOW_IN_EU'
      WHEN RegulationReportID = 1 AND RegulationID = 9 THEN 'SEYCHELLES'
      ELSE 'UNCLASSIFIED'
    END AS BranchName,
    TRY_CAST(Quantity AS DOUBLE) AS QuantityAsDouble,
    TRY_CAST(Price AS DOUBLE) AS PriceAsDouble,
    TRY_CAST(NetAmount AS DOUBLE) AS NetAmountAsDouble
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  BranchName,
  COUNT(*) AS row_count,
  SUM(QuantityAsDouble) AS quantity_sum,
  SUM(PriceAsDouble) AS price_sum,
  SUM(NetAmountAsDouble) AS net_amount_sum
FROM report_with_branch
GROUP BY BranchName
ORDER BY BranchName;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'ME' AS BranchName,
  COUNT(*) AS row_count,
  SUM(TRY_CAST(Quantity AS DOUBLE)) AS quantity_sum,
  SUM(TRY_CAST(Price AS DOUBLE)) AS price_sum,
  SUM(TRY_CAST(NetAmount AS DOUBLE)) AS net_amount_sum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);
