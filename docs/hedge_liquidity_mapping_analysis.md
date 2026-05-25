# Step 7 - Hedge Liquidity Mapping Staging Analysis

This document captures Step 7 only (hedge liquidity mapping staging). It excludes ASIC2, `MIFID2_ext` staging, final MiFID outputs, and Hedge EU/UK final report generation.

## Step 7 scope

In-scope Step 7 objects:

- `Reg_HedgeServerToLiquidityAccount_Ext`
- `Reg_LiquidtyAcount_Ext`
- `Reg_Ext_LiquidityAccountID`
- `Reg_Ext_LiquidityProviders`
- `Reg_LiquidtyAcount_SCD`

Databricks targets (all prefixed and in ops staging):

- `main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext`
- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders`
- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`

Legacy spelling note:

- SQL Server object names intentionally use `Liquidty` / `Acount`.
- Step 7 preserves legacy names in documentation and target naming for parity and traceability.

## Active flow in `HedgeServerToLiquidity_Mapping.dtsx`

Package sequence relevant to Step 7:

1. Truncate staging tables:
   - `Reg_HedgeServerToLiquidityAccount_Ext`
   - `Reg_LiquidtyAcount_Ext`
   - `Reg_Ext_LiquidityProviders`
   - `Reg_Ext_LiquidityAccountID`
2. Load ext staging tables via data flows from mapped sources.
3. Archive snapshot copy:
   - `Reg_Ext_LiquidityAccountID -> Reg_Ext_LiquidityAccountID_Archive` (control/audit behavior; not a Step 7 business target).
4. Execute `SP_Reg_LiquidtyAcount_SCD`.
5. Run alert/update tasks around liquidity-account checks (operational control flow; not Step 7 business targets).

Because SSIS truncates/reloads the ext tables, Step 7 uses materialized Delta staging tables (not views) for the ext layer.

## Source mappings and status

Known source mappings for Step 7:

- `Hedge.HedgeServerToLiquidityAccount` -> `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`
- `Trade.LiquidityAccounts` -> `main.trading.bronze_etoro_trade_liquidityaccounts`
- `Trade.LiquidityProviders` -> `main.trading.bronze_etoro_trade_liquidityproviders`
- `Trade.LiquidityProviderType` -> `main.bi_db.bronze_etoro_trade_liquidityprovidertype`
- `google_sheets.reg_liquidityaccountid_to_lei` -> `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`

Status:

- Mapping-level status is `Confirmed`.
- Execution-level status remains `Gated` until source profiling confirms required columns/access in runtime catalogs.

## Required output columns by object

`Reg_HedgeServerToLiquidityAccount_Ext`:

- `HedgeServerID`
- `LiquidityAccountID`
- `AltRatesLiquidityAccountID`

`Reg_LiquidtyAcount_Ext`:

- `LiquidityProviderID`
- `LiquidityAccountID`
- `LiquidityAccountName`
- `IsActive`
- `LiquidityAccountTypeID`
- `AccountRateSourceID`

`Reg_Ext_LiquidityAccountID`:

- `LiquidityAccountID`
- `LiquidityAccountName`
- `IsActive`
- `eToroEntity`
- `RealOrCFD`
- `LEI`
- `LpCountryCode`
- `Comment`
- `UpdateDate`

`Reg_Ext_LiquidityProviders`:

- `LiquidityProviderID`
- `LiquidityProviderName`
- `LiquidityProviderTypeID`
- `LiquidityProviderTypeName`
- `UpdateDate`

`Reg_LiquidtyAcount_SCD`:

- `LiquidityAccountID`
- `HedgeServerID`
- `LiquidityAccountName`
- `LiquidityProviderID`
- `ValidFrom`
- `ValidTo`
- `RunDate`
- `IsNew`
- `IsLast`

## Sensitive-column handling

SSIS source SQL for `Reg_LiquidtyAcount_Ext` includes:

- `Username`
- `Password`
- `SettingsXML`

Phase-1 Step 7 handling:

- `Password` and `SettingsXML` are intentionally excluded from normal materialized staging objects.
- `Username` is also excluded from normal Step 7 staging because `SP_Reg_LiquidtyAcount_SCD` does not require it.
- Secrets are not copied from SSIS into migration SQL.
- If a compatibility shape later requires these fields, use explicit masked/null placeholders in a dedicated compatibility object and document that as an intentional exception.

## SCD behavior representation (`SP_Reg_LiquidtyAcount_SCD`)

Step 7 represents SCD logic with gated templates and preserves SQL Server defaults:

- `RunDate = CAST(GETUTCDATE() AS DATE)`
- New rows:
  - `ValidFrom = GETUTCDATE()`
  - `ValidTo = 9999-12-31`
  - `IsNew = 1`
  - `IsLast = 1`
- Changed current rows:
  - close prior latest row with `ValidTo = GETUTCDATE()` and `IsLast = 0`
  - insert replacement current row with `IsNew = 0`, `IsLast = 1`, `ValidTo = 9999-12-31`
- Removed-account behavior:
  - SQL Server updates `ValidTo` and `RunDate` for removed rows
  - SQL Server does not explicitly set `IsLast = 0` in removed-account update
  - Step 7 preserves this behavior by default; no silent correction is introduced

## SCD execution gate

`Reg_LiquidtyAcount_SCD` is persistent history and remains gated for activation pending seed/cutover decision.

Step 7 SQL provides:

- Optional initial seed/rebuild template (explicitly non-default)
- Incremental update template (preferred operational pattern)
- Validation templates

No unconditional `CREATE OR REPLACE TABLE` activation pattern is used for SCD runtime flow.

## Validation requirements for Step 7

Required checks are authored in `databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql`:

- Source required-column checks
- Source row counts
- Source freshness support (timestamp-column discovery)
- Duplicate checks:
  - `Reg_HedgeServerToLiquidityAccount_Ext`
  - `Reg_LiquidtyAcount_Ext` by `LiquidityAccountID`
  - `Reg_Ext_LiquidityAccountID` by `LiquidityAccountID`
  - `Reg_Ext_LiquidityProviders` by `LiquidityProviderID`
- LEI completeness checks for active/report-relevant accounts
- Provider ID coverage checks
- Null checks for `LiquidityAccountID` / `HedgeServerID` / `LEI` where required
- SCD duplicate current-row checks
- SCD `ValidFrom`/`ValidTo` consistency checks
- SCD overlap checks
- Current SCD rows match current ext values
- Source-to-stage count checks where practical
- Sensitive-column exposure checks (`Password`, `SettingsXML`) in stage target

## Implemented/gated status for Step 7 artifacts

Authored in Step 7:

- Source profiling SQL:
  - `databricks/sql/05_hedge_liquidity/01_hedge_liquidity_source_profiling.sql`
- Gated ext-staging SQL templates:
  - `databricks/sql/05_hedge_liquidity/02_liquidity_ext_staging.sql`
- Gated SCD templates:
  - `databricks/sql/05_hedge_liquidity/03_reg_liquidtyacount_scd.sql`
- Validation SQL templates:
  - `databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql`

Activation status:

- All Step 7 executable staging/SCD logic is intentionally gated until source profiling and seed/cutover decisions are completed.

## Remaining unresolved items for Step 7

- Runtime source schema/access confirmation must be completed before un-gating staging SQL.
- SCD seed/cutover decision (initial load vs incremental-only cutover strategy) must be finalized.
- Removed-account `IsLast` behavior is preserved for parity; any correction must be explicitly approved and documented.
- Confirm whether any downstream compatibility object is required to expose masked/null legacy sensitive columns.
