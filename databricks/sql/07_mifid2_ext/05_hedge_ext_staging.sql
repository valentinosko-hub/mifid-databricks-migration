-- Step 9: MIFID2_ext hedge execution staging (gated authoring).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until source profiling passes.
-- - Source mapping is confirmed, but required-column validation is still mandatory.
-- - Downstream hedge reporting also depends on Step 7 liquidity SCD parity.

WITH staging_gates AS (
  SELECT
    'MIFID2_ext_HedgeExecutionLog' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting required-column profiling and hedge filter-parity validation.'
      AS gate_reason
)
SELECT *
FROM staging_gates;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATE ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
)
SELECT
  h.OrderID,
  h.HedgeServerID,
  h.InstrumentID,
  h.IsBuy,
  h.Units,
  h.ExecutionRate,
  h.ProviderExecID,
  h.ExecutionTime,
  h.Success,
  h.LogTime,
  h.LiquidityAccountID,
  h.EMSOrderID
FROM main.dealing.bronze_etoro_hedge_executionlog h
JOIN run_window w
  ON h.ExecutionTime >= w.start_ts
 AND h.ExecutionTime < w.end_ts
WHERE NOT (h.ProviderExecID IS NULL AND h.OrderState = 4);
*/
