# Manual Approval Gates (Step 17C)

This register is the authoritative Step 17C list of manual approval gates for future workflow activation. It does not enforce approvals in Databricks runtime.

Master governance model: `docs/workflow_governance_controls.md`.

Status values:

- `OPEN` — approval not granted.
- `PARTIAL` — partial evidence; sign-off still required.
- `CLOSED` — approved with evidence recorded.

## Approval gate register

| Gate ID | Approval gate | Owner | Status | Evidence required (summary) |
| --- | --- | --- | --- | --- |
| MAG-01 | Source access approval | DE/Data Platform | OPEN | Profiling result; no active no-schema/no-catalog blockers |
| MAG-02 | Source required-column approval | DE + Validation | OPEN | DESCRIBE output; required-column check outputs |
| MAG-03 | Storage/data scan blocker closure | DE/Data Platform | OPEN | Remediation evidence; re-profile; certified alternative if used |
| MAG-04 | Static reference availability confirmation | Engineering + Validation | PARTIAL | Row-count/duplicate checks; static ref sign-off |
| MAG-05 | Masked customer fallback policy approval | Governance + RegTech SME + Compliance | OPEN | Signed structural-test-only masked policy |
| MAG-06 | Unmasked PII approval for final parity | DE + Governance + RegTech SME + Compliance | OPEN | PII access grant or formal exception approval |
| MAG-07 | History/seed approval | RegTech SME + Data Owners | OPEN | Signed policies for NPD, Failed TRAX, ASIC2, liquidity SCD |
| MAG-08 | Reg_MigrationInOut / Reg_RegulationInOut materialization decision | DE + RegTech SME | OPEN | Materialization decision memo |
| MAG-09 | ASIC2 seed/history approval | RegTech SME + Validation | OPEN | Seed window + validation coverage agreement |
| MAG-10 | NPD_TRAX history/cutover approval | RegTech SME + Validation | OPEN | Latest-row cutover policy evidence |
| MAG-11 | Liquidity SCD seed/cutover approval | RegTech SME + Engineering | OPEN | SCD seed/rebuild vs incremental approval |
| MAG-12 | Hedge RecordID strategy approval | RegTech SME + Engineering | OPEN | Deterministic RecordID design approval |
| MAG-13 | Hedge TransactionReferenceNumber parity approval | RegTech SME + Validation | OPEN | Expression parity + reconciliation evidence |
| MAG-14 | CurrencyPriceMaxDateWithSplit source-selection approval | DE + SME | OPEN | Source comparison + certification sign-off |
| MAG-15 | Exact CFI / InstrumentClassification parity approval | RegTech SME | OPEN | Classification parity test evidence |
| MAG-16 | SQL Server baseline comparison approval | Validation Owner + SQL Server Team | OPEN | Baseline comparison outputs where required |
| MAG-17 | Final validation signoff | Validation Owner | OPEN | Module + cross-module validation acceptance |

## Evidence detail by gate

| Gate ID | Expected evidence artifacts |
| --- | --- |
| MAG-01 | Source profiling result (`docs/source_profiling_results.md` integration); catalog/schema access confirmation; SME/DE approval |
| MAG-02 | `DESCRIBE TABLE` outputs; `databricks/sql/validation/02_static_reference_required_columns.sql` and module `*_validation.sql` outputs |
| MAG-03 | Storage ticket resolution; successful re-scan/profile; alternative source certification if applicable |
| MAG-04 | `databricks/sql/validation/01_*` through `07_*` outputs; static reference availability notes |
| MAG-05 | Documented approval of masked fallback for dev/structural mode only |
| MAG-06 | `main.pii_data` grant evidence or RegTech SME/Compliance formal approval record |
| MAG-07 | `docs/history_seed_requirements.md` sign-off per module family |
| MAG-08 | Written decision: gold snapshot materialization vs SSIS-compatible recreation |
| MAG-09 | ASIC2 history window definition; `06_asic2_validation.sql` evidence when run |
| MAG-10 | NPD_TRAX cutover policy; `09_mifid2_npd_trax_validation.sql` evidence when run |
| MAG-11 | Liquidity SCD policy; `05_hedge_liquidity_validation.sql` evidence when run |
| MAG-12 | Approved RecordID strategy document (maps to D-12) |
| MAG-13 | Transaction-reference parity reconciliation (maps to D-13) |
| MAG-14 | Split-price source certification (maps to D-05) |
| MAG-15 | CFI/classification parity evidence (maps to D-14) |
| MAG-16 | SQL Server baseline comparison tables/reports (maps to D-23) |
| MAG-17 | Full validation chain per `docs/final_validation_execution_plan.md` + `09_validation/*` |

## Approval record placeholders

Complete one block per gate when closing. Do not store PII or secrets in the repo.

### Template (copy per gate)

```text
Gate ID: MAG-__
Approval gate:
Approval owner: _TBD_
Approval date: _TBD_
Jira ticket: _TBD_
Evidence location: _TBD_
Status after approval: CLOSED
```

### MAG-01 — Source access approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-02 — Source required-column approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-03 — Storage/data scan blocker closure

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-04 — Static reference availability confirmation

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | PARTIAL |

### MAG-05 — Masked customer fallback policy approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-06 — Unmasked PII approval for final parity

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-07 — History/seed approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-08 — Reg_MigrationInOut / Reg_RegulationInOut materialization decision

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-09 — ASIC2 seed/history approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-10 — NPD_TRAX history/cutover approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-11 — Liquidity SCD seed/cutover approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-12 — Hedge RecordID strategy approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-13 — Hedge TransactionReferenceNumber parity approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-14 — CurrencyPriceMaxDateWithSplit source-selection approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-15 — Exact CFI / InstrumentClassification parity approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-16 — SQL Server baseline comparison approval

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

### MAG-17 — Final validation signoff

| Field | Value |
| --- | --- |
| Approval owner | _TBD_ |
| Approval date | _TBD_ |
| Jira ticket | _TBD_ |
| Status | OPEN |

## Policy reminders

- Masked customer tables are development fallback only.
- Final parity requires unmasked PII or formal approval.
- NOC and old Databricks attempt materials remain reference-only.
- Delivery/upload/response and production deployment remain out of scope.
