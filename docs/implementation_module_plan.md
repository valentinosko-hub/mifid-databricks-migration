# Implementation Module Plan

This plan translates the Phase 1 documentation into implementation modules only. It does not contain implementation SQL, notebook definitions, Databricks table creation statements, or Databricks plugin actions.

Current scope remains table/report generation in `main.regtech_ops_stg`. CSV export, 7z compression, SFTP delivery, Cappitech upload, TRAX upload, TRAX response handling, production deployment into `main.regtech`, and full historical backfill remain out of scope.

All persistent target objects in `main.regtech_ops_stg` must use the `bi_output_regtechops_` prefix.

Reference policy:
- NOC materials and the old Databricks attempt remain reference-only for discovery/context and are not authoritative implementation logic.

Databricks plugin policy:
- Later for testing only, never for documentation or local SQL authoring steps.

## Module Order

1. Environment/config/naming helpers
2. Static reference compatibility views/tables
3A. ReplaceChar UDF and special-character dictionary compatibility
3B. InstrumentMetaData_SpecialChar_Conversion table-generation logic
4. Pre_Regulation_Ext staging
5. Regulation movement staging
6. Hedge liquidity mapping staging
7. ASIC2-compatible MiFID subset
8. MIFID2_ext staging
9. MIFID2_Customer output
10. MIFID2_RegChange_Customer output
11. MIFID2_Report and MIFID2_ME_Report outputs
12. MIFID2_ETORO_Report output
13. MIFID2_Hedge_Report EU/UK output
14. MIFID2_NPD_TRAX output
15. Validation/reconciliation SQL
16. Workflow/orchestration skeleton

## Module 1 - Environment/config/naming helpers

| Field | Plan |
| --- | --- |
| Purpose | Define reusable target catalog/schema/prefix conventions and prevent unprefixed persistent objects in `main.regtech_ops_stg`. |
| Source SQL files used | None directly. Use `FINAL_CURSOR_PROMPT.md` and Phase 1 docs as naming authority. |
| Source SSIS packages used | None directly. |
| Input tables | None. |
| Output tables | None required. Optional persisted control/config object only if needed. |
| Target Databricks object names | Optional: `main.regtech_ops_stg.bi_output_regtechops_config`, `main.regtech_ops_stg.bi_output_regtechops_run_parameters`. |
| Dependencies on prior modules | None. This is the first coding module. |
| Validation checks | Verify every planned target object in `main.regtech_ops_stg` starts with `bi_output_regtechops_`; verify no production `main.regtech` objects are targeted. |
| Open risks | Overly loose helper patterns could allow accidental unprefixed object creation. |
| Implementation files to create under `databricks/` | `databricks/sql/00_config/00_environment_config.sql`, `databricks/sql/00_config/01_naming_helpers.sql`. |
| Docs to update | `docs/validation_gates.md`, `docs/known_differences.md` if naming exceptions are discovered. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 2 - Static reference compatibility views/tables

| Field | Plan |
| --- | --- |
| Purpose | Expose already-available static/reference inputs through stable, prefixed compatibility objects where helpful. |
| Source SQL files used | None directly. Static references are documented in `docs/static_reference_tables.md` and `docs/dependency_coverage_matrix.md`. |
| Source SSIS packages used | None directly. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`, `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`, `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`, `main.general.bronze_etoro_dictionary_country` (for `Dictionary.Country` / `Dictionary.Ext_Country` compatibility handling), `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`, `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`, `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`, `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`, `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341`. |
| Output tables | No mandatory new tables. Compatibility views can be created for stable naming and logical columns. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`, `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`, `main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar`, `main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_country`, `main.regtech_ops_stg.bi_output_regtechops_vw_liquidityaccountid_to_lei`, `main.regtech_ops_stg.bi_output_regtechops_vw_regulation_report_excluded_cids`, `main.regtech_ops_stg.bi_output_regtechops_vw_regtech_excluded_instruments`, `main.regtech_ops_stg.bi_output_regtechops_vw_regtech_excluded_position_ids`, `main.regtech_ops_stg.bi_output_regtechops_vw_isin_for_instrumentid_341`. Existing prefixed tables remain canonical inputs where already available. |
| Dependencies on prior modules | Module 1. |
| Validation checks | Row counts, duplicate-key checks, required-column checks, freshness checks for Fivetran/SharePoint-derived inputs, EDNF logical-column alias checks. |
| Open risks | Some external reference inputs live outside `main.regtech_ops_stg`; compatibility views must not imply ownership of those source datasets. Country-source naming differences (`Dictionary.Country` vs `Dictionary.Ext_Country`) must be normalized explicitly in compatibility views. |
| Implementation files to create under `databricks/` | `databricks/sql/01_static_references/01_static_reference_compatibility.sql`, `databricks/sql/01_static_references/02_static_reference_quality_checks.sql`. |
| Docs to update | `docs/static_reference_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md` if any reference shape differs. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 3A - ReplaceChar UDF and special-character dictionary compatibility

| Field | Plan |
| --- | --- |
| Purpose | Recreate `dbo.ReplaceChar` parity behavior, wire static special-character dictionary compatibility, and define UDF-focused validation tests. |
| Source SQL files used | `03_sql_server_functions/replace_char_mapping.md`. |
| Source SSIS packages used | None required for UDF creation itself. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` (and/or `main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar`). |
| Output tables | `dbo.ReplaceChar` equivalent only. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`. |
| Dependencies on prior modules | Module 1 for naming and Module 2 for static dictionary compatibility objects. |
| Validation checks | Unit tests for trim-before-replace behavior, exact character replacements/removals, digit removal, and no accidental post-trim behavior. |
| Open risks | `dbo.ReplaceChar` behavior is strict; the SQL Server procedure uses `WHILE @iter < @count`, and parity must preserve or explicitly document that edge case. |
| Implementation files to create under `databricks/` | `databricks/sql/02_udfs/01_fn_replacechar.sql`, `databricks/sql/02_udfs/03_udf_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/known_differences.md`, `docs/validation_gates.md` after parity behavior is confirmed. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 3B - InstrumentMetaData_SpecialChar_Conversion table-generation logic

| Field | Plan |
| --- | --- |
| Purpose | Implement table-generation logic for `InstrumentMetaData_SpecialChar_Conversion` as a separate responsibility from UDF creation. |
| Source SQL files used | `SP_InstrumentMetaData_SpecialChar_Conversion.sql`. |
| Source SSIS packages used | `MIFID2.dtsx` (invokes conversion procedure flow). |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata` (from Module 4), `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` / `main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar`, `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`. |
| Output tables | `dbo.InstrumentMetaData_SpecialChar_Conversion`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`. |
| Dependencies on prior modules | Modules 1, 2, and 3A; hard dependency on Module 4 because `Reg_Ext_Trade_InstrumentMetaData` is required. |
| Validation checks | Conversion row counts, duplicate checks, sampled character-conversion parity versus SQL Server behavior. |
| Open risks | Conversion population cannot start before Module 4 materializes `Reg_Ext_Trade_InstrumentMetaData`. |
| Implementation files to create under `databricks/` | `databricks/sql/02_udfs/02_instrumentmetadata_specialchar_conversion.sql`, `databricks/sql/02_udfs/04_instrumentmetadata_conversion_validation.sql`. |
| Docs to update | `docs/dependency_coverage_matrix.md`, `docs/unresolved_dependencies.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

Step 4 boundary note:
- Step 4 should implement Module 3A only (ReplaceChar UDF + dictionary compatibility + UDF tests).
- Full `InstrumentMetaData_SpecialChar_Conversion` population is deferred to Module 3B after Module 4 is available.

## Module 4 - Pre_Regulation_Ext staging

| Field | Plan |
| --- | --- |
| Purpose | Recreate SSIS-created `Pre_Regulation_Ext.dtsx` staging for price/currency/split, migration in/out, customer/instrument, dictionary, and hedge extracts. |
| Source SQL files used | `SP_RegInRegOutPopulation.sql`, `SP_Reg_Instruments_SCD.sql` as lineage/reference where needed. |
| Source SSIS packages used | `Pre_Regulation_Ext.dtsx`. |
| Input tables | `main.trading.bronze_etoro_trade_currencyprice`, candidate `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit`, candidate `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, `main.dealing.bronze_candles_candles_t_pricecandle60min`, `main.dealing.bronze_pricelog_history_splitratio`, `main.regtech.gold_regtech_reg_migrationinout_population`, `main.regtech.gold_regtech_reg_regulationinoutdailydata`, `main.regtech.gold_regtech_reg_instruments_scd`, `main.regtech.gold_regtech_reg_instruments_full_description`, customer/history/dictionary/hedge mapped sources from the dependency matrix. |
| Output tables | `Reg_CurrencyPrice_Ext`, `Reg_Ext_CurrencyPriceMaxDateWithSplit`, `Reg_Ext_DailyMaxPrices`, `Reg_Ext_T_PriceCandle60Min`, `Reg_Ext_MigrationInOut_STG`, `Reg_MigrationInOut_Population`, `Reg_RegulationInOutDailyData`, `Reg_Ext_CustomerLatinName`, `Reg_Ext_HistorySplitRatio`, `Reg_Ext_Trade_GetInstrument`, `Reg_Ext_Trade_InstrumentMetaData`, `Reg_Ext_DictionaryCurrency`, `Reg_Ext_DictionaryCurrencyType`, `Reg_Ext_HedgeExecutionLog`, `Reg_Ext_HedgeHBCExecutionLog`, `Reg_Ext_HedgeHBCOrderLog`, `Reg_Instruments_ext`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg`, `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`, `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog`, `main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext`. |
| Dependencies on prior modules | Modules 1 and 2. Module 3B depends on this module for `Reg_Ext_Trade_InstrumentMetaData` population. |
| Validation checks | Row counts, source freshness, package filter parity, selected-column parity, price completeness, split-ratio parity, max-price checks, row-count parity against gold where applicable. |
| Open risks | Final source selection for `Reg_Ext_CurrencyPriceMaxDateWithSplit`; materialization policy for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` versus direct gold consumption; exact SSIS filters/date logic. These are carried forward and should not block initial implementation planning. |
| Implementation files to create under `databricks/` | `databricks/sql/03_pre_regulation_ext/01_price_currency_staging.sql`, `databricks/sql/03_pre_regulation_ext/02_migration_inout_staging.sql`, `databricks/sql/03_pre_regulation_ext/03_customer_instrument_dictionary_staging.sql`, `databricks/sql/03_pre_regulation_ext/04_hedge_extract_staging.sql`, `databricks/sql/03_pre_regulation_ext/05_pre_regulation_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/source_to_databricks_mapping_review.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 5 - Regulation movement staging

| Field | Plan |
| --- | --- |
| Purpose | Recreate regulation movement staging used by `MIFID2_Report`, especially `Reg_Regulation_Movments_Positions`. |
| Source SQL files used | `SP_RegInRegOutPopulation.sql` where movement population dependencies overlap. |
| Source SSIS packages used | `Regulation_Movments_Report.dtsx`, with upstream dependency on `Pre_Regulation_Ext.dtsx`. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg`, `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`, `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata`, mapped position/history inputs as required by package logic. |
| Output tables | `Reg_Regulation_Movments_Positions`; possible refresh participation for `Reg_Ext_MigrationInOut_STG` and `Reg_MigrationInOut_Population`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg`, `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`. |
| Dependencies on prior modules | Modules 1, 2, and 4. |
| Validation checks | Row counts by report/run date, business-key duplicate checks, migration in/out parity against gold and SSIS-created result, movement date continuity checks. |
| Open risks | Materialization policy for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData`; exact movement package filters and truncate/reload behavior. |
| Implementation files to create under `databricks/` | `databricks/sql/04_regulation_movements/01_regulation_movments_positions.sql`, `databricks/sql/04_regulation_movements/02_regulation_movements_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/ssis_created_staging_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 6 - Hedge liquidity mapping staging

| Field | Plan |
| --- | --- |
| Purpose | Recreate hedge server to liquidity account staging and SCD support required by Hedge EU/UK reports. |
| Source SQL files used | `SP_Reg_LiquidtyAcount_SCD.sql`. |
| Source SSIS packages used | `HedgeServerToLiquidity_Mapping.dtsx`. |
| Input tables | `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`, `main.trading.bronze_etoro_trade_liquidityaccounts`, `main.trading.bronze_etoro_trade_liquidityproviders`, `main.bi_db.bronze_etoro_trade_liquidityprovidertype`, `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`, static compatibility views from Module 2. |
| Output tables | `Reg_HedgeServerToLiquidityAccount_Ext`, `Reg_LiquidtyAcount_Ext`, `Reg_Ext_LiquidityAccountID`, `Reg_Ext_LiquidityProviders`, `Reg_LiquidtyAcount_SCD`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext`, `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders`, `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`. |
| Dependencies on prior modules | Modules 1 and 2. |
| Validation checks | Row counts, key coverage, LEI completeness, provider coverage, SCD validity-window checks, duplicate-current-row checks. |
| Open risks | Misspelled legacy object names (`Liquidty`, `Acount`) must be retained or mapped intentionally for parity; SCD validity-window behavior must match SQL Server enough for hedge outputs. |
| Implementation files to create under `databricks/` | `databricks/sql/05_hedge_liquidity/01_liquidity_ext_staging.sql`, `databricks/sql/05_hedge_liquidity/02_reg_liquidtyacount_scd.sql`, `databricks/sql/05_hedge_liquidity/03_hedge_liquidity_validation.sql`. |
| Docs to update | `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`, `docs/validation_gates.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 7 - ASIC2-compatible MiFID subset

| Field | Plan |
| --- | --- |
| Purpose | Build the ASIC2-compatible subset that replaces legacy `ASIC_Transactions` for MiFID ETORO logic. |
| Source SQL files used | `SP_ASIC2_Instrument_Automation.sql`, `SP_ASIC2_PositionReport.sql`, `SP_ASIC2_PositionReport_Agg.sql`, `SP_ASIC2_TransactionsReport.sql`. |
| Source SSIS packages used | `ASIC2.dtsx`. |
| Input tables | `main.general.gold_ib_u1059976_open_positions_all` (kept here because it is directly referenced by ASIC2 open-positions logic, not only hedge logic), `main.trading.silver_etoro_trade_position`, `main.trading.bronze_etoro_history_position_datafactory`, `main.trading.bronze_etoro_history_positionchangelog`, `main.regtech.gold_regtech_reg_instruments_scd`, `main.regtech.gold_regtech_reg_instruments_full_description`, Modules 2, 4, and 5 staging where consumed by ASIC2 logic. |
| Output tables | `ASIC2_ext_OpenPositions_PositionsReport`, `ASIC2_ext_PositionChangeLog`, `ASIC2_Customer_PositionReport`, `ASIC2_Positions`, `ASIC2_InstrumentMetaData`, `ASIC2_Removed_OP_Partials`, `ASIC2_Transactions` (ASIC2-shaped staging), `MIFID2_ASIC2_Transactions` (MiFID-owned projected subset), and compatibility view shape for old `ASIC_Transactions`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport`, `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog`, `main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport`, `main.regtech_ops_stg.bi_output_regtechops_asic2_positions`, `main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata`, `main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials`, `main.regtech_ops_stg.bi_output_regtechops_asic2_transactions`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`, `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`. |
| Dependencies on prior modules | Modules 1, 2, 4, and 5. |
| Validation checks | Row counts, position key checks, event continuity, instrument metadata coverage, transaction field parity, compatibility-view schema checks, `CDE_Execution_timestamp -> OpenTime` validation. |
| Open risks | ASIC2 compatibility replacement details for legacy `ASIC_Transactions`; `CDE_Execution_timestamp -> OpenTime` timezone/semantic parity; optional history seed strategy for `ASIC2_Transactions`; `Reg_DWH_StaticPosition` remains conditional/legacy and should not block unless proven to affect MiFID fields. |
| Implementation files to create under `databricks/` | `databricks/sql/06_asic2_subset/01_asic2_ext_staging.sql`, `databricks/sql/06_asic2_subset/02_asic2_positions.sql`, `databricks/sql/06_asic2_subset/03_asic2_transactions.sql`, `databricks/sql/06_asic2_subset/04_mifid_asic_compatibility.sql`, `databricks/sql/06_asic2_subset/05_asic2_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/source_to_databricks_mapping_review.md`, `docs/dependency_coverage_matrix.md`, `docs/history_seed_requirements.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 8 - MIFID2_ext staging

| Field | Plan |
| --- | --- |
| Purpose | Recreate `MIFID2.dtsx` staging tables consumed by customer, report, hedge, ETORO, and NPD_TRAX outputs. |
| Source SQL files used | Core MiFID procedures as consumers: `SP_MIFID_Customer.sql`, `SP_MIFID_RegChange_Customer.sql`, `SP_MIFID_Report.sql`, `SP_MIFID_HedgeEU_Report.sql`, `SP_MIFID_HedgeUK_Report.sql`, `SP_MIFID2_NPD_TRAX.sql`. |
| Source SSIS packages used | `MIFID2.dtsx`. |
| Input tables | Modules 2, 3A, 4, 5, and 6 outputs; mapped customer, history, trade position, history position, mirror, position-change-log, hedge execution sources. Module 7 outputs are not a hard prerequisite for core `MIFID2_ext_*` staging unless specific ETORO-linked branches explicitly consume them. |
| Output tables | `MIFID2_ext_Customer`, `MIFID2_ext_RegChange_Customer`, `MIFID2_ext_Position`, `MIFID2_ext_RegChange_Position`, `MIFID2_ext_PositionChangeLog`, `MIFID2_ext_Mirror`, `MIFID2_ext_HedgeExecutionLog`, `MIFID2_Failed_TRAX`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`. |
| Dependencies on prior modules | Modules 1, 2, 3A, 4, 5, and 6. Module 7 is optional only where proven by MIFID2/ETORO-specific dependency paths. |
| Validation checks | Staging row counts, required-field checks, key uniqueness, date continuity, failed TRAX counts, package filter parity. |
| Open risks | Exact SSIS selected columns and date filters must be preserved; `MIFID2_Failed_TRAX` is staging/failure support, not a raw source. |
| Implementation files to create under `databricks/` | `databricks/sql/07_mifid2_ext/01_customer_ext.sql`, `databricks/sql/07_mifid2_ext/02_position_ext.sql`, `databricks/sql/07_mifid2_ext/03_mirror_and_pcl_ext.sql`, `databricks/sql/07_mifid2_ext/04_hedge_ext.sql`, `databricks/sql/07_mifid2_ext/05_failed_trax.sql`, `databricks/sql/07_mifid2_ext/06_mifid2_ext_validation.sql`. |
| Docs to update | `docs/ssis_created_staging_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 9 - MIFID2_Customer output

| Field | Plan |
| --- | --- |
| Purpose | Generate the final `MIFID2_Customer` output table from MiFID customer staging and reference inputs. |
| Source SQL files used | `SP_MIFID_Customer.sql` (documented procedure dependency: `SP_MIFID2_Customer`). |
| Source SSIS packages used | `MIFID2.dtsx`. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`, static references, dictionary/country/label/customer/history mapped inputs as surfaced through earlier modules. |
| Output tables | `dbo.MIFID2_Customer`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`. |
| Dependencies on prior modules | Modules 1, 2, 3A, 4, and 8. |
| Validation checks | Schema parity, row counts by `ReportDate`, duplicate-key checks, required-field null checks, `dbo.ReplaceChar` output parity. |
| Open risks | Customer string normalization can drift if `dbo.ReplaceChar` parity is not exact. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/01_mifid2_customer.sql`, `databricks/sql/08_outputs/01_mifid2_customer_validation.sql`. |
| Docs to update | `docs/final_output_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 10 - MIFID2_RegChange_Customer output

| Field | Plan |
| --- | --- |
| Purpose | Generate the final `MIFID2_RegChange_Customer` output table from reg-change customer staging. |
| Source SQL files used | `SP_MIFID_RegChange_Customer.sql` (documented procedure dependency: `SP_MIFID2_RegChange_Customer`). |
| Source SSIS packages used | `MIFID2.dtsx`. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`, `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`, static references, customer/history mapped inputs. |
| Output tables | `dbo.MIFID2_RegChange_Customer`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`. |
| Dependencies on prior modules | Modules 1, 2, 3A, 4, and 8; Module 9 for shared customer parity assumptions. |
| Validation checks | Schema parity, row counts by `ReportDate`, duplicate-key checks, required-field null checks, `dbo.ReplaceChar` output parity. |
| Open risks | Reg-change window semantics and customer history joins must match SQL Server logic. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql`, `databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql`. |
| Docs to update | `docs/final_output_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 11 - MIFID2_Report and MIFID2_ME_Report outputs

| Field | Plan |
| --- | --- |
| Purpose | Generate the main MiFID reports and removed open-position partials from MIFID2 staging, regulation movements, pricing, instruments, and references. |
| Source SQL files used | `SP_MIFID_Report.sql` (documented procedure dependency: `SP_MIFID2_Report`). |
| Source SSIS packages used | `MIFID2.dtsx`, with upstream dependencies on `Pre_Regulation_Ext.dtsx` and `Regulation_Movments_Report.dtsx`. |
| Input tables | Modules 2, 3A, 3B, 4, 5, and 8 outputs; `main.regtech.gold_regtech_reg_instruments_scd`; `main.regtech.gold_regtech_reg_instruments_full_description`; position/history/mirror/price/split staging. |
| Output tables | `dbo.MIFID2_Report`, `dbo.MIFID2_ME_Report`, `dbo.MIFID2_Removed_OP_Partials`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`. |
| Dependencies on prior modules | Modules 1, 2, 3A, 3B, 4, 5, 6, and 8, plus customer outputs where referenced by report logic. |
| Validation checks | Row counts by `ReportDate`, row counts by regulation identifiers, business-key duplicate checks, required-field null checks, quantity/price aggregates, checksum/hash comparisons where practical, explicit-column behavior for removed partials. |
| Open risks | `MIFID2_Report` and `MIFID2_ME_Report` have nullable `UpdateDate` with no default; do not invent a default. `MIFID2_Removed_OP_Partials` must use explicit column ordering in implementation. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/03_mifid2_report.sql`, `databricks/sql/08_outputs/04_mifid2_me_report.sql`, `databricks/sql/08_outputs/05_mifid2_removed_op_partials.sql`, `databricks/sql/08_outputs/03_main_report_validation.sql`. |
| Docs to update | `docs/final_output_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`, `docs/reconciliation_plan.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 12 - MIFID2_ETORO_Report output

| Field | Plan |
| --- | --- |
| Purpose | Generate `MIFID2_ETORO_Report` using ASIC2-compatible source-of-truth logic instead of legacy `ASIC_Transactions`. |
| Source SQL files used | `SP_MIFID_ETORO_Report.sql`, plus ASIC2 source SQL files from Module 7 for replacement shape. |
| Source SSIS packages used | `MIFID2.dtsx`, `ASIC2.dtsx`. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions` or `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`, Modules 2, 4, 7, 8, and 11 outputs as required by ETORO logic. |
| Output tables | `dbo.MIFID2_ETORO_Report`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`. |
| Dependencies on prior modules | Modules 1 through 11, especially Module 7 ASIC2 compatibility. |
| Validation checks | Row counts, duplicate checks, required-field null checks, ASIC2 compatibility field parity, `OpenTime` parity, comparison with expected legacy ETORO output. |
| Open risks | ASIC2 compatibility replacement details and `CDE_Execution_timestamp -> OpenTime` validation remain unresolved; EMIR UPI is not a direct dependency unless ASIC2 validation proves it affects consumed MiFID ETORO fields. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/06_mifid2_etoro_report.sql`, `databricks/sql/08_outputs/06_mifid2_etoro_report_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/dependency_coverage_matrix.md`, `docs/source_to_databricks_mapping_review.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 13 - MIFID2_Hedge_Report EU/UK output

| Field | Plan |
| --- | --- |
| Purpose | Generate the combined Hedge EU/UK final output using hedge execution staging and liquidity-account SCD mapping. |
| Source SQL files used | `SP_MIFID_HedgeEU_Report.sql`, `SP_MIFID_HedgeUK_Report.sql`. |
| Source SSIS packages used | `MIFID2.dtsx`, `HedgeServerToLiquidity_Mapping.dtsx`. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`, `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`, `main.general.gold_ednf_coretrades`, `main.general.gold_ib_u1059976_open_positions_all`, `main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`, `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`, hedge execution/HBC staging, instrument metadata, static liquidity references. |
| Output tables | `dbo.MIFID2_Hedge_Report`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`. |
| Dependencies on prior modules | Modules 1, 2, 3B, 4, 6, and 8. |
| Validation checks | Row counts, duplicate checks, key consistency, hedge EU/UK split checks, liquidity-account coverage, deterministic `RecordID` sequence checks. |
| Open risks | `MIFID2_Hedge_Report.RecordID` identity strategy must be decided because SQL Server uses `IDENTITY(100000001,1)` and Databricks will need deterministic behavior for parity. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/07_mifid2_hedge_report.sql`, `databricks/sql/08_outputs/07_mifid2_hedge_report_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/final_output_tables.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 14 - MIFID2_NPD_TRAX output

| Field | Plan |
| --- | --- |
| Purpose | Generate `MIFID2_NPD_TRAX` table output only, excluding upload, delivery, and response handling. |
| Source SQL files used | `SP_MIFID2_NPD_TRAX.sql`. |
| Source SSIS packages used | `MIFID2 TRAX.dtsx` for table-generation flow only; file/response activities are out of scope. |
| Input tables | `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`, `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`, static references, internal accounts, `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax` if consumed by retry/exception logic. |
| Output tables | `dbo.MIFID2_NPD_TRAX`. |
| Target Databricks object names | `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`. |
| Dependencies on prior modules | Modules 1 through 13, especially customer, report, and failed TRAX staging outputs. |
| Validation checks | Row counts, required-field null checks, acceptance/status flag checks, duplicate checks, comparison against SQL Server output for current validation windows. |
| Open risks | `MIFID2_NPD_TRAX` history seed strategy remains unresolved for older parity windows; full historical backfill remains out of scope. TRAX upload and response processing remain out of scope. |
| Implementation files to create under `databricks/` | `databricks/sql/08_outputs/08_mifid2_npd_trax.sql`, `databricks/sql/08_outputs/08_mifid2_npd_trax_validation.sql`. |
| Docs to update | `docs/unresolved_dependencies.md`, `docs/history_seed_requirements.md`, `docs/dependency_coverage_matrix.md`, `docs/known_differences.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 15 - Validation/reconciliation SQL

| Field | Plan |
| --- | --- |
| Purpose | Create validation and reconciliation SQL for staging tables and final outputs without changing business logic. |
| Source SQL files used | All migrated source SQL files as validation subjects; no standalone business transformation source. |
| Source SSIS packages used | All in-scope packages as lineage subjects: `Pre_Regulation_Ext.dtsx`, `Regulation_Movments_Report.dtsx`, `HedgeServerToLiquidity_Mapping.dtsx`, `ASIC2.dtsx`, `MIFID2.dtsx`, `MIFID2 TRAX.dtsx`. |
| Input tables | All target staging and final output objects from Modules 2 through 14; SQL Server comparison extracts when available outside Databricks implementation. |
| Output tables | Optional validation/reconciliation result tables. |
| Target Databricks object names | Optional: `main.regtech_ops_stg.bi_output_regtechops_validation_row_counts`, `main.regtech_ops_stg.bi_output_regtechops_validation_duplicates`, `main.regtech_ops_stg.bi_output_regtechops_validation_null_checks`, `main.regtech_ops_stg.bi_output_regtechops_reconciliation_summary`, `main.regtech_ops_stg.bi_output_regtechops_known_differences`. |
| Dependencies on prior modules | Modules 1 through 14. |
| Validation checks | Row counts by `ReportDate`, row counts by `RegulationID` / `RegulationReportID`, business-key duplicate checks, required-field null checks, quantity/price aggregate checks, checksum/hash-style comparisons where practical, source freshness, staging and final row counts. |
| Open risks | Audit/control persistence scope is still conditional; validation design must document differences from missing historical seed data instead of changing business logic. |
| Implementation files to create under `databricks/` | `databricks/sql/09_validation/01_row_counts.sql`, `databricks/sql/09_validation/02_duplicate_checks.sql`, `databricks/sql/09_validation/03_null_checks.sql`, `databricks/sql/09_validation/04_aggregate_checks.sql`, `databricks/sql/09_validation/05_reconciliation_summary.sql`, `databricks/sql/09_validation/06_source_freshness.sql`. |
| Docs to update | `docs/reconciliation_plan.md`, `docs/known_differences.md`, `docs/history_seed_requirements.md`, `docs/validation_gates.md`, `docs/unresolved_dependencies.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Module 16 - Workflow/orchestration skeleton

| Field | Plan |
| --- | --- |
| Purpose | Define a repeatable Databricks workflow skeleton that preserves SQL Agent/SSIS ordering without implementing file delivery or response handling. |
| Source SQL files used | SQL Agent job metadata and all module SQL files once created. |
| Source SSIS packages used | `Pre_Regulation_Ext.dtsx`, `Regulation_Movments_Report.dtsx`, `HedgeServerToLiquidity_Mapping.dtsx`, `ASIC2.dtsx`, `MIFID2.dtsx`, `MIFID2 TRAX.dtsx`. |
| Input tables | All module inputs and outputs needed to execute the dependency chain. |
| Output tables | Optional run/audit/control tables if audit scope is approved. |
| Target Databricks object names | Optional: `main.regtech_ops_stg.bi_output_regtechops_audit_run_log`, `main.regtech_ops_stg.bi_output_regtechops_audit_ssis_log`, `main.regtech_ops_stg.bi_output_regtechops_workflow_control`. |
| Dependencies on prior modules | Modules 1 through 15. |
| Validation checks | Dependency order check, idempotency check, per-module success/failure status, validation result gating, no out-of-scope delivery tasks included. |
| Open risks | Audit/control persistence scope is unresolved; workflow must avoid secrets from SSIS metadata and must not include CSV export, compression, SFTP, Cappitech/TRAX upload, or response handling. |
| Implementation files to create under `databricks/` | `databricks/workflows/mifid_phase1_table_generation.yml`, `databricks/sql/10_workflow/01_run_control.sql`, `databricks/sql/10_workflow/02_audit_logging.sql`, `databricks/sql/10_workflow/03_workflow_readme.md`. |
| Docs to update | `docs/migration_execution_order.md`, `docs/reconciliation_plan.md`, `docs/known_differences.md`, `docs/unresolved_dependencies.md`. |
| Databricks plugin needed later for testing | Later for testing only; not for documentation or local SQL authoring. |

## Cross-Module Dependency Summary

- Modules 1 and 2 establish naming and static references for all downstream work.
- Module 3A provides `dbo.ReplaceChar` parity and UDF testing; Module 3B provides instrument special-character conversion after Module 4 inputs exist.
- Modules 4, 5, 6, 7, and 8 recreate SSIS-created staging layers and compatibility inputs.
- Modules 9 through 14 generate final MiFID outputs in dependency order.
- Modules 15 and 16 validate and orchestrate the table/report generation flow.

## Risks Carried Into Implementation

- `Reg_Ext_CurrencyPriceMaxDateWithSplit` final source selection is unresolved and belongs to Module 4.
- `Reg_MigrationInOut_Population` / `Reg_RegulationInOutDailyData` materialization policy belongs to Modules 4 and 5.
- `dbo.ReplaceChar` behavior parity tests belong to Module 3A.
- ASIC2 compatibility replacement details and `CDE_Execution_timestamp -> OpenTime` validation belong to Modules 7 and 12.
- `ASIC2_Transactions` history seed strategy belongs to Module 7.
- `MIFID2_Hedge_Report.RecordID` identity strategy belongs to Module 13.
- `MIFID2_NPD_TRAX` history seed strategy belongs to Module 14.
- Audit/control persistence scope belongs to Modules 15 and 16.
