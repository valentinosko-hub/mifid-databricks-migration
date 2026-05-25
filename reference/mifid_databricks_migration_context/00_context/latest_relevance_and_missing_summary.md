# Latest relevance and missing summary

## Relevant files added in this filtered package

The latest batch included files that are directly useful for the current MiFID table-generation migration:

- Core MiFID stored procedures:
  - SP_MIFID_Customer.sql
  - SP_MIFID_RegChange_Customer.sql
  - SP_MIFID_Report.sql
  - SP_MIFID_ETORO_Report.sql
  - SP_MIFID_HedgeEU_Report.sql
  - SP_MIFID_HedgeUK_Report.sql
- Supporting procedures:
  - SP_RegInRegOutPopulation.sql
  - SP_Reg_Instruments_SCD.sql
- Current ASIC2 procedures needed to replace the legacy ASIC dependency in MiFID ETORO:
  - SP_ASIC2_TransactionsReport.sql
  - SP_ASIC2_PositionReport.sql
  - SP_ASIC2_PositionReport_Agg.sql
  - SP_ASIC2_Instrument_Automation.sql

Note: several uploaded files were named with `SP_ASIC_...`, but the procedure body is `SP_ASIC2_...`. They were renamed in this package to avoid confusion.

## Files intentionally not included / disregarded for current scope

The following uploaded files are not part of the current MiFID table-generation scope:

- US regulatory procedures:
  - SP_Reg_US_Customers.sql
  - [SP_Reg_US_NOrders].sql
  - [SP_Reg_US_ROrders].sql
  - [SP_Reg_US_Reconsile].sql
- ASIC2 collateral / hedge-specific procedures, unless future inspection proves they are needed by the MiFID-compatible ASIC2 subset:
  - SP_ASIC_CollateralReport.sql
  - SP_ASIC_TransactionsReport_Hedge.sql
  - SP_ASIC_PositionReport_Agg_Hedge.sql

## Current scope

Build MiFID staging/report tables in `main.regtech_ops_stg` only. All persistent objects created there must start with `bi_output_regtechops_`.

Out of scope for this phase:

- CSV export
- 7z compression
- SFTP delivery
- TRAX/Cappitech upload
- TRAX/Cappitech response handling
- full historical backfill
- production deployment to `main.regtech`

## Remaining items / decisions

No core MiFID SQL/SSIS artifact is currently blocking prompt creation.

Remaining work should be treated as validation gates or design decisions:

1. Let Cursor validate currency/price/split staging logic from `Pre_Regulation_Ext.dtsx`, especially:
   - Reg_CurrencyPrice_Ext
   - Reg_Ext_CurrencyPriceMaxDateWithSplit
   - Reg_Ext_DailyMaxPrices
   - Reg_Ext_T_PriceCandle60Min
2. History strategy:
   - Recreate/seed `MIFID2_NPD_TRAX` history only if needed for validation.
   - Recreate/seed `ASIC2_Transactions` history only if needed for validation.
   - Do not block initial table-generation implementation on full historical backfill.
3. Reconciliation baselines will be needed later from SQL Server for selected report dates.
4. File delivery and response handling are phase 2 unless explicitly brought into scope.
