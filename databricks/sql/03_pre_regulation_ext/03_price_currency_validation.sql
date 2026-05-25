-- Step 5B1 validation checks for price/currency/split staging.
-- Run after staging SQL where relevant.

-- -----------------------------------------------------------------------------
-- Shared run window
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

-- -----------------------------------------------------------------------------
-- A) Reg_CurrencyPrice_Ext validation
-- -----------------------------------------------------------------------------
-- Row count by DATE(Occurred)
SELECT
  DATE(Occurred) AS occurred_date,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext
GROUP BY DATE(Occurred)
ORDER BY occurred_date;

-- Min/max Occurred and freshness
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
)
SELECT
  MIN(Occurred) AS min_occurred,
  MAX(Occurred) AS max_occurred,
  CASE WHEN MAX(Occurred) <= (SELECT window_end_ts FROM run_window) THEN 1 ELSE 0 END AS within_expected_window_flag
FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext;

-- Required columns present
WITH required_columns AS (
  SELECT col AS column_name FROM VALUES
    ('CurrencyPriceID'), ('ProviderID'), ('InstrumentID'), ('Bid'), ('Ask'),
    ('ValidFrom'), ('ValidTo'), ('OccurredOnProvider'), ('Occurred'), ('PriceRateID'),
    ('ReceivedOnPriceServer'), ('LiquidityAccountID'), ('USDConversionRate'),
    ('MarketPriceRateID'), ('RateLastEx'), ('BidSpreaded'), ('AskSpreaded'),
    ('BidMarketPriceRateID'), ('AskMarketPriceRateID'), ('MarkupPips'),
    ('MarketReceivedTime'), ('SkewValueBid'), ('SkewValueAsk'), ('SkewID'),
    ('USDConversionRateBidSpreaded'), ('USDConversionRateAskSpreaded'), ('USDConversionPriceRateID')
  AS t(col)
),
actual_columns AS (
  SELECT column_name
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_reg_currencyprice_ext'
)
SELECT rc.column_name AS missing_column
FROM required_columns rc
LEFT JOIN actual_columns ac
  ON lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.column_name;

-- Duplicate key checks
SELECT CurrencyPriceID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext
GROUP BY CurrencyPriceID
HAVING COUNT(*) > 1;

SELECT PriceRateID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext
GROUP BY PriceRateID
HAVING COUNT(*) > 1;

-- Null checks for key IDs and dates
SELECT
  SUM(CASE WHEN CurrencyPriceID IS NULL THEN 1 ELSE 0 END) AS null_currencypriceid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN Occurred IS NULL THEN 1 ELSE 0 END) AS null_occurred_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext;

-- Source-to-stage count check for run window
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
source_counts AS (
  SELECT COUNT(*) AS source_count
  FROM main.trading.bronze_etoro_trade_currencyprice src
  JOIN run_window w
    ON src.Occurred >= w.window_start_ts
   AND src.Occurred <= w.window_end_ts
),
stage_counts AS (
  SELECT COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext
)
SELECT source_count, stage_count, source_count - stage_count AS count_delta
FROM source_counts CROSS JOIN stage_counts;

-- -----------------------------------------------------------------------------
-- B) Reg_Ext_DailyMaxPrices validation
-- -----------------------------------------------------------------------------
-- Row count by DATE(Occurred)
SELECT
  DATE(Occurred) AS occurred_date,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices
GROUP BY DATE(Occurred)
ORDER BY occurred_date;

-- Duplicate CurrencyPriceID
SELECT CurrencyPriceID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices
GROUP BY CurrencyPriceID
HAVING COUNT(*) > 1;

-- Coverage by InstrumentID and date freshness
SELECT
  COUNT(DISTINCT InstrumentID) AS instrument_coverage,
  MIN(Occurred) AS min_occurred,
  MAX(Occurred) AS max_occurred
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices;

-- Null checks for key IDs and dates
SELECT
  SUM(CASE WHEN CurrencyPriceID IS NULL THEN 1 ELSE 0 END) AS null_currencypriceid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN Occurred IS NULL THEN 1 ELSE 0 END) AS null_occurred_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices;

-- Source-to-stage count check for run window
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
source_counts AS (
  SELECT COUNT(*) AS source_count
  FROM main.dealing.bronze_pricelog_history_currencypricemaxdate src
  JOIN run_window w
    ON src.Occurred >= w.window_start_ts
   AND src.Occurred <= w.window_end_ts
),
stage_counts AS (
  SELECT COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices
)
SELECT source_count, stage_count, source_count - stage_count AS count_delta
FROM source_counts CROSS JOIN stage_counts;

-- -----------------------------------------------------------------------------
-- C) Reg_Ext_CurrencyPriceMaxDateWithSplit (candidate comparison before source selection)
-- -----------------------------------------------------------------------------
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
    COUNT(*) - COUNT(DISTINCT PriceRateID) AS duplicate_pricerateid_count
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit src
  JOIN run_window w
    ON src.Occurred >= w.window_start_ts
   AND src.Occurred <= w.window_end_ts
)
SELECT * FROM candidate_1
UNION ALL
SELECT * FROM candidate_2;

-- -----------------------------------------------------------------------------
-- D) Reg_Ext_T_PriceCandle60Min validation
-- -----------------------------------------------------------------------------
-- Row count, min/max DateFrom, and freshness
SELECT
  COUNT(*) AS row_count,
  MIN(DateFrom) AS min_datefrom,
  MAX(DateFrom) AS max_datefrom
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min;

-- Exactly one latest row per InstrumentID and duplicate InstrumentID check
SELECT InstrumentID, COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min
GROUP BY InstrumentID
HAVING COUNT(*) > 1;

-- InstrumentID range constraint
SELECT COUNT(*) AS instrumentid_out_of_range_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min
WHERE InstrumentID >= 100000 OR InstrumentID IS NULL;

-- Null checks on key IDs and dates
SELECT
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN DateFrom IS NULL THEN 1 ELSE 0 END) AS null_datefrom_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min;

-- Source-to-stage count check for latest-row logic
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT CAST(date_add(report_date, 1) AS TIMESTAMP) AS candle_end_ts
  FROM run_parameters
),
source_latest AS (
  SELECT
    src.InstrumentID,
    ROW_NUMBER() OVER (PARTITION BY src.InstrumentID ORDER BY src.DateFrom DESC) AS rn
  FROM main.dealing.bronze_candles_candles_t_pricecandle60min src
  JOIN run_window w
    ON src.DateFrom < w.candle_end_ts
  WHERE src.InstrumentID < 100000
),
source_counts AS (
  SELECT COUNT(*) AS source_latest_count
  FROM source_latest
  WHERE rn = 1
),
stage_counts AS (
  SELECT COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min
)
SELECT source_latest_count, stage_count, source_latest_count - stage_count AS count_delta
FROM source_counts CROSS JOIN stage_counts;

