-- Step 5B2: validation templates for non-price Pre_Regulation_Ext staging.
--
-- These checks are intended for execution only after the corresponding
-- prefixed staging tables have been materialized in main.regtech_ops_stg.

-- -----------------------------------------------------------------------------
-- 1) Required-column checks for Step 5B2 target objects
-- -----------------------------------------------------------------------------
WITH target_objects AS (
  SELECT 'Reg_Ext_MigrationInOut_STG' AS staging_object, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_reg_ext_migrationinout_stg' AS table_name UNION ALL
  SELECT 'Reg_MigrationInOut_Population', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_migrationinout_population' UNION ALL
  SELECT 'Reg_Ext_CustomerLatinName', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_customerlatinname' UNION ALL
  SELECT 'Reg_Ext_HistorySplitRatio', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_historysplitratio' UNION ALL
  SELECT 'Reg_Ext_Trade_GetInstrument', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_trade_getinstrument' UNION ALL
  SELECT 'Reg_Ext_Trade_InstrumentMetaData', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_trade_instrumentmetadata' UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrency', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrency' UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrencyType', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrencytype' UNION ALL
  SELECT 'Reg_Ext_HedgeExecutionLog', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog' UNION ALL
  SELECT 'Reg_Ext_HedgeHBCExecutionLog', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgehbcexecutionlog' UNION ALL
  SELECT 'Reg_Ext_HedgeHBCOrderLog', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgehbcorderlog' UNION ALL
  SELECT 'Reg_Instruments_ext', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_instruments_ext'
),
required_columns AS (
  SELECT 'Reg_Ext_MigrationInOut_STG' AS staging_object, col AS column_name FROM VALUES
    ('CID'), ('RegulationID'), ('PrevRegulationID'), ('InstrumentID'), ('Migration_Occurred'),
    ('TransactionID'), ('IsBuy'), ('InitForexPriceRateID'), ('EndForexPriceRateID'), ('ExecutionPrice'),
    ('Quntity'), ('ExecutionTime'), ('Lei'), ('FirstName'), ('LastName')
  AS t(col)
  UNION ALL
  SELECT 'Reg_MigrationInOut_Population', col FROM VALUES
    ('RunDate'), ('CID'), ('Lei'), ('RegulationID'), ('Migration_Occurred'), ('PrevRegulationID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_CustomerLatinName', col FROM VALUES
    ('CID'), ('FirstName'), ('LastName'), ('ModifiedDate'), ('Address'), ('City'), ('MiddleName')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_HistorySplitRatio', col FROM VALUES
    ('InstrumentID'), ('MinDate'), ('MaxDate'), ('AmountRatio'), ('IsCompletedOpenPositions'),
    ('AmountRatioUnAdjusted'), ('PriceRatio'), ('PriceRatioUnAdjusted')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_Trade_GetInstrument', col FROM VALUES
    ('InstrumentID'), ('BuyCurrencyID'), ('SellCurrencyID'), ('InstrumentTypeID'), ('Name'),
    ('TradeRange'), ('DollarRatio'), ('Passport'), ('PipDifferenceThreshold'), ('IsMajor'),
    ('Industry'), ('ExchangeID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_Trade_InstrumentMetaData', col FROM VALUES
    ('InstrumentID'), ('InstrumentDisplayName'), ('InstrumentTypeImage'), ('Ticker'), ('ChartTicker'),
    ('InstrumentImageSmall'), ('InstrumentImageMedium'), ('InstrumentImageLarge'), ('Exchange'),
    ('Industry'), ('CompanyInfo'), ('DailyRolloverFee'), ('WeekendRolloverFee'), ('ContractRolloverFee'),
    ('InstrumentVisible'), ('Symbol'), ('CandleTimeframeGroup'), ('SymbolFull'), ('Tradable'),
    ('ExchangeID'), ('StocksIndustryID'), ('ISINCode'), ('ISINCountryCode'), ('ContractExpire'),
    ('InstrumentTypeSubCategoryID'), ('InstrumentTypeID'), ('PriceSourceID'), ('Cusip'), ('CreateDate'),
    ('UnderlyingExchangeID'), ('DbLoginName'), ('AppLoginName'), ('SysStartTime'), ('SysEndTime')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrency', col FROM VALUES
    ('CurrencyID'), ('CurrencyTypeID'), ('Name'), ('Abbreviation'), ('Mask'), ('EEAStockExchange'),
    ('ISINCode'), ('CurrencySymbol'), ('InterestRateID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrencyType', col FROM VALUES
    ('CurrencyTypeID'), ('Name'), ('MinPositionAmountAbsolute'), ('Priority'), ('PricesBy'),
    ('SLTPApproachPercent'), ('ImageUrl')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_HedgeExecutionLog', col FROM VALUES
    ('LogTime'), ('HedgeServerID'), ('LiquidityAccountID'), ('InstrumentID'), ('OrderID'),
    ('ParentOrderID'), ('Units'), ('IsBuy'), ('OrderState'), ('ProviderOrderID'), ('SendTime'),
    ('ProviderExecID'), ('ExecutionTime'), ('ExecutionRate'), ('FailID'), ('FailReason'), ('Success'),
    ('ProviderPartyIds'), ('ReceivedTime'), ('ProviderUnits'), ('RateIDAtSent'), ('EMSOrderID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCExecutionLog', col FROM VALUES
    ('ExecutionID'), ('HedgeServerID'), ('LiquidityAccountID'), ('InstrumentID'), ('IsBuy'), ('IsSuccess'),
    ('RequestAmountInLots'), ('ExecutionAmountInLots'), ('ExecutionRate'), ('StartTime'), ('EndTime'),
    ('FailReason'), ('LPExecutionRate'), ('MarketRateIDAtExecutionEnd'), ('ShouldWaitForConfirm'),
    ('InitialRate'), ('IsCancelExecution'), ('CancelledExecutionID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCOrderLog', col FROM VALUES
    ('OrderID'), ('ExecutionID'), ('HedgeID'), ('IsBuy'), ('IsCancelOrder'), ('OrderState'),
    ('RequestAmountInLots'), ('ExecutionAmountInLots'), ('ExecutionRate'), ('StartTime'), ('EndTime'),
    ('FailReason')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Instruments_ext', col FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('InstrumentDisplayName'), ('Symbol'), ('SymbolFull'),
    ('Tradable'), ('ISINCode'), ('InstrumentVisible'), ('BuyCurrencyID'), ('SellCurrencyID'),
    ('ContractExpire'), ('ExchangeID'), ('VisibleInternallyOnly'), ('UpdateDate'), ('IsFuture')
  AS t(col)
),
available_columns AS (
  SELECT
    t.staging_object,
    c.column_name
  FROM target_objects t
  JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(t.table_catalog)
   AND lower(c.table_schema) = lower(t.table_schema)
   AND lower(c.table_name) = lower(t.table_name)
)
SELECT
  rc.staging_object,
  rc.column_name AS missing_required_column
FROM required_columns rc
LEFT JOIN available_columns ac
  ON rc.staging_object = ac.staging_object
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.staging_object, rc.column_name;

-- Gated required-column contract check for `Reg_RegulationInOutDailyData`.
-- The exact output contract is still pending because the SQL Server procedure
-- output schema is not visible in DTSX. Track visible columns until contract is
-- finalized, then promote to strict required-column checks in this section.
SELECT
  c.column_name,
  c.data_type
FROM system.information_schema.columns c
WHERE lower(c.table_catalog) = 'main'
  AND lower(c.table_schema) = 'regtech_ops_stg'
  AND lower(c.table_name) = 'bi_output_regtechops_reg_regulationinoutdailydata'
ORDER BY c.ordinal_position;

-- -----------------------------------------------------------------------------
-- 2) Row-count and freshness checks
-- -----------------------------------------------------------------------------
WITH row_counts AS (
  SELECT 'Reg_Ext_MigrationInOut_STG' AS staging_object, COUNT(*) AS row_count FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg UNION ALL
  SELECT 'Reg_MigrationInOut_Population', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population UNION ALL
  SELECT 'Reg_RegulationInOutDailyData', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata UNION ALL
  SELECT 'Reg_Ext_CustomerLatinName', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname UNION ALL
  SELECT 'Reg_Ext_HistorySplitRatio', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio UNION ALL
  SELECT 'Reg_Ext_Trade_GetInstrument', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument UNION ALL
  SELECT 'Reg_Ext_Trade_InstrumentMetaData', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrency', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency UNION ALL
  SELECT 'Reg_Ext_DictionaryCurrencyType', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype UNION ALL
  SELECT 'Reg_Ext_HedgeExecutionLog', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog UNION ALL
  SELECT 'Reg_Ext_HedgeHBCExecutionLog', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog UNION ALL
  SELECT 'Reg_Ext_HedgeHBCOrderLog', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog UNION ALL
  SELECT 'Reg_Instruments_ext', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext
)
SELECT *
FROM row_counts
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- 3) Duplicate, null-key, and key-coverage checks
-- -----------------------------------------------------------------------------
SELECT 'Reg_MigrationInOut_Population duplicate RunDate/CID' AS check_name, RunDate, CID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population
GROUP BY RunDate, CID
HAVING COUNT(*) > 1;

SELECT 'Reg_Ext_CustomerLatinName duplicate CID' AS check_name, CID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname
GROUP BY CID
HAVING COUNT(*) > 1;

SELECT 'Reg_Ext_Trade_GetInstrument duplicate InstrumentID' AS check_name, InstrumentID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument
GROUP BY InstrumentID
HAVING COUNT(*) > 1;

SELECT 'Reg_Ext_Trade_InstrumentMetaData duplicate InstrumentID' AS check_name, InstrumentID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata
GROUP BY InstrumentID
HAVING COUNT(*) > 1;

SELECT 'Reg_Ext_DictionaryCurrency duplicate CurrencyID' AS check_name, CurrencyID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency
GROUP BY CurrencyID
HAVING COUNT(*) > 1;

SELECT 'Reg_Ext_DictionaryCurrencyType duplicate CurrencyTypeID' AS check_name, CurrencyTypeID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype
GROUP BY CurrencyTypeID
HAVING COUNT(*) > 1;

SELECT 'Reg_Instruments_ext duplicate InstrumentID' AS check_name, InstrumentID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext
GROUP BY InstrumentID
HAVING COUNT(*) > 1;

-- Null-key checks
SELECT
  'Reg_Ext_MigrationInOut_STG null keys' AS check_name,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN Migration_Occurred IS NULL THEN 1 ELSE 0 END) AS null_migration_occurred_count,
  SUM(CASE WHEN TransactionID IS NULL THEN 1 ELSE 0 END) AS null_transactionid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg;

SELECT
  'Reg_MigrationInOut_Population null keys' AS check_name,
  SUM(CASE WHEN RunDate IS NULL THEN 1 ELSE 0 END) AS null_rundate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population;

SELECT
  'Reg_Ext_CustomerLatinName null keys' AS check_name,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) AS null_firstname_count,
  SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) AS null_lastname_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname;

SELECT
  'Reg_Ext_HistorySplitRatio null keys' AS check_name,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN MinDate IS NULL THEN 1 ELSE 0 END) AS null_mindate_count,
  SUM(CASE WHEN MaxDate IS NULL THEN 1 ELSE 0 END) AS null_maxdate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio;

SELECT
  'Reg_Ext_Trade_GetInstrument null keys' AS check_name,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN BuyCurrencyID IS NULL THEN 1 ELSE 0 END) AS null_buycurrencyid_count,
  SUM(CASE WHEN SellCurrencyID IS NULL THEN 1 ELSE 0 END) AS null_sellcurrencyid_count,
  SUM(CASE WHEN InstrumentTypeID IS NULL THEN 1 ELSE 0 END) AS null_instrumenttypeid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument;

SELECT
  'Reg_Ext_Trade_InstrumentMetaData null keys' AS check_name,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN Symbol IS NULL THEN 1 ELSE 0 END) AS null_symbol_count,
  SUM(CASE WHEN InstrumentTypeID IS NULL THEN 1 ELSE 0 END) AS null_instrumenttypeid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata;

SELECT
  'Reg_Ext_DictionaryCurrency null keys' AS check_name,
  SUM(CASE WHEN CurrencyID IS NULL THEN 1 ELSE 0 END) AS null_currencyid_count,
  SUM(CASE WHEN CurrencyTypeID IS NULL THEN 1 ELSE 0 END) AS null_currencytypeid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency;

SELECT
  'Reg_Ext_DictionaryCurrencyType null keys' AS check_name,
  SUM(CASE WHEN CurrencyTypeID IS NULL THEN 1 ELSE 0 END) AS null_currencytypeid_count,
  SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS null_name_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype;

SELECT
  'Reg_Ext_HedgeExecutionLog null keys' AS check_name,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS null_orderid_count,
  SUM(CASE WHEN LogTime IS NULL THEN 1 ELSE 0 END) AS null_logtime_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog;

SELECT
  'Reg_Ext_HedgeHBCExecutionLog null keys' AS check_name,
  SUM(CASE WHEN ExecutionID IS NULL THEN 1 ELSE 0 END) AS null_executionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN StartTime IS NULL THEN 1 ELSE 0 END) AS null_starttime_count,
  SUM(CASE WHEN EndTime IS NULL THEN 1 ELSE 0 END) AS null_endtime_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog;

SELECT
  'Reg_Ext_HedgeHBCOrderLog null keys' AS check_name,
  SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS null_orderid_count,
  SUM(CASE WHEN ExecutionID IS NULL THEN 1 ELSE 0 END) AS null_executionid_count,
  SUM(CASE WHEN EndTime IS NULL THEN 1 ELSE 0 END) AS null_endtime_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog;

SELECT
  'Reg_Instruments_ext null keys' AS check_name,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN InstrumentTypeID IS NULL THEN 1 ELSE 0 END) AS null_instrumenttypeid_count,
  SUM(CASE WHEN Symbol IS NULL THEN 1 ELSE 0 END) AS null_symbol_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext;

-- Key coverage checks (distinct IDs)
SELECT
  'Reg_Ext_Trade_GetInstrument key coverage' AS check_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT InstrumentID) AS distinct_instrumentid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument;

SELECT
  'Reg_Ext_Trade_InstrumentMetaData key coverage' AS check_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT InstrumentID) AS distinct_instrumentid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata;

SELECT
  'Reg_Ext_DictionaryCurrency key coverage' AS check_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CurrencyID) AS distinct_currencyid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency;

SELECT
  'Reg_Ext_DictionaryCurrencyType key coverage' AS check_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CurrencyTypeID) AS distinct_currencytypeid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype;

-- -----------------------------------------------------------------------------
-- 4) Date-window validations for daily hedge extracts
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
  COUNT(*) AS out_of_window_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog s
CROSS JOIN run_window w
WHERE s.LogTime < w.window_start_ts OR s.LogTime >= w.window_end_ts
UNION ALL
SELECT
  'Reg_Ext_HedgeHBCExecutionLog',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog s
CROSS JOIN run_window w
WHERE s.StartTime < w.window_start_ts OR s.EndTime >= w.window_end_ts OR s.IsSuccess <> 1
UNION ALL
SELECT
  'Reg_Ext_HedgeHBCOrderLog',
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog s
CROSS JOIN run_window w
WHERE s.EndTime < w.window_start_ts OR s.EndTime >= w.window_end_ts;

-- -----------------------------------------------------------------------------
-- 5) Source-to-stage counts where practical
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
source_counts AS (
  SELECT
    'Reg_MigrationInOut_Population' AS staging_object,
    COUNT(*) AS source_count
  FROM main.regtech.gold_regtech_reg_migrationinout_population src
  JOIN run_parameters p
    ON src.RunDate = p.report_date
  UNION ALL
  SELECT
    'Reg_Ext_HistorySplitRatio',
    COUNT(*)
  FROM main.dealing.bronze_pricelog_history_splitratio src
  WHERE src.IsCompletedOpenPositions = 1
  UNION ALL
  SELECT 'Reg_Ext_HedgeExecutionLog' AS staging_object, COUNT(*) AS source_count
  FROM main.dealing.bronze_etoro_hedge_executionlog src
  JOIN run_window w
    ON src.LogTime >= w.window_start_ts
   AND src.LogTime < w.window_end_ts
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCExecutionLog', COUNT(*)
  FROM main.dealing.bronze_etoro_hedge_hbcexecutionlog src
  JOIN run_window w
    ON src.StartTime >= w.window_start_ts
   AND src.EndTime < w.window_end_ts
  WHERE src.IsSuccess = 1
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCOrderLog', COUNT(*)
  FROM main.dealing.bronze_etoro_hedge_hbcorderlog src
  JOIN run_window w
    ON src.EndTime >= w.window_start_ts
   AND src.EndTime < w.window_end_ts
),
stage_counts AS (
  SELECT 'Reg_MigrationInOut_Population' AS staging_object, COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population
  UNION ALL
  SELECT 'Reg_Ext_HistorySplitRatio', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio
  UNION ALL
  SELECT 'Reg_Ext_HedgeExecutionLog' AS staging_object, COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCExecutionLog', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog
  UNION ALL
  SELECT 'Reg_Ext_HedgeHBCOrderLog', COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog
)
SELECT
  s.staging_object,
  s.source_count,
  st.stage_count,
  s.source_count - st.stage_count AS count_delta
FROM source_counts s
JOIN stage_counts st
  ON s.staging_object = st.staging_object
ORDER BY s.staging_object;

-- `Reg_RegulationInOutDailyData` source-to-stage checks remain gated until the
-- gold/procedure output-column contract is confirmed.

