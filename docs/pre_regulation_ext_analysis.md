# Step 5A/5B1 - Pre_Regulation_Ext Price/Currency/Split Analysis

This document narrows `Pre_Regulation_Ext.dtsx` to Step 5B1 only (price/currency/split staging).

## Scope for this step

Included objects:

- `Reg_CurrencyPrice_Ext`
- `Reg_Ext_DailyMaxPrices`
- `Reg_Ext_CurrencyPriceMaxDateWithSplit`
- `Reg_Ext_T_PriceCandle60Min`

Excluded in Step 5B1:

- migration-in/out staging (`Reg_MigrationInOut_Population`, `Reg_RegulationInOutDailyData`, related flows)
- customer/instrument/dictionary staging
- hedge extract staging
- any `MIFID2_ext_*` or final MiFID outputs

## Target Databricks staging objects

All targets are in `main.regtech_ops_stg` with the required prefix:

- `main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min`

## Materialization policy

For these package-created staging outputs, Step 5B1 uses materialized Delta table SQL (not views) to preserve SSIS-style truncate/reload run snapshots and stable downstream read behavior.

## Source mapping status by object

### 1) `Reg_CurrencyPrice_Ext`

- SSIS source: `History.CurrencyPrice_Active`
- Current Databricks candidate: `main.trading.bronze_etoro_trade_currencyprice`
- Required SSIS-selected column set is documented in:
  - `databricks/sql/03_pre_regulation_ext/01_price_currency_source_profiling.sql`
  - `databricks/sql/03_pre_regulation_ext/02_price_currency_staging.sql`
- Step 5B1 status: provisional staging SQL authored, but execution is blocked until column-parity profiling confirms the candidate shape.

### 2) `Reg_Ext_DailyMaxPrices`

- SSIS source: `History.CurrencyPriceMaxDate`
- Current Databricks candidate: `main.dealing.bronze_pricelog_history_currencypricemaxdate`
- Required SSIS-selected columns are documented in source profiling/staging SQL.
- Step 5B1 status: provisional staging SQL authored, but execution is blocked until required-column parity is confirmed.

### 3) `Reg_Ext_CurrencyPriceMaxDateWithSplit`

- SSIS source: `Candles.CurrencyPriceMaxDateWithSplit`
- Candidate mappings:
  - `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit`
  - `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`
- Step 5B1 status: candidate-comparison profiling SQL authored; final source selection remains unresolved, so final staging table creation is intentionally pending.

### 4) `Reg_Ext_T_PriceCandle60Min`

- SSIS source: `Candles.GetSpreadedPriceCandle60MinSplitted`
- Candidate mapping: `main.dealing.bronze_candles_candles_t_pricecandle60min`
- Required columns for implementation: `InstrumentID`, `BidLast`, `AskLast`, `DateFrom`
- Logic preserved in SQL:
  - `@EndDate = DATEADD(DAY, 1, report_date)`
  - `DateFrom < @EndDate`
  - `InstrumentID < 100000`
  - latest row per `InstrumentID` by `DateFrom DESC`
  - output shape: `InstrumentID`, `RateBid`, `RateAsk`, `DateFrom`
- Step 5B1 status: staging SQL authored; execution pending required-column confirmation.

## Date-window equivalence preserved

Step 5B1 parameter SQL keeps SSIS window semantics documented as:

- `Occurred >= DATEADD(HOUR, -1, CAST(@StartDate AS datetime))`
- `Occurred <= end of @StartDate day`

Databricks equivalent used in module SQL:

- `Occurred >= CAST(report_date AS TIMESTAMP) - INTERVAL 1 HOUR`
- `Occurred <= CAST(date_add(report_date, 1) AS TIMESTAMP)`

## Validation coverage authored for Step 5B1

`databricks/sql/03_pre_regulation_ext/03_price_currency_validation.sql` includes:

- row counts
- min/max dates and freshness checks
- required-column checks
- duplicate checks
- null checks for key fields
- source-to-stage count checks where practical
- candidate comparison checks for `Reg_Ext_CurrencyPriceMaxDateWithSplit`

## Remaining unresolved items before Step 5B1 execution

- Confirm that the `Reg_CurrencyPrice_Ext` candidate includes all SSIS-required columns.
- Confirm that the `Reg_Ext_DailyMaxPrices` candidate includes all SSIS-required columns.
- Select final source for `Reg_Ext_CurrencyPriceMaxDateWithSplit` using the comparison profiling outputs.
- Confirm required columns for `Reg_Ext_T_PriceCandle60Min` in runtime environment before execution.

