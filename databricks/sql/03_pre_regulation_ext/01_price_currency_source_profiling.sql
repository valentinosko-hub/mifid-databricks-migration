-- Step 5B1: source profiling for Pre_Regulation price/currency/split staging.
-- Do not select final sources silently. Use this file to profile schema + coverage first.

-- -----------------------------------------------------------------------------
-- 1) Required-column coverage by candidate source
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'reg_currencyprice_ext' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_trade_currencyprice' AS table_name UNION ALL
  SELECT 'reg_ext_dailymaxprices', 'main', 'dealing', 'bronze_pricelog_history_currencypricemaxdate' UNION ALL
  SELECT 'reg_ext_currencypricemaxdatewithsplit_candidate_1', 'dwh_daily_process', 'migration_tables', 'ext_fcupnl_currencypricemaxdatewithsplit' UNION ALL
  SELECT 'reg_ext_currencypricemaxdatewithsplit_candidate_2', 'main', 'dwh', 'gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit' UNION ALL
  SELECT 'reg_ext_t_pricecandle60min', 'main', 'dealing', 'bronze_candles_candles_t_pricecandle60min'
),
required_columns AS (
  -- Reg_CurrencyPrice_Ext and Reg_Ext_DailyMaxPrices SSIS shape
  SELECT 'reg_currencyprice_ext' AS source_key, col AS column_name FROM VALUES
    ('CurrencyPriceID'), ('ProviderID'), ('InstrumentID'), ('Bid'), ('Ask'),
    ('ValidFrom'), ('ValidTo'), ('OccurredOnProvider'), ('Occurred'), ('PriceRateID'),
    ('ReceivedOnPriceServer'), ('LiquidityAccountID'), ('USDConversionRate'),
    ('MarketPriceRateID'), ('RateLastEx'), ('BidSpreaded'), ('AskSpreaded'),
    ('BidMarketPriceRateID'), ('AskMarketPriceRateID'), ('MarkupPips'),
    ('MarketReceivedTime'), ('SkewValueBid'), ('SkewValueAsk'), ('SkewID'),
    ('USDConversionRateBidSpreaded'), ('USDConversionRateAskSpreaded'), ('USDConversionPriceRateID')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_dailymaxprices', col FROM VALUES
    ('CurrencyPriceID'), ('ProviderID'), ('InstrumentID'), ('Bid'), ('Ask'),
    ('ValidFrom'), ('ValidTo'), ('OccurredOnProvider'), ('Occurred'), ('PriceRateID'),
    ('ReceivedOnPriceServer'), ('LiquidityAccountID'), ('USDConversionRate'),
    ('MarketPriceRateID'), ('RateLastEx'), ('BidSpreaded'), ('AskSpreaded'),
    ('BidMarketPriceRateID'), ('AskMarketPriceRateID'), ('MarkupPips'),
    ('MarketReceivedTime'), ('SkewValueBid'), ('SkewValueAsk'), ('isvalid')
  AS t(col)
  UNION ALL
  -- Reg_Ext_CurrencyPriceMaxDateWithSplit SSIS shape
  SELECT 'reg_ext_currencypricemaxdatewithsplit_candidate_1', col FROM VALUES
    ('PriceRateID'), ('ProviderID'), ('InstrumentID'), ('Occurred'), ('OccurredDate'),
    ('OccurredDateID'), ('isvalid'), ('MarkupPips'), ('AskSpreaded'), ('BidSpreaded'),
    ('RateLastEx'), ('SkewValueBid'), ('SkewValueAsk'), ('Ask'), ('Bid')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_currencypricemaxdatewithsplit_candidate_2', col FROM VALUES
    ('PriceRateID'), ('ProviderID'), ('InstrumentID'), ('Occurred'), ('OccurredDate'),
    ('OccurredDateID'), ('isvalid'), ('MarkupPips'), ('AskSpreaded'), ('BidSpreaded'),
    ('RateLastEx'), ('SkewValueBid'), ('SkewValueAsk'), ('Ask'), ('Bid')
  AS t(col)
  UNION ALL
  -- Reg_Ext_T_PriceCandle60Min source requirements
  SELECT 'reg_ext_t_pricecandle60min', col FROM VALUES
    ('InstrumentID'), ('BidLast'), ('AskLast'), ('DateFrom')
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
  rc.column_name AS missing_column
FROM required_columns rc
LEFT JOIN available_columns ac
  ON rc.source_key = ac.source_key
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.source_key, rc.column_name;

-- -----------------------------------------------------------------------------
-- 2) Run-window profiling helpers (run after required-column coverage passes)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS candle_end_ts
  FROM run_parameters
)
SELECT * FROM run_window;

-- Reg_CurrencyPrice_Ext candidate profiling
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
)
SELECT
  COUNT(*) AS row_count,
  MIN(Occurred) AS min_occurred,
  MAX(Occurred) AS max_occurred,
  COUNT(DISTINCT InstrumentID) AS instrument_coverage
FROM main.trading.bronze_etoro_trade_currencyprice src
JOIN run_window w
  ON src.Occurred >= w.window_start_ts
 AND src.Occurred <= w.window_end_ts;

-- Reg_Ext_DailyMaxPrices candidate profiling
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
)
SELECT
  COUNT(*) AS row_count,
  MIN(Occurred) AS min_occurred,
  MAX(Occurred) AS max_occurred,
  COUNT(DISTINCT InstrumentID) AS instrument_coverage
FROM main.dealing.bronze_pricelog_history_currencypricemaxdate src
JOIN run_window w
  ON src.Occurred >= w.window_start_ts
 AND src.Occurred <= w.window_end_ts;

-- Reg_Ext_CurrencyPriceMaxDateWithSplit candidate comparison profiling
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
candidate_1 AS (
  SELECT
    'dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit' AS candidate_source,
    COUNT(*) AS row_count,
    MIN(Occurred) AS min_occurred,
    MAX(Occurred) AS max_occurred,
    MIN(OccurredDate) AS min_occurred_date,
    MAX(OccurredDate) AS max_occurred_date,
    COUNT(DISTINCT InstrumentID) AS instrument_coverage,
    SUM(CASE WHEN PriceRateID IS NULL THEN 1 ELSE 0 END) AS null_pricerateid_count,
    COUNT(*) - COUNT(DISTINCT PriceRateID) AS duplicate_pricerateid_count
  FROM dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit src
  JOIN run_window w
    ON src.Occurred >= w.window_start_ts
   AND src.Occurred <= w.window_end_ts
),
candidate_2 AS (
  SELECT
    'main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit' AS candidate_source,
    COUNT(*) AS row_count,
    MIN(Occurred) AS min_occurred,
    MAX(Occurred) AS max_occurred,
    MIN(OccurredDate) AS min_occurred_date,
    MAX(OccurredDate) AS max_occurred_date,
    COUNT(DISTINCT InstrumentID) AS instrument_coverage,
    SUM(CASE WHEN PriceRateID IS NULL THEN 1 ELSE 0 END) AS null_pricerateid_count,
    COUNT(*) - COUNT(DISTINCT PriceRateID) AS duplicate_pricerateid_count
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit src
  JOIN run_window w
    ON src.Occurred >= w.window_start_ts
   AND src.Occurred <= w.window_end_ts
)
SELECT * FROM candidate_1
UNION ALL
SELECT * FROM candidate_2;

-- Reg_Ext_T_PriceCandle60Min candidate profiling and latest-row logic coverage
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT CAST(date_add(report_date, 1) AS TIMESTAMP) AS candle_end_ts
  FROM run_parameters
),
candidate_rows AS (
  SELECT
    src.InstrumentID,
    src.BidLast,
    src.AskLast,
    src.DateFrom
  FROM main.dealing.bronze_candles_candles_t_pricecandle60min src
  JOIN run_window w
    ON src.DateFrom < w.candle_end_ts
  WHERE src.InstrumentID < 100000
),
latest_rows AS (
  SELECT
    InstrumentID,
    DateFrom,
    ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY DateFrom DESC) AS rn
  FROM candidate_rows
)
SELECT
  COUNT(*) AS source_row_count,
  COUNT(DISTINCT InstrumentID) AS source_instrument_coverage,
  MIN(DateFrom) AS min_datefrom,
  MAX(DateFrom) AS max_datefrom
FROM candidate_rows;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT CAST(date_add(report_date, 1) AS TIMESTAMP) AS candle_end_ts
  FROM run_parameters
),
latest_rows AS (
  SELECT
    src.InstrumentID,
    src.DateFrom,
    ROW_NUMBER() OVER (PARTITION BY src.InstrumentID ORDER BY src.DateFrom DESC) AS rn
  FROM main.dealing.bronze_candles_candles_t_pricecandle60min src
  JOIN run_window w
    ON src.DateFrom < w.candle_end_ts
  WHERE src.InstrumentID < 100000
)
SELECT
  COUNT(*) AS latest_row_count,
  COUNT(DISTINCT InstrumentID) AS latest_instrument_coverage
FROM latest_rows
WHERE rn = 1;

