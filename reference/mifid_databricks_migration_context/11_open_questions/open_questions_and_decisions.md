# Open Questions and Decisions

## 1. Currency / price / split source choices
Cursor must validate exact logic from `Pre_Regulation_Ext.dtsx` before creating these staging objects:

- `Reg_CurrencyPrice_Ext`
- `Reg_Ext_CurrencyPriceMaxDateWithSplit`
- `Reg_Ext_DailyMaxPrices`
- `Reg_Ext_T_PriceCandle60Min`

`Reg_CurrencyPrice_Ext` is likely an SSIS-created staging extract from `main.trading.bronze_etoro_trade_currencyprice`, not a standalone source. Dynamic extracts should be recreated by Databricks workflow steps after SSIS logic is inspected.

## 2. Historical strategy
Do not block implementation on full historical backfill.

Recreate history only if needed for validation. Data Engineering may load historical data later after tables exist.

Tables with historical dependency:
- `MIFID2_NPD_TRAX`
- `ASIC2_Transactions`

## 3. Current scope
Current phase is Databricks table/report generation only.

Out of scope:
- CSV export
- 7z compression
- SFTP delivery
- Cappitech upload
- TRAX upload
- TRAX response processing
- production deployment into `main.regtech`

## 4. Reg_DWH_StaticPosition
Investigated and not a current blocker.

It appears stale/static, with latest `OpenOccurred`/`CloseOccurred` around 2022. Recent `ASIC2_Transactions` did not join to it by `PositionID` or `OriginalPositionID` in the checked 60-day window.

Treat as conditional legacy ASIC2 dependency only.

## 5. UPI / EMIR_Refit_UPI
Not a direct MiFID dependency.

Do not require for MiFID unless ASIC2 subset logic proves it affects fields consumed by `MIFID2_ETORO_Report`:
- ReportDate
- DateID
- CID
- PositionID
- InstrumentID
- RegChange
- OpenORClose
- IsBuy
- OpenTime
- Quantity / Volume
- OpenPrice
