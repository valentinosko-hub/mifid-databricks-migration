# Known Differences (Current Safe + Steps 5B1-7)

This document tracks known or intentional differences for the currently implemented scope:

- Environment/config/naming helpers
- Static reference compatibility views
- `ReplaceChar` UDF
- Validation SQL scripts for static references and `ReplaceChar`
- Pre_Regulation price/currency/split staging (Step 5B1)
- Pre_Regulation non-price staging analysis/profiling gates (Step 5B2)
- Regulation movement staging analysis/profiling gates (Step 6)
- Hedge liquidity mapping staging analysis/profiling gates (Step 7)

## Scope and non-goals in this step

- No full `Pre_Regulation_Ext` staging implementation.
- Step 5B1 includes only:
  - `Reg_CurrencyPrice_Ext`
  - `Reg_Ext_DailyMaxPrices`
  - `Reg_Ext_CurrencyPriceMaxDateWithSplit` (profiling/comparison only)
  - `Reg_Ext_T_PriceCandle60Min`
- Step 5B2 includes non-price profiling/gating only; no active non-price staging DDL is authored yet.
- Step 6 includes regulation-movement profiling/gating only; no active movement staging DDL is authored yet.
- Step 7 includes hedge-liquidity profiling/gating only; no active Step 7 staging/SCD DDL is enabled yet.
- No `MIFID2_ext` staging implementation.
- No final MiFID output table-generation implementation.
- No Hedge EU/UK final report implementation.
- No population logic for `InstrumentMetaData_SpecialChar_Conversion`.
- No CSV/7z/SFTP/Cappitech/TRAX upload/response handling.
- No production deployment to `main.regtech`.
- No full historical backfill.

## Implementation-phase assumptions

- Existing static sources are treated as available:
  - `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
  - `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`
- Country compatibility source for MiFID customer logic is exposed from:
  - `main.general.bronze_etoro_dictionary_country`
  - through view `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`.

## ReplaceChar parity notes

- UDF object:
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`
- Behavior implemented to match SQL Server intent:
  - trim before replacement
  - no trim after replacement
  - replacements for `š`, `Š`, `ß`, `É`, `é`
  - `-` and `_` replaced with spaces
  - listed punctuation/symbol characters removed
  - digits `0-9` removed
- Validation is script-based and must be executed later in test environment.
- Required-column validation now covers static base tables and compatibility views for EDNF, InternalAccounts, and Dictionary.Ext_SpecialChar.
- `vw_ext_country` column-contract validation is intentionally deferred until customer-logic schema expectations are finalized.

## Explicitly deferred to later module

- `InstrumentMetaData_SpecialChar_Conversion` population is deferred until `Pre_Regulation_Ext` creates:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata`
- Deferred artifact note:
  - `databricks/sql/02_udfs/02_instrumentmetadata_specialchar_conversion_deferred.sql`
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` final source and staging materialization are deferred until candidate profiling evidence selects one authoritative Databricks source.
- `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` remain gated until row-count/schema parity determines whether prefixed snapshots should be materialized from certified gold or recreated from SSIS-compatible logic.
- `Reg_Ext_Trade_InstrumentMetaData` remains gated until its source schema is confirmed; this continues to block `InstrumentMetaData_SpecialChar_Conversion` population.
- Step 6 enrichment for `Reg_Regulation_Movments_Positions` remains gated until split-price parity (`Reg_Ext_CurrencyPriceMaxDateWithSplit`) is resolved.
- Step 7 `Reg_LiquidtyAcount_SCD` activation remains gated until seed/cutover strategy is explicitly approved.

## Step 5B1 implementation differences and cautions

- `Reg_CurrencyPrice_Ext` and `Reg_Ext_DailyMaxPrices` SQL is authored as provisional and must not be executed until required-column parity checks pass.
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` is intentionally left as profiling/comparison-only in Step 5B1; no silent source choice was made.
- `Reg_Ext_T_PriceCandle60Min` staging SQL preserves SSIS-style logic (`DateFrom < report_date + 1 day`, latest row per `InstrumentID`, `InstrumentID < 100000`) and materializes to Delta.
- All Step 5B1 targets are prefixed and scoped to `main.regtech_ops_stg`.

## Step 5B2 implementation differences and cautions

- `databricks/sql/03_pre_regulation_ext/04_non_price_source_profiling.sql` profiles expected/confirmed sources before active staging SQL is allowed.
- `databricks/sql/03_pre_regulation_ext/05_non_price_staging_gates.sql` intentionally contains no `CREATE OR REPLACE TABLE` statements; it records why each non-price object is still gated.
- `databricks/sql/03_pre_regulation_ext/06_non_price_validation.sql` contains validation templates for later execution after staging tables are materialized.
- `Reg_Instruments_ext` is planned to use certified instrument gold/FIRDS sources if parity to the SSIS raw join output is confirmed.
- Dictionary and trade instrument sources are marked expected source / access pending; columns are not assumed.

## Step 6 implementation differences and cautions

- `databricks/sql/04_regulation_movements/01_regulation_movments_source_profiling.sql` profiles movement inputs before any executable Step 6 staging SQL is allowed.
- `databricks/sql/04_regulation_movements/02_regulation_movments_staging.sql` is intentionally gated and keeps intended staging logic commented until Step 5/6 gates pass.
- `databricks/sql/04_regulation_movements/03_regulation_movments_validation.sql` defines movement validation templates for later execution.
- SQL Server support-copy object `RegSupportDB.dbo.Ext_MigrationInOut_Population` is represented as non-persistent temporary logic in Databricks Step 6 flow.
- Legacy spelling `Movments` is preserved intentionally in target object naming for parity.

## Step 7 implementation differences and cautions

- `databricks/sql/05_hedge_liquidity/01_hedge_liquidity_source_profiling.sql` profiles source visibility, required columns, row counts, and freshness-support columns before Step 7 staging activation.
- `databricks/sql/05_hedge_liquidity/02_liquidity_ext_staging.sql` contains gated/commented Delta staging templates only; no active Step 7 staging DDL is enabled until profiling gates pass.
- `databricks/sql/05_hedge_liquidity/03_reg_liquidtyacount_scd.sql` contains gated SCD templates only and avoids unconditional `CREATE OR REPLACE TABLE` runtime behavior.
- `databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql` defines Step 7 validation templates for duplicates, LEI coverage, SCD consistency, and source-to-stage parity checks.
- Sensitive source fields from `Trade.LiquidityAccounts` (`Username`, `Password`, `SettingsXML`) are intentionally excluded from normal phase-1 `Reg_LiquidtyAcount_Ext` staging to avoid secrets exposure.
- If compatibility shape later requires legacy sensitive columns, only masked/null placeholders should be exposed in a dedicated compatibility object.
- SQL Server removed-account SCD behavior (does not explicitly set `IsLast = 0`) is preserved by default in the Step 7 gated template and is not silently corrected.
- Legacy spellings `Liquidty` / `Acount` are preserved intentionally in Step 7 target object naming for parity.

## Reference-only policy

- NOC artifacts and old Databricks attempt remain reference-only discovery sources and are not authoritative implementation logic.

