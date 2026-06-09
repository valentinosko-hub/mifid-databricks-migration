-- Staging readiness: required-column checks (SELECT-only).
-- No CREATE, INSERT, UPDATE, DELETE, MERGE, DROP.
-- Run after 01_source_table_existence_checks.sql for objects with status PASS (non-TODO).
-- Parameters: {{source_catalog}}, {{source_schema}}, {{target_catalog}}, {{target_schema}}, {{object_prefix}}
-- Metadata: catalog-scoped information_schema only ({{source_catalog}}, {{target_catalog}}).
-- Do not use system.information_schema — may fail with INSUFFICIENT_PERMISSIONS (USE SCHEMA).

WITH source_targets AS (
  -- price / currency / split (preferred primary)
  SELECT 'price_currency_split' AS check_group,
         'main.dealing.bronze_pricelog_history_currencyprice' AS object_name,
         'reg_currencyprice_ext' AS source_key,
         'main' AS table_catalog, 'dealing' AS table_schema, 'bronze_pricelog_history_currencyprice' AS table_name,
         false AS is_todo, false AS is_optional, false AS is_fallback,
         'preferred primary for Reg_CurrencyPrice_Ext (D-02)' AS manifest_notes UNION ALL
  SELECT 'price_currency_split',
         'main.trading.bronze_etoro_trade_currencyprice',
         'reg_currencyprice_ext_fallback',
         'main', 'trading', 'bronze_etoro_trade_currencyprice',
         false, true, true,
         'readable fallback — not preferred; does not satisfy Reg_CurrencyPrice_Ext readiness' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit',
         'reg_ext_currencypricemaxdatewithsplit',
         'main', 'dealing', 'bronze_pricelog_candles_currencypricemaxdatewithsplit',
         false, false, false, 'primary (D-05)' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_history_currencypricemaxdate',
         'reg_ext_dailymaxprices',
         'main', 'dealing', 'bronze_pricelog_history_currencypricemaxdate',
         false, false, false, 'confirmed candidate' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_candles_candles_t_pricecandle60min',
         'reg_ext_t_pricecandle60min',
         'main', 'dealing', 'bronze_candles_candles_t_pricecandle60min',
         false, false, false, 'confirmed candidate' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_history_splitratio',
         'reg_ext_historysplitratio',
         'main', 'dealing', 'bronze_pricelog_history_splitratio',
         false, false, false, 'candidate — validate columns' UNION ALL
  -- non-price Reg_Ext
  SELECT 'non_price_reg_ext',
         'main.trading.bronze_etoro_trade_getinstrument',
         'reg_ext_trade_getinstrument',
         'main', 'trading', 'bronze_etoro_trade_getinstrument',
         false, false, false, 'expected — access pending' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.trading.bronze_etoro_trade_instrumentmetadata',
         'reg_ext_trade_instrumentmetadata',
         'main', 'trading', 'bronze_etoro_trade_instrumentmetadata',
         false, false, false, 'expected — access pending' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.general.bronze_etoro_dictionary_currency',
         'reg_ext_dictionarycurrency',
         'main', 'general', 'bronze_etoro_dictionary_currency',
         false, false, false, 'expected — access pending' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.general.bronze_etoro_dictionary_currencytype',
         'reg_ext_dictionarycurrencytype',
         'main', 'general', 'bronze_etoro_dictionary_currencytype',
         false, false, false, 'expected — access pending' UNION ALL
  SELECT 'non_price_reg_ext',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_instruments_scd',
         'reg_instruments_scd',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_scd',
         true, false, false, 'TODO: confirm DE-migrated name in main.regtech' UNION ALL
  SELECT 'non_price_reg_ext',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_instruments_full_description',
         'reg_instruments_full_description',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_full_description',
         true, false, false, 'TODO: confirm DE-migrated name' UNION ALL
  -- regulation movement
  SELECT 'regulation_movement',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_migrationinout_population',
         'reg_migrationinout_population',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_migrationinout_population',
         true, false, false, 'DE-migrated gold preferred' UNION ALL
  SELECT 'regulation_movement',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_regulationinoutdailydata',
         'reg_regulationinoutdailydata',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_regulationinoutdailydata',
         true, false, false, 'DE-migrated gold preferred' UNION ALL
  SELECT 'regulation_movement',
         'main.trading.silver_etoro_trade_position',
         'trade_position',
         'main', 'trading', 'silver_etoro_trade_position',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'regulation_movement',
         'main.trading.bronze_etoro_history_position_datafactory',
         'history_position',
         'main', 'trading', 'bronze_etoro_history_position_datafactory',
         false, false, false, 'confirmed mapping' UNION ALL
  -- hedge / liquidity
  SELECT 'hedge_liquidity',
         'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount',
         'hedge_server_to_liquidity_account',
         'main', 'bi_db', 'bronze_etoro_hedge_hedgeservertoliquidityaccount',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'hedge_liquidity',
         'main.trading.bronze_etoro_trade_liquidityaccounts',
         'trade_liquidity_accounts',
         'main', 'trading', 'bronze_etoro_trade_liquidityaccounts',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'hedge_liquidity',
         'main.trading.bronze_etoro_trade_liquidityproviders',
         'trade_liquidity_providers',
         'main', 'trading', 'bronze_etoro_trade_liquidityproviders',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'hedge_liquidity',
         'main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
         'gsheet_liquidityaccountid_to_lei',
         'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'hedge_liquidity',
         'main.bi_db.bronze_etoro_trade_liquidityprovidertype',
         'trade_liquidityprovidertype',
         'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype',
         false, false, false, 'confirmed mapping' UNION ALL
  -- MIFID2_ext non-PII
  SELECT 'mifid2_ext_non_pii',
         'main.bi_db.bronze_etoro_trade_positionforexternaluse',
         'trade_positionforexternaluse',
         'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse',
         false, false, false, 'confirmed — column profiling pending' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_position_datafactory',
         'history_positionforexternaluse',
         'main', 'trading', 'bronze_etoro_history_position_datafactory',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_positionchangelog',
         'history_positionchangelog',
         'main', 'trading', 'bronze_etoro_history_positionchangelog',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_mirror',
         'history_mirror',
         'main', 'trading', 'bronze_etoro_history_mirror',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.dealing.bronze_etoro_hedge_executionlog',
         'hedge_executionlog',
         'main', 'dealing', 'bronze_etoro_hedge_executionlog',
         false, false, false, 'confirmed mapping' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         '{{target_catalog}}.{{target_schema}}.{{object_prefix}}mifid2_npd_trax',
         'mifid2_failed_trax',
         '{{target_catalog}}', '{{target_schema}}', '{{object_prefix}}mifid2_npd_trax',
         true, true, false, 'GATED — seed/history required; do not require on first pass'
),
catalog_tables AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name
  FROM {{source_catalog}}.information_schema.tables
  UNION
  SELECT
    lower(table_catalog),
    lower(table_schema),
    lower(table_name)
  FROM {{target_catalog}}.information_schema.tables
),
table_visibility AS (
  SELECT
    st.*,
    CASE WHEN t.table_name IS NOT NULL THEN true ELSE false END AS is_visible
  FROM source_targets st
  LEFT JOIN catalog_tables t
    ON lower(t.table_catalog) = lower(st.table_catalog)
   AND lower(t.table_schema) = lower(st.table_schema)
   AND lower(t.table_name) = lower(st.table_name)
),
catalog_columns AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name,
    column_name
  FROM {{source_catalog}}.information_schema.columns
  UNION
  SELECT
    lower(table_catalog),
    lower(table_schema),
    lower(table_name),
    column_name
  FROM {{target_catalog}}.information_schema.columns
),
required_columns AS (
  SELECT 'reg_currencyprice_ext' AS source_key, col AS column_name FROM VALUES
    ('CurrencyPriceID'), ('ProviderID'), ('InstrumentID'), ('Bid'), ('Ask'), ('ValidFrom'), ('ValidTo'), ('Occurred')
  AS t(col) UNION ALL
  SELECT 'reg_ext_currencypricemaxdatewithsplit', col FROM VALUES
    ('PriceRateID'), ('ProviderID'), ('InstrumentID'), ('Occurred'), ('Bid'), ('Ask')
  AS t(col) UNION ALL
  SELECT 'reg_ext_dailymaxprices', col FROM VALUES
    ('CurrencyPriceID'), ('ProviderID'), ('InstrumentID'), ('Bid'), ('Ask'), ('ValidFrom'), ('ValidTo')
  AS t(col) UNION ALL
  SELECT 'reg_ext_t_pricecandle60min', col FROM VALUES
    ('InstrumentID'), ('BidLast'), ('AskLast'), ('DateFrom')
  AS t(col) UNION ALL
  SELECT 'reg_ext_historysplitratio', col FROM VALUES
    ('InstrumentID'), ('SplitRatio'), ('Occurred')
  AS t(col) UNION ALL
  SELECT 'reg_ext_trade_getinstrument', col FROM VALUES
    ('InstrumentID')
  AS t(col) UNION ALL
  SELECT 'reg_ext_trade_instrumentmetadata', col FROM VALUES
    ('InstrumentID'), ('CFI'), ('ISIN')
  AS t(col) UNION ALL
  SELECT 'reg_ext_dictionarycurrency', col FROM VALUES
    ('CurrencyID'), ('CurrencyName')
  AS t(col) UNION ALL
  SELECT 'reg_ext_dictionarycurrencytype', col FROM VALUES
    ('CurrencyTypeID'), ('CurrencyTypeName')
  AS t(col) UNION ALL
  SELECT 'reg_instruments_scd', col FROM VALUES
    ('InstrumentID'), ('ValidFrom'), ('ValidTo'), ('Symbol')
  AS t(col) UNION ALL
  SELECT 'reg_instruments_full_description', col FROM VALUES
    ('InstrumentID'), ('Symbol'), ('Description')
  AS t(col) UNION ALL
  SELECT 'reg_migrationinout_population', col FROM VALUES
    ('RunDate'), ('CID'), ('RegulationID'), ('Migration_Occurred')
  AS t(col) UNION ALL
  SELECT 'reg_regulationinoutdailydata', col FROM VALUES
    ('ReportDate'), ('CID'), ('RegulationID')
  AS t(col) UNION ALL
  SELECT 'trade_position', col FROM VALUES
    ('PositionID'), ('CID'), ('Occurred'), ('InstrumentID'), ('IsSettled')
  AS t(col) UNION ALL
  SELECT 'history_position', col FROM VALUES
    ('PositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'), ('InstrumentID')
  AS t(col) UNION ALL
  SELECT 'hedge_server_to_liquidity_account', col FROM VALUES
    ('HedgeServerID'), ('LiquidityAccountID')
  AS t(col) UNION ALL
  SELECT 'trade_liquidity_accounts', col FROM VALUES
    ('LiquidityAccountID'), ('LiquidityProviderID'), ('IsActive')
  AS t(col) UNION ALL
  SELECT 'trade_liquidity_providers', col FROM VALUES
    ('LiquidityProviderID'), ('LiquidityProviderName')
  AS t(col) UNION ALL
  SELECT 'gsheet_liquidityaccountid_to_lei', col FROM VALUES
    ('liquidity_account_id'), ('lei')
  AS t(col) UNION ALL
  SELECT 'trade_liquidityprovidertype', col FROM VALUES
    ('LiquidityProviderTypeID'), ('LiquidityProviderTypeName')
  AS t(col) UNION ALL
  SELECT 'trade_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('IsBuy'), ('AmountInUnitsDecimal')
  AS t(col) UNION ALL
  SELECT 'history_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('CloseOccurred')
  AS t(col) UNION ALL
  SELECT 'history_positionchangelog', col FROM VALUES
    ('PositionID'), ('Occurred'), ('ChangeTypeID')
  AS t(col) UNION ALL
  SELECT 'history_mirror', col FROM VALUES
    ('MirrorID'), ('ParentCID'), ('Occurred')
  AS t(col) UNION ALL
  SELECT 'hedge_executionlog', col FROM VALUES
    ('OrderID'), ('HedgeServerID'), ('InstrumentID'), ('ExecutionTime'), ('LiquidityAccountID')
  AS t(col)
),
-- Fallback / optional / gated objects: explicit policy rows (no column contract enforcement).
policy_rows AS (
  SELECT
    tv.check_group,
    tv.object_name,
    'required_column_policy' AS check_name,
    CASE
      WHEN tv.is_fallback THEN 'preferred_source_only'
      WHEN tv.is_optional AND tv.is_todo THEN 'gated_optional'
      ELSE 'optional_only'
    END AS expected,
    CASE
      WHEN tv.is_fallback THEN 'fallback_visible'
      WHEN NOT tv.is_visible AND tv.is_optional THEN 'not_visible'
      ELSE 'not_enforced'
    END AS actual,
    CASE
      WHEN tv.is_fallback THEN 'SKIP'
      WHEN tv.is_todo AND tv.is_optional THEN 'SKIP'
      ELSE 'WARN'
    END AS status,
    tv.manifest_notes AS notes
  FROM table_visibility tv
  WHERE tv.is_fallback
     OR (tv.is_optional AND tv.source_key = 'mifid2_failed_trax')
),
available_columns AS (
  SELECT
    tv.check_group,
    tv.object_name,
    tv.source_key,
    tv.is_todo,
    tv.is_optional,
    tv.is_fallback,
    tv.is_visible,
    c.column_name
  FROM table_visibility tv
  JOIN catalog_columns c
    ON lower(c.table_catalog) = lower(tv.table_catalog)
   AND lower(c.table_schema) = lower(tv.table_schema)
   AND lower(c.table_name) = lower(tv.table_name)
  WHERE NOT tv.is_fallback
    AND NOT (tv.is_optional AND tv.source_key = 'mifid2_failed_trax')
),
missing AS (
  SELECT
    tv.check_group,
    tv.object_name,
    tv.is_todo,
    tv.is_optional,
    tv.is_visible,
    rc.column_name AS missing_column
  FROM table_visibility tv
  JOIN required_columns rc
    ON tv.source_key = rc.source_key
  LEFT JOIN available_columns ac
    ON tv.source_key = ac.source_key
   AND lower(rc.column_name) = lower(ac.column_name)
  WHERE NOT tv.is_fallback
    AND NOT (tv.is_optional AND tv.source_key = 'mifid2_failed_trax')
    AND ac.column_name IS NULL
),
missing_rows AS (
  SELECT
    m.check_group,
    m.object_name,
    'required_column' AS check_name,
    m.missing_column AS expected,
    'MISSING' AS actual,
    CASE
      WHEN m.is_todo THEN 'TODO'
      WHEN m.is_optional THEN 'SKIP'
      WHEN NOT m.is_visible THEN 'NOT_RUN'
      ELSE 'FAIL'
    END AS status,
    'Required column not found in information_schema' AS notes
  FROM missing m
),
summary_rows AS (
  SELECT
    tv.check_group,
    tv.object_name,
    'required_column_summary' AS check_name,
    'all_required_present' AS expected,
    CASE
      WHEN tv.is_todo AND NOT tv.is_visible THEN 'table_not_visible'
      WHEN EXISTS (SELECT 1 FROM missing m WHERE m.object_name = tv.object_name) THEN 'columns_missing'
      ELSE 'all_required_present'
    END AS actual,
    CASE
      WHEN tv.is_fallback THEN 'SKIP'
      WHEN tv.is_todo THEN 'TODO'
      WHEN tv.is_optional AND tv.source_key = 'mifid2_failed_trax' THEN 'SKIP'
      WHEN NOT tv.is_visible THEN 'NOT_RUN'
      WHEN EXISTS (SELECT 1 FROM missing m WHERE m.object_name = tv.object_name AND m.is_todo) THEN 'TODO'
      WHEN EXISTS (SELECT 1 FROM missing m WHERE m.object_name = tv.object_name AND NOT m.is_todo AND NOT m.is_optional) THEN 'FAIL'
      WHEN EXISTS (SELECT 1 FROM missing m WHERE m.object_name = tv.object_name AND m.is_optional) THEN 'SKIP'
      ELSE 'PASS'
    END AS status,
    concat('source_key=', tv.source_key, '; ', tv.manifest_notes) AS notes
  FROM table_visibility tv
  WHERE NOT tv.is_fallback
    AND NOT (tv.is_optional AND tv.source_key = 'mifid2_failed_trax')
)
SELECT check_group, object_name, check_name, expected, actual, status, notes FROM policy_rows
UNION ALL
SELECT check_group, object_name, check_name, expected, actual, status, notes FROM missing_rows
UNION ALL
SELECT check_group, object_name, check_name, expected, actual, status, notes FROM summary_rows
ORDER BY check_group, object_name, check_name;
