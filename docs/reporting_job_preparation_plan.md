# Reporting Job Preparation Plan — Staging Smoke Test

This plan describes how to prepare and (when approved) enable the **non-production staging smoke-test** workflow for MiFID ext/staging/audit tables. It does not authorize deployment or production execution.

## Objective

Validate structural readiness of ext/staging/audit table generation in `main.regtech_ops_stg` without claiming final regulatory parity or activating delivery/production paths.

## Workflow artifact

| Item | Location |
| --- | --- |
| Staging smoke-test skeleton | `databricks/workflows/mifid_phase1_staging_smoke_test.yml` |
| Shared parameter defaults | `databricks/config/workflow_parameters.yml` |
| Execution runbook | `docs/workflow_execution_runbook.md` |
| Orchestration plan | `docs/workflow_orchestration_plan.md` |

Job name (template): `mifid_phase1_staging_smoke_test_skeleton_do_not_deploy`

## Environment policy

| Setting | Value |
| --- | --- |
| Read sources (primary) | `main.regtech` when DE-migrated sources are available |
| Read sources (dev fallback) | Confirmed alternate schemas only when `main.regtech` object missing — **development fallback; document in run evidence** |
| Write target | `main.regtech_ops_stg` only |
| Object prefix | `bi_output_regtechops_` |
| Seed prefix | `bi_output_regtechops_seed_` |
| Default run mode | `development_structural_test` |
| Default dry run | `true` (readiness/check-only) |
| Staging execution approval | `staging_execution_approved=false` (required for `dry_run=false`) |
| Schedule | None |
| Deployment | Blocked (template-only) |

**Forbidden:** writes to `main.regtech`; delivery/upload/response; production schedules; final parity claims without MAG closure.

## Workflow groups

### Default critical path (required for first smoke-test pass)

1. **source_readiness_checks** — source/target policy gates (GATE-06–08 in `gate_global_scope.sql`)
2. **static_reference_checks** — static refs and required columns
3. **price_currency_split_ext_staging** — price/currency/split ext tables
4. **non_price_reg_ext_staging** — non-price Reg_Ext staging
5. **regulation_movement_staging** — regulation movements and migration snapshots
6. **hedge_liquidity_ext_staging** — liquidity ext; SCD structural only
7. **asic2_structural_staging** — ASIC2 subset structural checks only
8. **mifid2_ext_non_pii_staging** — MIFID2_ext non-PII tables
9. **validation_summary** — safe module validations + cross-module readiness

### Optional groups (commented manual task blocks — skippable)

| Group | Enable flag | Additional requirements | First pass required? |
| --- | --- | --- | --- |
| **masked_customer_structural_tests** | `enable_masked_customer_structural_tests=false` | `allow_masked_customer_sources=true`; MAG-05 CLOSED | **No** |
| **manual_seed_testing_checks** | `enable_manual_seed_testing_checks=false` | Seed tables loaded; manifest evidence per [manual_seed_testing_plan.md](manual_seed_testing_plan.md) | **No** |

Uncomment optional tasks in workflow YAML only when flags and approvals are set. `validation_summary` depends on `mifid2_ext_non_pii_staging` by default.

## dry_run and staging execution

| Setting | Meaning |
| --- | --- |
| `dry_run=true` (default) | Readiness/check-only safe mode; GATE-03 PASS |
| `dry_run=false` | Allowed only with `staging_execution_approved=true`, `run_mode=development_structural_test`, and MAG-18; writes still `main.regtech_ops_stg` only — not production |

First executions should keep `dry_run=true` until MAG-18 closes and staging execution is explicitly approved.

## Audit / evidence mapping

| Artifact | Role |
| --- | --- |
| `databricks/sql/10_workflow/gates/gate_global_scope.sql` | Source/target policy gate (SELECT-only) |
| `databricks/sql/10_workflow/02_audit_logging.sql` | Optional SELECT-only audit manifest (no persistent writes) |
| `docs/staging_execution_evidence_log.md` | **TODO** — external run evidence log (not yet authored) |
| Secure storage manifests | Baseline/seed evidence outside repo |

Workflow does not activate persistent audit table writes.

## Explicitly disabled / gated (not in smoke-test workflow)

| Exclusion | Gate / blocker |
| --- | --- |
| Final `MIFID2_NPD_TRAX` flow | MAG-10; NPD history |
| Final Hedge report activation | MAG-12, MAG-13; RecordID registry |
| Final PII customer parity | MAG-06; `main.pii_data` |
| Delivery / upload / response / production | Out of repo scope |
| Full table-generation output chain | `mifid_phase1_table_generation.yml` — separate, gated skeleton |

## Preparation checklist (documentation-only until MAG/blocker closure)

### A — Prerequisites

- [ ] `docs/open_blockers_for_execution.md` reviewed for intended run mode
- [ ] `docs/execution_prerequisites.md` staging items complete
- [ ] `docs/manual_approval_gates.md` — MAG-01 through MAG-04 minimum for structural smoke test
- [ ] `databricks/config/workflow_parameters.yml` parameters aligned with run intent
- [ ] SQL warehouse ID placeholder replaced only when deployment explicitly authorized (outside this repo step)

### B — Source readiness

- [ ] DE-migrated tables present in `main.regtech` or fallback documented
- [ ] Source profiling templates identified per module (`*_source_profiling.sql`)
- [ ] Required-column validation paths mapped (`docs/reporting_job_preparation_plan.md` group table above)

### C — Target readiness

- [ ] `main.regtech_ops_stg` schema exists and write access confirmed for RegTechOps role
- [ ] Naming convention `bi_output_regtechops_*` enforced
- [ ] No job task writes to `main.regtech`

### D — Optional paths

- [ ] Masked customer: MAG-05 CLOSED before `allow_masked_customer_sources=true`
- [ ] Manual seed: CSV in secure storage; load via `databricks/sql/11_seed_testing/`; validate with `04_manual_seed_validation.sql`

### E — Evidence capture

- [ ] Gate wrapper outputs (`databricks/sql/10_workflow/gates/`)
- [ ] Module validation outputs where structural-only
- [ ] Cross-module summary (`databricks/sql/09_validation/07_phase1_readiness_summary.sql`)
- [ ] Label all results **staging structural evidence only**

## SQL reference map by group

| Group | Primary SQL folders |
| --- | --- |
| 1 | `databricks/sql/validation/`, `03_pre_regulation_ext/*_source_profiling.sql`, `11_seed_testing/04_manual_seed_validation.sql` |
| 2 | `databricks/sql/01_static_references/`, `databricks/sql/validation/01_*`–`07_*` |
| 3 | `databricks/sql/03_pre_regulation_ext/02_*`, `03_*` |
| 4 | `databricks/sql/03_pre_regulation_ext/05_*`, `06_*` |
| 5 | `databricks/sql/04_regulation_movements/` |
| 6 | `databricks/sql/05_hedge_liquidity/` (structural subset) |
| 7 | `databricks/sql/06_asic2_subset/` |
| 8 | `databricks/sql/07_mifid2_ext/` (non-PII) |
| 9 | Masked customer policy docs; no `main.pii_data` |
| 10 | `databricks/sql/11_seed_testing/` |
| 11 | `databricks/sql/09_validation/`, module `*_validation.sql` |

Workflow tasks currently invoke **gate wrappers** as placeholders; module SQL activation remains a separate enablement step.

## Relationship to full Phase 1 generation workflow

`mifid_phase1_table_generation.yml` covers the broader report/output chain (customer, reports, hedge, NPD). The staging smoke-test workflow is a **narrower, earlier** orchestration for ext/staging/audit validation only. Do not conflate smoke-test success with final reporting readiness.

## SQL Server baseline extracts (prerequisite for final parity)

Before final parity comparison (not required for initial structural smoke tests):

1. RegTech / Validation nominate scenario dates — [baseline_scenario_request.md](baseline_scenario_request.md)
2. DBA / DE land extracts in secure storage (not Git)
3. Validation captures evidence — [validation_evidence_plan.md](validation_evidence_plan.md)

Distinguish baseline-date extracts, full-history seeds, and staging-only manual seed tests.

---

## Remaining blockers (summary)

- `main.pii_data` access for final parity (MAG-06)
- SQL Server baseline scenario dates and scoped extracts (D-23 / MAG-16)
- Historical seed extraction ownership (MAG-07)
- Hedge RecordID natural-key SME signoff and registry seed (MAG-12, D-12)
- NPD_TRAX history/cutover (MAG-10)
- Liquidity SCD full validation (MAG-11)
- Production deployment and DE production adaptation — separate program

See `docs/post_blocker_execution_plan.md` for post-blocker sequencing.

## Related documents

- [baseline_scenario_request.md](baseline_scenario_request.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
