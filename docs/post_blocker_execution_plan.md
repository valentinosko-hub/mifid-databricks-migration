# Post-Blocker Execution Plan (Step 18B)

This plan describes the **controlled sequence** after open blockers close and manual approvals are recorded. It does not authorize immediate execution while blockers remain open.

Prerequisites before starting:

- `docs/open_blockers_for_execution.md` — active blockers closed or formally waived
- `docs/manual_approval_gates.md` — applicable MAG gates **CLOSED** with external evidence
- `docs/execution_prerequisites.md` — checklist complete
- `docs/de_data_platform_action_list.md` and `docs/regtech_sme_decision_list.md` — relevant actions closed

**Out of scope for this plan:** CSV export, 7z, SFTP, TRAX/Cappitech upload, TRAX response handling, production deployment to `main.regtech`.

---

## Phase 0 — Confirm enablement (no DML yet)

1. Re-read [final_repository_audit.md](final_repository_audit.md) and confirm go/no-go with Manager/PM.
2. Set run posture per [workflow_governance_controls.md](workflow_governance_controls.md):
   - Development structural test: `development_structural_test`, masked only if MAG-05 satisfied.
   - Final parity path: `final_parity_production`, unmasked PII required (MAG-06).
3. Keep workflow skeleton **non-deployed** until Phase 6 criteria are met.

---

## Phase 1 — Refresh source truth

| Step | Action | Artifact |
| --- | --- | --- |
| 1 | Rerun source profiling for all module upstream objects | Update `docs/source_profiling_results.md` |
| 2 | Integrate profiling into blocker/decision registers | Update `docs/open_blockers_for_execution.md`, `docs/remaining_decisions.md` if needed |

Selected primary sources to re-validate in this phase:

- `main.dealing.bronze_pricelog_history_currencyprice` (for `Reg_CurrencyPrice_Ext`)
- `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` (for `Reg_Ext_CurrencyPriceMaxDateWithSplit`)

---

## Phase 2 — Static and column gates (SELECT-only)

| Step | Action | SQL / doc reference |
| --- | --- | --- |
| 3 | Run static reference checks | `databricks/sql/validation/01_*` through `07_*` |
| 4 | Run source required-column checks | `databricks/sql/validation/02_static_reference_required_columns.sql`; module `*_validation.sql` where applicable |

Do not un-gate business DML if hard gates fail.

---

## Phase 2.5 — Historical seed implementation

| Step | Action |
| --- | --- |
| 4a | Implement approved historical seed strategy for parity/retry/SCD/baseline windows and confirm extract ownership (NPD, Failed TRAX, ASIC2, Hedge, liquidity SCD, migration/regulation in-out) |
| 4b | If minimum safe historical windows cannot be proven, seed all available history for affected objects |

Execution evidence from this phase must be captured before module activation.

---

## Phase 3 — Module activation (dependency order)

Follow `docs/migration_execution_order.md` and `docs/final_validation_execution_plan.md`.

| Step | Action |
| --- | --- |
| 5 | Activate modules in dependency order: static/config/UDF → Pre_Regulation → regulation movements → hedge liquidity/SCD → ASIC2 → MIFID2_ext → customer outputs → report family → ETORO → hedge report → NPD TRAX |
| 6 | After each module activation tranche, run that module’s validation SQL (SELECT-only packages) |

Use gated templates only; uncomment/enable DML only when prerequisites for that module are met.

---

## Phase 4 — Cross-module validation

| Step | Action |
| --- | --- |
| 7 | Run cross-module validation | `databricks/sql/09_validation/07_*`, `08_*`, `09_*` |
| 8 | Capture evidence per `docs/final_validation_execution_plan.md` and workflow gate wrappers if used in dry-run mode |

---

## Phase 5 — Baseline and parity

| Step | Action |
| --- | --- |
| 9 | Compare against SQL Server baseline where MAG-16 and module plans require it |
| 10 | Resolve differences; document accepted deltas in `docs/known_differences.md` |

---

## Phase 6 — Workflow consideration (separate approval)

| Step | Action |
| --- | --- |
| 11 | **Only then** consider workflow skeleton activation | `databricks/workflows/mifid_phase1_table_generation.yml` remains template until deployment change approval |

Workflow activation requires:

- MAG-17 final validation sign-off
- All stop/go rules in `docs/workflow_governance_controls.md`
- Explicit deployment authorization (not granted by documentation alone)

---

## Phase 7 — Future delivery phase (not part of phase 1)

| Step | Action |
| --- | --- |
| 12 | Delivery/upload/response remains a **separate future program phase** | No CSV, SFTP, 7z, TRAX upload, or response import from this repository phase |

---

## Stop criteria (revert to validation-only)

Stop and update blocker docs if:

- Any storage or PII access regression occurs
- Masked customer sources used in final parity mode
- Validation packages report unresolved hard-gate failures
- SME rejects baseline or classification parity
- Request includes delivery, production `main.regtech` deployment, or TRAX file operations

---

## Related documents

- [handoff_index.md](handoff_index.md)
- [final_validation_execution_plan.md](final_validation_execution_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
