-- Step 15B3: MIFID2_NPD_TRAX validation and reconciliation package (read-only).
--
-- Scope:
-- - Validate output and source-to-output reconciliation readiness for:
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
--
-- Rules:
-- - SELECT-only validation SQL.
-- - Keep placeholder-dependent checks explicitly gated/commented.
-- - Do not add response handling, file/upload logic, or production deployment behavior.

-- -----------------------------------------------------------------------------
-- 0) Run parameters, target summary, and gate checklist
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax' AS target_table
),
validation_gates AS (
  SELECT *
  FROM VALUES
    ('step15_history_cutover_policy', 'pending', 'Prior/current NPD seed policy is required for exact new/existing/retry/REPL parity.'),
    ('step15_step9_failed_trax_dependency', 'pending', 'MIFID2_Failed_TRAX parity is coupled to latest NPD history availability.'),
    ('step15_upstream_customer_outputs', 'pending', 'MIFID2_Customer and MIFID2_RegChange_Customer remain gated by upstream dependencies.'),
    ('step15_upstream_report_output', 'pending', 'MIFID2_Report dependency remains gated until Step 12 gates pass.'),
    ('step15_pii_customer_access', 'pending', 'main.pii_data customer sources are still no-schema-access in latest profiling.'),
    ('step15_rownum_exact_ordering_parity', 'pending', 'Exact SQL Server ordering parity remains gated unless explicitly confirmed.'),
    ('step15_optional_candidate_sources', 'pending', 'Placeholder candidate-source checks remain gated until materialized.'),
    ('step15_optional_sqlserver_baseline', 'pending', 'SQL Server baseline comparison is optional/gated until normalized baseline source exists.'),
    ('step15_response_boundary', 'pending', 'SP_MIFID2_NPD_TRAX_Response_Update and response updates are out of scope.'),
    ('step15_delivery_boundary', 'pending', 'CSV/export/upload/SFTP/7z/Cappitech flows are out of scope.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  rp.target_table,
  vg.gate_name,
  vg.gate_status,
  vg.gate_reason
FROM run_parameters rp
CROSS JOIN validation_gates vg
ORDER BY vg.gate_name;

SELECT
  'Validation notes' AS section_name,
  'Run as read-only validation only. Placeholder-dependent checks are intentionally gated.' AS execution_note;

-- -----------------------------------------------------------------------------
-- 1) Schema parity checks
-- - column names
-- - column order
-- - data types / precision / scale (where relevant)
-- - nullability expectations (including response fields)
-- -----------------------------------------------------------------------------
WITH expected_table AS (
  SELECT
    'main' AS expected_catalog,
    'regtech_ops_stg' AS expected_schema,
    'bi_output_regtechops_mifid2_npd_trax' AS expected_table_name
),
actual_table_columns AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name,
    COUNT(*) AS actual_column_count
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_npd_trax'
  GROUP BY lower(table_catalog), lower(table_schema), lower(table_name)
)
SELECT
  e.expected_catalog,
  e.expected_schema,
  e.expected_table_name,
  a.actual_column_count,
  CASE WHEN a.table_name IS NULL THEN 'missing_table' ELSE 'present' END AS table_presence_status
FROM expected_table e
LEFT JOIN actual_table_columns a
  ON a.table_catalog = lower(e.expected_catalog)
 AND a.table_schema = lower(e.expected_schema)
 AND a.table_name = lower(e.expected_table_name);

SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  numeric_precision,
  numeric_scale
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_mifid2_npd_trax'
ORDER BY ordinal_position;

WITH expected_contract AS (
  SELECT *
  FROM VALUES
    ( 1, 'ReportDate',                     'date',      'NO',  NULL, NULL),
    ( 2, 'CID',                            'int',       'NO',  32,   0),
    ( 3, 'ReportTypeID',                   'int',       'NO',  32,   0),
    ( 4, 'Entity',                         'string',    'NO',  NULL, NULL),
    ( 5, 'RegulationID',                   'int',       'YES', 32,   0),
    ( 6, 'AccountTypeID',                  'int',       'YES', 32,   0),
    ( 7, 'IDType',                         'int',       'YES', 32,   0),
    ( 8, 'OrigPINType',                    'string',    'YES', NULL, NULL),
    ( 9, 'PIN',                            'string',    'YES', NULL, NULL),
    (10, 'NotAllowedCONCAT',               'boolean',   'YES', NULL, NULL),
    (11, 'MessageID',                      'string',    'YES', NULL, NULL),
    (12, 'Action',                         'string',    'YES', NULL, NULL),
    (13, 'InternalCode',                   'string',    'YES', NULL, NULL),
    (14, 'ExpiryDate',                     'string',    'YES', NULL, NULL),
    (15, 'EffectiveFromDate',              'string',    'YES', NULL, NULL),
    (16, 'ExecutingEntity',                'string',    'YES', NULL, NULL),
    (17, 'CountryofBranch',                'string',    'YES', NULL, NULL),
    (18, 'LEI',                            'string',    'YES', NULL, NULL),
    (19, 'LEIType',                        'string',    'YES', NULL, NULL),
    (20, 'NaturalPersonType',              'string',    'YES', NULL, NULL),
    (21, 'BusinessUnit',                   'string',    'YES', NULL, NULL),
    (22, 'ContactEmail',                   'string',    'YES', NULL, NULL),
    (23, 'ParentOfCollectiveInvestmentSchemeStatus', 'string', 'YES', NULL, NULL),
    (24, 'CountryofNationality',           'string',    'YES', NULL, NULL),
    (25, 'PassportNumber',                 'string',    'YES', NULL, NULL),
    (26, 'NationalID',                     'string',    'YES', NULL, NULL),
    (27, 'CONCAT',                         'string',    'YES', NULL, NULL),
    (28, 'FirstNames',                     'string',    'YES', NULL, NULL),
    (29, 'Surnames',                       'string',    'YES', NULL, NULL),
    (30, 'DateofBirth',                    'string',    'YES', NULL, NULL),
    (31, 'AcceptedTRAX',                   'boolean',   'YES', NULL, NULL),
    (32, 'ErrorColumn',                    'string',    'YES', NULL, NULL),
    (33, 'ErrorDescription',               'string',    'YES', NULL, NULL),
    (34, 'FailedSinceDate',                'date',      'YES', NULL, NULL),
    (35, 'DateFixedTRAX',                  'timestamp', 'YES', NULL, NULL),
    (36, 'RowNum',                         'int',       'YES', 32,   0),
    (37, 'TraxAccount',                    'string',    'YES', NULL, NULL),
    (38, 'NonLatinOrEmptyName',            'boolean',   'YES', NULL, NULL),
    (39, 'UpdateDate',                     'timestamp', 'YES', NULL, NULL)
  AS t(expected_ordinal, column_name, expected_data_type, expected_is_nullable, expected_precision, expected_scale)
),
actual_columns AS (
  SELECT
    ordinal_position,
    column_name,
    lower(data_type) AS data_type,
    upper(is_nullable) AS is_nullable,
    numeric_precision,
    numeric_scale
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_npd_trax'
)
SELECT
  e.expected_ordinal,
  e.column_name AS expected_column_name,
  a.ordinal_position AS actual_ordinal,
  a.column_name AS actual_column_name,
  e.expected_data_type,
  a.data_type AS actual_data_type,
  e.expected_is_nullable,
  a.is_nullable AS actual_is_nullable,
  e.expected_precision,
  a.numeric_precision AS actual_precision,
  e.expected_scale,
  a.numeric_scale AS actual_scale,
  CASE
    WHEN a.column_name IS NULL THEN 'missing_required_column'
    WHEN a.ordinal_position <> e.expected_ordinal THEN 'ordinal_mismatch'
    WHEN a.data_type <> e.expected_data_type THEN 'datatype_mismatch'
    WHEN a.is_nullable <> e.expected_is_nullable THEN 'nullability_mismatch'
    WHEN COALESCE(e.expected_precision, -1) <> COALESCE(a.numeric_precision, -1) THEN 'precision_mismatch'
    WHEN COALESCE(e.expected_scale, -1) <> COALESCE(a.numeric_scale, -1) THEN 'scale_mismatch'
    ELSE 'ok'
  END AS contract_status
FROM expected_contract e
LEFT JOIN actual_columns a
  ON lower(a.column_name) = lower(e.column_name)
ORDER BY e.expected_ordinal;

-- -----------------------------------------------------------------------------
-- 2) Duplicate checks (PK intent: ReportDate, Entity, CID)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  Entity,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, Entity, CID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, Entity, CID;

-- -----------------------------------------------------------------------------
-- 3) Required null checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'ReportDate' AS required_field,
  COUNT(*) AS null_row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND ReportDate IS NULL
UNION ALL
SELECT
  'CID',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND CID IS NULL
UNION ALL
SELECT
  'ReportTypeID',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND ReportTypeID IS NULL
UNION ALL
SELECT
  'Entity',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND Entity IS NULL;

-- -----------------------------------------------------------------------------
-- 4) Row-count checks
-- - by ReportDate / Entity / RegulationID / Action / AcceptedTRAX
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'BY_REPORTDATE' AS metric_name,
  CAST(ReportDate AS STRING) AS metric_key_1,
  CAST(NULL AS STRING) AS metric_key_2,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate
UNION ALL
SELECT
  'BY_ENTITY',
  COALESCE(CAST(Entity AS STRING), '<NULL>'),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY Entity
UNION ALL
SELECT
  'BY_REGULATIONID',
  COALESCE(CAST(RegulationID AS STRING), '<NULL>'),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY RegulationID
UNION ALL
SELECT
  'BY_ACTION',
  COALESCE(CAST(Action AS STRING), '<NULL>'),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY Action
UNION ALL
SELECT
  'BY_ACCEPTEDTRAX',
  CASE
    WHEN AcceptedTRAX IS NULL THEN 'NULL_SENDABLE'
    WHEN AcceptedTRAX = 0 THEN '0_NOT_SENT'
    WHEN AcceptedTRAX = 1 THEN '1_ACCEPTED'
    ELSE CAST(AcceptedTRAX AS STRING)
  END,
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY
  CASE
    WHEN AcceptedTRAX IS NULL THEN 'NULL_SENDABLE'
    WHEN AcceptedTRAX = 0 THEN '0_NOT_SENT'
    WHEN AcceptedTRAX = 1 THEN '1_ACCEPTED'
    ELSE CAST(AcceptedTRAX AS STRING)
  END
ORDER BY metric_name, metric_key_1;

-- -----------------------------------------------------------------------------
-- 5) AcceptedTRAX and invalid-name behavior checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS sendable_rows_acceptedtrax_null
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX IS NULL;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS invalid_rows_with_expected_error
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX = 0
  AND ErrorDescription = 'Not Sent. Invalid Name detected';

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS invalid_rows_missing_expected_error
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX = 0
  AND (ErrorDescription IS NULL OR ErrorDescription <> 'Not Sent. Invalid Name detected');

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
prior_latest_ids AS (
  SELECT
    CID,
    RegulationID,
    MAX(ReportDate) AS latest_report_date
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate < (SELECT report_date FROM run_parameters)
  GROUP BY CID, RegulationID
),
prior_latest_rows AS (
  SELECT p.*
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax p
  INNER JOIN prior_latest_ids i
    ON p.CID = i.CID
   AND COALESCE(p.RegulationID, -1) = COALESCE(i.RegulationID, -1)
   AND p.ReportDate = i.latest_report_date
)
SELECT
  COUNT(*) AS current_rows_with_prior_retry_eligibility
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax cur
INNER JOIN prior_latest_rows prv
  ON cur.CID = prv.CID
 AND COALESCE(cur.RegulationID, -1) = COALESCE(prv.RegulationID, -1)
WHERE cur.ReportDate = (SELECT report_date FROM run_parameters)
  AND (prv.AcceptedTRAX = 0 OR prv.AcceptedTRAX IS NULL);

-- -----------------------------------------------------------------------------
-- 6) RowNum checks
-- - assigned only where AcceptedTRAX IS NULL
-- - NULL for invalid/not-sent rows
-- - partition summary by Entity
-- - exact ordering parity remains hard-gated
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS rownum_present_for_non_sendable_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX IS NOT NULL
  AND RowNum IS NOT NULL;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS sendable_rows_missing_rownum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX IS NULL
  AND RowNum IS NULL;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  Entity,
  COUNT(*) AS sendable_rows,
  COUNT(DISTINCT RowNum) AS distinct_rownum_count,
  MIN(RowNum) AS min_rownum,
  MAX(RowNum) AS max_rownum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND AcceptedTRAX IS NULL
GROUP BY Entity
ORDER BY Entity;

-- Gated exact-ordering parity check:
-- Exact SQL Server ordering proof is optional and must remain gated unless ordering contract is explicitly approved.
-- Placeholder (commented): compare SQL Server-normalized ordering evidence when available.
/*
SELECT
  'rownum_exact_ordering_parity_gated' AS check_name,
  'pending' AS check_status,
  'Requires approved exact SQL Server row-order contract and baseline evidence.' AS check_note;
*/

-- -----------------------------------------------------------------------------
-- 7) History/seed checks
-- - prior latest row per CID/RegulationID
-- - missing-seed warning
-- - seed coverage summary
-- - forward-only warning if no seed exists
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
prior_latest_ids AS (
  SELECT
    CID,
    RegulationID,
    MAX(ReportDate) AS latest_report_date
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate < (SELECT report_date FROM run_parameters)
  GROUP BY CID, RegulationID
),
current_ids AS (
  SELECT DISTINCT
    CID,
    RegulationID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS current_cid_reg_pairs,
  COUNT(i.CID) AS current_pairs_with_prior_seed,
  COUNT(*) - COUNT(i.CID) AS current_pairs_missing_prior_seed,
  MAX(i.latest_report_date) AS max_prior_seed_reportdate
FROM current_ids c
LEFT JOIN prior_latest_ids i
  ON c.CID = i.CID
 AND COALESCE(c.RegulationID, -1) = COALESCE(i.RegulationID, -1);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
prior_seed_summary AS (
  SELECT
    COUNT(*) AS prior_seed_rows,
    MAX(ReportDate) AS max_prior_reportdate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate < (SELECT report_date FROM run_parameters)
)
SELECT
  prior_seed_rows,
  max_prior_reportdate,
  CASE
    WHEN prior_seed_rows = 0 THEN 'FORWARD_ONLY_WARNING_NO_SEED'
    ELSE 'SEED_PRESENT'
  END AS seed_coverage_status
FROM prior_seed_summary;

-- -----------------------------------------------------------------------------
-- 8) Exclusion checks
-- - excluded CIDs source: main.regtech_stg...regulation_report_excluded_cids
-- - excluded CIDs absent from output
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  o.ReportDate,
  o.Entity,
  o.CID,
  o.RegulationID
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax o
INNER JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids ex
  ON o.CID = ex.CID
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
ORDER BY o.Entity, o.CID;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_cids_present_in_output
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax o
INNER JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids ex
  ON o.CID = ex.CID
WHERE o.ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 9) Source-to-output checks (placeholder-dependent, gated/commented)
-- -----------------------------------------------------------------------------
-- These checks remain gated until candidate sources/checkpoints are materialized.
-- Expected placeholders:
--   {{npd_customer_all_source}}
--   {{npd_new_candidates_source}}
--   {{npd_existing_changed_source}}
--   {{npd_failed_retry_source}}

/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'customer_all_candidates_count' AS metric_name,
  COUNT(*) AS metric_value
FROM {{npd_customer_all_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
UNION ALL
SELECT
  'new_candidates_count',
  COUNT(*)
FROM {{npd_new_candidates_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
UNION ALL
SELECT
  'existing_changed_candidates_count',
  COUNT(*)
FROM {{npd_existing_changed_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
UNION ALL
SELECT
  'failed_retry_candidates_count',
  COUNT(*)
FROM {{npd_failed_retry_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
UNION ALL
SELECT
  'final_output_rows_count',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = (SELECT report_date FROM run_parameters);
*/

/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
expected_candidates AS (
  SELECT
    COUNT(*) AS expected_candidate_count
  FROM (
    SELECT CID, RegulationID FROM {{npd_new_candidates_source}} WHERE ReportDate = (SELECT report_date FROM run_parameters)
    UNION ALL
    SELECT CID, RegulationID FROM {{npd_existing_changed_source}} WHERE ReportDate = (SELECT report_date FROM run_parameters)
    UNION ALL
    SELECT CID, RegulationID FROM {{npd_failed_retry_source}} WHERE ReportDate = (SELECT report_date FROM run_parameters)
  ) s
),
actual_output AS (
  SELECT
    COUNT(*) AS actual_output_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  e.expected_candidate_count,
  a.actual_output_count,
  a.actual_output_count - e.expected_candidate_count AS output_minus_expected
FROM expected_candidates e
CROSS JOIN actual_output a;
*/

-- -----------------------------------------------------------------------------
-- 10) Optional SQL Server baseline comparison (gated/commented)
-- -----------------------------------------------------------------------------
-- Optional placeholder for normalized SQL Server baseline source.
-- Do not require this check for template authoring.
-- Placeholder: {{sqlserver_npd_trax_baseline_source}}

/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
databricks_counts AS (
  SELECT
    COUNT(*) AS databricks_row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
sqlserver_counts AS (
  SELECT
    COUNT(*) AS sqlserver_row_count
  FROM {{sqlserver_npd_trax_baseline_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  d.databricks_row_count,
  s.sqlserver_row_count,
  d.databricks_row_count - s.sqlserver_row_count AS row_count_delta
FROM databricks_counts d
CROSS JOIN sqlserver_counts s;
*/

/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
databricks_keys AS (
  SELECT ReportDate, Entity, CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
sqlserver_keys AS (
  SELECT ReportDate, Entity, CID
  FROM {{sqlserver_npd_trax_baseline_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  'in_databricks_not_in_sqlserver' AS delta_type,
  COUNT(*) AS key_delta_count
FROM databricks_keys d
LEFT ANTI JOIN sqlserver_keys s
  ON d.ReportDate = s.ReportDate
 AND d.Entity = s.Entity
 AND d.CID = s.CID
UNION ALL
SELECT
  'in_sqlserver_not_in_databricks',
  COUNT(*)
FROM sqlserver_keys s
LEFT ANTI JOIN databricks_keys d
  ON d.ReportDate = s.ReportDate
 AND d.Entity = s.Entity
 AND d.CID = s.CID;
*/

