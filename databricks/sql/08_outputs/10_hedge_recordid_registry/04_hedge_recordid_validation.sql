-- Step 10: Hedge RecordID registry validation package (SELECT-ONLY).
--
-- Scope:
-- - Validate registry quality and continuity before any Hedge activation.
-- - No DDL/DML: no CREATE/INSERT/UPDATE/DELETE/MERGE/DROP in this file.
--
-- Required runtime placeholder:
--   {{hedge_registry_seed_validation_source}}
--     -> DE-migrated historical source or approved seed-test source
--        (e.g. main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report)
--
-- Optional runtime placeholders:
--   {{expected_seed_min_recordid}}  default design reference: 100253434
--   {{expected_seed_max_recordid}}  default design reference: 136314953

-- -----------------------------------------------------------------------------
-- 0) Gate/status summary
-- -----------------------------------------------------------------------------
WITH gate_status AS (
  SELECT * FROM VALUES
    ('registry_table_exists', 'required', 'Registry must exist before validation.'),
    ('historical_seed_validated', 'required', 'Historical source/seed must be validated before allocation activation.'),
    ('natural_key_signoff', 'pending', 'RecordBusinessKey final SME signoff remains required.'),
    ('hedge_activation_gate', 'pending', 'MIFID2_Hedge_Report activation remains gated until registry checks pass.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT gate_name, gate_status, gate_reason
FROM gate_status
ORDER BY gate_name;

-- -----------------------------------------------------------------------------
-- 1) Duplicate RecordID check
-- -----------------------------------------------------------------------------
SELECT
  'duplicate_recordid_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT RecordID, COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
  GROUP BY RecordID
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 2) Duplicate RecordBusinessKey check
-- -----------------------------------------------------------------------------
SELECT
  'duplicate_recordbusinesskey_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT RecordBusinessKey, COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
  GROUP BY RecordBusinessKey
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 3) Business-key uniqueness at natural-key level
-- -----------------------------------------------------------------------------
SELECT
  'duplicate_natural_key_groups' AS check_name,
  COUNT(*) AS duplicate_group_count
FROM (
  SELECT
    ReportDate,
    RegulationReportID,
    TransactionReferenceNumber,
    COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
  GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber
  HAVING COUNT(*) > 1
) d;

-- -----------------------------------------------------------------------------
-- 4) Historical RecordID preservation and reconciliation
-- -----------------------------------------------------------------------------
WITH seed_source AS (
  SELECT
    CAST(RecordID AS BIGINT) AS RecordID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(RegulationReportID AS INT) AS RegulationReportID,
    CAST(TransactionReferenceNumber AS STRING) AS TransactionReferenceNumber,
    concat_ws(
      '|',
      CAST(ReportDate AS STRING),
      CAST(RegulationReportID AS STRING),
      coalesce(trim(TransactionReferenceNumber), '')
    ) AS RecordBusinessKey
  FROM {{hedge_registry_seed_validation_source}}
  WHERE RecordID IS NOT NULL
    AND ReportDate IS NOT NULL
    AND RegulationReportID IS NOT NULL
    AND TransactionReferenceNumber IS NOT NULL
),
registry_active AS (
  SELECT
    RecordID,
    RecordBusinessKey
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
)
SELECT
  'historical_recordid_preservation_mismatch' AS check_name,
  COUNT(*) AS mismatch_count
FROM seed_source s
JOIN registry_active r
  ON s.RecordBusinessKey = r.RecordBusinessKey
WHERE s.RecordID <> r.RecordID;

-- -----------------------------------------------------------------------------
-- 5) Missing registry rows for seeded hedge rows
-- -----------------------------------------------------------------------------
WITH seed_source AS (
  SELECT
    concat_ws(
      '|',
      CAST(ReportDate AS STRING),
      CAST(RegulationReportID AS STRING),
      coalesce(trim(TransactionReferenceNumber), '')
    ) AS RecordBusinessKey
  FROM {{hedge_registry_seed_validation_source}}
  WHERE ReportDate IS NOT NULL
    AND RegulationReportID IS NOT NULL
    AND TransactionReferenceNumber IS NOT NULL
)
SELECT
  'missing_registry_rows_for_seed' AS check_name,
  COUNT(*) AS missing_row_count
FROM seed_source s
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry r
  ON s.RecordBusinessKey = r.RecordBusinessKey
 AND r.IsActive = TRUE
WHERE r.RecordBusinessKey IS NULL;

-- -----------------------------------------------------------------------------
-- 6) Registry rows not matching seeded source rows
-- -----------------------------------------------------------------------------
WITH seed_source AS (
  SELECT
    concat_ws(
      '|',
      CAST(ReportDate AS STRING),
      CAST(RegulationReportID AS STRING),
      coalesce(trim(TransactionReferenceNumber), '')
    ) AS RecordBusinessKey
  FROM {{hedge_registry_seed_validation_source}}
  WHERE ReportDate IS NOT NULL
    AND RegulationReportID IS NOT NULL
    AND TransactionReferenceNumber IS NOT NULL
)
SELECT
  'registry_rows_not_in_seed_source' AS check_name,
  COUNT(*) AS registry_only_row_count
FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry r
LEFT JOIN seed_source s
  ON r.RecordBusinessKey = s.RecordBusinessKey
WHERE r.IsActive = TRUE
  AND r.MigratedFromSQLServerFlag = TRUE
  AND s.RecordBusinessKey IS NULL;

-- -----------------------------------------------------------------------------
-- 7) Max RecordID continuity and min-threshold check
-- -----------------------------------------------------------------------------
WITH registry_stats AS (
  SELECT
    MIN(RecordID) AS min_registry_recordid,
    MAX(RecordID) AS max_registry_recordid
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
),
seed_stats AS (
  SELECT
    MIN(CAST(RecordID AS BIGINT)) AS min_seed_recordid,
    MAX(CAST(RecordID AS BIGINT)) AS max_seed_recordid
  FROM {{hedge_registry_seed_validation_source}}
  WHERE RecordID IS NOT NULL
)
SELECT
  'recordid_range_and_continuity' AS check_name,
  r.min_registry_recordid,
  r.max_registry_recordid,
  s.min_seed_recordid,
  s.max_seed_recordid,
  CASE WHEN r.max_registry_recordid >= s.max_seed_recordid THEN 0 ELSE 1 END AS max_recordid_continuity_violation_flag
FROM registry_stats r
CROSS JOIN seed_stats s;

SELECT
  'recordid_below_seed_min_for_non_migrated_rows' AS check_name,
  COUNT(*) AS below_seed_min_count
FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry r
WHERE r.IsActive = TRUE
  AND r.MigratedFromSQLServerFlag = FALSE
  AND r.RecordID < CAST({{expected_seed_min_recordid}} AS BIGINT);

-- -----------------------------------------------------------------------------
-- 8) Final validation note
-- -----------------------------------------------------------------------------
SELECT
  'validation_note' AS section_name,
  'Registry validation is SELECT-only. Hedge activation remains gated until all checks pass and SME natural-key signoff is complete.' AS note;
