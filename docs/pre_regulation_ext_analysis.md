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

## Step 5B2 - non-price Pre_Regulation_Ext staging

Step 5B2 covers the remaining non-price staging objects produced or refreshed by `Pre_Regulation_Ext.dtsx`. The Step 5B1 price/currency/split objects remain excluded from this section.

Materialization policy for Step 5B2 remains the same as Step 5B1: SSIS-created staging outputs should be materialized as prefixed Delta staging tables in `main.regtech_ops_stg`, not implemented as simple views, because the package uses truncate/reload or delete-by-run-date patterns and downstream consumers expect stable run snapshots.

### Step 5B2 object analysis

| SQL Server staging object | Required for MiFID phase 1 | SSIS producer | Source tables / logic | Databricks source mapping status | Required output columns | Target object | Materialize | Required validation | Unresolved issue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Reg_Ext_MigrationInOut_STG` | Yes | `RegInRegOut` sequence: `TRUNCATE Reg_Ext_MigrationInOut_STG`, SQL task `RegInRegOut TranData`, data flow destination `Reg_RegulationInOutDailyData STG` | `##TRAN_DATA` built from `History.BackOfficeCustomer`, `Customer.Customer`, `Trade.PositionForExternalUse`, `History.PositionForExternalUse` and regulation migration logic for `User::StartDate` | Expected source / access pending for the raw inputs; not a single raw Databricks replacement table | `CID`, `RegulationID`, `PrevRegulationID`, `InstrumentID`, `Migration_Occurred`, `TransactionID`, `IsBuy`, `InitForexPriceRateID`, `EndForexPriceRateID`, `ExecutionPrice`, `Quntity`, `ExecutionTime`, `Lei`, `FirstName`, `LastName` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg` | Yes, truncate/reload run snapshot | row count, run-date consistency, null checks for `CID`/`InstrumentID`/dates, duplicate transaction checks, source-to-stage count from reconstructed `##TRAN_DATA` | Raw source schema/access and faithful temp-table reconstruction pending |
| `Reg_MigrationInOut_Population` | Yes | `RegInRegOut` sequence: delete by `RunDate`, data flow `Data Flow Task 1` from `##REG_MIGRATION` | `##REG_MIGRATION` built from `History.BackOfficeCustomer` regulation changes on `User::StartDate` | Confirmed gold mapping exists: `main.regtech.gold_regtech_reg_migrationinout_population`; materialization policy still gated | `RunDate`, `CID`, `Lei`, `RegulationID`, `Migration_Occurred`, `PrevRegulationID` | `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` | Yes, delete-by-run-date or replace run-date snapshot | row-count parity vs gold and SQL Server, `RunDate` freshness, duplicate `RunDate`/`CID`, null keys | Decide whether to materialize from certified gold or recreate SSIS logic |
| `Reg_RegulationInOutDailyData` | Yes | `RegInRegOut` sequence: delete by `ReportDate`, then `EXEC SP_RegInRegOutPopulation` | Stored procedure output derived from migration/in-out staging | Confirmed gold mapping exists: `main.regtech.gold_regtech_reg_regulationinoutdailydata`; materialization policy still gated | Procedure output columns are not visible in DTSX; schema must be profiled from gold and SQL Server procedure/DDL before implementation | `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata` | Yes, delete-by-report-date or replace report-date snapshot | row-count parity vs gold and SQL Server, `ReportDate` freshness, duplicate business keys, required-column parity | Decide gold snapshot vs recreated stored-procedure logic; output-column contract pending |
| `Reg_Ext_CustomerLatinName` | Yes | `Sequence Reg_Ext_CustomerLatinName`: truncate + data flow `GET Reg_Ext_CustomerLatinName` | `Customer.CustomerLatinName` full extract | Expected source / access pending, likely customer-domain bronze source; do not assume columns until profiling | `CID`, `FirstName`, `LastName`, `ModifiedDate`, `Address`, `City`, `MiddleName` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname` | Yes, full snapshot | row counts, required columns, duplicate `CID`, null name/key checks, source-to-stage count | Databricks source table and schema must be confirmed |
| `Reg_Ext_HistorySplitRatio` | Yes | `Sequence HistorySplitRatio`: truncate + data flow `Laod SplitRatio` | `History.SplitRatio` filtered to `IsCompletedOpenPositions = 1` | Candidate/expected source: `main.dealing.bronze_pricelog_history_splitratio`; schema validation pending | `InstrumentID`, `MinDate`, `MaxDate`, `AmountRatio`, `IsCompletedOpenPositions`, `AmountRatioUnAdjusted`, `PriceRatio`, `PriceRatioUnAdjusted` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio` | Yes, filtered full snapshot | row counts, required columns, duplicate `InstrumentID`/date ranges, split-ratio null checks, `IsCompletedOpenPositions = 1` filter parity | Required-column and filter parity pending |
| `Reg_Ext_Trade_GetInstrument` | Yes | `Sequence Reg_Ext_Trade_GetInstrument`: truncate + data flow `GET Reg_Ext_Trade_GetInstrument` | `Trade.GetInstrument` full extract | Expected source / access pending; exact bronze/gold table not confirmed in docs | `InstrumentID`, `BuyCurrencyID`, `SellCurrencyID`, `InstrumentTypeID`, `Name`, `TradeRange`, `DollarRatio`, `Passport`, `PipDifferenceThreshold`, `IsMajor`, `Industry`, `ExchangeID` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument` | Yes, full snapshot | row counts, required columns, duplicate `InstrumentID`, null key/currency/type checks | Databricks source table and schema must be confirmed |
| `Reg_Ext_Trade_InstrumentMetaData` | Yes | `Sequence Reg_Ext_Trade_InsertedInstrument`: truncate + data flow `GET Reg_Ext_Trade_InstrumentMetaData` | `Trade.InstrumentMetaData` full extract | Expected source / access pending; certified instrument gold may support shaping but SSIS source contract must be profiled | `InstrumentID`, `InstrumentDisplayName`, `InstrumentTypeImage`, `Ticker`, `ChartTicker`, `InstrumentImageSmall`, `InstrumentImageMedium`, `InstrumentImageLarge`, `Exchange`, `Industry`, `CompanyInfo`, `DailyRolloverFee`, `WeekendRolloverFee`, `ContractRolloverFee`, `InstrumentVisible`, `Symbol`, `CandleTimeframeGroup`, `SymbolFull`, `Tradable`, `ExchangeID`, `StocksIndustryID`, `ISINCode`, `ISINCountryCode`, `ContractExpire`, `InstrumentTypeSubCategoryID`, `InstrumentTypeID`, `PriceSourceID`, `Cusip`, `CreateDate`, `UnderlyingExchangeID`, `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata` | Yes, full snapshot | row counts, required columns, duplicate `InstrumentID`, null metadata keys, source-to-stage count | Hard prerequisite for `InstrumentMetaData_SpecialChar_Conversion`; source schema/access pending |
| `Reg_Ext_DictionaryCurrency` | Yes | `Sequence DictionaryCurrency`: truncate + data flow `GET DictionaryCurrency` | `Dictionary.Currency` full extract; `EEAStockExchange` cast to int | Expected source / access pending; likely dictionary-domain bronze source | `CurrencyID`, `CurrencyTypeID`, `Name`, `Abbreviation`, `Mask`, `EEAStockExchange`, `ISINCode`, `CurrencySymbol`, `InterestRateID` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency` | Yes, full dictionary snapshot | row counts, required columns, duplicate `CurrencyID`, null abbreviation/type checks | Exact Databricks source table and cast parity pending |
| `Reg_Ext_DictionaryCurrencyType` | Yes | `Sequence Hedge DictionaryCurrencyType`: truncate + data flow `GET DictionaryCurrencyType` | `Dictionary.CurrencyType` full extract | Expected source / access pending; likely dictionary-domain bronze source | `CurrencyTypeID`, `Name`, `MinPositionAmountAbsolute`, `Priority`, `PricesBy`, `SLTPApproachPercent`, `ImageUrl` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype` | Yes, full dictionary snapshot | row counts, required columns, duplicate `CurrencyTypeID`, null `Name` checks | Exact Databricks source table and schema pending |
| `Reg_Ext_HedgeExecutionLog` | Yes, for hedge report path | `Sequence HedgeExecutionLog`: truncate + daily data flow `GET HedgeExecutionLog` | `Hedge.ExecutionLog` where `LogTime >= StartDate` and `< StartDate + 1 day`; casts `IsBuy`/`Success` to int | Confirmed raw source: `main.dealing.bronze_etoro_hedge_executionlog`; package filter/column parity pending | `LogTime`, `HedgeServerID`, `LiquidityAccountID`, `InstrumentID`, `OrderID`, `ParentOrderID`, `Units`, `IsBuy`, `OrderState`, `ProviderOrderID`, `SendTime`, `ProviderExecID`, `ExecutionTime`, `ExecutionRate`, `FailID`, `FailReason`, `Success`, `ProviderPartyIds`, `ReceivedTime`, `ProviderUnits`, `RateIDAtSent`, `EMSOrderID` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog` | Yes, daily run snapshot | run-window row counts, required columns, duplicate order/execution checks, null key/date checks, cast parity | Source access/schema and package filter parity pending |
| `Reg_Ext_HedgeHBCExecutionLog` | Yes, for hedge report path | `Sequence HedgeHBCExecutionLog`: truncate + data flow `Load Reg_Ext_HedgeHBCExecutionLog` | `Hedge.HBCExecutionLog` where `IsSuccess = 1`, `StartTime >= RunDate`, `EndTime < RunDate + 1 day` | Confirmed raw source: `main.dealing.bronze_etoro_hedge_hbcexecutionlog`; package filter/column parity pending | `ExecutionID`, `HedgeServerID`, `LiquidityAccountID`, `InstrumentID`, `IsBuy`, `IsSuccess`, `RequestAmountInLots`, `ExecutionAmountInLots`, `ExecutionRate`, `StartTime`, `EndTime`, `FailReason`, `LPExecutionRate`, `MarketRateIDAtExecutionEnd`, `ShouldWaitForConfirm`, `InitialRate`, `IsCancelExecution`, `CancelledExecutionID` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog` | Yes, daily successful-execution snapshot | run-window row counts, required columns, duplicate `ExecutionID`, null key/date checks, `IsSuccess = 1` filter parity | Source schema and filter parity pending |
| `Reg_Ext_HedgeHBCOrderLog` | Yes, for hedge report path | `Sequence Hedge HBCOrderLog`: truncate + data flow `GET HedgeHBCOrderLog` | `Hedge.HBCOrderLog` where `EndTime >= StartDate` and `< StartDate + 1 day`; casts `IsBuy`/`IsCancelOrder` to int | Confirmed raw source: `main.dealing.bronze_etoro_hedge_hbcorderlog`; package filter/column parity pending | `OrderID`, `ExecutionID`, `HedgeID`, `IsBuy`, `IsCancelOrder`, `OrderState`, `RequestAmountInLots`, `ExecutionAmountInLots`, `ExecutionRate`, `StartTime`, `EndTime`, `FailReason` | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog` | Yes, daily run snapshot | run-window row counts, required columns, duplicate `OrderID`/`ExecutionID`, null key/date checks, cast parity | Source schema and filter parity pending |
| `Reg_Instruments_ext` | Yes | `Sequence Container`: truncate `Reg_Instruments_ext`, data flow `Reg_Instruments_ext`, then `EXEC SP_Reg_Instruments_SCD` | SQL Server extract joins `Trade.InstrumentMetaData`, `Trade.GetInstrument`, `Trade.ProviderToInstrument`, and `Trade.InstrumentGroups` for `IsFuture` | Preferred approach: shape from certified `main.regtech.gold_regtech_reg_instruments_scd` and `main.regtech.gold_regtech_reg_instruments_full_description`; parity to SSIS raw join must be validated | `InstrumentID`, `InstrumentTypeID`, `InstrumentDisplayName`, `Symbol`, `SymbolFull`, `Tradable`, `ISINCode`, `InstrumentVisible`, `BuyCurrencyID`, `SellCurrencyID`, `ContractExpire`, `ExchangeID`, `VisibleInternallyOnly`, `UpdateDate`, `IsFuture` | `main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext` | Yes, full instrument snapshot | row counts, required columns, duplicate `InstrumentID`, FIRDS/gold coverage, `IsFuture` and visibility parity | Gold/FIRDS replacement approach must be documented and validated against SSIS output contract |

### Step 5B2 safe-to-implement status

No Step 5B2 object is ready for active `CREATE OR REPLACE TABLE` staging SQL until source profiling confirms access and required columns. The first implementation artifact should therefore be source profiling and gated staging notes, not executable transformations.

Objects closest to safe implementation after profiling:

- `Reg_Ext_HistorySplitRatio`, because a candidate Databricks source is already documented.
- `Reg_Ext_HedgeExecutionLog`, `Reg_Ext_HedgeHBCExecutionLog`, and `Reg_Ext_HedgeHBCOrderLog`, because raw hedge source mappings are confirmed, subject to date-filter and required-column validation.
- `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData`, only if the phase-1 decision is to materialize prefixed snapshots from certified gold and row-count parity is accepted.

Objects that must remain gated pending schema/access validation:

- `Reg_Ext_MigrationInOut_STG`
- `Reg_Ext_CustomerLatinName`
- `Reg_Ext_Trade_GetInstrument`
- `Reg_Ext_Trade_InstrumentMetaData`
- `Reg_Ext_DictionaryCurrency`
- `Reg_Ext_DictionaryCurrencyType`
- `Reg_Instruments_ext`

### Documentation updates needed from Step 5B2

- Add missing dependency-matrix rows for `Reg_Ext_HedgeExecutionLog`, `Reg_Ext_HedgeHBCExecutionLog`, `Reg_Ext_HedgeHBCOrderLog`, and `Reg_Instruments_ext`.
- Expand mapping review to distinguish confirmed raw sources from expected/access-pending sources.
- Carry forward unresolved decisions for migration/in-out materialization, instrument-gold shaping, and dictionary/trade source access.

