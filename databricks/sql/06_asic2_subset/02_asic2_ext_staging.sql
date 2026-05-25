-- Step 8: ASIC2 ext staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until source profiling
--   confirms access and required columns (`01_asic2_source_profiling.sql`).
-- - These are SSIS truncate/reload staging objects and should be materialized as Delta.
-- - No missing columns should be synthesized; unresolved source contracts remain gated.

WITH staging_gates AS (
  SELECT
    'ASIC2_ext_PositionChangeLog' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting source-column confirmation for History.PositionChangeLog parity aliases.' AS gate_reason
  UNION ALL
  SELECT
    'ASIC2_ext_OpenPositions_PositionsReport',
    'main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport',
    'pending',
    'Awaiting Trade.PositionForExternalUse / History.PositionForExternalUse profiling and package-filter parity.'
  UNION ALL
  SELECT
    'ASIC2_Customer_PositionReport',
    'main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport',
    'pending',
    'Awaiting customer/regulation source profiling and exact output-column parity.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog
USING DELTA
AS
SELECT
  PositionID,
  LastOpPriceRate AS ChangeLogLastOpPriceRate,
  Occurred AS ChangeLogOccurred,
  ChangeTypeID,
  IsSettled
FROM main.trading.bronze_etoro_history_positionchangelog;
*/

/*
-- Expected primary source from confirmed mapping:
--   main.bi_db.bronze_etoro_trade_positionforexternaluse
-- Keep commented until required columns and report-window filters are profiled.
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
USING DELTA
AS
SELECT
  PositionID,
  CID,
  InstrumentID,
  OpenOccurred,
  CloseOccurred,
  AmountInUnitsDecimal,
  InitForexRate,
  Amount,
  IsBuy,
  IsSettled,
  UpdateDate,
  EndForexRate,
  NetProfit,
  LastOpPriceRate,
  OriginalPositionID,
  RegulationID,
  InitForexPriceRateID,
  EndForexPriceRateID,
  InitConversionRate,
  InitialUnits,
  PartialCloseRatio,
  SettlementTypeID
FROM main.bi_db.bronze_etoro_trade_positionforexternaluse;
*/

/*
-- This object is intentionally gated because package/procedure logic combines
-- multiple customer/regulation sources and historical attributes.
--
-- Candidate dependencies include:
-- - main.general.bronze_etoro_customer_customer
-- - main.pii_data.bronze_etoro_history_customer
-- - main.general.bronze_etoro_dictionary_country
-- - main.general.bronze_etoro_dictionary_label
-- - main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname
-- - main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata
--
-- Keep this template commented until source contracts are fully profiled.
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport
USING DELTA
AS
SELECT
  CID,
  RegulationID,
  LabelID,
  PlayerLevelID,
  PlayerStatusID,
  ExternalID,
  PrevRegulationID,
  PrevLabelID,
  PrevPlayerLevelID,
  PrevPlayerStatusID,
  PrevLabel,
  CountryID,
  Country,
  UpdateDate,
  CurLabel,
  FirstName,
  LastName,
  LEI,
  AccountTypeID
FROM <resolved_customer_position_source>;
*/

