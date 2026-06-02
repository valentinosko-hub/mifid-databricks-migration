# MiFID Source Profiling Results

This document integrates the latest MiFID source profiling run captured in `MiFID_Source_Profiling (1).csv` and the static-table recreation update for RegTech reference objects in `main.regtech_ops_stg`.

Profiling scope:
- Read-only source visibility and access classification for phase-1 migration dependencies.
- No SQL execution, table creation, or business-logic changes are performed by this documentation update.

Status taxonomy used in this document:
- Confirmed accessible
- Fallback/reference only
- No schema access
- No catalog access
- Storage/data scan failure
- Table not found
- Migration-produced object, not raw source
- Candidate source still needs certification
- Static reference resolved with explicit external LOCATION

## Profiling summary by status

### Confirmed accessible

| Databricks object | SQL Server / logical lineage | Migration use | Next step |
| --- | --- | --- | --- |
| `main.general.bronze_etoro_history_backofficecustomer` | `History.BackOfficeCustomer` | Step 8/9 customer enrichment, ASIC2 customer profile | Required-column contract validation per consumer module |
| `main.bi_db.bronze_etoro_trade_positionforexternaluse` | `Trade.PositionForExternalUse` | Step 8/9 position staging | Required-column and date-window parity validation |
| `main.trading.bronze_etoro_history_position_datafactory` | `History.PositionForExternalUse`, `History.Position` | Step 6/8/9 position and movement inputs | Required-column and window parity validation |
| `main.trading.bronze_etoro_history_positionchangelog` | `History.PositionChangeLog` | Step 9 / ASIC2 change-log staging | Event continuity and filter parity validation |
| `main.trading.bronze_etoro_history_mirror` | `History.Mirror` | Step 9 mirror staging | Mirror-window and CopyFund parity validation |
| `main.dealing.bronze_candles_candles_t_pricecandle60min` | `Reg_Ext_T_PriceCandle60Min` source | Step 5B1 price candle staging | Required-column contract validation (`InstrumentID`, `BidLast`, `AskLast`, `DateFrom`) |
| `main.dealing.bronze_pricelog_history_currencypricemaxdate` | `History.CurrencyPriceMaxDate` / `Reg_Ext_DailyMaxPrices` | Step 5B1 daily max prices | Required-column parity validation |
| `main.dealing.bronze_pricelog_history_splitratio` | `History.SplitRatio` / `Reg_Ext_HistorySplitRatio` | Step 5B2/12 split logic | Filter and split-ratio parity validation |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | `Reg_Ext_CurrencyPriceMaxDateWithSplit` candidate | Step 5B1/6/12 split-price logic | Candidate comparison vs blocked `dwh_daily_process` source |
| `main.regtech.gold_regtech_reg_instruments_scd` | `Reg_Instruments_SCD` | Instrument coverage across modules | Report-date validity-window validation |
| `main.regtech.gold_regtech_reg_instruments_full_description` | `Reg_Instruments_Full_Description` | Instrument enrichment | Latest-description coverage validation |
| `main.trading.bronze_etoro_trade_futuresmetadata` | `Trade.FuturesMetaData` | Step 12B3 futures enrichment | Required-column certification (`InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`) |
| `main.trading.bronze_etoro_trade_getinstrument` | `Trade.GetInstrument` | `Reg_Ext_Trade_GetInstrument` | Staging required-column contract validation |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | `Trade.InstrumentMetaData` | `Reg_Ext_Trade_InstrumentMetaData`, special-char conversion feeder | Staging required-column contract validation |
| `main.general.bronze_etoro_dictionary_currency` | `Dictionary.Currency` | `Reg_Ext_DictionaryCurrency` | Staging required-column and cast parity validation |
| `main.general.bronze_etoro_dictionary_currencytype` | `Dictionary.CurrencyType` | `Reg_Ext_DictionaryCurrencyType` | Staging required-column contract validation |
| `main.regtech.gold_regtech_reg_migrationinout_population` | `Reg_MigrationInOut_Population` | Step 6/9 migration population | Snapshot/materialization policy validation |
| `main.regtech.gold_regtech_reg_regulationinoutdailydata` | `Reg_RegulationInOutDailyData` | downstream reg-in/out consumers | Output-column contract validation |
| `main.dealing.bronze_etoro_hedge_executionlog` | `Hedge.ExecutionLog` | Step 5B2/9/14 hedge staging | Package filter and required-column validation |
| `main.dealing.bronze_etoro_hedge_hbcexecutionlog` | `Hedge.HBCExecutionLog` | Step 5B2/14 hedge staging | Success-filter and required-column validation |
| `main.dealing.bronze_etoro_hedge_hbcorderlog` | `Hedge.HBCOrderLog` | Step 5B2/14 hedge staging | Date-window and required-column validation |
| `main.trading.bronze_etoro_trade_liquidityaccounts` | `Trade.LiquidityAccounts` | Step 7 liquidity staging / SCD | Required-column validation; sensitive columns remain excluded |
| `main.trading.bronze_etoro_trade_liquidityproviders` | `Trade.LiquidityProviders` | Step 7 liquidity staging | Provider coverage validation |
| `main.bi_db.bronze_etoro_trade_liquidityprovidertype` | `Trade.LiquidityProviderType` | Step 7 liquidity staging | Provider-type coverage validation |
| `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei` | LEI mapping sheet | Step 7/14 LEI enrichment | LEI completeness validation |
| `main.general.gold_ednf_coretrades` | Synapse EDNF core trades | Step 14 EDNF enrichment | Join coverage validation |
| `main.general.gold_ib_u1059976_open_positions_all` | Synapse IB open positions | Step 14 IB enrichment | Join coverage validation |
| `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341` | InstrumentID 341 override | Step 12B3 override adapter | Required-column contract validation |
| `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments` | excluded instruments | report exclusion logic | Report-scoped semantics validation |
| `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids` | excluded position IDs | report exclusion logic | Report-scoped semantics validation |
| `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids` | excluded CIDs | customer/report exclusion logic | Exclusion coverage validation |

### Static reference resolved with explicit external LOCATION

These are RegTech static/reference tables in `main.regtech_ops_stg`, not raw DE source tables. They were previously classified as missing/table-not-found and are now recreated as external Delta tables with fixed LOCATION under:

`abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/`

| Databricks object | Classification | LOCATION | Migration use |
| --- | --- | --- | --- |
| `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts` | Static reference resolved with explicit external LOCATION | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dbo_internal_accounts` | Customer/NPD TRAX internal-account and LEI logic |
| `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` | Static reference resolved with explicit external LOCATION | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dictionary_ext_specialchar` | ReplaceChar and special-char conversion |
| `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro` | Static reference resolved with explicit external LOCATION | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/ed_f_to_istrument_id_e_toro` | EDNF-to-InstrumentID mapping for ETORO/Hedge enrichment |

### Storage/data scan failure

| Databricks object | SQL Server / logical lineage | Impact | Required action |
| --- | --- | --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | `History.CurrencyPrice_Active` / `Reg_CurrencyPrice_Ext` candidate | Step 5B1 `Reg_CurrencyPrice_Ext` remains gated | DE/Data Platform must resolve storage issue or certify an alternative source |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | `Hedge.HedgeServerToLiquidityAccount` | Step 7 hedge liquidity mapping and Step 14 hedge activation remain gated | DE/Data Platform must resolve storage issue before hedge SCD activation |

### No schema access

| Databricks object | SQL Server / logical lineage | Impact | Required action |
| --- | --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | unmasked `Customer.Customer` | Customer outputs and NPD_TRAX customer-dependent logic remain gated | Grant schema access or confirm business-approved masked/alternative source |
| `main.pii_data.bronze_etoro_history_customer` | unmasked `History.Customer` | Customer as-of/history enrichment remains gated | Grant schema access or confirm business-approved masked/alternative source |

### No catalog access

| Databricks object | SQL Server / logical lineage | Impact | Required action |
| --- | --- | --- | --- |
| `dwh_daily_process.daily_snapshot.etoro_history_customer` | fallback/history customer candidate | Cannot profile fallback until catalog access is granted | Grant `USE CATALOG dwh_daily_process` or provide certified alternative |
| `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` | `Reg_Ext_CurrencyPriceMaxDateWithSplit` candidate | Cannot compare against primary candidate until catalog access is granted | Grant `USE CATALOG dwh_daily_process` or certify `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` |

### Candidate source still needs certification

| Databricks object | Notes |
| --- | --- |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | Accessible, but still requires candidate-comparison certification against blocked `dwh_daily_process` source before final split-price source selection |
| `main.trading.bronze_etoro_trade_futuresmetadata` | Accessible, but Step 12B3 still requires required-column certification before futures activation |
| `main.trading.bronze_etoro_trade_getinstrument` | Accessible; staging required-column contract still pending |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | Accessible; staging required-column contract still pending |
| `main.general.bronze_etoro_dictionary_currency` | Accessible; staging required-column contract still pending |
| `main.general.bronze_etoro_dictionary_currencytype` | Accessible; staging required-column contract still pending |

## Gate impact summary

### Gates improved by this profiling pass

- Static reference availability for internal accounts, special-char dictionary, and EDNF mapping tables.
- Source visibility for position, mirror, changelog, hedge execution, liquidity provider, instrument dictionary, futures metadata, migration gold, split-ratio, price-candle, and SharePoint exclusion sources.
- Mapping confidence for `Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Dictionary.Currency`, `Dictionary.CurrencyType`, and `FuturesMetaData`.

### Gates that remain open

- `Reg_CurrencyPrice_Ext` activation blocked by storage failure on `main.trading.bronze_etoro_trade_currencyprice`.
- Step 7 hedge-server mapping blocked by storage failure on `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`.
- Customer and NPD_TRAX customer-dependent paths blocked by no schema access on `main.pii_data` customer tables.
- Split-price candidate comparison blocked by no catalog access on `dwh_daily_process` objects.
- `Dictionary.Ext_TradeFund`, `Reg_Ext_CustomerLatinName`, PIN/UserAPI, RecordID, transaction-reference parity, and module activation gates remain unchanged by this profiling pass.

## Reference-only policy

- Old Databricks attempt artifacts remain reference-only discovery material.
- NOC documents remain reference-only and are not implementation authority.
- Delivery/SFTP/TRAX upload/response handling remains out of phase-1 scope.

## Source artifact

- Profiling input: `MiFID_Source_Profiling (1).csv`
- Integration date: documentation update only; no runtime SQL executed from this step.
