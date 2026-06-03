# Execution Prerequisites (Step 16B2)

This document lists what must be in place **before** any Databricks module execution or DML un-gating in `main.regtech_ops_stg`.

Current status: **execution is not approved** until prerequisites below are satisfied. See `docs/open_blockers_for_execution.md`.

## Temporary masked customer policy (manager-approved)

While `main.pii_data` access is pending, the following may be used for **temporary development and structural testing only**:

| Object | Status |
| --- | --- |
| `main.general.bronze_etoro_customer_customer_masked` | Temporary development fallback / manager-approved workaround |
| `main.general.bronze_etoro_history_customer_masked` | Temporary development fallback / manager-approved workaround |

Allowed uses: schema profiling, required-column checks, row-count checks, join-path testing, gated template development, non-production structural validation, workflow dry-run planning without identity parity certification.

Not approved as: confirmed final source, production source, regulatory parity source.

Final field-level parity remains gated for identity-sensitive customer fields and final validation of `MIFID2_Customer`, `MIFID2_RegChange_Customer`, `MIFID2_Failed_TRAX`, and `MIFID2_NPD_TRAX`.

Future orchestration must distinguish development/structural test mode (masked) from final parity/production mode (unmasked PII or formal approval).

## Workflow parameter semantics (Step 17B skeleton)

The Step 17B workflow skeleton is defined in `databricks/workflows/mifid_phase1_table_generation.yml` and must remain non-executing until prerequisites are closed.

Required parameter behavior:

| Parameter | Meaning | Required behavior |
| --- | --- | --- |
| `run_mode` | Workflow mode selector | Use `development_structural_test` for structural checks only; use `final_parity_production` only after blocker closure and manual approvals |
| `dry_run` | Activation safety switch | Keep `true` until explicit final go/no-go approval |
| `customer_source_policy` | Customer-source governance policy | Keep `temporary_masked_dev_only_v1` unless a formally approved replacement policy is documented |
| `dev_customer_source_mode` | Customer source path for development mode | `masked_fallback` is structural-test only; `pii_required` is mandatory for final parity mode |
| `allow_masked_customer_sources` | Explicit masked-source override | Keep `false` by default; set `true` only for approved structural checks |
| `require_unmasked_pii_for_parity` | Final parity enforcement flag | Keep `true` in final parity mode |

Related wrappers:

- `databricks/sql/10_workflow/00_workflow_parameters.sql`
- `databricks/sql/10_workflow/gates/gate_global_scope.sql`
- `databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql`

## Required access grants (final parity; blockers remain open)

| Object / scope | Issue | Owner action |
| --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access | Grant `main.pii_data` schema access for final regulatory parity (masked tables do not close this prerequisite) |
| `main.pii_data.bronze_etoro_history_customer` | No schema access | Same as above for final as-of/history parity |
| `dwh_daily_process` catalog | No catalog access | Grant `USE CATALOG dwh_daily_process` for fallback profiling, or formally retire candidates in favor of accessible alternatives |
| `dwh_daily_process.daily_snapshot.etoro_history_customer` | Blocked by catalog | Profile or retire as customer-history fallback |
| `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` | Blocked by catalog | Enable candidate comparison or certify `main.dwh` alternative as sole source |

## Required source fixes (storage / scan)

| Object | Issue | Impacted modules |
| --- | --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | Storage/data scan failure | Pre_Regulation `Reg_CurrencyPrice_Ext`, report pricing, movements |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Storage/data scan failure | Hedge liquidity mapping, SCD, hedge report |

DE/Data Platform must resolve underlying storage issues or certify approved alternative sources before activation.

## Required source certifications

Confirmed-accessible sources still need **required-column contract certification** before executable staging SQL is enabled. Examples:

- `main.dealing.bronze_pricelog_history_currencypricemaxdate` (`Reg_Ext_DailyMaxPrices`)
- `main.dealing.bronze_candles_candles_t_pricecandle60min` (`Reg_Ext_T_PriceCandle60Min`)
- `main.trading.bronze_etoro_trade_getinstrument`, `main.trading.bronze_etoro_trade_instrumentmetadata`
- `main.general.bronze_etoro_dictionary_currency`, `main.general.bronze_etoro_dictionary_currencytype`
- `main.trading.bronze_etoro_trade_futuresmetadata` (FuturesMetaData columns for report branches)
- Position/mirror/changelog sources for Step 8/9
- PIN/UserAPI source contract for customer and Failed TRAX flows
- `Reg_Ext_CustomerLatinName` source mapping (still pending)
- `Dictionary.Ext_TradeFund` mapping for customer copy-fund attributes

Profiling summary: `docs/source_profiling_results.md`.

## Required history / seed decisions

| Topic | Decision needed | Notes |
| --- | --- | --- |
| `MIFID2_NPD_TRAX` | History/cutover for prior latest rows by `(CID, RegulationID)` | Required for exact new/existing/retry/REPL parity |
| `MIFID2_Failed_TRAX` | Shared policy with NPD TRAX history | Failed-customer supplementation depends on NPD latest state |
| `ASIC2_Transactions` | Seed/history window for older ETORO parity | Coverage-limited without approved window |
| `Reg_LiquidtyAcount_SCD` | Seed/rebuild vs incremental cutover | Persistent SCD; cannot use blind full replace |
| `Reg_MigrationInOut_Population` / `Reg_RegulationInOutDailyData` | Materialize prefixed gold snapshot vs recreate SSIS logic | Affects movement and report lineage |

Detail: `docs/history_seed_requirements.md`.

## Required business decisions

| Topic | Owner | Blocking impact |
| --- | --- | --- |
| `Reg_Ext_CurrencyPriceMaxDateWithSplit` final source | DE/SME | Split-price and movement enrichment parity |
| Hedge `RecordID` strategy | SME | SQL Server uses IDENTITY; Databricks needs approved deterministic approach |
| Hedge transaction-reference parity | SME | Expression and exclusion-key matching |
| Exact CFI / InstrumentClassification parity | SME | ETORO/Hedge/report branches where still gated |
| ReplaceChar parity sign-off | Validation owner | Customer name/PIN normalization |
| `CDE_Execution_timestamp -> OpenTime` semantics | SME | ASIC2 compatibility view activation |
| Report-scoped exclusion semantics | SME | ETORO/Hedge row-level vs full-table suppression |
| `UpdateDate` no-default rule | SME | Report/ME report nullable behavior |
| Removed partials explicit-column insert | Engineering | Schema-order parity |

Consolidated list: `docs/remaining_decisions.md`.

## Required validation order

After prerequisites pass and module DML is enabled **only with explicit approval**, run validations in this order:

1. Static reference checks
2. Source access / required-column checks
3. Pre_Regulation staging checks
4. Regulation movement checks
5. Hedge liquidity/SCD checks
6. ASIC2 compatibility checks
7. `MIFID2_ext` checks
8. Customer output checks
9. Main report output checks
10. ETORO checks
11. Hedge report checks
12. NPD_TRAX checks
13. Cross-output reconciliation
14. SQL Server baseline comparison (if available)

Full plan: `docs/final_validation_execution_plan.md`.

Cross-module readiness SQL (SELECT-only, run when execution environment is available):

- `databricks/sql/09_validation/07_phase1_readiness_summary.sql`
- `databricks/sql/09_validation/08_cross_module_validation_manifest.sql`
- `databricks/sql/09_validation/09_cross_module_dependency_gate_checks.sql`

## Module activation order (dependency)

Canonical staging/output activation order: `docs/migration_execution_order.md`.

Do not skip upstream gates (for example, do not activate report outputs before Pre_Regulation, movements, ext staging, and customer gates are cleared).

## Warnings and scope boundaries

- **Delivery/upload/response is out of scope:** no CSV, 7z, SFTP, TRAX/Cappitech upload, or `SP_MIFID2_NPD_TRAX_Response_Update` implementation in phase 1.
- **No production `main.regtech` writes** in this phase.
- **No full historical backfill** required to start forward-only validation, but historical parity windows need explicit seed policy.
- **NOC** is reference-only (monitoring/freshness; not MiFID report-generation authority).
- **Old Databricks attempt** is reference-only (includes delivery/SFTP/TRAX scope outside current table-generation phase).
- **Do not modify `reference/`** files; use them for parity comparison only.

## Go/no-go checklist (minimum)

- [ ] All access blockers in `docs/open_blockers_for_execution.md` closed or formally waived with documented alternative
- [ ] Storage blockers resolved or certified alternatives approved
- [ ] Required-column certifications recorded per module
- [ ] History/seed policies signed off where stateful logic applies
- [ ] Business/SME parity decisions recorded in `docs/remaining_decisions.md`
- [ ] Validation evidence captured per `docs/final_validation_execution_plan.md`
- [ ] No activation of delivery/upload/response or production deployment without a new phase charter
