# Source to Databricks Mapping

## Core RegTech / instrument mappings

```text
dbo.Reg_Instruments_SCD
-> main.regtech.gold_regtech_reg_instruments_scd

 dbo.Reg_Instruments_Full_Description
-> main.regtech.gold_regtech_reg_instruments_full_description

FIRDS/FCA FIRDS gold tables are confirmed certified sources.
```

## Regulation in/out

```text
dbo.Reg_MigrationInOut_Population
-> main.regtech.gold_regtech_reg_migrationinout_population

dbo.Reg_RegulationInOutDailyData
-> main.regtech.gold_regtech_reg_regulationinoutdailydata
```

## Synapse / LP sources

```text
[SYNAPSE-DWH-PROD].[sql_dp_prod_we].[Dealing_staging].[LP_EdnF_CoreTrades]
-> main.general.gold_ednf_coretrades

[SYNAPSE-DWH-PROD].[sql_dp_prod_we].[Dealing_staging].[LP_IB_U1059976_Open_Positions_All]
-> main.general.gold_ib_u1059976_open_positions_all
```

## Static or staging reference mappings

```text
google_sheets.reg_liquidityaccountid_to_lei
-> main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei

regtech.si_reporting_configurations
-> main.bi_db.bronze_fivetran_regtech_si_reporting_configurations

ThirdParty_Fivetran.Fivetran.google_sheets.ed_n_f_to_istrumentid_etoro
-> main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro

dbo.InternalAccounts
-> main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts

Dictionary.Ext_SpecialChar
-> main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar
```

## Customer / dictionary sources

```text
Dictionary.Country
-> main.general.bronze_etoro_dictionary_country

Dictionary.Label
-> main.general.bronze_etoro_dictionary_label

Customer.Customer
-> main.general.bronze_etoro_customer_customer

History.Customer
-> main.pii_data.bronze_etoro_history_customer

Customer.ExtendedUserField
-> main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield

Dictionary.ExtendedUserValueType
-> main.compliance.bronze_userapidb_dictionary_extendeduservaluetype
```

## Position / mirror sources

```text
Trade.Position
-> main.trading.silver_etoro_trade_position

History.Position
-> main.trading.bronze_etoro_history_position_datafactory

History.Mirror
-> main.trading.bronze_etoro_history_mirror

History.PositionChangeLog
-> main.trading.bronze_etoro_history_positionchangelog

Trade.PositionForExternalUse
-> main.bi_db.bronze_etoro_trade_positionforexternaluse

History.PositionForExternalUse
-> main.trading.bronze_etoro_history_position_datafactory
```

## Liquidity / hedge sources

```text
Trade.LiquidityAccounts
-> main.trading.bronze_etoro_trade_liquidityaccounts

Trade.LiquidityProviders
-> main.trading.bronze_etoro_trade_liquidityproviders

Trade.LiquidityProviderType
-> main.bi_db.bronze_etoro_trade_liquidityprovidertype

Hedge.HedgeServerToLiquidityAccount
-> main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount

Hedge.ExecutionLog
-> main.dealing.bronze_etoro_hedge_executionlog

Hedge.HBCExecutionLog
-> main.dealing.bronze_etoro_hedge_hbcexecutionlog

Hedge.HBCOrderLog
-> main.dealing.bronze_etoro_hedge_hbcorderlog
```

## Pricing / candle / split candidates

```text
Reg_CurrencyPrice_Ext source
-> main.trading.bronze_etoro_trade_currencyprice

Reg_Ext_T_PriceCandle60Min source
-> main.dealing.bronze_candles_candles_t_pricecandle60min

History.CurrencyPriceMaxDate source
-> main.dealing.bronze_pricelog_history_currencypricemaxdate

Reg_Ext_CurrencyPriceMaxDateWithSplit candidate
-> dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit

Reg_Ext_CurrencyPriceMaxDateWithSplit candidate alternative
-> main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit

History.SplitRatio
-> main.dealing.bronze_pricelog_history_splitratio
```

## Notes
- For duplicate/candidate mappings, Cursor must validate required columns and SSIS package logic before choosing.
- Dynamic SSIS-created extracts should be refreshed by Databricks workflow steps, not manually uploaded as static tables.
