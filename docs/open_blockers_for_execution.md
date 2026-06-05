# Open Blockers for Execution (Step 16B1; aligned with Step 17C)

This document is a consolidated execution blocker register for phase-1 MiFID migration in `main.regtech_ops_stg`.

Governance mapping: each blocker below maps to manual approval gates in `docs/manual_approval_gates.md` and stop/go rules in `docs/workflow_governance_controls.md`. **Final-parity** workflow activation remains blocked until these are closed or formally waived.

## Staging-only execution (not blocked)

The following are **permitted** under the staging-only RegTechOps policy and do **not** close final-parity blockers:

- Create and run staging-only Databricks job/workflow skeletons and smoke-test jobs
- Load approved CSV seed extracts into `main.regtech_ops_stg` (`bi_output_regtechops_seed_*` prefix)
- Initial `MIFID2_NPD_TRAX` seed/load test (manageable volume; staging evidence only)
- Test ext/staging/audit tables not requiring final PII or production state
- `development_structural_test` mode with masked customer fallback for structural tests only

**Constraints:** writes to `main.regtech_ops_stg` only; read `main.regtech` when DE-migrated sources exist; no seed CSVs or PII in Git; no production schedules; no regulatory delivery/upload/response; no final parity claims.

Jobs in this repo are not production-grade. DE will later adapt them for production via the general pipeline.

## Temporary masked customer workaround (manager-approved)

Not a blocker closure. Approved for temporary development and structural testing only:

- `main.general.bronze_etoro_customer_customer_masked`
- `main.general.bronze_etoro_history_customer_masked`

Allowed only for schema profiling, row-count checks, join-path testing, gated template development, and non-production structural validation.

Does not replace final PII sources or close identity-field parity gates (`FirstName`, `LastName`, `BirthDate`, `PIN`, `PIN_Type`, identity-change comparison, `NonLatinOrEmptyName`, and final customer/NPD validation).

## Active blockers (current)

Only active access blockers:

- `main.pii_data.bronze_etoro_customer_customer` (no schema access)
- `main.pii_data.bronze_etoro_history_customer` (no schema access)

## Execution gates (not downgraded to "resolved")

These are no longer active source-access/storage blockers, but execution still requires closure of validation/approval gates:

- Final required-column certification for selected sources (MAG-02 / D-21).
- Historical seed implementation per approved strategy (MAG-07/08/09/10/11; BI-21 MCP confirms nine seed-critical tables exist — see `docs/historical_seed_inventory.md`; extract ownership and load still pending).
- Hedge `RecordID` approved design implementation and validation (MAG-12 / D-12).
- Hedge `TransactionReferenceNumber` exact SQL Server parity validation (MAG-13 / D-13).
- CFI / `InstrumentClassification` exact SQL Server parity validation (MAG-15 / D-14).
- SQL Server baseline comparison signoff where required (MAG-16 / D-23).

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
- `main.trading.bronze_etoro_trade_currencyprice` reclassified:
  - readable but not preferred for `Reg_CurrencyPrice_Ext`; replaced by selected primary source
- `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` reclassified:
  - readable with required columns present (`HedgeServerID`, `LiquidityAccountID`, `AltRatesLiquidityAccountID`)
- CurrencyPrice source selected:
  - `main.dealing.bronze_pricelog_history_currencyprice` (primary for `History.CurrencyPrice` / `History.CurrencyPrice_Active` / `Reg_CurrencyPrice_Ext`)
- CurrencyPriceMaxDateWithSplit source selected:
  - `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` (primary for `Candles.CurrencyPriceMaxDateWithSplit` / `Reg_Ext_CurrencyPriceMaxDateWithSplit`)
- Previous split-price candidates downgraded to fallback/reference:
  - `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit`
  - `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`

## Execution status

- **Final-parity execution** remains blocked until active PII blockers close and execution-gate approvals/validations are completed.
- **Staging-only** smoke-test, seed-load, and structural validation in `main.regtech_ops_stg` may proceed per staging policy (see above).
- Step 17C documents governance and manual approvals; it does not close final-parity blockers.
- Production-schedule workflow deployment remains gated (`docs/workflow_governance_controls.md`).
- Writes to `main.regtech` from RegTech staging jobs are not permitted.
- Regulatory delivery/upload/response and production deployment remain out of scope.
- TransactionReferenceNumber and CFI/`InstrumentClassification` exact SQL Server parity requirements remain in force.
- Hedge RecordID registry/control requirement remains in force.
- NOC and old Databricks attempt materials remain reference-only and are not implementation authority.
