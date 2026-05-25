-- Step 7: hedge liquidity ext staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
--   main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until source profiling
--   confirms access and required columns (`01_hedge_liquidity_source_profiling.sql`).
-- - These are SSIS truncate/reload staging objects and should be materialized as Delta.
-- - Sensitive source fields (`Username`, `Password`, `SettingsXML`) are intentionally excluded
--   from normal staging outputs in phase 1.

WITH staging_gates AS (
  SELECT
    'Reg_HedgeServerToLiquidityAccount_Ext' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting source required-column/access profiling.' AS gate_reason
  UNION ALL
  SELECT
    'Reg_LiquidtyAcount_Ext',
    'main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext',
    'pending',
    'Awaiting source required-column/access profiling and sensitive-column masking confirmation.'
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityAccountID',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid',
    'pending',
    'Awaiting source required-column/access profiling.'
  UNION ALL
  SELECT
    'Reg_Ext_LiquidityProviders',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders',
    'pending',
    'Awaiting source required-column/access profiling.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext
USING DELTA
AS
SELECT
  HedgeServerID,
  LiquidityAccountID,
  AltRatesLiquidityAccountID
FROM main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount;
*/

/*
-- Sensitive-column handling:
-- - SQL Server SSIS selected `Username`, `Password`, `SettingsXML` from
--   Trade.LiquidityAccounts.
-- - Step 7 phase-1 staging intentionally excludes `Password` and `SettingsXML`.
-- - `Username` is also excluded from the normal staging object because it is not
--   required by SP_Reg_LiquidtyAcount_SCD.
-- - If a compatibility shape later requires these fields, expose masked/null
--   placeholders in a dedicated compatibility view only.
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext
USING DELTA
AS
SELECT
  LiquidityProviderID,
  LiquidityAccountID,
  LiquidityAccountName,
  CAST(IsActive AS INT) AS IsActive,
  LiquidityAccountTypeID,
  AccountRateSourceID
FROM main.trading.bronze_etoro_trade_liquidityaccounts;
*/

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid
USING DELTA
AS
SELECT
  liquidity_account_id AS LiquidityAccountID,
  liquidity_account_name AS LiquidityAccountName,
  is_active AS IsActive,
  e_toro_entity AS eToroEntity,
  real_or_cfd AS RealOrCFD,
  lei AS LEI,
  lp_country_code AS LpCountryCode,
  trading_account_purpose_or_traded_instruments AS Comment,
  to_utc_timestamp(current_timestamp(), current_timezone()) AS UpdateDate
FROM main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei;
*/

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders
USING DELTA
AS
SELECT
  lp.LiquidityProviderID,
  lp.LiquidityProviderName,
  lp.LiquidityProviderTypeID,
  lpt.Name AS LiquidityProviderTypeName,
  to_utc_timestamp(current_timestamp(), current_timezone()) AS UpdateDate
FROM main.trading.bronze_etoro_trade_liquidityproviders lp
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lp.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID;
*/
