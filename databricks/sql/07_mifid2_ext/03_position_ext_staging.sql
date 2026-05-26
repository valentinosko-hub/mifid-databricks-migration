-- Step 9: MIFID2_ext position staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until:
--   1) Step 9 source profiling confirms PositionForExternalUse required columns.
--   2) Customer staging contracts are confirmed (CID scope parity).
--   3) Step 6 migration-population parity is confirmed for reg-change flow.
-- - These are SSIS truncate/reload staging objects and should be materialized as Delta.

WITH staging_gates AS (
  SELECT
    'MIFID2_ext_Position' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting PositionForExternalUse source profiling and customer-scope parity validation.' AS gate_reason
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Position',
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position',
    'pending',
    'Awaiting migration interval parity (RegValidFrom/RegValidTo/RegChangeRank) and source profiling.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
customer_scope AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
trade_positions AS (
  -- SSIS parity: trade branch where Occurred is inside the report-day window.
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.LastOpConversionRate,
    p.MirrorID,
    p.InitExecutionID,
    p.EndExecutionID,
    p.HedgeServerID,
    p.IsSettled,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    p.InitialUnits,
    rp.report_date AS ReportDate
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  JOIN customer_scope c
    ON p.CID = c.CID
  JOIN run_parameters rp
    ON 1 = 1
),
history_positions AS (
  -- SSIS parity: history branch with open/close day-window logic and 2015 boundary.
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.LastOpConversionRate,
    p.MirrorID,
    p.InitExecutionID,
    p.EndExecutionID,
    p.HedgeServerID,
    p.IsSettled,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    p.InitialUnits,
    rp.report_date AS ReportDate
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND COALESCE(p.CloseOccurred, w.end_ts) >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
  JOIN customer_scope c
    ON p.CID = c.CID
  JOIN run_parameters rp
    ON 1 = 1
)
SELECT * FROM trade_positions
UNION ALL
SELECT * FROM history_positions;
*/

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
reg_population AS (
  -- Step 6 dependency: parity to migration-population support-copy behavior.
  SELECT
    p.CID,
    p.PrevRegulationID,
    p.RegulationID AS NewRegulationID,
    p.RegValidFrom,
    p.RegValidTo,
    p.RegChangeRank
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population p
  JOIN run_parameters rp
    ON p.RunDate = rp.report_date
  WHERE p.PrevRegulationID IN (1, 2, 9, 11)
),
customer_scope AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
position_union AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.LastOpConversionRate,
    p.MirrorID,
    p.InitExecutionID,
    p.EndExecutionID,
    p.HedgeServerID,
    p.IsSettled,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    p.InitialUnits
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  UNION ALL
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.LastOpConversionRate,
    p.MirrorID,
    p.InitExecutionID,
    p.EndExecutionID,
    p.HedgeServerID,
    p.IsSettled,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    p.InitialUnits
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND COALESCE(p.CloseOccurred, w.end_ts) >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
),
regchange_scoped AS (
  -- SSIS parity intent: keep rows aligned to regulation-change intervals/ranks.
  SELECT
    pu.*,
    rp.report_date AS ReportDate
  FROM position_union pu
  JOIN customer_scope c
    ON pu.CID = c.CID
  JOIN reg_population reg
    ON pu.CID = reg.CID
   AND pu.OpenOccurred < COALESCE(reg.RegValidTo, CAST('9999-12-31 00:00:00' AS TIMESTAMP))
   AND COALESCE(pu.CloseOccurred, CAST('9999-12-31 00:00:00' AS TIMESTAMP)) >= reg.RegValidFrom
  JOIN run_parameters rp
    ON 1 = 1
)
SELECT
  PositionID,
  ParentPositionID,
  CID,
  OpenOccurred,
  CloseOccurred,
  InitForexRate,
  EndForexRate,
  AmountInUnitsDecimal,
  InstrumentID,
  IsBuy,
  Leverage,
  LastOpConversionRate,
  MirrorID,
  InitExecutionID,
  EndExecutionID,
  HedgeServerID,
  IsSettled,
  InitForexPriceRateID,
  EndForexPriceRateID,
  LastOpPriceRate,
  OriginalPositionID,
  InitialUnits,
  ReportDate
FROM regchange_scoped;
*/
