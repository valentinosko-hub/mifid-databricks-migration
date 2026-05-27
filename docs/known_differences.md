# Known Differences (Current Safe + Steps 5B1-12B3)

This document tracks known or intentional differences for the currently implemented scope:

- Environment/config/naming helpers
- Static reference compatibility views
- `ReplaceChar` UDF
- Validation SQL scripts for static references and `ReplaceChar`
- Pre_Regulation price/currency/split staging (Step 5B1)
- Pre_Regulation non-price staging analysis/profiling gates (Step 5B2)
- Regulation movement staging analysis/profiling gates (Step 6)
- Hedge liquidity mapping staging analysis/profiling gates (Step 7)
- ASIC2-compatible MiFID subset profiling/gated templates (Step 8)
- MIFID2_ext staging profiling/gated templates (Step 9)
- MIFID2_Customer output profiling/gated templates (Step 10)
- MIFID2_RegChange_Customer output profiling/gated templates (Step 11)
- MIFID2_Report / MIFID2_ME_Report / MIFID2_Removed_OP_Partials scaffolding and validation foundation (Step 12B1):
  - Step 12B1 created scaffolding, output schema contracts, gates, and validation foundation only.
  - It did not implement full report business logic.
  - Final report business logic remains gated for later Step 12B2 / 12B3.
  - `UpdateDate` remains nullable; no default should be invented.
  - `MIFID2_Removed_OP_Partials` must use explicit column lists.
- MIFID2_Report intermediate position/trade population templates (Step 12B2):
  - Step 12B2 adds gated pre-branch population templates only.
  - It stops at unified intermediate trade pool (`#tradesFinal` equivalent).
  - Final branch inserts remain deferred to Step 12B3.

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
- Step 8 includes ASIC2 subset profiling/gating only; no active Step 8 staging/view DDL is enabled yet.
- Step 9 includes MIFID2_ext profiling/gating only; no active Step 9 staging DDL is enabled yet.
- Step 10 includes only `MIFID2_Customer` profiling/gating; no active final-output DDL is enabled yet.
- Step 11 includes only `MIFID2_RegChange_Customer` profiling/gating; no active final-output DDL is enabled yet.
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
- Step 8 compatibility view activation remains gated until `CDE_Execution_timestamp -> OpenTime` semantics are validated.
- Step 8 keeps `SP_ASIC2_Instrument_Automation` and `SP_ASIC2_PositionReport_Agg` as conditional dependencies only; they are not activated unless profiling proves direct feed into required Step 8 outputs.
- Step 8 keeps `Reg_DWH_StaticPosition` conditional/legacy and non-blocking unless OpenPrice fallback impact is proven for MiFID-consumed fields.
- Step 9 customer/reg-change customer activation remains gated until BackOffice as-of contracts and PIN/UserAPI source contracts are runtime-profiled.
- Step 9 position/reg-change position activation remains gated until `PositionForExternalUse` source-shape and migration interval parity are validated.
- Step 9 `MIFID2_Failed_TRAX` activation remains gated until `MIFID2_NPD_TRAX` history/current seed policy is approved for requested validation windows.
- Step 10 `MIFID2_Customer` activation remains gated until:
  - Step 9 customer/failed-TRAX staging gates are cleared.
  - `Reg_Ext_CustomerLatinName` source/profile gate is cleared.
  - `Dictionary.Ext_TradeFund` Databricks mapping is confirmed.
- Step 11 `MIFID2_RegChange_Customer` activation remains gated until:
  - Step 9 reg-change customer staging gates are cleared.
  - `Reg_Ext_CustomerLatinName` source/profile gate is cleared.
  - `Dictionary.Ext_TradeFund` Databricks mapping is confirmed.

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

## Step 8 implementation differences and cautions

- `databricks/sql/06_asic2_subset/01_asic2_source_profiling.sql` profiles Step 8 source visibility, required columns, conditional dependencies, and UPI/static-position gate evidence before any activation.
- `databricks/sql/06_asic2_subset/02_asic2_ext_staging.sql` contains commented Delta templates for:
  - `ASIC2_ext_OpenPositions_PositionsReport`
  - `ASIC2_ext_PositionChangeLog`
  - `ASIC2_Customer_PositionReport`
- `databricks/sql/06_asic2_subset/03_asic2_positions_and_instruments.sql` contains commented Delta templates for:
  - `ASIC2_InstrumentMetaData`
  - `ASIC2_Positions`
- `databricks/sql/06_asic2_subset/04_asic2_transactions.sql` contains commented Delta templates for:
  - `ASIC2_Removed_OP_Partials`
  - `ASIC2_Transactions`
  - `MIFID2_ASIC2_Transactions`
- `databricks/sql/06_asic2_subset/05_mifid_asic_compatibility_view.sql` contains a commented compatibility view template that exposes exactly:
  - `DateID`, `ReportDate`, `CID`, `PositionID`, `InstrumentID`, `OpenORClose`, `IsBuy`, `OpenTime`, `Volume`, `OpenPrice`, `RegChange`
- `databricks/sql/06_asic2_subset/06_asic2_validation.sql` includes OpenTime parsing checks, Quantity->Volume parity checks, exact 11-column compatibility schema checks, UPI non-dependency checks, and Reg_DWH_StaticPosition fallback-impact checks.
- `CDE_Execution_timestamp -> OpenTime` is intentionally treated as unproven and remains validation-gated.
- EMIR Refit UPI remains out of active Step 8 dependency scope unless validation proves impact on MiFID-consumed compatibility fields.

## Step 9 implementation differences and cautions

- `databricks/sql/07_mifid2_ext/01_mifid2_ext_source_profiling.sql` profiles Step 9 source visibility, required columns, PIN/UserAPI discovery, and migration/NPD_TRAX dependency gates before any Step 9 activation.
- `databricks/sql/07_mifid2_ext/02_customer_ext_staging.sql` contains commented Delta templates for:
  - `MIFID2_ext_Customer`
  - `MIFID2_ext_RegChange_Customer`
- `databricks/sql/07_mifid2_ext/03_position_ext_staging.sql` contains commented Delta templates for:
  - `MIFID2_ext_Position`
  - `MIFID2_ext_RegChange_Position`
- `databricks/sql/07_mifid2_ext/04_positionchangelog_mirror_ext_staging.sql` contains commented Delta templates for:
  - `MIFID2_ext_PositionChangeLog`
  - `MIFID2_ext_Mirror`
- `databricks/sql/07_mifid2_ext/05_hedge_ext_staging.sql` contains a commented Delta template for:
  - `MIFID2_ext_HedgeExecutionLog`
- `databricks/sql/07_mifid2_ext/06_failed_trax_staging.sql` contains a commented Delta template for:
  - `MIFID2_Failed_TRAX`
- `databricks/sql/07_mifid2_ext/07_mifid2_ext_validation.sql` includes source/target contract checks, duplicate/null checks, as-of/date-window checks, `ChangeTypeID = 0`, mirror `CopyFund`, hedge exclusion checks, failed-TRAX latest-row checks, and source-to-stage parity checks.
- Only `MIFID2_Failed_TRAX` has formal DDL in the ssis-created DDL folder; the other seven Step 9 table contracts are documented as derived from SSIS metadata plus consumer stored-procedure usage.
- Step 9 position staging uses `Trade.PositionForExternalUse` and `History.PositionForExternalUse` mappings; broad `Trade.Position` / `History.Position` are not used as replacement sources for this module unless package proof requires it.

## Step 10 implementation differences and cautions

- `databricks/sql/08_outputs/01_mifid2_customer.sql` is authored as a gated template only:
  - includes gate-status output
  - includes commented DDL + report-date delete/insert template
  - includes explicit DDL-aligned column list for `MIFID2_Customer`
- `databricks/sql/08_outputs/01_mifid2_customer_validation.sql` contains Step 10 validation templates for:
  - target/schema contract checks
  - row counts by `ReportDate` and `RegulationID`
  - duplicate and required-null checks
  - exclusion checks (excluded CIDs, CountryID 250, PlayerLevelID/internal-account rule)
  - country normalization checks (Citizenship precedence, 144->143, abbreviation coverage)
  - ReplaceChar and name-normalization sample checks
  - InternalAccounts/LEI coverage checks
  - PIN/UserAPI availability/completeness checks
  - source-to-output count checks
- Step 10 preserves SQL Server fallback behavior for `FTD` (`COALESCE(..., '2015-04-26')`) and does not invent upstream `FirstTimeDepositSuccessDate` source behavior.
- Step 10 template keeps `FirstTimeDepositSuccessDate` as a consumer-layer fallback derivation because Step 9 customer staging does not provide this field directly.
- Step 10 preserves no-concat country controls (`67,95,102,126,164,191`) for `NotAllowedCONCAT` and non-LEI PIN identifier handling.
- Step 10 template intentionally does not enable any out-of-scope final outputs (`RegChange_Customer`, `Report`, `ME`, `ETORO`, `Hedge`, `NPD_TRAX`).

## Step 11 implementation differences and cautions

- `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql` is authored as a gated template only:
  - includes gate-status output
  - includes commented DDL + report-date delete/insert template
  - includes explicit DDL-aligned column list for `MIFID2_RegChange_Customer`
  - remains gated on Step 9 reg-change source readiness, Step 6 migration interval parity evidence, PIN/UserAPI contracts, TradeFund mapping, CustomerLatinName availability, and ReplaceChar parity approval
- `databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql` contains Step 11 validation templates for:
  - target/schema contract checks
  - source dependency and gate checklist checks
  - row counts by `ReportDate` and `RegulationID`
  - duplicate and required-null checks
  - exclusion checks (`CountryID = 250`, `PlayerLevelID = 4` unless internal account)
  - country normalization and no-concat-flag checks
  - country/name/ReplaceChar checks
  - Latin-name coverage checks
  - LEI/PIN checks
  - source-to-output count checks
  - schema/row-set comparison notes vs `MIFID2_Customer`
- Step 11 preserves SQL Server fallback behavior for `FTD` (`ISNULL(FirstTimeDepositSuccessDate, '20150426')`) without inventing an upstream source.
- Step 11 intentionally uses `MIFID2_ext_RegChange_Customer` only, without `MIFID2_Failed_TRAX` union and without excluded-CID filtering.
- Step 11 preserves SQL Server no-concat behavior:
  - countries `67,95,102,126,164,191` drive `NotAllowedCONCAT`
  - non-LEI `PIN_LEI` remains `CountryAbbreviation + PIN` (no no-concat PIN suppression in this module).
- Step 11 template does not enable any out-of-scope final outputs (`Report`, `ME`, `ETORO`, `Hedge`, `NPD_TRAX`).

## Step 12B1 implementation differences and cautions

- `databricks/sql/08_outputs/03_mifid2_report_scaffolding.sql` is scaffolding-only and intentionally non-executable for final report loads:
  - report-date parameter scaffold only
  - gate-status output only
  - commented DDL contracts only for:
    - `bi_output_regtechops_mifid2_report`
    - `bi_output_regtechops_mifid2_me_report`
    - `bi_output_regtechops_mifid2_removed_op_partials`
  - explicit TODO anchors for Step 12B2 (position/trade CTEs), Step 12B3 (branch projections), Step 12B4 (activation/reconciliation)
- `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql` contains validation foundations only:
  - schema parity templates (including order and precision/scale checks)
  - row-count, duplicate, null, exclusion, coverage, movement/regchange, removed-partials, aggregate, source-to-output placeholders
- No full `SP_MIFID_Report` business logic is ported in Step 12B1.
- No position/trade population CTEs are activated in Step 12B1.
- No final branch projections (EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, ME) are activated in Step 12B1.
- `MIFID2_Report` and `MIFID2_ME_Report` keep `UpdateDate` nullable with no invented default.
- `MIFID2_Removed_OP_Partials` requires explicit target column lists for inserts; implicit-order SQL Server pattern is not acceptable for Databricks parity safety.
- Futures metadata is treated as expected mapping (`main.trading.bronze_etoro_trade_futuresmetadata`) and remains profiling-gated, not unknown.
- Step 12B1 intentionally excludes:
  - `MIFID2_ETORO_Report`
  - `MIFID2_Hedge_Report`
  - `MIFID2_NPD_TRAX`
  - file delivery and deployment workflows

## Step 12B2 implementation differences and cautions

- `databricks/sql/08_outputs/04_mifid2_report_position_population.sql` is a gated template only:
  - includes dependency/gate status output
  - includes commented CTE stack for intermediate flow only
  - does not create final-report rows in `MIFID2_Report` / `MIFID2_ME_Report`
- `databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql` defines validation templates for pre-branch intermediate population checks only.
- SQL Server temp-table `DELETE`/`UPDATE` behavior in intermediate flow is represented as Databricks CTE filtering/anti-join logic in templates.
- Step 12B2 includes optional customer EU/UK flag preparation but does not apply final customer table updates.
- Step 12B2 includes removed-partial candidate logic only; final write to `MIFID2_Removed_OP_Partials` remains deferred.
- Step 12B2 preserves SQL Server null semantics for the 10-second migration/open exception:
  - no `COALESCE(..., sentinel)` substitution is used to force null differences into deletion criteria.
- Removed-partials candidate insert activation is scoped to the full Step 12B2 CTE stack:
  - standalone insert snippets that reference out-of-scope `removed_partial_candidates` are not valid.
- Optional intermediate checkpoint materialization is documented but not provided as dummy one-column DDL:
  - full schemas must be derived before any checkpoint table activation.
- Checkpoint-dependent validation blocks are marked optional/gated and must not be executed before checkpoint materialization.
- Split/GBX parity validation is gated on audit-field availability and is not treated as proven without those fields.
- FuturesMetaData is intentionally deferred to Step 12B3:
  - Step 12B2 pre-branch trade-pool templates do not include FuturesMetaData-dependent logic.
  - Futures metadata remains an activation/profile gate for final branch projections.

## Step 12B3 implementation differences and cautions

- `databricks/sql/08_outputs/05_mifid2_report_branch_projections.sql` is authored as a gated template only:
  - branch projections are present for EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, and ME
  - removed partials finalization template is included with explicit target columns
  - all final delete/insert statements remain commented pending gate clearance
- `databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql` adds Step 12B3 validation templates:
  - branch counts and suffix behavior checks
  - report/ME uniqueness checks
  - exclusion coverage checks
  - instrument/futures coverage checks (category-specific, with futures candidates derived from pre-output `IsFuture`)
  - removed-partials candidate-to-output reconciliation templates
- `InstrumentClassification` / CFI in Step 12B3 branch projections is hard-gated:
  - simplified fallback mapping is intentionally removed.
  - templates keep `InstrumentClassification = NULL` until exact `SP_MIFID_Report` branch-specific mappings are ported.
- `InstrumentID = 341` UK override source remains placeholder-gated:
  - branch template uses `{{isin_for_instrumentid_341_source}}`.
  - required normalized logical columns (`InstrumentID`, `OverrideISIN`, optional effective/report date) are still profiling-pending.
- `UpdateDate` is intentionally not populated in final branch templates:
  - templates keep `UpdateDate` nullable (`NULL`) and do not use `current_timestamp` or any default synthesis
- FuturesMetaData remains Step 12B3 profiling-gated:
  - expected source is `main.trading.bronze_etoro_trade_futuresmetadata`
  - activation remains blocked until required columns are verified
- No file-delivery/upload/deployment logic is included in Step 12B3 artifacts:
  - no CSV/7z/SFTP/TRAX/Cappitech/response handling
  - no production deployment behavior

## Step 12B4 implementation differences and cautions

- `databricks/sql/08_outputs/06_mifid2_report_final_reconciliation.sql` is authored as a read-only validation package:
  - SELECT-only reconciliation queries
  - no activation/business-write logic
  - no table creation or mutation statements
- Step 12B4 consolidates validation evidence across B1/B2/B3 validation artifacts and does not alter prior-step business logic.
- Source-to-output reconciliation in B4 remains placeholder-gated:
  - run only after `{{trades_final_source}}` is available/materialized.
- Removed-partials candidate-vs-output reconciliation remains placeholder-gated:
  - run only after `{{removed_partial_candidates_source}}` is available/materialized.
- Split/GBX audit validation in B4 remains gated:
  - do not treat split/GBX parity as proven until audit fields are materialized.
- Exact branch-specific `InstrumentClassification` / CFI parity remains a hard gate:
  - B4 preserves this gating and does not convert hard-gated logic into active parity logic.
- B4 includes no file-delivery/upload/deployment logic:
  - no CSV/7z/SFTP/TRAX/Cappitech/response handling
  - no production deployment behavior

## Reference-only policy

- NOC artifacts and old Databricks attempt remain reference-only discovery sources and are not authoritative implementation logic.

