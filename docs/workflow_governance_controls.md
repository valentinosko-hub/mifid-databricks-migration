# Workflow Governance Controls (Step 17C)

This document defines the governance model for future activation of the Step 17B workflow skeleton. It is **documentation only** and does not implement runtime enforcement in Databricks.

Related artifacts:

- Step 17B skeleton: `databricks/workflows/mifid_phase1_table_generation.yml`
- Gate wrappers: `databricks/sql/10_workflow/gates/`
- Approval register: `docs/manual_approval_gates.md`
- Runbook: `docs/workflow_execution_runbook.md`

## Governance model

| Principle | Requirement |
| --- | --- |
| Scope | Table/report generation and validation in `main.regtech_ops_stg` with `bi_output_regtechops_` prefix only |
| Execution | Workflow skeleton remains non-executing until explicit change approval |
| Enforcement | Manual approvals and evidence recorded outside repo runtime; no Databricks policy engine in this step |
| Authority | SQL Server SP/SSIS/DDL under `reference/mifid_databricks_migration_context/` remain business-logic authority |
| Exclusions | No CSV/7z/SFTP, TRAX/Cappitech upload, TRAX response handling, or production deployment in this phase |

## Approval matrix

Status values: `OPEN`, `PARTIAL`, `CLOSED`.

| Gate ID | Approval gate | Proposed owner | Current status | Related decision |
| --- | --- | --- | --- | --- |
| MAG-01 | Source access approval | DE/Data Platform | OPEN | D-01, D-04 |
| MAG-02 | Source required-column approval | DE + Validation | OPEN | D-21 |
| MAG-03 | Storage/data scan blocker closure | DE/Data Platform | OPEN | D-02, D-03 |
| MAG-04 | Static reference availability confirmation | Engineering + Validation | PARTIAL | — |
| MAG-05 | Masked customer fallback policy approval | Governance + RegTech SME + Compliance | OPEN (dev only) | D-01 |
| MAG-06 | Unmasked PII approval for final parity | DE + Governance + RegTech SME + Compliance | OPEN | D-01 |
| MAG-07 | History/seed approval (batch) | RegTech SME + Data Owners | OPEN | D-06, D-07 |
| MAG-08 | Reg_MigrationInOut / Reg_RegulationInOut materialization decision | DE + RegTech SME | OPEN | D-10, D-11 |
| MAG-09 | ASIC2 seed/history approval | RegTech SME + Validation | OPEN | D-08 |
| MAG-10 | NPD_TRAX history/cutover approval | RegTech SME + Validation | OPEN | D-06 |
| MAG-11 | Liquidity SCD seed/cutover approval | RegTech SME + Engineering | OPEN | D-09 |
| MAG-12 | Hedge RecordID strategy approval | RegTech SME + Engineering | OPEN | D-12 |
| MAG-13 | Hedge TransactionReferenceNumber parity approval | RegTech SME + Validation | OPEN | D-13 |
| MAG-14 | CurrencyPriceMaxDateWithSplit source-selection approval | DE + SME | OPEN | D-05 |
| MAG-15 | Exact CFI / InstrumentClassification parity approval | RegTech SME | OPEN | D-14 |
| MAG-16 | SQL Server baseline comparison approval | Validation Owner + SQL Server Team | OPEN | D-23 |
| MAG-17 | Final validation signoff | Validation Owner | OPEN | — |

Detailed gate rows, evidence, and approval placeholders: `docs/manual_approval_gates.md`.

## Evidence matrix

Expected evidence types by gate (store outside repo; no PII samples or secrets in git).

| Gate ID | Expected evidence |
| --- | --- |
| MAG-01 | Source profiling result; access grant confirmation; SME/DE approval record |
| MAG-02 | `DESCRIBE TABLE` output; required-column check output from module validation SQL |
| MAG-03 | Storage remediation ticket; re-profile result; certified alternative source decision |
| MAG-04 | Static reference row-count/duplicate checks; availability sign-off |
| MAG-05 | Signed masked-fallback policy for structural testing only |
| MAG-06 | `main.pii_data` access grant or formal Compliance/RegTech exception |
| MAG-07 | Signed history/seed policy document per stateful module |
| MAG-08 | Materialization decision memo (gold snapshot vs SSIS-compatible recreation) |
| MAG-09 | ASIC2 seed window definition and validation-window agreement |
| MAG-10 | NPD_TRAX cutover policy and latest-row seed evidence |
| MAG-11 | Liquidity SCD seed/rebuild vs incremental approval |
| MAG-12 | Hedge RecordID deterministic strategy specification |
| MAG-13 | Transaction-reference parity reconciliation output |
| MAG-14 | Split-price source comparison and certification sign-off |
| MAG-15 | CFI/classification parity test results for gated report branches |
| MAG-16 | SQL Server baseline comparison output (where required) |
| MAG-17 | Module + cross-module validation package outputs accepted |

Common evidence fields for every gate:

- Jira ticket link placeholder: `_TBD_`
- Approval owner placeholder: `_TBD_`
- Approval date placeholder: `_TBD_`

## Run-mode governance

### `development_structural_test`

| Control | Rule |
| --- | --- |
| Customer sources | Masked fallback allowed only if `allow_masked_customer_sources=true` and MAG-05 recorded |
| Allowed work | Schema checks, join-path checks, row counts, validation dry-runs, gated template structural testing |
| Prohibited | Final customer/NPD identity parity certification; production deployment claims |
| Parameters | `dry_run=true`, `enable_validation_only=true`, `skip_delivery_steps=true` |

### `final_parity_production`

| Control | Rule |
| --- | --- |
| Customer sources | Unmasked `main.pii_data` customer tables or formal approval (MAG-06); masked fallback disabled |
| Prerequisites | Source/storage/history/SME blockers resolved; validation evidence complete |
| Activation | Requires MAG-17 and applicable MAG-01 through MAG-16 closed |
| Parameters | `require_unmasked_pii_for_parity=true`, `allow_masked_customer_sources=false` |

## Masked-customer governance

### Temporary development fallback (not final parity)

- `main.general.bronze_etoro_customer_customer_masked`
- `main.general.bronze_etoro_history_customer_masked`

### Final expected PII sources

- `main.pii_data.bronze_etoro_customer_customer`
- `main.pii_data.bronze_etoro_history_customer`

### Rules

1. Masked tables are development fallback only; not confirmed final, production, or regulatory parity sources.
2. Masked tables cannot certify final customer or NPD identity parity.
3. Final field-level parity remains gated for: `FirstName`, `LastName`, `BirthDate`, `PIN`, `PIN_Type`, customer identity-change comparison, `NonLatinOrEmptyName` detection, and final validation of `MIFID2_Customer`, `MIFID2_RegChange_Customer`, `MIFID2_Failed_TRAX`, and `MIFID2_NPD_TRAX`.
4. Final parity requires unmasked PII access or formal approval from data owner / RegTech SME / Compliance.

## Stop/go criteria

### Development dry run — may proceed only when

- Workflow remains non-executing or explicitly limited to validation-only tasks.
- `dry_run=true`.
- Masked fallback explicitly allowed and MAG-05 recorded.
- No final parity or production claims are made.
- Delivery/upload/response tasks remain excluded.

### Parity run — may proceed only when

- MAG-01 source access approvals closed or waived with documented alternative.
- MAG-03 storage blockers closed.
- MAG-07, MAG-08, MAG-09, MAG-10, MAG-11 history/seed and materialization gates closed.
- MAG-05/MAG-06 PII source policy approved for intended mode.
- Validation packages are ready to execute (SELECT-only evidence capture).
- MAG-16 SQL Server baseline strategy agreed (even if comparison remains optional per module).

### Production-candidate run — may proceed only when

- All parity gates (MAG-01 through MAG-17) applicable to the run window are `CLOSED`.
- Manual approvals recorded in Jira or designated approval log.
- Final validation evidence accepted (MAG-17).
- Production deployment decision is explicitly approved in a **separate** phase charter (not implied by this repo skeleton).

## Audit trail expectations

- Record all approvals in Jira or a designated approval log (not only in git comments).
- Do not store secrets, credentials, or delivery/upload configuration in this repository.
- Do not store PII samples in this repository.
- Store validation evidence in controlled operational storage (separate from repo skeleton).
- Keep production deployment approvals separate from Step 17B/17C documentation.
- Workflow activation in Databricks requires explicit change approval after Step 17C gates close.

## Current open blockers (carried forward)

See `docs/open_blockers_for_execution.md`. Summary:

| Blocker | Category |
| --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | Storage/data scan failure |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Storage/data scan failure |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access (final parity) |
| `main.pii_data.bronze_etoro_history_customer` | No schema access (final parity) |
| `dwh_daily_process` catalog | No catalog access |
| `MIFID2_NPD_TRAX` history/cutover | History/seed unresolved |
| `ASIC2_Transactions` history/seed | History/seed unresolved |
| `Reg_LiquidtyAcount_SCD` seed/cutover | History/seed unresolved |
| Hedge `RecordID` strategy | SME/business decision |
| Hedge `TransactionReferenceNumber` parity | SME/business decision |
| `CurrencyPriceMaxDateWithSplit` source selection | Certification/SME |
| Exact CFI / `InstrumentClassification` | Certification/SME |
| Required-column certifications (batch) | Certification pending |

## Reference-only policy

- **NOC monitoring materials** are reference-only and are not implementation authority (monitoring/freshness scope only).
- **Old Databricks attempt / deployment guide** is reference-only and is not implementation authority (includes delivery/SFTP/TRAX scope outside current table-generation phase).
- **Delivery/upload/response handling** remains out of scope for this phase (CSV, 7z, SFTP, TRAX/Cappitech upload, TRAX response import/update).
