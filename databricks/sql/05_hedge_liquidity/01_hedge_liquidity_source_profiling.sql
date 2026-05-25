-- Step 7: hedge liquidity mapping source profiling (non-executable staging).
--
-- Target objects (gated):
--   main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
--
-- Purpose:
-- - Validate source visibility/access and required columns before enabling Step 7 staging SQL.
-- - Confirm source row counts and key coverage.
-- - Surface timestamp columns that can support freshness checks.
-- - Keep source-sensitive fields (`Username`, `Password`, `SettingsXML`) profiled but excluded/masked in staging.

-- -----------------------------------------------------------------------------
-- 1) Source inventory and visibility
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'hedge_server_to_liquidity_account' AS source_key, 'main' AS table_catalog, 'bi_db' AS table_schema, 'bronze_etoro_hedge_hedgeservertoliquidityaccount' AS table_name, 'confirmed mapping' AS source_status UNION ALL
  SELECT 'trade_liquidity_accounts', 'main', 'trading', 'bronze_etoro_trade_liquidityaccounts', 'confirmed mapping' UNION ALL
  SELECT 'trade_liquidity_providers', 'main', 'trading', 'bronze_etoro_trade_liquidityproviders', 'confirmed mapping' UNION ALL
  SELECT 'trade_liquidity_provider_type', 'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype', 'confirmed mapping' UNION ALL
  SELECT 'gsheet_liquidityaccountid_to_lei', 'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei', 'confirmed mapping'
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
-- 2) Required-column coverage checks (Step 7 contracts)
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'hedge_server_to_liquidity_account' AS source_key, 'main' AS table_catalog, 'bi_db' AS table_schema, 'bronze_etoro_hedge_hedgeservertoliquidityaccount' AS table_name UNION ALL
  SELECT 'trade_liquidity_accounts', 'main', 'trading', 'bronze_etoro_trade_liquidityaccounts' UNION ALL
  SELECT 'trade_liquidity_providers', 'main', 'trading', 'bronze_etoro_trade_liquidityproviders' UNION ALL
  SELECT 'trade_liquidity_provider_type', 'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype' UNION ALL
  SELECT 'gsheet_liquidityaccountid_to_lei', 'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei'
),
required_columns AS (
  SELECT 'hedge_server_to_liquidity_account' AS source_key, col AS column_name FROM VALUES
    ('HedgeServerID'), ('LiquidityAccountID'), ('AltRatesLiquidityAccountID')
  AS t(col)
  UNION ALL
  SELECT 'trade_liquidity_accounts', col FROM VALUES
    ('LiquidityAccountID'), ('LiquidityAccountName'), ('LiquidityProviderID'),
    ('IsActive'), ('LiquidityAccountTypeID'), ('AccountRateSourceID')
  AS t(col)
  UNION ALL
  SELECT 'trade_liquidity_providers', col FROM VALUES
    ('LiquidityProviderID'), ('LiquidityProviderName'), ('LiquidityProviderTypeID')
  AS t(col)
  UNION ALL
  SELECT 'trade_liquidity_provider_type', col FROM VALUES
    ('LiquidityProviderTypeID'), ('Name')
  AS t(col)
  UNION ALL
  SELECT 'gsheet_liquidityaccountid_to_lei', col FROM VALUES
    ('liquidity_account_id'), ('liquidity_account_name'), ('is_active'), ('e_toro_entity'),
    ('real_or_cfd'), ('lei'), ('lp_country_code'), ('trading_account_purpose_or_traded_instruments')
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

-- Optional sensitive-column presence check (for masking/exclusion policy).
-- These columns are intentionally excluded from normal Step 7 staging outputs.
WITH source_targets AS (
  SELECT 'trade_liquidity_accounts' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_trade_liquidityaccounts' AS table_name
),
sensitive_columns AS (
  SELECT 'trade_liquidity_accounts' AS source_key, col AS column_name FROM VALUES
    ('Username'), ('Password'), ('SettingsXML')
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
  sc.source_key,
  sc.column_name AS sensitive_column,
  CASE WHEN ac.column_name IS NULL THEN 'missing' ELSE 'present' END AS column_status
FROM sensitive_columns sc
LEFT JOIN available_columns ac
  ON sc.source_key = ac.source_key
 AND lower(sc.column_name) = lower(ac.column_name)
ORDER BY sc.column_name;

-- -----------------------------------------------------------------------------
-- 3) Source row counts and key coverage
-- -----------------------------------------------------------------------------
SELECT
  'hedge_server_to_liquidity_account' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LiquidityAccountID) AS distinct_liquidityaccountid_count,
  COUNT(DISTINCT HedgeServerID) AS distinct_hedgeserverid_count
FROM main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
UNION ALL
SELECT
  'trade_liquidity_accounts' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LiquidityAccountID) AS distinct_liquidityaccountid_count,
  COUNT(DISTINCT LiquidityProviderID) AS distinct_liquidityproviderid_count
FROM main.trading.bronze_etoro_trade_liquidityaccounts
UNION ALL
SELECT
  'trade_liquidity_providers' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LiquidityProviderID) AS distinct_liquidityproviderid_count,
  COUNT(DISTINCT LiquidityProviderTypeID) AS distinct_liquidityprovidertypeid_count
FROM main.trading.bronze_etoro_trade_liquidityproviders
UNION ALL
SELECT
  'trade_liquidity_provider_type' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT LiquidityProviderTypeID) AS distinct_liquidityprovidertypeid_count,
  CAST(NULL AS BIGINT) AS reserved_metric
FROM main.bi_db.bronze_etoro_trade_liquidityprovidertype
UNION ALL
SELECT
  'gsheet_liquidityaccountid_to_lei' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT liquidity_account_id) AS distinct_liquidityaccountid_count,
  COUNT(DISTINCT lei) AS distinct_lei_count
FROM main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei;

-- LEI completeness in source for active rows (where source marks active).
SELECT
  COUNT(*) AS active_row_count,
  SUM(CASE WHEN lei IS NULL OR TRIM(CAST(lei AS STRING)) = '' THEN 1 ELSE 0 END) AS active_missing_lei_count
FROM main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei
WHERE UPPER(TRIM(CAST(is_active AS STRING))) = 'ACTIVE';

-- -----------------------------------------------------------------------------
-- 4) Source freshness support (timestamp-column discovery)
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'hedge_server_to_liquidity_account' AS source_key, 'main' AS table_catalog, 'bi_db' AS table_schema, 'bronze_etoro_hedge_hedgeservertoliquidityaccount' AS table_name UNION ALL
  SELECT 'trade_liquidity_accounts', 'main', 'trading', 'bronze_etoro_trade_liquidityaccounts' UNION ALL
  SELECT 'trade_liquidity_providers', 'main', 'trading', 'bronze_etoro_trade_liquidityproviders' UNION ALL
  SELECT 'trade_liquidity_provider_type', 'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype' UNION ALL
  SELECT 'gsheet_liquidityaccountid_to_lei', 'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei'
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
   OR lower(c.column_name) LIKE '%sync%'
ORDER BY st.source_key, c.column_name;

-- Freshness template (activate per source after selecting a confirmed timestamp column):
-- SELECT
--   'trade_liquidity_accounts' AS source_key,
--   MIN(<freshness_column>) AS min_freshness_value,
--   MAX(<freshness_column>) AS max_freshness_value
-- FROM main.trading.bronze_etoro_trade_liquidityaccounts;
