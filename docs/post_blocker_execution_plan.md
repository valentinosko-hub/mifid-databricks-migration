# Post-Blocker Execution Plan (Step 18B)

This plan describes the **controlled sequence** for RegTech staging execution and final-parity enablement. Jobs/workflows in this repository are **staging-only RegTechOps jobs** — they write to `main.regtech_ops_stg` only and are not production-grade. Data Engineering will later adapt them for production.

## Staging-only execution (permitted before final-parity gates close)

The following may proceed **without** claiming final regulatory parity:

| Activity | Target / constraint |
| --- | --- |
| Create staging job/workflow skeletons and smoke-test jobs | `main.regtech_ops_stg` only; `bi_output_regtechops_` prefix |
| Load approved CSV seed extracts | `main.regtech_ops_stg` seed tables; `bi_output_regtechops_seed_` prefix; CSV in secure storage only — **not Git** |
| Initial NPD_TRAX seed/load test | `bi_output_regtechops_seed_mifid2_npd_trax` (or equivalent); manageable volume; **not final parity** until PII/validation gates close |
| Test ext/staging/audit tables | Modules not requiring final PII or final production state |
| `development_structural_test` runs | Masked customer fallback permitted for structural tests only |
| Read DE-migrated sources | `main.regtech` when available |

**Not permitted:** writes to `main.regtech`; production schedules; delivery/upload/response; seed CSVs or PII in Git; final parity claims without MAG closure.

---

## Final-parity prerequisites (blockers must close)

Prerequisites before **final-parity** module activation:

- `docs/open_blockers_for_execution.md` — active blockers closed or formally waived
- `docs/manual_approval_gates.md` — applicable MAG gates **CLOSED** with external evidence
- `docs/execution_prerequisites.md` — checklist complete
- `docs/de_data_platform_action_list.md` and `docs/regtech_sme_decision_list.md` — relevant actions closed

**Out of scope for this plan:** regulatory CSV export/delivery, 7z, SFTP, TRAX/Cappitech upload, TRAX response handling, production deployment to `main.regtech`, production-grade job adaptation (DE's separate program).

**In scope for staging:** approved CSV **seed loads** into `main.regtech_ops_stg` (not committed to Git).

---

## Phase 0 — Confirm enablement

1. Re-read [final_repository_audit.md](final_repository_audit.md) and confirm go/no-go with Manager/PM.
2. Set run posture per [workflow_governance_controls.md](workflow_governance_controls.md):
   - Development structural test: `development_structural_test`, masked only if MAG-05 satisfied.
   - Final parity path: `final_parity_production`, unmasked PII required (MAG-06).
3. Confirm run is **staging-only** — writes target `main.regtech_ops_stg`; no `main.regtech` writes.
4. For staging smoke tests: `run_mode=development_structural_test`; no final parity claims.
5. Production workflow schedules remain blocked until Phase 6 final-parity criteria are met.

---

## Phase 0.5 — Staging seed and smoke tests (optional; before full blocker closure)

Permitted when secure seed extracts and `main.regtech_ops_stg` write access exist:

| Step | Action |
| --- | --- |
| 0a | Load approved CSV seed for `MIFID2_NPD_TRAX` using `databricks/sql/11_seed_testing/` templates into `bi_output_regtechops_seed_test_mifid2_npd_trax` (initial feasibility test) |
| 0b | Run `04_manual_seed_validation.sql` (SELECT-only); document as **staging evidence only** — see [manual_seed_testing_plan.md](manual_seed_testing_plan.md) |
| 0c | Run staging smoke-test workflow (`databricks/workflows/mifid_phase1_staging_smoke_test.yml`) for ext/staging/audit modules not requiring final PII — see [reporting_job_preparation_plan.md](reporting_job_preparation_plan.md) |
| 0d | Confirm NPD remains later in reporting flow (history/state dependency); seed test does not close NPD parity gates |
| 0e | Keep final NPD_TRAX, Hedge report, PII customer parity, and delivery paths disabled in smoke-test workflow |

Do not treat Phase 0.5 as final-parity or production readiness.

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

## Phase 2.5 — Historical seed extraction and load

BI-21 MCP metadata confirms all nine seed-critical tables exist; manual SQL aggregates support chunk planning and Hedge/NPD key integrity. See [historical_seed_inventory.md](historical_seed_inventory.md) and [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md).

| Step | Action |
| --- | --- |
| 4a | Assign historical seed **extraction ownership** and secure landing process (DE/Data Platform) |
| 4b | Extract and load seed tables per inventory — CSV/secure landing → `bi_output_regtechops_seed_*` in `main.regtech_ops_stg`; chunk by month where documented. **Start with `MIFID2_NPD_TRAX`** as feasible initial test; expand to Hedge, ASIC2, migration/regulation in-out |
| 4c | If minimum safe historical windows cannot be proven, seed all available history for affected objects |
| 4d | **Validate** seed row counts, keys, and date ranges (reconcile known MCP vs manual count variances for Hedge and ASIC2_Transactions) |
| 4e | **Build Hedge RecordID registry** using gated package templates under `databricks/sql/08_outputs/10_hedge_recordid_registry/` and [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md) before Hedge module DML activation |

Execution evidence from this phase must be captured before module activation.

---

## Phase 2.6 — Controlled structural dry run

| Step | Action |
| --- | --- |
| 4f | Run controlled structural dry run (SELECT-only / gated templates) after seed validation and registry scaffold |
| 4g | Confirm no un-gated DML into final outputs |

Registry-specific gate before Step 14 activation:

- Historical source availability confirmed (DE-migrated or approved seed-test source).
- Registry seed validation passes (`04_hedge_recordid_validation.sql` + Step 14 validation).
- Natural-key signoff completed.

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

## Phase 4.5 — Baseline scenario request and extract (before parity comparison)

| Step | Action | Artifact |
| --- | --- | --- |
| 8a | RegTech / Validation nominate baseline scenario dates per [baseline_scenario_request.md](baseline_scenario_request.md) | Completed request forms (external) |
| 8b | DBA / DE execute baseline-date extracts and full-history seeds per extract type | Manifests in secure storage (not Git) |
| 8c | Validation reviews manifests (row count, min/max date, scenario tag, schema) | Evidence log outside repo |
| 8d | Distinguish Type 1 (baseline-date), Type 2 (full-history seed), Type 3 (staging manual seed test) | Per-request tagging |

Do not treat baseline-date slices as substitutes for full-history seeds on stateful tables (Hedge, NPD, ASIC2, SCD, migration/regulation).

---

## Phase 5 — Baseline and parity

| Step | Action |
| --- | --- |
| 9 | Compare against SQL Server baseline on **selected baseline dates** where MAG-16 requires it (do not default to full `MIFID2_Report` export) — follow [validation_evidence_plan.md](validation_evidence_plan.md) |
| 10 | Resolve differences; document accepted deltas in `docs/known_differences.md` |
| 11 | Capture exact-comparison evidence for Hedge `TransactionReferenceNumber`, CFI/`InstrumentClassification`, Hedge `RecordID`, NPD `AcceptedTRAX`/`Action`/`RowNum` |

Baseline comparisons run **only after** seed validation and controlled dry run (Phases 2.5–2.6) and baseline extracts are landed (Phase 4.5).

---

## Phase 6 — Workflow consideration (separate approval)

| Step | Action |
| --- | --- |
| 12 | **Only then** consider workflow skeleton activation | `databricks/workflows/mifid_phase1_table_generation.yml` remains template until deployment change approval |

Workflow activation requires:

- MAG-17 final validation sign-off
- All stop/go rules in `docs/workflow_governance_controls.md`
- Explicit deployment authorization (not granted by documentation alone)

---

## Phase 7 — Future delivery phase (not part of phase 1)

| Step | Action |
| --- | --- |
| 13 | Delivery/upload/response remains a **separate future program phase** | No CSV, SFTP, 7z, TRAX upload, or response import from this repository phase |

---

## Stop criteria (revert to validation-only)

Stop and update blocker docs if:

- Any storage or PII access regression occurs
- Masked customer sources used in final parity mode
- Validation packages report unresolved hard-gate failures
- SME rejects baseline or classification parity
- Request includes delivery, production `main.regtech` deployment, or TRAX file operations

---

## Recommended sequence (summary)

**Staging track (may start earlier):**

1. Create/run staging-only smoke-test jobs in `main.regtech_ops_stg`
2. Load approved CSV seed (initial: `MIFID2_NPD_TRAX`) into `bi_output_regtechops_seed_*`
3. Validate seed row counts/keys as staging evidence

**Final-parity track (after blockers/MAG close):**

4. Complete PII access or formal exception (D-01 / MAG-06)
5. Complete seed extraction ownership for remaining inventory tables
6. Validate all seed row counts, keys, and date ranges
7. Build Hedge RecordID registry per [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
8. Submit baseline scenario requests per [baseline_scenario_request.md](baseline_scenario_request.md); land extracts in secure storage
9. Run controlled structural dry run → baseline comparisons on approved dates per [validation_evidence_plan.md](validation_evidence_plan.md)
10. **Only then** consider production-schedule workflow activation (Phase 6); DE adapts to production separately

---

## Related documents

- [handoff_index.md](handoff_index.md)
- [historical_seed_inventory.md](historical_seed_inventory.md)
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
- [baseline_scenario_request.md](baseline_scenario_request.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
- [manual_seed_testing_plan.md](manual_seed_testing_plan.md)
- [final_validation_execution_plan.md](final_validation_execution_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
