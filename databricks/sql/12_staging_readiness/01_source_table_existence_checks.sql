-- Staging readiness: source table existence checks (SELECT-only).
-- No CREATE, INSERT, UPDATE, DELETE, MERGE, DROP.
-- Parameters: {{source_catalog}}, {{source_schema}}, {{target_catalog}}, {{target_schema}}, {{object_prefix}}, {{report_date}}

WITH run_params AS (
  SELECT
    lower(trim('{{source_catalog}}')) AS source_catalog,
    lower(trim('{{source_schema}}')) AS source_schema,
    lower(trim('{{target_catalog}}')) AS target_catalog,
    lower(trim('{{target_schema}}')) AS target_schema,
    lower(trim('{{object_prefix}}')) AS object_prefix,
    CAST('{{report_date}}' AS DATE) AS report_date
),
source_manifest AS (
  -- Group 1: price / currency / split
  SELECT 'price_currency_split' AS check_group, 'Reg_CurrencyPrice_Ext' AS staging_object,
         'main' AS table_catalog, 'dealing' AS table_schema, 'bronze_pricelog_history_currencyprice' AS table_name,
         'preferred primary (D-02) — required for Reg_CurrencyPrice_Ext readiness' AS manifest_status,
         false AS is_todo, false AS is_optional UNION ALL
  SELECT 'price_currency_split', 'Reg_CurrencyPrice_Ext (fallback)', 'main', 'trading', 'bronze_etoro_trade_currencyprice',
         'readable fallback — not preferred; does not satisfy Reg_CurrencyPrice_Ext readiness',
         false, true UNION ALL
  SELECT 'price_currency_split', 'Reg_Ext_CurrencyPriceMaxDateWithSplit', 'main', 'dealing', 'bronze_pricelog_candles_currencypricemaxdatewithsplit',
         'primary (D-05)', false, false UNION ALL
  SELECT 'price_currency_split', 'Reg_Ext_DailyMaxPrices', 'main', 'dealing', 'bronze_pricelog_history_currencypricemaxdate',
         'confirmed candidate', false, false UNION ALL
  SELECT 'price_currency_split', 'Reg_Ext_T_PriceCandle60Min', 'main', 'dealing', 'bronze_candles_candles_t_pricecandle60min',
         'confirmed candidate', false, false UNION ALL
  SELECT 'price_currency_split', 'Reg_Ext_HistorySplitRatio', 'main', 'dealing', 'bronze_pricelog_history_splitratio',
         'candidate — validate columns', false, false UNION ALL
  -- Group 2: non-price Reg_Ext
  SELECT 'non_price_reg_ext', 'Reg_Ext_Trade_GetInstrument', 'main', 'trading', 'bronze_etoro_trade_getinstrument',
         'expected — access pending', false, false UNION ALL
  SELECT 'non_price_reg_ext', 'Reg_Ext_Trade_InstrumentMetaData', 'main', 'trading', 'bronze_etoro_trade_instrumentmetadata',
         'expected — access pending', false, false UNION ALL
  SELECT 'non_price_reg_ext', 'Reg_Ext_DictionaryCurrency', 'main', 'general', 'bronze_etoro_dictionary_currency',
         'expected — access pending', false, false UNION ALL
  SELECT 'non_price_reg_ext', 'Reg_Ext_DictionaryCurrencyType', 'main', 'general', 'bronze_etoro_dictionary_currencytype',
         'expected — access pending', false, false UNION ALL
  SELECT 'non_price_reg_ext', 'Reg_Instruments_ext (SCD)', '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_scd',
         'TODO: confirm DE-migrated name in main.regtech', true, false UNION ALL
  SELECT 'non_price_reg_ext', 'Reg_Instruments_ext (full description)', '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_full_description',
         'TODO: confirm DE-migrated name', true, false UNION ALL
  -- Group 3: regulation movement
  SELECT 'regulation_movement', 'Reg_MigrationInOut_Population', '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_migrationinout_population',
         'DE-migrated gold preferred', true, false UNION ALL
  SELECT 'regulation_movement', 'Reg_RegulationInOutDailyData', '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_regulationinoutdailydata',
         'DE-migrated gold preferred', true, false UNION ALL
  SELECT 'regulation_movement', 'Reg_Regulation_Movments_Positions (upstream position)', 'main', 'trading', 'silver_etoro_trade_position',
         'confirmed mapping', false, false UNION ALL
  SELECT 'regulation_movement', 'Reg_Regulation_Movments_Positions (history position)', 'main', 'trading', 'bronze_etoro_history_position_datafactory',
         'confirmed mapping', false, false UNION ALL
  -- Group 4: hedge / liquidity
  SELECT 'hedge_liquidity', 'Reg_HedgeServerToLiquidityAccount_Ext', 'main', 'bi_db', 'bronze_etoro_hedge_hedgeservertoliquidityaccount',
         'confirmed mapping', false, false UNION ALL
  SELECT 'hedge_liquidity', 'Reg_LiquidtyAcount_Ext', 'main', 'trading', 'bronze_etoro_trade_liquidityaccounts',
         'confirmed mapping', false, false UNION ALL
  SELECT 'hedge_liquidity', 'Reg_Ext_LiquidityProviders', 'main', 'trading', 'bronze_etoro_trade_liquidityproviders',
         'confirmed mapping', false, false UNION ALL
  SELECT 'hedge_liquidity', 'Reg_Ext_LiquidityAccountID / LEI', 'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
         'confirmed mapping', false, false UNION ALL
  SELECT 'hedge_liquidity', 'LiquidityProviderType', 'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype',
         'confirmed mapping', false, false UNION ALL
  -- Group 5: MIFID2_ext non-PII
  SELECT 'mifid2_ext_non_pii', 'MIFID2_ext_Position (PositionForExternalUse)', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse',
         'confirmed — column profiling pending', false, false UNION ALL
  SELECT 'mifid2_ext_non_pii', 'MIFID2_ext_Position (history)', 'main', 'trading', 'bronze_etoro_history_position_datafactory',
         'confirmed mapping', false, false UNION ALL
  SELECT 'mifid2_ext_non_pii', 'MIFID2_ext_PositionChangeLog', 'main', 'trading', 'bronze_etoro_history_positionchangelog',
         'confirmed mapping', false, false UNION ALL
  SELECT 'mifid2_ext_non_pii', 'MIFID2_ext_Mirror', 'main', 'trading', 'bronze_etoro_history_mirror',
         'confirmed mapping', false, false UNION ALL
  SELECT 'mifid2_ext_non_pii', 'MIFID2_ext_HedgeExecutionLog', 'main', 'dealing', 'bronze_etoro_hedge_executionlog',
         'confirmed mapping', false, false UNION ALL
  SELECT 'mifid2_ext_non_pii', 'MIFID2_Failed_TRAX (dependency)', '{{target_catalog}}', '{{target_schema}}', '{{object_prefix}}mifid2_npd_trax',
         'GATED — seed/history required; do not require on first pass', true, true
),
normalized_manifest AS (
  SELECT
    check_group,
    staging_object,
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name,
    manifest_status,
    is_todo,
    is_optional,
    concat_ws('.', lower(table_catalog), lower(table_schema), lower(table_name)) AS object_name
  FROM source_manifest
),
existing_tables AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name
  FROM system.information_schema.tables
  WHERE lower(table_type) IN ('managed', 'external', 'view')
)
SELECT
  m.check_group,
  m.object_name,
  'table_exists' AS check_name,
  'EXISTS' AS expected,
  CASE WHEN e.table_name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual,
  CASE
    WHEN m.is_todo AND NOT m.is_optional THEN 'TODO'
    WHEN m.is_optional AND m.staging_object LIKE '%fallback%' THEN
      CASE WHEN e.table_name IS NOT NULL THEN 'WARN' ELSE 'SKIP' END
    WHEN m.is_optional THEN 'SKIP'
    WHEN e.table_name IS NOT NULL THEN 'PASS'
    ELSE 'FAIL'
  END AS status,
  m.manifest_status AS notes
FROM normalized_manifest m
LEFT JOIN existing_tables e
  ON m.table_catalog = e.table_catalog
 AND m.table_schema = e.table_schema
 AND m.table_name = e.table_name
ORDER BY m.check_group, m.staging_object;
