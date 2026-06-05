-- Step 11: Manual CSV seed validation package (SELECT-ONLY).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
--   main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
--
-- Rules:
-- - SELECT-only. No CREATE/INSERT/UPDATE/DELETE/MERGE/DROP.
-- - Staging evidence only — does not close final module activation gates.
-- - Replace {{expected_*}} placeholders with values from SQL Server export manifest.
--
-- Placeholders:
--   {{sql_server_npd_export_row_count}}
--   {{sql_server_hedge_export_row_count}}
--   {{expected_npd_min_report_date}} / {{expected_npd_max_report_date}}
--   {{expected_hedge_min_report_date}} / {{expected_hedge_max_report_date}}
--   {{expected_hedge_min_recordid}} / {{expected_hedge_max_recordid}}

-- -----------------------------------------------------------------------------
-- 0) Gate checklist
-- -----------------------------------------------------------------------------
WITH seed_gates AS (
  SELECT * FROM VALUES
    ('seed_test_staging_only', 'required', 'Validation applies to seed_test tables only; not final output activation.'),
    ('seed_test_no_main_regtech', 'required', 'No validation path should write to main.regtech.'),
    ('npd_final_activation', 'pending', 'bi_output_regtechops_mifid2_npd_trax activation remains gated after seed test.'),
    ('hedge_final_activation', 'pending', 'bi_output_regtechops_mifid2_hedge_report activation remains gated after seed test.'),
    ('delivery_boundary', 'required', 'No delivery/upload/response logic in seed testing package.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT gate_name, gate_status, gate_reason
FROM seed_gates
ORDER BY gate_name;

-- -----------------------------------------------------------------------------
-- 1) Table presence and schema checks
-- -----------------------------------------------------------------------------
SELECT
  'npd_seed_test' AS seed_object,
  table_catalog,
  table_schema,
  table_name,
  COUNT(*) AS column_count
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_seed_test_mifid2_npd_trax'
GROUP BY table_catalog, table_schema, table_name

UNION ALL

SELECT
  'hedge_seed_test' AS seed_object,
  table_catalog,
  table_schema,
  table_name,
  COUNT(*) AS column_count
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_seed_test_mifid2_hedge_report'
GROUP BY table_catalog, table_schema, table_name;

-- Critical NPD columns presence
SELECT
  'npd_critical_columns' AS check_name,
  column_name,
  data_type,
  is_nullable
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_seed_test_mifid2_npd_trax'
  AND lower(column_name) IN (
    'reportdate', 'entity', 'cid', 'acceptedtrax', 'errordescription', 'failedsincedate',
    'regulationid', 'action'
  )
ORDER BY column_name;

-- Critical Hedge columns presence
SELECT
  'hedge_critical_columns' AS check_name,
  column_name,
  data_type,
  is_nullable
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_seed_test_mifid2_hedge_report'
  AND lower(column_name) IN (
    'reportdate', 'regulationreportid', 'transactionreferencenumber', 'recordid'
  )
ORDER BY column_name;

-- -----------------------------------------------------------------------------
-- 2) NPD row-count validation
-- -----------------------------------------------------------------------------
SELECT
  'npd_row_count' AS check_name,
  COUNT(*) AS loaded_row_count,
  CAST({{sql_server_npd_export_row_count}} AS BIGINT) AS expected_sql_server_row_count,
  COUNT(*) - CAST({{sql_server_npd_export_row_count}} AS BIGINT) AS row_count_delta
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax;

-- -----------------------------------------------------------------------------
-- 3) NPD duplicate key check — (ReportDate, Entity, CID)
-- -----------------------------------------------------------------------------
SELECT
  'npd_duplicate_pk_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT
    ReportDate,
    Entity,
    CID,
    COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
  GROUP BY ReportDate, Entity, CID
  HAVING COUNT(*) > 1
) d;

SELECT
  'npd_duplicate_pk_rows' AS check_name,
  COALESCE(SUM(row_count - 1), 0) AS duplicate_row_count
FROM (
  SELECT COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
  GROUP BY ReportDate, Entity, CID
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 4) NPD AcceptedTRAX / ErrorDescription / FailedSinceDate presence checks
-- -----------------------------------------------------------------------------
SELECT
  'npd_field_presence' AS check_name,
  COUNT(*) AS total_rows,
  SUM(CASE WHEN AcceptedTRAX IS NULL THEN 1 ELSE 0 END) AS acceptedtrax_null_count,
  SUM(CASE WHEN ErrorDescription IS NULL OR length(trim(ErrorDescription)) = 0 THEN 1 ELSE 0 END) AS errordescription_null_or_blank_count,
  SUM(CASE WHEN FailedSinceDate IS NULL THEN 1 ELSE 0 END) AS failedsincedate_null_count,
  SUM(CASE WHEN AcceptedTRAX IS NOT NULL THEN 1 ELSE 0 END) AS acceptedtrax_populated_count,
  SUM(CASE WHEN ErrorDescription IS NOT NULL AND length(trim(ErrorDescription)) > 0 THEN 1 ELSE 0 END) AS errordescription_populated_count,
  SUM(CASE WHEN FailedSinceDate IS NOT NULL THEN 1 ELSE 0 END) AS failedsincedate_populated_count
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax;

-- -----------------------------------------------------------------------------
-- 5) NPD min/max ReportDate
-- -----------------------------------------------------------------------------
SELECT
  'npd_report_date_range' AS check_name,
  MIN(ReportDate) AS min_report_date,
  MAX(ReportDate) AS max_report_date,
  CAST('{{expected_npd_min_report_date}}' AS DATE) AS expected_min_report_date,
  CAST('{{expected_npd_max_report_date}}' AS DATE) AS expected_max_report_date
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax;

-- -----------------------------------------------------------------------------
-- 6) NPD null critical keys
-- -----------------------------------------------------------------------------
SELECT
  'npd_null_critical_keys' AS check_name,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN Entity IS NULL OR length(trim(Entity)) = 0 THEN 1 ELSE 0 END) AS null_or_blank_entity_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax;

-- -----------------------------------------------------------------------------
-- 7) Hedge row-count validation
-- -----------------------------------------------------------------------------
SELECT
  'hedge_row_count' AS check_name,
  COUNT(*) AS loaded_row_count,
  CAST({{sql_server_hedge_export_row_count}} AS BIGINT) AS expected_sql_server_row_count,
  COUNT(*) - CAST({{sql_server_hedge_export_row_count}} AS BIGINT) AS row_count_delta
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report;

-- -----------------------------------------------------------------------------
-- 8) Hedge duplicate RecordID check
-- -----------------------------------------------------------------------------
SELECT
  'hedge_duplicate_recordid_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT RecordID, COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
  WHERE RecordID IS NOT NULL
  GROUP BY RecordID
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 9) Hedge duplicate business key — (ReportDate, RegulationReportID, TransactionReferenceNumber)
-- -----------------------------------------------------------------------------
SELECT
  'hedge_duplicate_business_key_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT
    ReportDate,
    RegulationReportID,
    TransactionReferenceNumber,
    COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
  GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 10) Hedge RecordID min/max validation
-- -----------------------------------------------------------------------------
SELECT
  'hedge_recordid_stats' AS check_name,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT RecordID) AS distinct_recordid_count,
  MIN(RecordID) AS min_recordid,
  MAX(RecordID) AS max_recordid,
  CAST({{expected_hedge_min_recordid}} AS INT) AS expected_min_recordid,
  CAST({{expected_hedge_max_recordid}} AS INT) AS expected_max_recordid,
  SUM(CASE WHEN RecordID IS NULL THEN 1 ELSE 0 END) AS null_recordid_count,
  SUM(CASE WHEN RecordID < CAST({{expected_hedge_min_recordid}} AS INT) THEN 1 ELSE 0 END) AS recordid_below_expected_min_count,
  SUM(CASE WHEN RecordID > CAST({{expected_hedge_max_recordid}} AS INT) THEN 1 ELSE 0 END) AS recordid_above_expected_max_count
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report;

-- -----------------------------------------------------------------------------
-- 11) Hedge min/max ReportDate and null critical keys
-- -----------------------------------------------------------------------------
SELECT
  'hedge_report_date_range' AS check_name,
  MIN(ReportDate) AS min_report_date,
  MAX(ReportDate) AS max_report_date,
  CAST('{{expected_hedge_min_report_date}}' AS DATE) AS expected_min_report_date,
  CAST('{{expected_hedge_max_report_date}}' AS DATE) AS expected_max_report_date
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report;

SELECT
  'hedge_null_critical_keys' AS check_name,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_or_blank_transactionreference_count,
  SUM(CASE WHEN RecordID IS NULL THEN 1 ELSE 0 END) AS null_recordid_count
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report;

-- -----------------------------------------------------------------------------
-- 12) Summary note
-- -----------------------------------------------------------------------------
SELECT
  'validation_summary' AS section_name,
  'Seed test validation is staging evidence only. Final NPD/Hedge module activation gates remain open.' AS execution_note;
