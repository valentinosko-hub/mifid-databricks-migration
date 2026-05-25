-- Step 8: ASIC2 transactions staging and MiFID-owned projection (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials
--   main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
--
-- Important:
-- - Keep executable DDL gated until Step 8 source profiling passes.
-- - Do not block activation on full historical backfill.
-- - Document minimum seed needs (report date + prior-day positions, and possibly
--   prior transactions for non-MiFID carry-forward fields).
-- - EMIR UPI remains non-blocking unless proven to affect MiFID-consumed fields.

WITH gate_status AS (
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting ASIC2_Positions and open-position lifecycle parity checks.' AS gate_reason
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_asic2_transactions',
    'pending',
    'Awaiting source-profile parity and conditional fallback checks (Reg_DWH_StaticPosition).'
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions',
    'pending',
    'Awaiting verified CDE_Execution_timestamp parsing semantics and Quantity->Volume parity.'
),
history_seed_guidance AS (
  SELECT
    'minimum_seed_scope' AS guidance_key,
    'Target ReportDate source rows required for transaction build window.' AS guidance_text
  UNION ALL
  SELECT
    'prior_day_positions',
    'Prior-day ASIC2_Positions may be required for transaction parity branches.'
  UNION ALL
  SELECT
    'prior_transactions_conditional',
    'Prior ASIC2_Transactions may be needed only for non-MiFID carry-forward fields.'
)
SELECT *
FROM gate_status
ORDER BY target_object;

SELECT *
FROM history_seed_guidance
ORDER BY guidance_key;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials
USING DELTA
AS
SELECT
  CAST('{{report_date}}' AS DATE) AS ReportDate,
  op.PositionID,
  op.CID,
  op.InstrumentID,
  op.OpenOccurred,
  op.CloseOccurred,
  op.AmountInUnitsDecimal,
  op.InitForexRate,
  op.Amount,
  CAST(op.IsBuy AS TINYINT) AS IsBuy,
  CAST(op.IsSettled AS TINYINT) AS IsSettled,
  op.UpdateDate,
  op.EndForexRate,
  op.NetProfit,
  op.LastOpPriceRate,
  op.OriginalPositionID,
  op.RegulationID,
  op.InitForexPriceRateID,
  op.EndForexPriceRateID,
  op.InitConversionRate,
  op.InitialUnits,
  op.PartialCloseRatio,
  op.SettlementTypeID,
  CASE WHEN op.CloseOccurred IS NULL THEN 'O' ELSE 'C' END AS OpenORClose
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport op
WHERE op.OriginalPositionID IS NOT NULL;
*/

/*
-- Full ASIC2_Transactions shape follows SQL Server DDL.
-- Keep gated: dependencies include ext staging, positions, customer profile,
-- instrument metadata, exclusion references, and optional conditional fallbacks.
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
USING DELTA
AS
SELECT
  pos.DateID,
  pos.ReportDate,
  pos.CID,
  pos.RegulationID,
  CASE WHEN cpr.PrevRegulationID IS NULL THEN 0 ELSE 1 END AS RegChange,
  CAST(pos.PositionID AS STRING) AS `Order`,
  pos.InstrumentID,
  imd.InstrumentName AS Symbol,
  imd.ISINCode AS ISIN,
  pos.PositionID,
  CASE WHEN pos.`Close Price` IS NULL THEN 'OPEN' ELSE 'CLOSE' END AS OpenORClose,
  CASE WHEN pos.Type = 'BUY' THEN 'BUY' ELSE 'SELL' END AS IsBuy,
  CAST(pos.`Open Price` AS STRING) AS OpenPrice,
  CAST(pos.Volume AS STRING) AS Quantity,
  current_timestamp() AS UpdateDate,
  date_format(CAST(pos.`Transaction Time` AS TIMESTAMP), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS CDE_Execution_timestamp
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_positions pos
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport cpr
  ON pos.CID = cpr.CID
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata imd
  ON pos.InstrumentID = imd.InstrumentID
LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments ei
  ON pos.InstrumentID = ei.InstrumentID
LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids ep
  ON pos.PositionID = ep.PositionID
WHERE ei.InstrumentID IS NULL
  AND ep.PositionID IS NULL;
*/

/*
-- MiFID-owned projected ASIC2 subset required for ETORO compatibility flow.
-- CDE_Execution_timestamp -> OpenTime remains explicitly unproven and must pass
-- validation checks before activation.
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
USING DELTA
AS
SELECT
  DateID,
  ReportDate,
  CID,
  PositionID,
  InstrumentID,
  OpenORClose,
  IsBuy,
  COALESCE(
    to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss.SSSX"),
    to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ssX"),
    to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss'Z'")
  ) AS OpenTime,
  Quantity AS Volume,
  OpenPrice,
  RegChange
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions;
*/

