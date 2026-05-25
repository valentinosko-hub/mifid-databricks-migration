-- Step 8: ASIC2-compatible MiFID subset source profiling (non-executable staging).
--
-- Targets (gated in Step 8):
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport
--   main.regtech_ops_stg.bi_output_regtechops_asic2_positions
--   main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata
--   main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials
--   main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
--   main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
--
-- Purpose:
-- - Validate source visibility/access and required columns before enabling Step 8 SQL.
-- - Make conditional dependencies explicit:
--   - SP_ASIC2_Instrument_Automation
--   - SP_ASIC2_PositionReport_Agg / aggregate outputs
--   - Reg_DWH_StaticPosition fallback impact
--   - EMIR Refit UPI non-dependency for MiFID-consumed fields

-- -----------------------------------------------------------------------------
-- 1) Source inventory and visibility
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'history_positionchangelog' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_history_positionchangelog' AS table_name, 'confirmed mapping' AS source_status UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse', 'confirmed mapping (profile required)' UNION ALL
  SELECT 'history_position_datafactory', 'main', 'trading', 'bronze_etoro_history_position_datafactory', 'confirmed mapping (profile required)' UNION ALL
  SELECT 'customer_customer', 'main', 'general', 'bronze_etoro_customer_customer', 'confirmed mapping' UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer', 'confirmed mapping' UNION ALL
  SELECT 'dictionary_country', 'main', 'general', 'bronze_etoro_dictionary_country', 'confirmed mapping' UNION ALL
  SELECT 'dictionary_label', 'main', 'general', 'bronze_etoro_dictionary_label', 'confirmed mapping' UNION ALL
  SELECT 'reg_ext_customerlatinname', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_customerlatinname', 'Step 5B2 gated dependency' UNION ALL
  SELECT 'reg_ext_dictionarycurrency', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrency', 'Step 5B2 gated dependency' UNION ALL
  SELECT 'reg_instruments_ext', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_instruments_ext', 'Step 5B2 gated dependency' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd', 'confirmed mapping' UNION ALL
  SELECT 'reg_instruments_full_description', 'main', 'regtech', 'gold_regtech_reg_instruments_full_description', 'confirmed mapping' UNION ALL
  SELECT 'reg_ext_currencypricemaxdatewithsplit', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit', 'Step 5B1 gated dependency' UNION ALL
  SELECT 'reg_ext_dailymaxprices', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dailymaxprices', 'Step 5B1 gated dependency' UNION ALL
  SELECT 'reg_regulationinoutdailydata', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_regulationinoutdailydata', 'Step 5B2 gated dependency' UNION ALL
  SELECT 'excluded_instruments', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_instruments', 'confirmed mapping' UNION ALL
  SELECT 'excluded_position_ids', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_position_ids', 'confirmed mapping' UNION ALL
  SELECT 'emir_refir_upi', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_emir_refir_upi', 'conditional / expected source'
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
-- 2) Required-column checks for key Step 8 source contracts
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'history_positionchangelog' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_history_positionchangelog' AS table_name UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse' UNION ALL
  SELECT 'history_position_datafactory', 'main', 'trading', 'bronze_etoro_history_position_datafactory' UNION ALL
  SELECT 'customer_customer', 'main', 'general', 'bronze_etoro_customer_customer' UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'dictionary_country', 'main', 'general', 'bronze_etoro_dictionary_country' UNION ALL
  SELECT 'dictionary_label', 'main', 'general', 'bronze_etoro_dictionary_label' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd' UNION ALL
  SELECT 'excluded_instruments', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_instruments' UNION ALL
  SELECT 'excluded_position_ids', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_position_ids'
),
required_columns AS (
  SELECT 'history_positionchangelog' AS source_key, col AS column_name FROM VALUES
    ('PositionID'), ('Occurred'), ('ChangeTypeID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'trade_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('CloseOccurred'),
    ('AmountInUnitsDecimal'), ('InitForexRate'), ('Amount'), ('IsBuy'), ('IsSettled'),
    ('UpdateDate'), ('EndForexRate'), ('NetProfit'), ('LastOpPriceRate'),
    ('OriginalPositionID'), ('RegulationID'), ('InitForexPriceRateID'),
    ('EndForexPriceRateID'), ('InitConversionRate'), ('InitialUnits'),
    ('PartialCloseRatio'), ('SettlementTypeID')
  AS t(col)
  UNION ALL
  SELECT 'history_position_datafactory', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('CloseOccurred'),
    ('AmountInUnitsDecimal'), ('InitForexRate'), ('EndForexRate'), ('IsBuy'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'customer_customer', col FROM VALUES
    ('CID'), ('LabelID'), ('PlayerLevelID'), ('PlayerStatusID'), ('ExternalID'), ('CountryID')
  AS t(col)
  UNION ALL
  SELECT 'history_customer', col FROM VALUES
    ('CID'), ('FirstName'), ('LastName')
  AS t(col)
  UNION ALL
  SELECT 'dictionary_country', col FROM VALUES
    ('CountryID')
  AS t(col)
  UNION ALL
  SELECT 'dictionary_label', col FROM VALUES
    ('LabelID')
  AS t(col)
  UNION ALL
  SELECT 'reg_instruments_scd', col FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('BuyCurrencyID'), ('SellCurrencyID')
  AS t(col)
  UNION ALL
  SELECT 'excluded_instruments', col FROM VALUES
    ('InstrumentID')
  AS t(col)
  UNION ALL
  SELECT 'excluded_position_ids', col FROM VALUES
    ('PositionID')
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
-- 3) Source row counts and key coverage (where practical)
-- -----------------------------------------------------------------------------
SELECT
  'history_positionchangelog' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT PositionID) AS distinct_positionid_count
FROM main.trading.bronze_etoro_history_positionchangelog
UNION ALL
SELECT
  'trade_positionforexternaluse',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.bi_db.bronze_etoro_trade_positionforexternaluse
UNION ALL
SELECT
  'history_position_datafactory',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.trading.bronze_etoro_history_position_datafactory
UNION ALL
SELECT
  'customer_customer',
  COUNT(*),
  COUNT(DISTINCT CID)
FROM main.general.bronze_etoro_customer_customer
UNION ALL
SELECT
  'reg_instruments_scd',
  COUNT(*),
  COUNT(DISTINCT InstrumentID)
FROM main.regtech.gold_regtech_reg_instruments_scd
UNION ALL
SELECT
  'excluded_instruments',
  COUNT(*),
  COUNT(DISTINCT InstrumentID)
FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
UNION ALL
SELECT
  'excluded_position_ids',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids;

-- -----------------------------------------------------------------------------
-- 4) Source freshness support (timestamp-column discovery)
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'history_positionchangelog' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_history_positionchangelog' AS table_name UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse' UNION ALL
  SELECT 'history_position_datafactory', 'main', 'trading', 'bronze_etoro_history_position_datafactory' UNION ALL
  SELECT 'customer_customer', 'main', 'general', 'bronze_etoro_customer_customer' UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd'
)
SELECT
  st.source_key,
  c.column_name,
  c.data_type
FROM source_targets st
JOIN system.information_schema.columns c
  ON lower(c.table_catalog) = lower(st.table_catalog)
 AND lower(c.table_schema) = lower(st.table_schema)
 AND lower(c.table_name) = lower(st.table_name)
WHERE lower(c.data_type) IN ('timestamp', 'timestamp_ntz', 'date')
   OR lower(c.column_name) LIKE '%update%'
   OR lower(c.column_name) LIKE '%modified%'
   OR lower(c.column_name) LIKE '%created%'
   OR lower(c.column_name) LIKE '%occurred%'
ORDER BY st.source_key, c.column_name;

-- -----------------------------------------------------------------------------
-- 5) Conditional dependency checks for Step 8 clarifications
-- -----------------------------------------------------------------------------
-- 5a) SP_ASIC2_Instrument_Automation dependency gate:
-- Verify whether ASIC2_InstrumentMetaData can be built from profiled sources.
WITH dependency_columns AS (
  SELECT 'reg_instruments_ext' AS dependency_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_reg_instruments_ext' AS table_name, col AS required_column FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('BuyCurrencyID'), ('SellCurrencyID'), ('ISINCode'), ('IsinCountryCode')
  AS t(col)
  UNION ALL
  SELECT 'reg_ext_dictionarycurrency', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrency', col FROM VALUES
    ('CurrencyID'), ('Abbreviation')
  AS t(col)
),
available_columns AS (
  SELECT
    dc.dependency_key,
    dc.required_column,
    c.column_name
  FROM dependency_columns dc
  LEFT JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(dc.table_catalog)
   AND lower(c.table_schema) = lower(dc.table_schema)
   AND lower(c.table_name) = lower(dc.table_name)
   AND lower(c.column_name) = lower(dc.required_column)
)
SELECT
  dependency_key,
  required_column AS missing_required_column
FROM available_columns
WHERE column_name IS NULL
ORDER BY dependency_key, required_column;

-- 5b) Aggregate dependency gate:
-- SP_ASIC2_PositionReport_Agg remains out of scope unless direct feed to
-- ASIC2_Positions / ASIC2_Transactions is proven.
SELECT
  table_catalog,
  table_schema,
  table_name
FROM system.information_schema.tables
WHERE lower(table_catalog) = 'main'
  AND (
    lower(table_name) LIKE '%asic2%position%agg%'
    OR lower(table_name) LIKE '%asic2%positions_scd%'
    OR lower(table_name) LIKE '%asic2%daily%price%'
  )
ORDER BY table_catalog, table_schema, table_name;

-- 5c) Reg_DWH_StaticPosition fallback gate:
-- Keep conditional unless profiling proves OpenPrice impact for MiFID-consumed fields.
SELECT
  table_catalog,
  table_schema,
  table_name,
  COUNT(*) AS visible_column_count
FROM system.information_schema.columns
WHERE lower(table_name) LIKE '%staticposition%'
GROUP BY table_catalog, table_schema, table_name
ORDER BY table_catalog, table_schema, table_name;

-- 5d) EMIR Refit UPI dependency gate:
-- UPI is not a direct MiFID dependency unless proven to affect compatibility fields.
SELECT
  table_catalog,
  table_schema,
  table_name
FROM system.information_schema.tables
WHERE lower(table_name) LIKE '%emir%refir%upi%'
   OR lower(table_name) LIKE '%upi%'
ORDER BY table_catalog, table_schema, table_name;

