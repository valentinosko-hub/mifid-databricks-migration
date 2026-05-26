# Phase 1B - Source to Databricks Mapping Review

Source scope used for this review:
- `reference/mifid_databricks_migration_context/04_sql_agent_jobs`
- `reference/mifid_databricks_migration_context/05_ssis/selected_packages`
- `reference/mifid_databricks_migration_context/05_ssis/metadata`
- `reference/mifid_databricks_migration_context/06_mappings`

## Confirmed mappings

These mappings are explicitly documented as established in `06_mappings`:

- `dbo.Reg_Instruments_SCD` -> `main.regtech.gold_regtech_reg_instruments_scd`
- `dbo.Reg_Instruments_Full_Description` -> `main.regtech.gold_regtech_reg_instruments_full_description`
- `dbo.Reg_MigrationInOut_Population` -> `main.regtech.gold_regtech_reg_migrationinout_population`
- `dbo.Reg_RegulationInOutDailyData` -> `main.regtech.gold_regtech_reg_regulationinoutdailydata`
- `[SYNAPSE-DWH-PROD]...[LP_EdnF_CoreTrades]` -> `main.general.gold_ednf_coretrades`
- `[SYNAPSE-DWH-PROD]...[LP_IB_U1059976_Open_Positions_All]` -> `main.general.gold_ib_u1059976_open_positions_all`
- `Dictionary.Country` -> `main.general.bronze_etoro_dictionary_country`
- `Dictionary.Label` -> `main.general.bronze_etoro_dictionary_label`
- `Customer.Customer` -> `main.general.bronze_etoro_customer_customer`
- `History.Customer` -> `main.pii_data.bronze_etoro_history_customer`
- `History.BackOfficeCustomer` -> `main.general.bronze_etoro_history_backofficecustomer`
- `Customer.ExtendedUserField` -> `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield`
- `Dictionary.ExtendedUserValueType` -> `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype`
- `Trade.Position` -> `main.trading.silver_etoro_trade_position`
- `History.Position` -> `main.trading.bronze_etoro_history_position_datafactory`
- `Trade.PositionForExternalUse` -> `main.bi_db.bronze_etoro_trade_positionforexternaluse`
- `History.PositionForExternalUse` -> `main.trading.bronze_etoro_history_position_datafactory`
- `History.Mirror` -> `main.trading.bronze_etoro_history_mirror`
- `History.PositionChangeLog` -> `main.trading.bronze_etoro_history_positionchangelog`
- `Hedge.ExecutionLog` -> `main.dealing.bronze_etoro_hedge_executionlog`
- `Hedge.HBCExecutionLog` -> `main.dealing.bronze_etoro_hedge_hbcexecutionlog`
- `Hedge.HBCOrderLog` -> `main.dealing.bronze_etoro_hedge_hbcorderlog`
- `Hedge.HedgeServerToLiquidityAccount` -> `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`
- `Trade.LiquidityAccounts` -> `main.trading.bronze_etoro_trade_liquidityaccounts`
- `Trade.LiquidityProviders` -> `main.trading.bronze_etoro_trade_liquidityproviders`
- `Trade.LiquidityProviderType` -> `main.bi_db.bronze_etoro_trade_liquidityprovidertype`
- `google_sheets.reg_liquidityaccountid_to_lei` -> `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`
- `ThirdParty_Fivetran...regulation_report_excluded_cids` -> `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
- `ThirdParty_Fivetran...regtech_excluded_instruments` -> `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
- `ThirdParty_Fivetran...regtech_excluded_position_ids` -> `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
- `ThirdParty_Fivetran...isin_for_instrumentid_341` -> `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341`

## Candidate mappings

Candidate mappings that require final selection after SSIS column-level validation:

- `Reg_Ext_CurrencyPriceMaxDateWithSplit` -> `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` (candidate)
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` -> `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (candidate alternative)

## Conditional mappings

These are valid mappings but should be used conditionally based on package logic and dependency confirmation:

- `Reg_CurrencyPrice_Ext source` -> `main.trading.bronze_etoro_trade_currencyprice`  
  Use as an SSIS-created dynamic extract input, not as a one-time static replacement.  
  Step 5B1 status: provisional staging SQL authored; required-column parity profiling still pending.
- `Reg_Ext_T_PriceCandle60Min source` -> `main.dealing.bronze_candles_candles_t_pricecandle60min`  
  Conditional on exact package-side filtering/column logic.  
  Step 5B1 status: staging SQL authored with latest-row-per-`InstrumentID` logic; runtime source-shape check still required.
- `History.CurrencyPriceMaxDate source` -> `main.dealing.bronze_pricelog_history_currencypricemaxdate`  
  Conditional on run-window and column-level parity to SSIS-selected fields.  
  Step 5B1 status: provisional staging SQL authored; required-column profiling still pending.
- `ThirdParty_Fivetran...ed_n_f_to_istrumentid_etoro` -> `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`  
  Documented as manually uploaded static reference; keep as compatibility/static input.
- `regtech.si_reporting_configurations` -> `main.bi_db.bronze_fivetran_regtech_si_reporting_configurations`  
  Mapped in inventory, but usage should be confirmed per package/procedure dependency.

Classification note:
- `dbo.Reg_MigrationInOut_Population` and `dbo.Reg_RegulationInOutDailyData` have confirmed gold mappings, but in phase-1 dependency documentation they remain classified as SSIS-created staging dependencies (not missing raw sources) when produced/refreshed by SSIS/package logic.

Step 5B1 note:
- `Reg_CurrencyPrice_Ext`, `Reg_Ext_DailyMaxPrices`, and `Reg_Ext_T_PriceCandle60Min` are treated as SSIS-created staging outputs with materialized Delta targets in `main.regtech_ops_stg` (not replacement views).
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` remains unresolved pending candidate-comparison profiling; no silent source choice is made.

Step 5B2 note:
- `Reg_MigrationInOut_Population` -> `main.regtech.gold_regtech_reg_migrationinout_population` remains a confirmed gold source mapping, but the phase-1 staging object should be a prefixed materialized snapshot only after row-count and schema parity are accepted.
- `Reg_RegulationInOutDailyData` -> `main.regtech.gold_regtech_reg_regulationinoutdailydata` remains a confirmed gold source mapping, but output-column parity is gated because the procedure output schema is not visible in `Pre_Regulation_Ext.dtsx`.
- `Reg_Ext_HistorySplitRatio` -> `main.dealing.bronze_pricelog_history_splitratio` is a candidate/expected source with required-column and `IsCompletedOpenPositions = 1` filter validation pending.
- `Reg_Ext_HedgeExecutionLog` -> `main.dealing.bronze_etoro_hedge_executionlog`, `Reg_Ext_HedgeHBCExecutionLog` -> `main.dealing.bronze_etoro_hedge_hbcexecutionlog`, and `Reg_Ext_HedgeHBCOrderLog` -> `main.dealing.bronze_etoro_hedge_hbcorderlog` are confirmed raw sources; package-side date filters, casts, and required columns still require profiling before staging SQL is executable.
- `Reg_Ext_CustomerLatinName`, `Reg_Ext_Trade_GetInstrument`, `Reg_Ext_Trade_InstrumentMetaData`, `Reg_Ext_DictionaryCurrency`, and `Reg_Ext_DictionaryCurrencyType` are expected source / access pending until the corresponding Databricks source tables and required columns are confirmed.
- `Reg_Instruments_ext` should be shaped from certified FIRDS/instrument gold sources (`main.regtech.gold_regtech_reg_instruments_scd` and `main.regtech.gold_regtech_reg_instruments_full_description`) only after parity to the SSIS raw join output is validated.

Step 6 note (Regulation movement staging):
- Primary target remains `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions` (legacy spelling preserved for parity).
- Active movement build path uses migration population plus position/history sources, then post-load enrichment from instrument SCD and split-price data.
- `RegSupportDB.dbo.Ext_MigrationInOut_Population` is treated as a support-copy artifact in SQL Server and should be represented as non-persistent temporary logic in Databricks (CTE/temp relation), not a new persistent business table.
- `Reg_MigrationInOut_Population` can be consumed from prefixed snapshot `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` after parity validation; certified gold `main.regtech.gold_regtech_reg_migrationinout_population` remains the confirmed fallback mapping.
- `Reg_RegulationInOutDailyData` is not an active Step 6 build input for `Reg_Regulation_Movments_Positions`, but its mapping remains relevant for downstream consumers and parity governance.
- Step 6 post-load price enrichment remains gated until `Reg_Ext_CurrencyPriceMaxDateWithSplit` source-selection/parity is resolved.

Step 7 note (Hedge liquidity mapping staging):
- Confirmed source mappings for Step 7 are:
  - `Hedge.HedgeServerToLiquidityAccount` -> `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`
  - `Trade.LiquidityAccounts` -> `main.trading.bronze_etoro_trade_liquidityaccounts`
  - `Trade.LiquidityProviders` -> `main.trading.bronze_etoro_trade_liquidityproviders`
  - `Trade.LiquidityProviderType` -> `main.bi_db.bronze_etoro_trade_liquidityprovidertype`
  - `google_sheets.reg_liquidityaccountid_to_lei` -> `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`
- Step 7 target staging objects are:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`
- Execution remains gated until Step 7 source profiling confirms required columns and access in runtime schema.
- Sensitive source fields from `Trade.LiquidityAccounts` (`Username`, `Password`, `SettingsXML`) are intentionally excluded/masked for phase-1 normal staging objects.
- `Reg_LiquidtyAcount_SCD` activation is gated by seed/cutover decision; removed-account `IsLast` behavior follows SQL Server parity by default (no silent correction).

Step 8 note (ASIC2-compatible MiFID subset):
- Confirmed/selected source mappings for Step 8 include:
  - `History.PositionChangeLog` -> `main.trading.bronze_etoro_history_positionchangelog`
  - `Trade.PositionForExternalUse` -> `main.bi_db.bronze_etoro_trade_positionforexternaluse`
  - `History.PositionForExternalUse` -> `main.trading.bronze_etoro_history_position_datafactory`
  - `Customer.Customer` -> `main.general.bronze_etoro_customer_customer`
  - `History.Customer` -> `main.pii_data.bronze_etoro_history_customer`
  - `Dictionary.Country` -> `main.general.bronze_etoro_dictionary_country`
  - `Dictionary.Label` -> `main.general.bronze_etoro_dictionary_label`
  - `Reg_Instruments_SCD` -> `main.regtech.gold_regtech_reg_instruments_scd`
  - `Reg_Instruments_Full_Description` -> `main.regtech.gold_regtech_reg_instruments_full_description`
  - `ThirdParty_Fivetran...regtech_excluded_instruments` -> `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `ThirdParty_Fivetran...regtech_excluded_position_ids` -> `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
- Step 8 target objects are:
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_positions`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials`
  - `main.regtech_ops_stg.bi_output_regtechops_asic2_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- Step 8 execution remains gated until `databricks/sql/06_asic2_subset/01_asic2_source_profiling.sql` confirms required source columns and access.
- Conditional dependency rules:
  - `SP_ASIC2_Instrument_Automation` is out of scope only if `ASIC2_InstrumentMetaData` can be recreated without procedure-only logic.
  - `SP_ASIC2_PositionReport_Agg` and aggregate outputs remain out of scope only if profiling confirms they do not feed `ASIC2_Positions` / `ASIC2_Transactions` / MiFID projection.
  - `Reg_DWH_StaticPosition` remains conditional/legacy and non-blocking unless OpenPrice fallback impact is proven.
  - EMIR Refit UPI remains non-blocking unless profiling proves effect on the 11 MiFID compatibility fields.
- Expected source/access pending for Step 8:
  - Step 5 gated dependencies consumed by ASIC2 logic (`Reg_Ext_CustomerLatinName`, `Reg_Ext_DictionaryCurrency`, `Reg_Ext_CurrencyPriceMaxDateWithSplit`, `Reg_Ext_DailyMaxPrices`, `Reg_RegulationInOutDailyData`, `Reg_Instruments_ext`)
  - `Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Trade.Instrument`, `Trade.ProviderToInstrument`, `Dictionary.Currency`

Step 9 note (MIFID2_ext staging):
- Confirmed mappings for Step 9 include:
  - `History.BackOfficeCustomer` -> `main.general.bronze_etoro_history_backofficecustomer` (required-column profiling pending)
  - `Trade.PositionForExternalUse` -> `main.bi_db.bronze_etoro_trade_positionforexternaluse`
  - `History.PositionForExternalUse` -> `main.trading.bronze_etoro_history_position_datafactory`
  - `History.PositionChangeLog` -> `main.trading.bronze_etoro_history_positionchangelog`
  - `History.Mirror` -> `main.trading.bronze_etoro_history_mirror`
  - `Hedge.ExecutionLog` -> `main.dealing.bronze_etoro_hedge_executionlog`
  - `Customer.Customer` -> `main.general.bronze_etoro_customer_customer`
  - `History.Customer` -> `main.pii_data.bronze_etoro_history_customer`
  - `Customer.ExtendedUserField` -> `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield`
  - `Dictionary.ExtendedUserValueType` -> `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype`
  - `Dictionary.Country` -> `main.general.bronze_etoro_dictionary_country`
  - `Dictionary.Label` -> `main.general.bronze_etoro_dictionary_label`
- Step 9 position staging contract is `PositionForExternalUse`-based. Do not replace it with broad `Trade.Position` / `History.Position` mappings unless package evidence requires that.
- Step 9 expected source/access pending:
  - PIN/UserAPI runtime source object/column contract for `PIN_ID`, `PIN_Type`, `PIN`, `UAPI_CountryID`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` parity contract for reg-change windows
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` history/current availability for `MIFID2_Failed_TRAX`

## Mappings not to use (legacy/reference-only)

- Do not use optional/reference package artifacts as current mapping authority:
  - `optional_reference/MIFID2_TRAX_BACKREP2025.dtsx`
  - `optional_reference/BestEX_Daily.dtsx`
- Do not treat FIRDS lineage tables as primary replacement mappings when certified gold mappings exist:
  - `main.regtech.silver_esma_full`
  - `main.regtech.silver_esma_delta`
  - `main.regtech.silver_fca_full`
  - `main.regtech.silver_fca_delta`
  - Use certified targets instead: `main.regtech.gold_regtech_reg_instruments_scd`, `main.regtech.gold_regtech_reg_instruments_full_description`.
- Do not map SSIS-created staging families (`MIFID2_ext_*`, `Reg_Ext_*`, `ASIC2_ext_*`, `Reg_CurrencyPrice_Ext`, `Reg_MigrationInOut_Population`, `Reg_Regulation_Movments_Positions`) as if they were raw source systems; they are package-produced staging layers.
