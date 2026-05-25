-- Step 5B1: Pre_Regulation price/currency/split staging parameters
-- Scope: parameter and window-equivalence helpers only (no object creation in this file).
--
-- SSIS window equivalence to preserve:
--   Occurred >= DATEADD(HOUR, -1, CAST(@StartDate AS datetime))
--   Occurred <= end of @StartDate day
--
-- Databricks-safe equivalent used in this module:
--   occurred >= (CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR)
--   occurred <= CAST(date_add(report_date, 1) AS TIMESTAMP)
--
-- NOTE:
-- - Keep report_date placeholder consistent across all Step 5B1 SQL files.
-- - Do not execute this file directly; copy the CTE into profiling/staging/validation blocks.

WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS report_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS report_end_of_day_inclusive_ts,
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS report_start_lookback_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS report_end_plus_one_day_ts
  FROM run_parameters
)
SELECT *
FROM run_window;

