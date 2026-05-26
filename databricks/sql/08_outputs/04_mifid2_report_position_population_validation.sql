-- Step 12B2 validation templates:
-- MIFID2_Report intermediate position/trade population only (pre-branch).
--
-- Scope in this file:
-- - Validate intermediate population up to #tradesFinal equivalent.
-- - Validate removed partial candidates and customer EU/UK flag preparation.
--
-- Out of scope in this file:
-- - Final branch insert projections (EU/UK/FCA-flow-in-EU/Seychelles/ME).
-- - Final target inserts into MIFID2_Report / MIFID2_ME_Report.
-- - Finalized insert into MIFID2_Removed_OP_Partials.
-- - FuturesMetaData final-projection validations (Step 12B3).

-- -----------------------------------------------------------------------------
-- 0) Run parameter scaffold
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
intermediate_objects AS (
  SELECT *
  FROM VALUES
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates')
  AS t(intermediate_object)
),
validation_gates AS (
  SELECT 'step12b2_source_counts' AS validation_name, 'required' AS status, 'Source row-count checks by report date.' AS description
  UNION ALL
  SELECT 'step12b2_intermediate_counts', 'required', 'Intermediate row-count checks by stage and trade pool.'
  UNION ALL
  SELECT 'step12b2_open_close_counts', 'required', 'Open/close and same-day synthetic-open counts.'
  UNION ALL
  SELECT 'step12b2_partial_removed_counts', 'required', 'Partial close and removed partial candidate counts.'
  UNION ALL
  SELECT 'step12b2_regchange_counts', 'required', 'RegChange counts (0/1/2) and migration exception evidence.'
  UNION ALL
  SELECT 'step12b2_split_gbx_counts', 'required', 'Split adjustment and GBX divide-by-100 checks.'
  UNION ALL
  SELECT 'step12b2_instrument_coverage', 'required', 'Instrument metadata coverage before #tradesFinal.'
  UNION ALL
  SELECT 'step12b2_duplicates', 'required', 'Duplicate business-key checks.'
  UNION ALL
  SELECT 'step12b2_required_nulls', 'required', 'Required null checks for intermediate keys/fields.'
  UNION ALL
  SELECT 'step12b2_reconciliation', 'required', 'Source-to-intermediate reconciliation checks.'
  UNION ALL
  SELECT 'step12b3_futuresmetadata_boundary', 'deferred', 'FuturesMetaData is final-branch only and validated in Step 12B3.'
)
SELECT
  rw.report_date,
  io.intermediate_object,
  vg.validation_name,
  vg.status,
  vg.description
FROM run_window rw
CROSS JOIN intermediate_objects io
CROSS JOIN validation_gates vg
ORDER BY io.intermediate_object, vg.validation_name;

-- -----------------------------------------------------------------------------
-- 1) Source row counts (required)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  src.source_name,
  src.row_count
FROM (
  SELECT 'mifid2_customer' AS source_name, COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'mifid2_regchange_customer', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'mifid2_ext_position', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
  WHERE ReportDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'mifid2_ext_regchange_position', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
  WHERE ReportDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'mifid2_ext_positionchangelog', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog

  UNION ALL
  SELECT 'mifid2_ext_mirror', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror

  UNION ALL
  SELECT 'reg_migrationinout_population', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population
  WHERE RunDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'reg_regulation_movments_positions', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)

  UNION ALL
  SELECT 'reg_ext_historysplitratio', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio
  WHERE IsCompletedOpenPositions = 1
) src
ORDER BY src.source_name;

-- -----------------------------------------------------------------------------
-- 2) OPTIONAL - Intermediate row counts (checkpoint-dependent)
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'trade_population' AS checkpoint_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
UNION ALL
SELECT
  'customer_reg_flags',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags
UNION ALL
SELECT
  'removed_partials_candidates',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates
WHERE ReportDate = (SELECT report_date FROM run_parameters);
*/

-- -----------------------------------------------------------------------------
-- 3) OPTIONAL - Main vs reg-change / open-close / same-day counts
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  RegChange,
  OpenORClose,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
GROUP BY RegChange, OpenORClose
ORDER BY RegChange, OpenORClose;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS same_day_open_close_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
WHERE OpenORClose = 'O'
  AND DATE(OpenOccurred) = (SELECT report_date FROM run_parameters)
  AND DATE(CloseOccurred) = (SELECT report_date FROM run_parameters);
*/

-- -----------------------------------------------------------------------------
-- 4) OPTIONAL - Partial close and removed partial candidate counts
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS removed_partial_candidate_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  CID,
  OriginalPositionID,
  COUNT(*) AS rows_per_partial_family
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY CID, OriginalPositionID
ORDER BY rows_per_partial_family DESC, CID, OriginalPositionID;
*/

-- -----------------------------------------------------------------------------
-- 5) OPTIONAL - RegChange checks and 10-second exception evidence
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
WITH regchange_distribution AS (
  SELECT
    RegChange,
    COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
  GROUP BY RegChange
)
SELECT *
FROM regchange_distribution
ORDER BY RegChange;
*/

-- SQL Server parity reminder for 10-second exception:
-- keep NULL-as-not-true behavior for movement joins in the Step 12B2 CTE logic.
-- Example check to run when a movement-audit relation is available:
-- SELECT ... WHERE pm.PositionID IS NOT NULL
--   AND TIMESTAMPDIFF(SECOND, pm.OpenOccurred, pm.Migration_Occurred) <= 10;

-- -----------------------------------------------------------------------------
-- 6) OPTIONAL - Split adjustment and GBX checks
-- -----------------------------------------------------------------------------
-- OPTIONAL - do not execute split/GBX parity checks until audit fields are
-- materialized in the intermediate checkpoint output.
--
-- Required audit fields for parity-proof checks:
-- - AmountRatioSplit
-- - IsSplitAdjusted
-- - IsGBX
-- - InitForexRateBeforeGBX
-- - InitForexRateAfterGBX
-- - EndForexRateBeforeGBX
-- - EndForexRateAfterGBX
--
-- Example split/GBX checks once the fields above exist:
/*
SELECT
  COUNT(*) AS split_adjusted_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
WHERE IsSplitAdjusted = 1
  AND AmountRatioSplit IS NOT NULL;

SELECT
  COUNT(*) AS gbx_rows_mismatched_divide_100
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
WHERE IsGBX = 1
  AND (
    ABS(InitForexRateAfterGBX - InitForexRateBeforeGBX / 100.0) > 0.00000001
    OR ABS(EndForexRateAfterGBX - EndForexRateBeforeGBX / 100.0) > 0.00000001
  );
*/

-- -----------------------------------------------------------------------------
-- 7) OPTIONAL - Instrument coverage checks (pre-branch)
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
SELECT
  COUNT(*) AS missing_instrument_metadata_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population p
LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd s
  ON s.InstrumentID = p.InstrumentID
WHERE s.InstrumentID IS NULL;

SELECT
  COUNT(*) AS missing_full_description_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population p
LEFT JOIN main.regtech.gold_regtech_reg_instruments_full_description f
  ON f.InstrumentID = p.InstrumentID
WHERE f.InstrumentID IS NULL;
*/

-- -----------------------------------------------------------------------------
-- 8) OPTIONAL - Duplicate business keys
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
SELECT
  CID,
  PositionID,
  OpenORClose,
  RegChange,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population
GROUP BY CID, PositionID, OpenORClose, RegChange
HAVING COUNT(*) > 1;

SELECT
  ReportDate,
  CID,
  PositionID,
  OriginalPositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates
GROUP BY ReportDate, CID, PositionID, OriginalPositionID, OpenORClose
HAVING COUNT(*) > 1;
*/

-- -----------------------------------------------------------------------------
-- 9) OPTIONAL - Required null checks
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
SELECT
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_CID,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_PositionID,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_InstrumentID,
  SUM(CASE WHEN OpenORClose IS NULL THEN 1 ELSE 0 END) AS null_OpenORClose,
  SUM(CASE WHEN OpenOccurred IS NULL THEN 1 ELSE 0 END) AS null_OpenOccurred,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_RegChange,
  SUM(CASE WHEN OrigRegulationID IS NULL THEN 1 ELSE 0 END) AS null_OrigRegulationID
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population;

SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_ReportDate,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_CID,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_PositionID,
  SUM(CASE WHEN OriginalPositionID IS NULL THEN 1 ELSE 0 END) AS null_OriginalPositionID,
  SUM(CASE WHEN OpenORClose IS NULL THEN 1 ELSE 0 END) AS null_OpenORClose
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates;
*/

-- -----------------------------------------------------------------------------
-- 10) OPTIONAL - Source-to-intermediate reconciliation
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS trade_population_without_position_source_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population t
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position p
  ON p.PositionID = t.PositionID
 AND p.CID = t.CID
 AND p.ReportDate = (SELECT report_date FROM run_parameters)
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position pr
  ON pr.PositionID = t.PositionID
 AND pr.CID = t.CID
 AND pr.ReportDate = (SELECT report_date FROM run_parameters)
WHERE p.PositionID IS NULL
  AND pr.PositionID IS NULL;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS removed_partials_without_trade_population_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population t
  ON t.CID = r.CID
 AND t.PositionID = r.PositionID
WHERE r.ReportDate = (SELECT report_date FROM run_parameters)
  AND t.PositionID IS NULL;
*/

-- -----------------------------------------------------------------------------
-- 11) OPTIONAL - Customer flag preparation checks
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after optional checkpoint tables are materialized.
/*
SELECT
  IsEUReport,
  IsUKReport,
  COUNT(*) AS cid_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags
GROUP BY IsEUReport, IsUKReport
ORDER BY IsEUReport, IsUKReport;
*/

-- -----------------------------------------------------------------------------
-- 12) Step 12B3 boundary note
-- -----------------------------------------------------------------------------
-- FuturesMetaData validation is intentionally not included here.
-- It is deferred to Step 12B3 because FuturesMetaData is used in final branch projections.
