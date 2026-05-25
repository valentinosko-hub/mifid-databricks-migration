-- Step 6: Regulation movement validation templates.
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
--
-- These checks are meant to run only after Step 6 staging is materialized.

-- -----------------------------------------------------------------------------
-- 1) Row count by ReportDate
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
GROUP BY ReportDate
ORDER BY ReportDate;

-- -----------------------------------------------------------------------------
-- 2) Duplicate checks by ReportDate, CID, PositionID
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  CID,
  PositionID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
GROUP BY ReportDate, CID, PositionID
HAVING COUNT(*) > 1;

-- 2a) Stricter duplicate check for position-level rows only
SELECT
  ReportDate,
  CID,
  PositionID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
WHERE PositionID IS NOT NULL
GROUP BY ReportDate, CID, PositionID
HAVING COUNT(*) > 1;

-- 2b) Migration-only duplicate check (PositionID is intentionally NULL)
SELECT
  ReportDate,
  CID,
  RegulationID,
  PrevRegulationID,
  Migration_Occurred,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
WHERE PositionID IS NULL
GROUP BY ReportDate, CID, RegulationID, PrevRegulationID, Migration_Occurred
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 3) Null checks for required fields
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN PrevRegulationID IS NULL THEN 1 ELSE 0 END) AS null_prevregulationid_count,
  SUM(CASE WHEN Migration_Occurred IS NULL THEN 1 ELSE 0 END) AS null_migration_occurred_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions;

-- -----------------------------------------------------------------------------
-- 4) Counts by RegulationID / PrevRegulationID
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  RegulationID,
  PrevRegulationID,
  COUNT(*) AS movement_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
GROUP BY ReportDate, RegulationID, PrevRegulationID
ORDER BY ReportDate, RegulationID, PrevRegulationID;

-- -----------------------------------------------------------------------------
-- 5) IsOpenedAfterLastMigration checks
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  IsOpenedAfterLastMigration,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
GROUP BY ReportDate, IsOpenedAfterLastMigration
ORDER BY ReportDate, IsOpenedAfterLastMigration;

SELECT
  COUNT(*) AS invalid_opened_after_last_migration_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
WHERE IsOpenedAfterLastMigration NOT IN (0, 1)
   OR IsOpenedAfterLastMigration IS NULL;

-- -----------------------------------------------------------------------------
-- 6) Source-to-stage comparisons where practical
-- -----------------------------------------------------------------------------
-- 6a) Migration population coverage by report date
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_counts AS (
  SELECT
    COUNT(*) AS source_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population src
  JOIN run_parameters p
    ON src.RunDate = p.report_date
),
stage_counts AS (
  SELECT
    COUNT(DISTINCT CONCAT(CAST(CID AS STRING), '|', CAST(RegulationID AS STRING), '|', CAST(PrevRegulationID AS STRING), '|', CAST(Migration_Occurred AS STRING))) AS stage_migration_tuple_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions stg
  JOIN run_parameters p
    ON stg.ReportDate = p.report_date
)
SELECT
  source_count,
  stage_migration_tuple_count,
  source_count - stage_migration_tuple_count AS count_delta
FROM source_counts
CROSS JOIN stage_counts;

-- 6b) Stage rows with missing enrichment where InstrumentID exists
SELECT
  COUNT(*) AS missing_symbol_or_eod_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
WHERE InstrumentID IS NOT NULL
  AND (Symbol IS NULL OR EOD_Price IS NULL);

-- 6c) Movement branch composition (practical coverage check)
SELECT
  ReportDate,
  CASE
    WHEN PositionID IS NULL THEN 'migration_only'
    WHEN CloseOccurred IS NULL THEN 'open_position_branch'
    ELSE 'closed_position_branch'
  END AS branch_type,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
GROUP BY
  ReportDate,
  CASE
    WHEN PositionID IS NULL THEN 'migration_only'
    WHEN CloseOccurred IS NULL THEN 'open_position_branch'
    ELSE 'closed_position_branch'
  END
ORDER BY ReportDate, branch_type;

-- -----------------------------------------------------------------------------
-- 7) Optional comparison against certified gold migration population
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
gold_source AS (
  SELECT COUNT(*) AS gold_source_count
  FROM main.regtech.gold_regtech_reg_migrationinout_population src
  JOIN run_parameters p
    ON src.RunDate = p.report_date
),
stage_counts AS (
  SELECT
    COUNT(DISTINCT CONCAT(CAST(CID AS STRING), '|', CAST(RegulationID AS STRING), '|', CAST(PrevRegulationID AS STRING), '|', CAST(Migration_Occurred AS STRING))) AS stage_migration_tuple_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions stg
  JOIN run_parameters p
    ON stg.ReportDate = p.report_date
)
SELECT
  gold_source_count,
  stage_migration_tuple_count,
  gold_source_count - stage_migration_tuple_count AS count_delta
FROM gold_source
CROSS JOIN stage_counts;

