-- Step 8: ASIC2 positions and instrument metadata staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata
--   main.regtech_ops_stg.bi_output_regtechops_asic2_positions
--
-- Clarification gates:
-- - SP_ASIC2_Instrument_Automation is conditional:
--   activate only if profiling proves ASIC2_InstrumentMetaData cannot be derived
--   from profiled Step 4/Step 5 source contracts.
-- - SP_ASIC2_PositionReport_Agg outputs remain out of scope unless profiling
--   proves they directly feed ASIC2_Positions or ASIC2_Transactions.
-- - Reg_DWH_StaticPosition remains conditional/legacy and does not block Step 8
--   unless OpenPrice parity checks prove impact on MiFID-consumed fields.

WITH staging_gates AS (
  SELECT
    'ASIC2_InstrumentMetaData' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting Step 5B2 source profiling and conditional automation-path confirmation.' AS gate_reason
  UNION ALL
  SELECT
    'ASIC2_Positions',
    'main.regtech_ops_stg.bi_output_regtechops_asic2_positions',
    'pending',
    'Awaiting ext/customer/profile parity and aggregate-dependency confirmation.'
),
conditional_dependencies AS (
  SELECT
    'SP_ASIC2_Instrument_Automation' AS dependency_name,
    'conditional' AS dependency_status,
    'Out of scope unless profiling proves required for ASIC2_InstrumentMetaData parity.' AS dependency_rule
  UNION ALL
  SELECT
    'SP_ASIC2_PositionReport_Agg',
    'conditional',
    'Out of scope unless direct feed into ASIC2_Positions/ASIC2_Transactions is proven.'
  UNION ALL
  SELECT
    'Reg_DWH_StaticPosition',
    'conditional',
    'Do not block activation unless OpenPrice fallback impact is evidenced.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

SELECT *
FROM conditional_dependencies
ORDER BY dependency_name;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
-- Intended shape from SQL Server DDL:
-- InstrumentID, InstrumentTypeID, Exchange, BuyCurrencyID, SellCurrencyID,
-- ISINCode, BuyAbbreviation, SellAbbreviation, InstrumentName, IsGBX,
-- ISINCountryCode, InstrumentOfficialName, DollarRatio, Precision
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata
USING DELTA
AS
SELECT
  r.InstrumentID,
  r.InstrumentTypeID,
  r.Exchange,
  r.BuyCurrencyID,
  r.SellCurrencyID,
  r.ISINCode,
  buy_curr.Abbreviation AS BuyAbbreviation,
  sell_curr.Abbreviation AS SellAbbreviation,
  r.InstrumentDisplayName AS InstrumentName,
  CASE WHEN UPPER(sell_curr.Abbreviation) = 'GBX' THEN 1 ELSE 0 END AS IsGBX,
  r.IsinCountryCode AS ISINCountryCode,
  full_desc.InstrumentOfficialName,
  r.DollarRatio,
  r.Precision
FROM main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency buy_curr
  ON r.BuyCurrencyID = buy_curr.CurrencyID
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency sell_curr
  ON r.SellCurrencyID = sell_curr.CurrencyID
LEFT JOIN main.regtech.gold_regtech_reg_instruments_full_description full_desc
  ON r.InstrumentID = full_desc.InstrumentID;
*/

/*
-- Intended shape from SQL Server DDL:
-- ReportDate, DateID, CID, PositionID, InstrumentID, Deal, Login,
-- [Transaction Time], Type, Symbol, Volume, [Open Price], [Close Price],
-- Profit, [Login Name], UpdateDate, LEI, ValuationDateTime, RegulationID
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_positions
USING DELTA
AS
SELECT
  CAST('{{report_date}}' AS DATE) AS ReportDate,
  CAST(date_format(CAST('{{report_date}}' AS DATE), 'yyyyMMdd') AS INT) AS DateID,
  op.CID,
  op.PositionID,
  op.InstrumentID,
  CAST(op.PositionID AS STRING) AS Deal,
  CAST(op.CID AS STRING) AS Login,
  op.OpenOccurred AS `Transaction Time`,
  CASE WHEN op.IsBuy = 1 THEN 'BUY' ELSE 'SELL' END AS Type,
  imd.InstrumentName AS Symbol,
  op.AmountInUnitsDecimal AS Volume,
  op.InitForexRate AS `Open Price`,
  op.EndForexRate AS `Close Price`,
  op.NetProfit AS Profit,
  CONCAT_WS(' ', cpr.FirstName, cpr.LastName) AS `Login Name`,
  current_timestamp() AS UpdateDate,
  cpr.LEI,
  op.UpdateDate AS ValuationDateTime,
  op.RegulationID
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport op
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport cpr
  ON op.CID = cpr.CID
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata imd
  ON op.InstrumentID = imd.InstrumentID;
*/

