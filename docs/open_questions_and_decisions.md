# Phase 1C - Open Questions and Decisions

## Fixed decisions

The following decisions are fixed for Phase 1:

- Current scope is Databricks table/report generation only.
- CSV export, file delivery, 7z, SFTP, TRAX/Cappitech upload, and response handling are out of scope for phase 1.
- Full historical backfill is out of scope for phase 1.
- Historical data may be seeded or rebuilt only if needed for validation.
- Production deployment into `main.regtech` is out of scope for phase 1.
- ASIC2 is the source of truth for MiFID ETORO, not legacy ASIC.
- FIRDS gold RegTech tables are certified sources.
- All persistent objects in `main.regtech_ops_stg` must start with `bi_output_regtechops_`.
- NOC documents are reference-only because the NOC monitor was not implemented.
- Old Databricks attempt is reference-only.

## Open questions to keep documented (do not guess)

These remain open and should be explicitly tracked:

1. Historical seed strategy for `MIFID2_NPD_TRAX` for parity windows that require older data.
2. Historical seed strategy for `ASIC2_Transactions` for parity windows that require older data.
3. Final source choice for `Reg_Ext_CurrencyPriceMaxDateWithSplit`:
   - `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` (candidate)
   - `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (candidate alternative)
4. Exact package-parity rules (filters/columns/date handling) for:
   - `Reg_CurrencyPrice_Ext`
   - `Reg_Ext_CurrencyPriceMaxDateWithSplit`
   - `Reg_Ext_DailyMaxPrices`
   - `Reg_Ext_T_PriceCandle60Min`
5. `MIFID2_Hedge_Report` identity strategy for `RecordID` (`IDENTITY(100000001,1)` in SQL Server).
6. Final validation of ASIC2 compatibility mapping for MiFID ETORO, especially `CDE_Execution_timestamp -> OpenTime`.
7. Whether any phase-2 delivery scope is brought forward (only if scope is explicitly changed later).

## Conditional decisions already documented

- `Reg_DWH_StaticPosition` is treated as conditional/legacy and not a phase-1 blocker.
- EMIR UPI is not required for MiFID unless ASIC2 subset validation proves impact on fields consumed by `MIFID2_ETORO_Report`.
