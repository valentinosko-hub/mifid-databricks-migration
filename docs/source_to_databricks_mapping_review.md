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
- `ThirdParty_Fivetran...isin_for_instrumentid_341` -> `{{isin_for_instrumentid_341_source}}` (mapped source table expected, but required-column contract for Step 12B3 override adapter is still pending)

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
- `Dictionary.Ext_TradeFund` -> expected source/access pending  
  Required by Step 10/11 customer outputs (`SP_MIFID2_Customer`, `SP_MIFID2_RegChange_Customer`) copy-fund enrichment (`FundAccountID`, `FundName`, `FundType`); do not activate mapping without profiling.

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

Step 10 note (`MIFID2_Customer` output):
- Step 10 target object is:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
- Step 10 consumes:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`
- Step 10 expected source/access pending:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname` (name translation path)
  - Databricks mapping for `Dictionary.Ext_TradeFund` (copy-fund enrichment path)
- Step 10 also depends on Step 9 failed-TRAX upstream seed availability:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` (latest-row dependency for `MIFID2_Failed_TRAX`)
- Step 10 activation remains gated until Step 9 customer/failed-TRAX gates are cleared and the two Step 10 pending mappings above are confirmed.
- Step 10 activation also requires approved ReplaceChar parity validation before executable output SQL is enabled.
- Step 10 preserves no-concat country controls (`67,95,102,126,164,191`) for customer PIN/identifier handling and `NotAllowedCONCAT` flag derivation.

Step 11 note (`MIFID2_RegChange_Customer` output):
- Step 11 target object is:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
- Step 11 consumes:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`
- Step 11 expected source/access pending:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname` (name translation path)
  - Databricks mapping for `Dictionary.Ext_TradeFund` (copy-fund enrichment path)
- Step 11 activation remains gated until Step 9 reg-change customer gates are cleared and the two pending mappings above are confirmed.
- Step 11 activation also requires approved ReplaceChar parity validation before executable output SQL is enabled.
- Step 11 does not consume `MIFID2_Failed_TRAX` and does not apply excluded-CID filtering (per `SP_MIFID2_RegChange_Customer` logic).
- Step 11 preserves SQL Server no-concat behavior:
  - countries (`67,95,102,126,164,191`) drive `NotAllowedCONCAT`
  - non-LEI `PIN_LEI` remains country-prefix concatenated (no Step 10-style no-concat PIN suppression).

Step 12 note (`MIFID2_Report` / `MIFID2_ME_Report` / `MIFID2_Removed_OP_Partials`):
- Step 12B1 target objects are:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`
- Step 12 consumes confirmed-but-gated lineage objects:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`
- Step 12B2 (intermediate population templates) additionally references:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext`
  - `main.regtech.gold_regtech_reg_instruments_scd`
  - `main.regtech.gold_regtech_reg_instruments_full_description`
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion` (if available and report-date covered)
- Step 12 expected source/access pending mappings remain gated:
  - `bi_output_regtechops_reg_ext_trade_getinstrument`
  - `bi_output_regtechops_reg_ext_trade_instrumentmetadata`
  - `bi_output_regtechops_reg_ext_dictionarycurrency`
  - `bi_output_regtechops_reg_ext_dictionarycurrencytype`
  - `bi_output_regtechops_reg_ext_historysplitratio`
  - `bi_output_regtechops_reg_regulationinoutdailydata` usage confirmation
  - `MIFID2_Instruments_To_Exclude` mapped equivalent
  - `Dictionary.Ext_TradeFund` mapped equivalent for mirror/copy-fund enrichment in intermediate population
- Futures metadata must be treated as expected mapping, not unknown:
  - `Trade.FuturesMetaData` -> `main.trading.bronze_etoro_trade_futuresmetadata`
  - required-column profiling is still pending for `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`.
  - boundary rule: FuturesMetaData is deferred to Step 12B3 final branch projections and is not a Step 12B2 pre-branch dependency.
- Step 12 must keep `UpdateDate` nullable for `MIFID2_Report` and `MIFID2_ME_Report` (no default invention), and must use explicit insert column lists for `MIFID2_Removed_OP_Partials`.
- Step 12B2 SQL artifacts are gated templates only:
  - `databricks/sql/08_outputs/04_mifid2_report_position_population.sql`
  - `databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql`

Step 12B3 note (final branch projections):

- Step 12B3 starts from Step 12B2 `#tradesFinal` equivalent:
  - `{{trades_final_source}}` or a validated materialized intermediate with equivalent contract.
- Step 12B3 final branch template artifacts:
  - `databricks/sql/08_outputs/05_mifid2_report_branch_projections.sql`
  - `databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql`
- Branch targets:
  - EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles -> `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - ME -> `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - removed partials finalization -> `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`
- FuturesMetaData remains Step 12B3-only and still profiling-gated:
  - expected mapping: `Trade.FuturesMetaData` -> `main.trading.bronze_etoro_trade_futuresmetadata`
  - required columns pending confirmation: `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`
- Futures validation rule in Step 12B3:
  - futures candidate rows must be identified from pre-output metadata (`IsFuture = 1`) via `{{report_metadata_source}}` / `{{trades_final_source}}` enrichment, not from output-populated futures fields.
- InstrumentClassification/CFI mapping rule in Step 12B3:
  - exact `SP_MIFID_Report` branch-specific mappings are still a hard gate.
  - simplified fallback logic is intentionally removed until exact branch mappings are ported.
- Category-specific instrument coverage rule in Step 12B3 validation:
  - real stock/ETF rows require ISIN.
  - futures rows require FuturesMetaData (`CFICode`, `ExpirationDateTime`, `Multiplier`) coverage.
  - non-real, non-future CFD CFI checks remain gated until exact branch-specific mapping is finalized.
- Exclusion parity in Step 12B3 final branch logic requires:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids` (UK branch)
  - `{{isin_for_instrumentid_341_source}}` (normalized logical columns required: `InstrumentID`, `OverrideISIN`, optional effective/report date)
  - `MIFID2_Instruments_To_Exclude` mapped equivalent (still unresolved)

Step 13 note (`MIFID2_ETORO_Report`):

- Step 13 target object is:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- Legacy `dbo.ASIC_Transactions` is intentionally replaced by Step 8 ASIC2 compatibility objects:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- Required 11-field compatibility contract consumed by ETORO:
  - `DateID`, `ReportDate`, `CID`, `PositionID`, `InstrumentID`, `OpenORClose`, `IsBuy`, `OpenTime`, `Volume`, `OpenPrice`, `RegChange`
- ETORO metadata/enrichment dependencies remain profiling-gated:
  - `main.regtech.gold_regtech_reg_instruments_scd`
  - `main.regtech.gold_regtech_reg_instruments_full_description`
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`
- Exclusion mappings reused for ETORO:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
- Step 13 conditional mapping rule:
  - `Reg_DWH_StaticPosition` remains conditional/non-blocking unless fallback impact is proven for consumed fields.
- UPI governance rule:
  - EMIR Refit UPI remains out of direct ETORO dependency scope unless profiling proves impact on the 11 consumed fields.

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
