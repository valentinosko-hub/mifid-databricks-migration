# Open Blockers for Execution (Step 16B1; aligned with Step 17C)

This document is a consolidated execution blocker register for phase-1 MiFID migration in `main.regtech_ops_stg`.

Governance mapping: each blocker below maps to manual approval gates in `docs/manual_approval_gates.md` and stop/go rules in `docs/workflow_governance_controls.md`. Workflow activation remains blocked until these are closed or formally waived.

## Temporary masked customer workaround (manager-approved)

Not a blocker closure. Approved for temporary development and structural testing only:

- `main.general.bronze_etoro_customer_customer_masked`
- `main.general.bronze_etoro_history_customer_masked`

Status: Temporary development fallback / manager-approved workaround.

Does not replace final PII sources or close final identity-field parity gates. Policy: `docs/source_to_databricks_mapping_review.md`.

## Access blockers (remain open)

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

- `CurrencyPriceMaxDateWithSplit` final source selection/certification (MAG-14; D-05).
- Exact CFI / InstrumentClassification parity where still gated (MAG-15; D-14).
- `RecordID` strategy for Hedge report (MAG-12; D-12).
- TransactionReferenceNumber parity for Hedge report (MAG-13; D-13).
- Source certification for required-column mappings where pending (MAG-02; D-21).

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
- Step 17C documents governance and manual approvals only; it does not close blockers or enable workflow execution.
- Workflow skeleton deployment/execution remains gated (`docs/workflow_governance_controls.md`).
- Delivery/upload/response handling and production deployment remain out of scope.
- NOC and old Databricks attempt materials remain reference-only and are not implementation authority.
