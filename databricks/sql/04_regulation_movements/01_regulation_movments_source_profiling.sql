-- Step 6: Regulation movement source profiling (non-executable staging).
-- Primary target (gated): main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
--
-- Purpose:
-- - Validate source access and required columns before authoring executable Step 6 staging SQL.
-- - Keep support-copy semantics (`Ext_MigrationInOut_Population`) as logical/temporary only.

-- -----------------------------------------------------------------------------
-- 1) Source inventory and visibility
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'migration_population_snapshot' AS source_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_reg_migrationinout_population' AS table_name, 'prefixed snapshot (gated)' AS source_status UNION ALL
  SELECT 'migration_population_gold', 'main', 'regtech', 'gold_regtech_reg_migrationinout_population', 'certified gold (confirmed)' UNION ALL
  SELECT 'regulation_inout_daily_snapshot', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_regulationinoutdailydata', 'prefixed snapshot (gated / not active Step 6 input)' UNION ALL
  SELECT 'regulation_inout_daily_gold', 'main', 'regtech', 'gold_regtech_reg_regulationinoutdailydata', 'certified gold (confirmed / gated output contract)' UNION ALL
  SELECT 'trade_position', 'main', 'trading', 'silver_etoro_trade_position', 'confirmed mapping' UNION ALL
  SELECT 'history_position', 'main', 'trading', 'bronze_etoro_history_position_datafactory', 'confirmed mapping' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd', 'confirmed certified source' UNION ALL
  SELECT 'split_price_snapshot', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit', 'Step 5B1 gated source' UNION ALL
  SELECT 'split_price_candidate_fact', 'main', 'dwh', 'gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit', 'candidate source (fallback parity check)'
),
source_columns AS (
  SELECT
    st.source_key,
    st.table_catalog,
    st.table_schema,
    st.table_name,
    st.source_status,
    c.column_name
  FROM source_targets st
  LEFT JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(st.table_catalog)
   AND lower(c.table_schema) = lower(st.table_schema)
   AND lower(c.table_name) = lower(st.table_name)
)
SELECT
  source_key,
  table_catalog,
  table_schema,
  table_name,
  source_status,
  COUNT(column_name) AS visible_column_count
FROM source_columns
GROUP BY source_key, table_catalog, table_schema, table_name, source_status
ORDER BY source_key;

-- -----------------------------------------------------------------------------
-- 2) Required-column coverage checks for Step 6 movement logic
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'migration_population_snapshot' AS source_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_reg_migrationinout_population' AS table_name UNION ALL
  SELECT 'migration_population_gold', 'main', 'regtech', 'gold_regtech_reg_migrationinout_population' UNION ALL
  SELECT 'trade_position', 'main', 'trading', 'silver_etoro_trade_position' UNION ALL
  SELECT 'history_position', 'main', 'trading', 'bronze_etoro_history_position_datafactory' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd' UNION ALL
  SELECT 'split_price_snapshot', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit' UNION ALL
  SELECT 'split_price_candidate_fact', 'main', 'dwh', 'gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit'
),
required_columns AS (
  SELECT 'migration_population_snapshot' AS source_key, col AS column_name FROM VALUES
    ('RunDate'), ('CID'), ('Lei'), ('RegulationID'), ('Migration_Occurred'), ('PrevRegulationID')
  AS t(col)
  UNION ALL
  SELECT 'migration_population_gold', col FROM VALUES
    ('RunDate'), ('CID'), ('Lei'), ('RegulationID'), ('Migration_Occurred'), ('PrevRegulationID')
  AS t(col)
  UNION ALL
  SELECT 'trade_position', col FROM VALUES
    ('PositionID'), ('CID'), ('Occurred'), ('IsBuy'), ('AmountInUnitsDecimal'),
    ('InitForexRate'), ('InstrumentID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'history_position', col FROM VALUES
    ('PositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'), ('IsBuy'),
    ('AmountInUnitsDecimal'), ('InitForexRate'), ('EndForexRate'), ('InstrumentID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'reg_instruments_scd', col FROM VALUES
    ('InstrumentID'), ('ValidFrom'), ('ValidTo'), ('Symbol'), ('IsMifid'), ('IsMifidByFCA'), ('SellCurrencyID')
  AS t(col)
  UNION ALL
  SELECT 'split_price_snapshot', col FROM VALUES
    ('InstrumentID'), ('OccurredDate'), ('AskSpreaded'), ('BidSpreaded')
  AS t(col)
  UNION ALL
  SELECT 'split_price_candidate_fact', col FROM VALUES
    ('InstrumentID'), ('OccurredDate'), ('AskSpreaded'), ('BidSpreaded')
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
-- 3) Report-date run-window profiling templates
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
  'migration_population_snapshot' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CID) AS cid_count,
  MIN(Migration_Occurred) AS min_migration_occurred,
  MAX(Migration_Occurred) AS max_migration_occurred
FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population src
JOIN run_parameters p
  ON src.RunDate = p.report_date
UNION ALL
SELECT
  'migration_population_gold' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CID) AS cid_count,
  MIN(Migration_Occurred) AS min_migration_occurred,
  MAX(Migration_Occurred) AS max_migration_occurred
FROM main.regtech.gold_regtech_reg_migrationinout_population src
JOIN run_parameters p
  ON src.RunDate = p.report_date;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
)
SELECT
  'trade_position_pre_enddate' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CID) AS cid_count
FROM main.trading.silver_etoro_trade_position src
JOIN run_window w
  ON src.Occurred < w.window_end_ts
UNION ALL
SELECT
  'history_position_open_pre_enddate' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CID) AS cid_count
FROM main.trading.bronze_etoro_history_position_datafactory src
JOIN run_window w
  ON src.OpenOccurred < w.window_end_ts;

-- -----------------------------------------------------------------------------
-- 4) Split-price source availability for post-load enrichment
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'split_price_snapshot' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT InstrumentID) AS instrument_coverage
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit src
JOIN run_parameters p
  ON src.OccurredDate = p.report_date
UNION ALL
SELECT
  'split_price_candidate_fact' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT InstrumentID) AS instrument_coverage
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit src
JOIN run_parameters p
  ON src.OccurredDate = p.report_date;

