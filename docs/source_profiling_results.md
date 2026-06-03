# MiFID Source Profiling Results

This document captures the latest source-resolution and RegTech decision updates for phase-1 migration readiness.

Profiling scope:

- Read-only source visibility and source-contract documentation.
- Documentation update only (no SQL execution, no table creation, no workflow deployment).

Status taxonomy used in this document:

- Confirmed accessible
- Readable but not preferred
- Primary source selected
- Fallback/reference only
- No schema access
- Static reference resolved with explicit external LOCATION
- Temporary development fallback / manager-approved workaround

## 1) Active blocker simplification (current)

### Active access blockers (only remaining active blockers)

| Databricks object | Status | Impact |
| --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access | Final customer/NPD identity parity remains gated |
| `main.pii_data.bronze_etoro_history_customer` | No schema access | Final customer history/as-of parity remains gated |

### Temporary masked customer fallback (development-only)

| Databricks object | Status | Allowed use |
| --- | --- | --- |
| `main.general.bronze_etoro_customer_customer_masked` | Temporary development fallback / manager-approved workaround | Schema profiling, row-count checks, join-path testing, gated template development, non-production structural validation |
| `main.general.bronze_etoro_history_customer_masked` | Temporary development fallback / manager-approved workaround | Same as above for history/as-of paths |

Masked tables must not be treated as final regulatory parity sources.

Final parity remains gated for:

- `FirstName`, `LastName`, `BirthDate`, `PIN`, `PIN_Type`
- customer identity-change comparison
- `NonLatinOrEmptyName` detection
- final validation of `MIFID2_Customer`, `MIFID2_RegChange_Customer`, `MIFID2_Failed_TRAX`, `MIFID2_NPD_TRAX`

## 2) CurrencyPrice source update

### Primary source selected

Primary source for `History.CurrencyPrice`, `History.CurrencyPrice_Active`, and `Reg_CurrencyPrice_Ext`:

- `main.dealing.bronze_pricelog_history_currencyprice`

Required SSIS-selected columns are present:

- `CurrencyPriceID`
- `ProviderID`
- `InstrumentID`
- `Bid`
- `Ask`
- `ValidFrom`
- `ValidTo`
- `OccurredOnProvider`
- `Occurred`
- `PriceRateID`
- `ReceivedOnPriceServer`
- `LiquidityAccountID`
- `USDConversionRate`
- `MarketPriceRateID`
- `RateLastEx`
- `BidSpreaded`
- `AskSpreaded`
- `BidMarketPriceRateID`
- `AskMarketPriceRateID`
- `MarkupPips`
- `MarketReceivedTime`
- `SkewValueBid`
- `SkewValueAsk`
- `SkewID`
- `USDConversionRateBidSpreaded`
- `USDConversionRateAskSpreaded`
- `USDConversionPriceRateID`

Execution notes:

- Use report-date and one-hour lookback logic.
- Use partition filters `etr_y`, `etr_ym`, `etr_ymd` where applicable.
- Final execution still requires SQL Server baseline/date-window validation.

### Reclassified candidate

`main.trading.bronze_etoro_trade_currencyprice` is now:

- **Readable but not preferred** for `Reg_CurrencyPrice_Ext`.
- Not selected as the primary parity source because it does not expose the full SSIS-selected `History.CurrencyPrice_Active` shape.

## 3) CurrencyPriceMaxDateWithSplit source update

### Primary source selected

Primary source for `Candles.CurrencyPriceMaxDateWithSplit` / `Reg_Ext_CurrencyPriceMaxDateWithSplit`:

- `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`

Required columns are present:

- `PriceRateID`
- `ProviderID`
- `InstrumentID`
- `Occurred`
- `OccurredDate`
- `OccurredDateID`
- `isvalid`
- `MarkupPips`
- `AskSpreaded`
- `BidSpreaded`
- `RateLastEx`
- `SkewValueBid`
- `SkewValueAsk`
- `Ask`
- `Bid`

Partition columns:

- `etr_y`
- `etr_ym`
- `etr_ymd`

Status:

- Source identified.
- Required columns present.
- `dwh_daily_process` comparison is no longer an active blocker for this source decision.
- Final execution still requires date-window validation and SQL Server baseline comparison.

### Older candidates downgraded

Fallback/reference only:

- `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit`
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`

## 4) HedgeServerToLiquidityAccount source update

`main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` is reclassified to:

- **Confirmed accessible / readable**
- Required columns present:
  - `HedgeServerID`
  - `LiquidityAccountID`
  - `AltRatesLiquidityAccountID`
- No longer an active DE/Data Platform storage blocker

Remaining validation items (normal execution-phase checks):

- duplicate/key checks
- coverage checks
- liquidity SCD validation during execution

## 5) Historical seed strategy update (RegTech direction)

Approved strategy:

- Seed all historical data required for future reporting, retry logic, SCD validity, missed-trade back-reporting, identity continuity, and SQL Server baseline comparison.
- If a minimum safe historical window cannot be proven, seed all available history for that object.

Applies especially to:

- `MIFID2_NPD_TRAX`
- `MIFID2_Failed_TRAX`
- `MIFID2_Hedge_Report`
- `ASIC2_Transactions` and related ASIC2 history
- `Reg_LiquidtyAcount_SCD`
- `Reg_MigrationInOut_Population`
- `Reg_RegulationInOutDailyData`
- `Reg_Regulation_Movments_Positions`
- relevant instrument/FIRDS history where needed

Status: strategy approved; execution implementation still pending.

## 6) RegTech parity clarifications

### Hedge `RecordID`

- Functional role is confirmed: required for missed-trade back-reporting.
- Historical SQL Server `MIFID2_Hedge_Report.RecordID` values must be preserved exactly.
- Approved direction:
  - seed historical SQL Server RecordIDs,
  - continue future allocation from `MAX(SQL Server RecordID) + 1`,
  - use persistent Databricks RecordID registry/control-table mechanism (or equivalent),
  - reuse existing RecordIDs for already-known trades,
  - allocate new RecordIDs only for genuinely new/back-reported missed trades,
  - define/document natural business key for row identity across reruns.
- Status: design direction approved; implementation and validation pending.

### Hedge `TransactionReferenceNumber`

- Hard parity requirement: Databricks must match SQL Server/SSMS values exactly.
- Uniqueness-only behavior is not acceptable.
- Baseline comparison remains required.

### CFI / `InstrumentClassification`

- Hard parity requirement: exact SQL Server value matching is required.
- Simplified fallback classification is not acceptable for final regulatory parity.
- Baseline comparison remains required.

## 7) Static reference objects (resolved)

Static/reference tables in `main.regtech_ops_stg` remain resolved as external Delta with explicit LOCATION:

- `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`
- `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`
- `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`

## 8) Reference-only and scope boundaries

- Old Databricks attempt artifacts remain reference-only and are not implementation authority.
- NOC documents remain reference-only and are not implementation authority.
- Delivery/upload/response and production deployment remain out of scope in this phase.

## Source artifact

- Profiling input lineage: `MiFID_Source_Profiling (1).csv`
- Integration date: documentation/status update only (no runtime SQL executed)
