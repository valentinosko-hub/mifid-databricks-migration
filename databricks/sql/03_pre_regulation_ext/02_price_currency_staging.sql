-- Step 5B1: Pre_Regulation price/currency/split staging materialization.
-- Scope of this file is intentionally limited to:
--   - Reg_CurrencyPrice_Ext
--   - Reg_Ext_DailyMaxPrices
--   - Reg_Ext_CurrencyPriceMaxDateWithSplit (pending source selection)
--   - Reg_Ext_T_PriceCandle60Min
--
-- Guardrails:
-- - Materialize Delta staging tables (no views) to match SSIS truncate/reload behavior.
-- - All targets remain under main.regtech_ops_stg with bi_output_regtechops_ prefix.
-- - Execute only after source profiling (01_price_currency_source_profiling.sql) passes.

-- -----------------------------------------------------------------------------
-- A) Reg_CurrencyPrice_Ext (provisional: execute after required-column parity confirms)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext
USING DELTA
AS
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
  src.CurrencyPriceID,
  src.ProviderID,
  src.InstrumentID,
  src.Bid,
  src.Ask,
  src.ValidFrom,
  src.ValidTo,
  src.OccurredOnProvider,
  src.Occurred,
  src.PriceRateID,
  src.ReceivedOnPriceServer,
  src.LiquidityAccountID,
  src.USDConversionRate,
  src.MarketPriceRateID,
  src.RateLastEx,
  src.BidSpreaded,
  src.AskSpreaded,
  src.BidMarketPriceRateID,
  src.AskMarketPriceRateID,
  src.MarkupPips,
  src.MarketReceivedTime,
  src.SkewValueBid,
  src.SkewValueAsk,
  src.SkewID,
  src.USDConversionRateBidSpreaded,
  src.USDConversionRateAskSpreaded,
  src.USDConversionPriceRateID
FROM main.trading.bronze_etoro_trade_currencyprice src
JOIN run_window w
  ON src.Occurred >= w.window_start_ts
 AND src.Occurred <= w.window_end_ts;

-- -----------------------------------------------------------------------------
-- B) Reg_Ext_DailyMaxPrices (provisional: execute after required-column parity confirms)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices
USING DELTA
AS
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
  src.CurrencyPriceID,
  src.ProviderID,
  src.InstrumentID,
  src.Bid,
  src.Ask,
  src.ValidFrom,
  src.ValidTo,
  src.OccurredOnProvider,
  src.Occurred,
  src.PriceRateID,
  src.ReceivedOnPriceServer,
  src.LiquidityAccountID,
  src.USDConversionRate,
  src.MarketPriceRateID,
  src.RateLastEx,
  src.BidSpreaded,
  src.AskSpreaded,
  src.BidMarketPriceRateID,
  src.AskMarketPriceRateID,
  src.MarkupPips,
  src.MarketReceivedTime,
  src.SkewValueBid,
  src.SkewValueAsk,
  src.isvalid
FROM main.dealing.bronze_pricelog_history_currencypricemaxdate src
JOIN run_window w
  ON src.Occurred >= w.window_start_ts
 AND src.Occurred <= w.window_end_ts;

-- -----------------------------------------------------------------------------
-- C) Reg_Ext_CurrencyPriceMaxDateWithSplit (PENDING)
-- -----------------------------------------------------------------------------
-- Source selection is unresolved between:
--   1) dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit
--   2) main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
--
-- DO NOT create main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit
-- until candidate profiling and source decision are finalized.
--
-- Final target (pending):
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit

-- -----------------------------------------------------------------------------
-- D) Reg_Ext_T_PriceCandle60Min (PROVISIONAL / PENDING)
-- -----------------------------------------------------------------------------
-- DO NOT EXECUTE this table creation until required-column profiling confirms
-- the candidate source contains all required fields:
--   - InstrumentID
--   - BidLast
--   - AskLast
--   - DateFrom
--
-- Required profiling gate:
--   databricks/sql/03_pre_regulation_ext/01_price_currency_source_profiling.sql
--
-- Intended logic is retained below for later execution after profiling passes.
/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_date_plus_one_ts
  FROM run_parameters
),
filtered_source AS (
  SELECT
    src.InstrumentID,
    src.BidLast,
    src.AskLast,
    src.DateFrom,
    ROW_NUMBER() OVER (PARTITION BY src.InstrumentID ORDER BY src.DateFrom DESC) AS rn
  FROM main.dealing.bronze_candles_candles_t_pricecandle60min src
  JOIN run_window w
    ON src.DateFrom < w.end_date_plus_one_ts
  WHERE src.InstrumentID < 100000
)
SELECT
  InstrumentID,
  BidLast AS RateBid,
  AskLast AS RateAsk,
  DateFrom
FROM filtered_source
WHERE rn = 1;
*/

