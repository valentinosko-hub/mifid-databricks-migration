-- Step 7: hedge liquidity validation templates.
--
-- Intended targets:
--   main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
--
-- Execute only after Step 7 staging/SCD materialization is activated.

-- -----------------------------------------------------------------------------
-- 1) Source required-column checks
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
    ('LiquidityProviderID'), ('LiquidityAccountID'), ('LiquidityAccountName'),
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

-- -----------------------------------------------------------------------------
-- 2) Source row counts and source freshness support
-- -----------------------------------------------------------------------------
SELECT
  'hedge_server_to_liquidity_account' AS source_key,
  COUNT(*) AS row_count
FROM main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
UNION ALL
SELECT
  'trade_liquidity_accounts',
  COUNT(*)
FROM main.trading.bronze_etoro_trade_liquidityaccounts
UNION ALL
SELECT
  'trade_liquidity_providers',
  COUNT(*)
FROM main.trading.bronze_etoro_trade_liquidityproviders
UNION ALL
SELECT
  'trade_liquidity_provider_type',
  COUNT(*)
FROM main.bi_db.bronze_etoro_trade_liquidityprovidertype
UNION ALL
SELECT
  'gsheet_liquidityaccountid_to_lei',
  COUNT(*)
FROM main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei;

-- Discover candidate source freshness columns (timestamps or audit-like names).
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

-- -----------------------------------------------------------------------------
-- 3) Target required-column checks
-- -----------------------------------------------------------------------------
WITH target_objects AS (
  SELECT 'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext' AS table_name UNION ALL
  SELECT 'Reg_LiquidtyAcount_Ext', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_ext' UNION ALL
  SELECT 'Reg_Ext_LiquidityAccountID', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid' UNION ALL
  SELECT 'Reg_Ext_LiquidityProviders', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityproviders' UNION ALL
  SELECT 'Reg_LiquidtyAcount_SCD', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_scd'
),
required_columns AS (
  SELECT 'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object, col AS column_name FROM VALUES
    ('HedgeServerID'), ('LiquidityAccountID'), ('AltRatesLiquidityAccountID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_LiquidtyAcount_Ext', col FROM VALUES
    ('LiquidityProviderID'), ('LiquidityAccountID'), ('LiquidityAccountName'),
    ('IsActive'), ('LiquidityAccountTypeID'), ('AccountRateSourceID')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_LiquidityAccountID', col FROM VALUES
    ('LiquidityAccountID'), ('LiquidityAccountName'), ('IsActive'), ('eToroEntity'),
    ('RealOrCFD'), ('LEI'), ('LpCountryCode'), ('Comment'), ('UpdateDate')
  AS t(col)
  UNION ALL
  SELECT 'Reg_Ext_LiquidityProviders', col FROM VALUES
    ('LiquidityProviderID'), ('LiquidityProviderName'), ('LiquidityProviderTypeID'),
    ('LiquidityProviderTypeName'), ('UpdateDate')
  AS t(col)
  UNION ALL
  SELECT 'Reg_LiquidtyAcount_SCD', col FROM VALUES
    ('LiquidityAccountID'), ('HedgeServerID'), ('LiquidityAccountName'), ('LiquidityProviderID'),
    ('ValidFrom'), ('ValidTo'), ('RunDate'), ('IsNew'), ('IsLast')
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

-- -----------------------------------------------------------------------------
-- 4) Staging row counts
-- -----------------------------------------------------------------------------
WITH stage_counts AS (
  SELECT 'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object, COUNT(*) AS row_count FROM main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext UNION ALL
  SELECT 'Reg_LiquidtyAcount_Ext', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext UNION ALL
  SELECT 'Reg_Ext_LiquidityAccountID', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid UNION ALL
  SELECT 'Reg_Ext_LiquidityProviders', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders UNION ALL
  SELECT 'Reg_LiquidtyAcount_SCD', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
)
SELECT *
FROM stage_counts
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- 5) Duplicate checks
-- -----------------------------------------------------------------------------
SELECT
  'Reg_HedgeServerToLiquidityAccount_Ext duplicate HedgeServerID/LiquidityAccountID' AS check_name,
  HedgeServerID,
  LiquidityAccountID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
GROUP BY HedgeServerID, LiquidityAccountID
HAVING COUNT(*) > 1;

SELECT
  'Reg_LiquidtyAcount_Ext duplicate LiquidityAccountID' AS check_name,
  LiquidityAccountID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
GROUP BY LiquidityAccountID
HAVING COUNT(*) > 1;

SELECT
  'Reg_Ext_LiquidityAccountID duplicate LiquidityAccountID' AS check_name,
  LiquidityAccountID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
GROUP BY LiquidityAccountID
HAVING COUNT(*) > 1;

SELECT
  'Reg_Ext_LiquidityProviders duplicate LiquidityProviderID' AS check_name,
  LiquidityProviderID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
GROUP BY LiquidityProviderID
HAVING COUNT(*) > 1;

-- Duplicate "current" SCD rows.
SELECT
  'Reg_LiquidtyAcount_SCD duplicate current rows' AS check_name,
  LiquidityAccountID,
  COUNT(*) AS duplicate_current_row_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
WHERE IsLast = 1
GROUP BY LiquidityAccountID
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 6) Null checks for required keys and LEI
-- -----------------------------------------------------------------------------
SELECT
  'Reg_HedgeServerToLiquidityAccount_Ext null keys' AS check_name,
  SUM(CASE WHEN HedgeServerID IS NULL THEN 1 ELSE 0 END) AS null_hedgeserverid_count,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS null_liquidityaccountid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext;

SELECT
  'Reg_LiquidtyAcount_Ext null keys' AS check_name,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS null_liquidityaccountid_count,
  SUM(CASE WHEN LiquidityProviderID IS NULL THEN 1 ELSE 0 END) AS null_liquidityproviderid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext;

SELECT
  'Reg_Ext_LiquidityAccountID null keys/lei' AS check_name,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS null_liquidityaccountid_count,
  SUM(CASE WHEN LEI IS NULL OR TRIM(CAST(LEI AS STRING)) = '' THEN 1 ELSE 0 END) AS null_or_blank_lei_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid;

SELECT
  'Reg_Ext_LiquidityProviders null keys' AS check_name,
  SUM(CASE WHEN LiquidityProviderID IS NULL THEN 1 ELSE 0 END) AS null_liquidityproviderid_count,
  SUM(CASE WHEN LiquidityProviderTypeID IS NULL THEN 1 ELSE 0 END) AS null_liquidityprovidertypeid_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders;

SELECT
  'Reg_LiquidtyAcount_SCD null required fields' AS check_name,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS null_liquidityaccountid_count,
  SUM(CASE WHEN ValidFrom IS NULL THEN 1 ELSE 0 END) AS null_validfrom_count,
  SUM(CASE WHEN ValidTo IS NULL THEN 1 ELSE 0 END) AS null_validto_count,
  SUM(CASE WHEN RunDate IS NULL THEN 1 ELSE 0 END) AS null_rundate_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd;

-- -----------------------------------------------------------------------------
-- 7) LEI completeness and provider coverage checks
-- -----------------------------------------------------------------------------
-- Active/report-relevant accounts: IsActive in gsheet marked ACTIVE.
SELECT
  COUNT(*) AS active_row_count,
  SUM(CASE WHEN LEI IS NULL OR TRIM(CAST(LEI AS STRING)) = '' THEN 1 ELSE 0 END) AS active_missing_lei_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
WHERE UPPER(TRIM(CAST(IsActive AS STRING))) = 'ACTIVE';

-- Accounts present in liquidity ext but missing gsheet/LEI mapping.
SELECT
  COUNT(*) AS liquidity_accounts_missing_lei_mapping_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid ex
  ON la.LiquidityAccountID = ex.LiquidityAccountID
WHERE ex.LiquidityAccountID IS NULL;

-- Provider ID coverage from accounts to providers lookup.
SELECT
  COUNT(*) AS liquidity_accounts_missing_provider_lookup_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders lp
  ON la.LiquidityProviderID = lp.LiquidityProviderID
WHERE la.LiquidityProviderID IS NOT NULL
  AND lp.LiquidityProviderID IS NULL;

-- -----------------------------------------------------------------------------
-- 8) SCD validity-window checks
-- -----------------------------------------------------------------------------
-- Invalid windows where ValidFrom > ValidTo.
SELECT
  COUNT(*) AS invalid_validity_window_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
WHERE ValidFrom > ValidTo;

-- Open-ended validity contract check.
SELECT
  COUNT(*) AS invalid_open_ended_validto_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
WHERE IsLast = 1
  AND ValidTo <> CAST('9999-12-31 00:00:00' AS TIMESTAMP);

-- Overlap checks per LiquidityAccountID.
WITH ordered_windows AS (
  SELECT
    LiquidityAccountID,
    ValidFrom,
    ValidTo,
    LAG(ValidTo) OVER (
      PARTITION BY LiquidityAccountID
      ORDER BY ValidFrom, ValidTo
    ) AS prev_valid_to
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
)
SELECT
  LiquidityAccountID,
  ValidFrom,
  ValidTo,
  prev_valid_to
FROM ordered_windows
WHERE prev_valid_to IS NOT NULL
  AND ValidFrom < prev_valid_to;

-- Current SCD rows should match current ext values.
SELECT
  COUNT(*) AS scd_current_mismatch_count
FROM (
  SELECT
    scd.LiquidityAccountID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd scd
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
    ON scd.LiquidityAccountID = la.LiquidityAccountID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext hs
    ON la.LiquidityAccountID = hs.LiquidityAccountID
  WHERE scd.IsLast = 1
    AND (
      COALESCE(scd.HedgeServerID, -1) <> COALESCE(hs.HedgeServerID, -1)
      OR COALESCE(scd.LiquidityAccountName, '') <> COALESCE(la.LiquidityAccountName, '')
      OR COALESCE(scd.LiquidityProviderID, -1) <> COALESCE(la.LiquidityProviderID, -1)
    )
) mismatches;

-- -----------------------------------------------------------------------------
-- 9) Source-to-stage count checks where practical
-- -----------------------------------------------------------------------------
WITH source_counts AS (
  SELECT
    'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object,
    COUNT(*) AS source_count
  FROM main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
  UNION ALL
  SELECT
    'Reg_LiquidtyAcount_Ext',
    COUNT(*)
  FROM main.trading.bronze_etoro_trade_liquidityaccounts
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityAccountID',
    COUNT(*)
  FROM main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityProviders',
    COUNT(*)
  FROM main.trading.bronze_etoro_trade_liquidityproviders lp
  JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
    ON lp.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
),
stage_counts AS (
  SELECT
    'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object,
    COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
  UNION ALL
  SELECT
    'Reg_LiquidtyAcount_Ext',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityAccountID',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityProviders',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
)
SELECT
  src.staging_object,
  src.source_count,
  stg.stage_count,
  src.source_count - stg.stage_count AS count_delta
FROM source_counts src
JOIN stage_counts stg
  ON src.staging_object = stg.staging_object
ORDER BY src.staging_object;

-- -----------------------------------------------------------------------------
-- 10) Sensitive-column contract check (stage must not expose raw secrets)
-- -----------------------------------------------------------------------------
SELECT
  c.column_name
FROM system.information_schema.columns c
WHERE lower(c.table_catalog) = 'main'
  AND lower(c.table_schema) = 'regtech_ops_stg'
  AND lower(c.table_name) = 'bi_output_regtechops_reg_liquidtyacount_ext'
  AND lower(c.column_name) IN ('username', 'password', 'settingsxml')
ORDER BY c.column_name;
