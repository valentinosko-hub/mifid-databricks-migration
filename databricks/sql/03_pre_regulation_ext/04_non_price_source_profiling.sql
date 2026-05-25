-- Step 5B2: source profiling for non-price Pre_Regulation_Ext staging.
-- Scope:
--   - Reg_Ext_MigrationInOut_STG
--   - Reg_MigrationInOut_Population
--   - Reg_RegulationInOutDailyData
--   - Reg_Ext_CustomerLatinName
--   - Reg_Ext_HistorySplitRatio
--   - Reg_Ext_Trade_GetInstrument
--   - Reg_Ext_Trade_InstrumentMetaData
--   - Reg_Ext_DictionaryCurrency
--   - Reg_Ext_DictionaryCurrencyType
--   - Reg_Ext_HedgeExecutionLog
--   - Reg_Ext_HedgeHBCExecutionLog
--   - Reg_Ext_HedgeHBCOrderLog
--   - Reg_Instruments_ext
--
-- Do not create staging tables from this file. Use it to verify access and
-- required columns before any Step 5B2 CREATE OR REPLACE TABLE SQL is authored.

-- -----------------------------------------------------------------------------
-- 1) Expected source inventory
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'reg_migrationinout_population_gold' AS source_key, 'Reg_MigrationInOut_Population' AS staging_object, 'main' AS table_catalog, 'regtech' AS table_schema, 'gold_regtech_reg_migrationinout_population' AS table_name, 'confirmed gold / materialization decision pending' AS source_status UNION ALL
  SELECT 'reg_regulationinoutdailydata_gold', 'Reg_RegulationInOutDailyData', 'main', 'regtech', 'gold_regtech_reg_regulationinoutdailydata', 'confirmed gold / materialization decision pending' UNION ALL
  SELECT 'reg_ext_customerlatinname_expected', 'Reg_Ext_CustomerLatinName', 'main', 'general', 'bronze_etoro_customer_customerlatinname', 'expected source / access pending' UNION ALL
  SELECT 'reg_ext_historysplitratio_candidate', 'Reg_Ext_HistorySplitRatio', 'main', 'dealing', 'bronze_pricelog_history_splitratio', 'candidate source / required-column validation pending' UNION ALL
  SELECT 'reg_ext_trade_getinstrument_expected', 'Reg_Ext_Trade_GetInstrument', 'main', 'trading', 'bronze_etoro_trade_getinstrument', 'expected source / access pending' UNION ALL
  SELECT 'reg_ext_trade_instrumentmetadata_expected', 'Reg_Ext_Trade_InstrumentMetaData', 'main', 'trading', 'bronze_etoro_trade_instrumentmetadata', 'expected source / access pending' UNION ALL
  SELECT 'reg_ext_dictionarycurrency_expected', 'Reg_Ext_DictionaryCurrency', 'main', 'general', 'bronze_etoro_dictionary_currency', 'expected source / access pending' UNION ALL
  SELECT 'reg_ext_dictionarycurrencytype_expected', 'Reg_Ext_DictionaryCurrencyType', 'main', 'general', 'bronze_etoro_dictionary_currencytype', 'expected source / access pending' UNION ALL
  SELECT 'reg_ext_hedgeexecutionlog_confirmed', 'Reg_Ext_HedgeExecutionLog', 'main', 'dealing', 'bronze_etoro_hedge_executionlog', 'confirmed raw source / package filter validation pending' UNION ALL
  SELECT 'reg_ext_hedgehbcexecutionlog_confirmed', 'Reg_Ext_HedgeHBCExecutionLog', 'main', 'dealing', 'bronze_etoro_hedge_hbcexecutionlog', 'confirmed raw source / package filter validation pending' UNION ALL
  SELECT 'reg_ext_hedgehbcorderlog_confirmed', 'Reg_Ext_HedgeHBCOrderLog', 'main', 'dealing', 'bronze_etoro_hedge_hbcorderlog', 'confirmed raw source / package filter validation pending' UNION ALL
  SELECT 'reg_instruments_scd_gold', 'Reg_Instruments_ext', 'main', 'regtech', 'gold_regtech_reg_instruments_scd', 'confirmed certified source / SSIS-shape validation pending' UNION ALL
  SELECT 'reg_instruments_full_description_gold', 'Reg_Instruments_ext', 'main', 'regtech', 'gold_regtech_reg_instruments_full_description', 'confirmed certified source / SSIS-shape validation pending'
),
source_columns AS (
  SELECT
    st.source_key,
    st.staging_object,
    st.table_catalog,
    st.table_schema,
    st.table_name,
    st.source_status,
    c.column_name,
    c.data_type
  FROM source_targets st
  LEFT JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(st.table_catalog)
   AND lower(c.table_schema) = lower(st.table_schema)
   AND lower(c.table_name) = lower(st.table_name)
)
SELECT
  source_key,
  staging_object,
  table_catalog,
  table_schema,
  table_name,
  source_status,
  COUNT(column_name) AS visible_column_count
FROM source_columns
GROUP BY source_key, staging_object, table_catalog, table_schema, table_name, source_status
ORDER BY staging_object, source_key;

-- -----------------------------------------------------------------------------
-- 2) Required-column coverage by expected/candidate source
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'reg_migrationinout_population_gold' AS source_key, 'main' AS table_catalog, 'regtech' AS table_schema, 'gold_regtech_reg_migrationinout_population' AS table_name UNION ALL
  SELECT 'reg_ext_customerlatinname_expected', 'main', 'general', 'bronze_etoro_customer_customerlatinname' UNION ALL
  SELECT 'reg_ext_historysplitratio_candidate', 'main', 'dealing', 'bronze_pricelog_history_splitratio' UNION ALL
  SELECT 'reg_ext_trade_getinstrument_expected', 'main', 'trading', 'bronze_etoro_trade_getinstrument' UNION ALL
  SELECT 'reg_ext_trade_instrumentmetadata_expected', 'main', 'trading', 'bronze_etoro_trade_instrumentmetadata' UNION ALL
  SELECT 'reg_ext_dictionarycurrency_expected', 'main', 'general', 'bronze_etoro_dictionary_currency' UNION ALL
  SELECT 'reg_ext_dictionarycurrencytype_expected', 'main', 'general', 'bronze_etoro_dictionary_currencytype' UNION ALL
  SELECT 'reg_ext_hedgeexecutionlog_confirmed', 'main', 'dealing', 'bronze_etoro_hedge_executionlog' UNION ALL
  SELECT 'reg_ext_hedgehbcexecutionlog_confirmed', 'main', 'dealing', 'bronze_etoro_hedge_hbcexecutionlog' UNION ALL
  SELECT 'reg_ext_hedgehbcorderlog_confirmed', 'main', 'dealing', 'bronze_etoro_hedge_hbcorderlog' UNION ALL
  SELECT 'reg_instruments_scd_gold', 'main', 'regtech', 'gold_regtech_reg_instruments_scd'
),
required_columns AS (
  SELECT 'reg_migrationinout_population_gold' AS source_key, col AS column_name FROM VALUES
    ('RunDate'), ('CID'), ('Lei'), ('RegulationID'), ('Migration_Occurred'), ('PrevRegulationID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_customerlatinname_expected', col FROM VALUES
    ('CID'), ('FirstName'), ('LastName'), ('ModifiedDate'), ('Address'), ('City'), ('MiddleName')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_historysplitratio_candidate', col FROM VALUES
    ('InstrumentID'), ('MinDate'), ('MaxDate'), ('AmountRatio'), ('IsCompletedOpenPositions'),
    ('AmountRatioUnAdjusted'), ('PriceRatio'), ('PriceRatioUnAdjusted')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_trade_getinstrument_expected', col FROM VALUES
    ('InstrumentID'), ('BuyCurrencyID'), ('SellCurrencyID'), ('InstrumentTypeID'), ('Name'),
    ('TradeRange'), ('DollarRatio'), ('Passport'), ('PipDifferenceThreshold'), ('IsMajor'),
    ('Industry'), ('ExchangeID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_trade_instrumentmetadata_expected', col FROM VALUES
    ('InstrumentID'), ('InstrumentDisplayName'), ('InstrumentTypeImage'), ('Ticker'), ('ChartTicker'),
    ('InstrumentImageSmall'), ('InstrumentImageMedium'), ('InstrumentImageLarge'), ('Exchange'),
    ('Industry'), ('CompanyInfo'), ('DailyRolloverFee'), ('WeekendRolloverFee'), ('ContractRolloverFee'),
    ('InstrumentVisible'), ('Symbol'), ('CandleTimeframeGroup'), ('SymbolFull'), ('Tradable'),
    ('ExchangeID'), ('StocksIndustryID'), ('ISINCode'), ('ISINCountryCode'), ('ContractExpire'),
    ('InstrumentTypeSubCategoryID'), ('InstrumentTypeID'), ('PriceSourceID'), ('Cusip'), ('CreateDate'),
    ('UnderlyingExchangeID'), ('DbLoginName'), ('AppLoginName'), ('SysStartTime'), ('SysEndTime')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_dictionarycurrency_expected', col FROM VALUES
    ('CurrencyID'), ('CurrencyTypeID'), ('Name'), ('Abbreviation'), ('Mask'), ('EEAStockExchange'),
    ('ISINCode'), ('CurrencySymbol'), ('InterestRateID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_dictionarycurrencytype_expected', col FROM VALUES
    ('CurrencyTypeID'), ('Name'), ('MinPositionAmountAbsolute'), ('Priority'), ('PricesBy'),
    ('SLTPApproachPercent'), ('ImageUrl')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_hedgeexecutionlog_confirmed', col FROM VALUES
    ('LogTime'), ('HedgeServerID'), ('LiquidityAccountID'), ('InstrumentID'), ('OrderID'),
    ('ParentOrderID'), ('Units'), ('IsBuy'), ('OrderState'), ('ProviderOrderID'), ('SendTime'),
    ('ProviderExecID'), ('ExecutionTime'), ('ExecutionRate'), ('FailID'), ('FailReason'), ('Success'),
    ('ProviderPartyIds'), ('ReceivedTime'), ('ProviderUnits'), ('RateIDAtSent'), ('EMSOrderID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_hedgehbcexecutionlog_confirmed', col FROM VALUES
    ('ExecutionID'), ('HedgeServerID'), ('LiquidityAccountID'), ('InstrumentID'), ('IsBuy'), ('IsSuccess'),
    ('RequestAmountInLots'), ('ExecutionAmountInLots'), ('ExecutionRate'), ('StartTime'), ('EndTime'),
    ('FailReason'), ('LPExecutionRate'), ('MarketRateIDAtExecutionEnd'), ('ShouldWaitForConfirm'),
    ('InitialRate'), ('IsCancelExecution'), ('CancelledExecutionID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_hedgehbcorderlog_confirmed', col FROM VALUES
    ('OrderID'), ('ExecutionID'), ('HedgeID'), ('IsBuy'), ('IsCancelOrder'), ('OrderState'),
    ('RequestAmountInLots'), ('ExecutionAmountInLots'), ('ExecutionRate'), ('StartTime'), ('EndTime'),
    ('FailReason')
  AS t(col)
  UNION ALL
  SELECT 'reg_instruments_scd_gold', col FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('InstrumentDisplayName'), ('Symbol'), ('SymbolFull'),
    ('Tradable'), ('ISINCode'), ('InstrumentVisible'), ('BuyCurrencyID'), ('SellCurrencyID'),
    ('ContractExpire'), ('ExchangeID'), ('VisibleInternallyOnly'), ('UpdateDate'), ('IsFuture')
  AS t(col)
),
available_columns AS (
  SELECT
    st.source_key,
    c.column_name
  FROM source_targets st
  JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(st.table_catalog)
   AND lower(c.table_schema) = lower(st.table_schema)
   AND lower(c.table_name) = lower(st.table_name)
)
SELECT
  rc.source_key,
  rc.column_name AS missing_required_column
FROM required_columns rc
LEFT JOIN available_columns ac
  ON rc.source_key = ac.source_key
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.source_key, rc.column_name;

-- -----------------------------------------------------------------------------
-- 3) Run-window profiling templates for daily hedge extracts
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
)
SELECT
  'Reg_Ext_HedgeExecutionLog' AS staging_object,
  COUNT(*) AS source_row_count,
  MIN(LogTime) AS min_logtime,
  MAX(LogTime) AS max_logtime
FROM main.dealing.bronze_etoro_hedge_executionlog src
JOIN run_window w
  ON src.LogTime >= w.window_start_ts
 AND src.LogTime < w.window_end_ts
UNION ALL
SELECT
  'Reg_Ext_HedgeHBCExecutionLog' AS staging_object,
  COUNT(*) AS source_row_count,
  MIN(StartTime) AS min_logtime,
  MAX(EndTime) AS max_logtime
FROM main.dealing.bronze_etoro_hedge_hbcexecutionlog src
JOIN run_window w
  ON src.StartTime >= w.window_start_ts
 AND src.EndTime < w.window_end_ts
WHERE src.IsSuccess = 1
UNION ALL
SELECT
  'Reg_Ext_HedgeHBCOrderLog' AS staging_object,
  COUNT(*) AS source_row_count,
  MIN(StartTime) AS min_logtime,
  MAX(EndTime) AS max_logtime
FROM main.dealing.bronze_etoro_hedge_hbcorderlog src
JOIN run_window w
  ON src.EndTime >= w.window_start_ts
 AND src.EndTime < w.window_end_ts;

-- -----------------------------------------------------------------------------
-- 4) Migration/daily-data gold profiling templates
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'Reg_MigrationInOut_Population' AS staging_object,
  COUNT(*) AS gold_row_count,
  COUNT(DISTINCT CID) AS cid_count,
  MIN(Migration_Occurred) AS min_migration_occurred,
  MAX(Migration_Occurred) AS max_migration_occurred
FROM main.regtech.gold_regtech_reg_migrationinout_population src
JOIN run_parameters p
  ON src.RunDate = p.report_date;

-- `Reg_RegulationInOutDailyData` output columns are not visible in the DTSX.
-- First profile its schema in query (1), then add report-date/key checks once
-- the gold contract is confirmed.

