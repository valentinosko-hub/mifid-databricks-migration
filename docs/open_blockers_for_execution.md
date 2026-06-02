# Open Blockers for Execution (Step 16B1)

This document is a consolidated execution blocker register for phase-1 MiFID migration in `main.regtech_ops_stg`.

## Access blockers

- `main.pii_data.bronze_etoro_customer_customer` (no schema access)
- `main.pii_data.bronze_etoro_history_customer` (no schema access)
- `dwh_daily_process` catalog access for:
  - `dwh_daily_process.daily_snapshot.etoro_history_customer`
  - `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit`

## Storage/data scan blockers

- `main.trading.bronze_etoro_trade_currencyprice`
- `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`

## History/seed blockers

- `MIFID2_NPD_TRAX` history/cutover strategy is unresolved.
- `MIFID2_Failed_TRAX` depends on `MIFID2_NPD_TRAX` history and requires a shared seed policy.
- `ASIC2_Transactions` seed/history window for parity windows is unresolved.
- `Reg_LiquidtyAcount_SCD` seed/cutover strategy is unresolved.
- `Reg_MigrationInOut_Population` / `Reg_RegulationInOutDailyData` materialization decision remains unresolved.

## Certification/SME blockers

- `CurrencyPriceMaxDateWithSplit` final source selection/certification.
- Exact CFI / InstrumentClassification parity where still gated.
- `RecordID` strategy for Hedge report.
- TransactionReferenceNumber parity for Hedge report.
- Source certification for required-column mappings where pending.

## Resolved blockers

- Internal accounts static table recreated with explicit LOCATION:
  - `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`
- Special char dictionary static table recreated with explicit LOCATION:
  - `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`
- EDNF to InstrumentID static table recreated with explicit LOCATION:
  - `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
- `FuturesMetaData` source confirmed accessible, certification pending:
  - `main.trading.bronze_etoro_trade_futuresmetadata`
- InstrumentID 341 source confirmed accessible, certification pending:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341`
- `Trade.GetInstrument` source confirmed accessible:
  - `main.trading.bronze_etoro_trade_getinstrument`
- `Trade.InstrumentMetaData` source confirmed accessible:
  - `main.trading.bronze_etoro_trade_instrumentmetadata`
- `Dictionary.Currency` source confirmed accessible:
  - `main.general.bronze_etoro_dictionary_currency`
- `Dictionary.CurrencyType` source confirmed accessible:
  - `main.general.bronze_etoro_dictionary_currencytype`

## Execution status

- Execution remains blocked until active blocker categories above are closed.
- This step does not introduce workflow/orchestration, delivery/upload logic, response handling, or production deployment actions.
