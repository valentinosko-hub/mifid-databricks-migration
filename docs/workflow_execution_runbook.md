# Workflow Execution Runbook (Step 17B Skeleton; Step 17C Governance)

This runbook defines how to use the **staging smoke-test** and Step 17B workflow skeletons for **staging-only RegTechOps** execution and governance. Jobs/workflows in this repository are **not production-grade**; they write to `main.regtech_ops_stg` only. Workflow YAML files are **template-only / `do_not_deploy`** — unscheduled and not deployed to production schedules. **Approved staging smoke-test execution** is permitted in `development_structural_test` mode when prerequisites and MAG gates allow. Production scheduling, delivery/upload/response, and final parity remain blocked. Data Engineering may later adapt definitions for production criteria.

**Primary staging artifacts:** `databricks/workflows/mifid_phase1_staging_jobs.yml` (canonical split jobs)  
**Notebook companion artifacts:** `databricks/workflows/mifid_phase1_staging_notebook_jobs.yml`, `databricks/notebooks/mifid_staging/`  
**Combined view:** `databricks/workflows/mifid_phase1_staging_smoke_test.yml`  
**Job creation plan:** `docs/staging_workflow_job_creation_plan.md`  
**Parameter defaults:** `databricks/config/workflow_parameters.yml`  
**Preparation plan:** `docs/reporting_job_preparation_plan.md`  
**First-run plan:** `docs/staging_first_run_plan.md`  
**Evidence log:** `docs/staging_execution_evidence_log.md`  
**Remaining work checklist:** `docs/remaining_migration_work_checklist.md`  
**Readiness SQL:** `databricks/sql/12_staging_readiness/`  
**Baseline extracts:** `docs/baseline_scenario_request.md`, `docs/validation_evidence_plan.md`

Governance controls and manual approval workflow: `docs/workflow_governance_controls.md`, `docs/manual_approval_gates.md`.

## Staging-only environment policy

| Setting | Value |
| --- | --- |
| Job type | Staging-only RegTechOps (smoke-test, seed-load, structural validation) |
| Read sources | `main.regtech` when DE-migrated sources are available |
| Write target | `main.regtech_ops_stg` only — **never** `main.regtech` |
| Generated prefix | `bi_output_regtechops_` |
| Seed prefix | `bi_output_regtechops_seed_` |
| CSV seeds | Approved extracts in secure storage only — **not Git** |

**Allowed:** staging job/workflow skeletons; smoke-test runs; CSV seed loads; ext/staging/audit tests without final PII; `development_structural_test`; masked customer for structural tests.

**Not allowed:** `main.regtech` writes; production schedules; delivery/upload/response; final parity claims without MAG closure; seed CSVs in Git.

## Step 18 pre-activation evidence gate

Before treating this runbook as actionable for any run (including dry-run), confirm:

1. [final_repository_audit.md](final_repository_audit.md) (Step 18A) — preparation complete; **not execution-ready** while blockers remain.
2. [final_handoff_package.md](final_handoff_package.md) and [handoff_index.md](handoff_index.md) (Step 18B) — role actions and transition criteria understood.
3. [open_blockers_for_execution.md](open_blockers_for_execution.md) — no unresolved hard blockers for the intended run mode.
4. [manual_approval_gates.md](manual_approval_gates.md) — applicable MAG gates **CLOSED** with external evidence.
5. [post_blocker_execution_plan.md](post_blocker_execution_plan.md) — team aligned on post-blocker sequence if enabling execution.

If any item above fails for the **intended run mode**, remain in documentation-only mode or restrict to permitted staging smoke tests. Do not deploy production schedules or write to `main.regtech`.

## Pre-run policy notes

NOC and old Databricks attempt materials remain reference-only and are not implementation authority.

**Repository authority:** Cursor-authored workflow YAML and docs in this repository are the source of truth. If Databricks UI, Genie, or manual workspace editing is used to adapt a workflow, copy the accepted change back into the repository and commit it. Do not allow untracked workflow drift in the workspace.

## Pre-run checklist

Before any execution enablement, confirm:

- `docs/open_blockers_for_execution.md` blockers are closed or formally waived.
- `docs/execution_prerequisites.md` checklist is completed.
- Required decisions in `docs/remaining_decisions.md` are approved.
- Manual approvals in `docs/manual_approval_gates.md` are recorded (Step 17C; supersedes checklist use of `docs/workflow_manual_approval_checkpoints.md` for new runs).
- Stop/go criteria in `docs/workflow_governance_controls.md` are satisfied for the intended run type.
- `run_mode`, `dry_run`, and customer-source policy parameters are set correctly.
- `skip_delivery_steps=true` and no delivery/upload/response tasks are included.

## Staging first-run (manual sequence)

For the step-by-step first execution, follow [staging_first_run_plan.md](staging_first_run_plan.md):

- Phase 0 — pre-run checks (git, parameters, no `main.regtech` writes, evidence outside Git)
- Phases 1–8 — default critical path (readiness → static → ext/staging modules → MIFID2_ext non-PII)
- Phase 11 — validation summary + evidence log update
- Phases 9–10 — **optional** (manual seed and RecordID; skip on first pass unless explicitly needed)

Record each phase in an external working copy of [staging_execution_evidence_log.md](staging_execution_evidence_log.md). Staging success is **not** final parity signoff.

### Readiness SQL before Phase 1 execution

Run SELECT-only checks from `databricks/sql/12_staging_readiness/` in order:

1. `04_target_schema_safety_checks.sql`
2. `gate_global_scope.sql`
3. `01_source_table_existence_checks.sql`
4. `02_required_column_checks.sql`
5. `03_row_count_date_range_checks.sql` (after existence PASS)

**Stop on `FAIL`** in steps 1–4 (04, gate, 01, 02). Step 5 (`03`) may emit `TODO`, `RUN_MANUAL`, `NOT_RUN`, or `SKIP` — resolve manual COUNT evidence before claiming full readiness. Store all outputs outside Git. Staging readiness pass is **not** final parity signoff.

**Databricks metadata:** use catalog-scoped `information_schema` (`{{source_catalog}}` / `{{target_catalog}}`, default `main`); avoid `system.information_schema`. For `main.dealing.bronze_pricelog_history_currencyprice`, use report-date or one-hour window COUNT only — not full-table scan.

See [databricks/sql/12_staging_readiness/00_readme.md](../databricks/sql/12_staging_readiness/00_readme.md).

---

## Staging workflow jobs (template-only)

| Order | Job | Purpose |
| --- | --- | --- |
| 1 | `mifid_staging_readiness_job_do_not_deploy` | Readiness SQL — **run first** |
| 2 | `mifid_staging_static_reference_job_do_not_deploy` | Static references and UDF readiness |
| 3 | `mifid_staging_price_currency_split_job_do_not_deploy` | Price/currency/split structural checks |
| 4 | `mifid_staging_non_price_reg_ext_job_do_not_deploy` | Non-price Reg_Ext structural checks |
| 5 | `mifid_staging_regulation_movement_job_do_not_deploy` | Regulation movement snapshots |
| 6 | `mifid_staging_hedge_liquidity_job_do_not_deploy` | Hedge/liquidity structural checks |
| 7 | `mifid_staging_asic2_structural_job_do_not_deploy` | ASIC2 structural subset checks |
| 8 | `mifid_staging_mifid2_ext_non_pii_job_do_not_deploy` | MIFID2_ext non-PII groups |
| 9 | `mifid_staging_manual_seed_testing_job_do_not_deploy` | Optional seed mechanics |
| 10 | `mifid_staging_hedge_recordid_registry_job_do_not_deploy` | Optional RecordID registry |
| 11 | `mifid_staging_validation_summary_job_do_not_deploy` | Cross-module summary and evidence guidance |

YAML: `databricks/workflows/mifid_phase1_staging_jobs.yml`. Combined single-workflow: `mifid_phase1_staging_smoke_test.yml`.
Notebook companion YAML: `databricks/workflows/mifid_phase1_staging_notebook_jobs.yml`.

If `system.information_schema` permissions block Job 1, use catalog-scoped checks (`main.information_schema.*`) or manual inline evidence per `12_staging_readiness/00_readme.md`.

**Cross-job dependencies (manual):** this skeleton does not configure automatic Databricks triggers between jobs. Run jobs one-by-one in repository order: Job 1 first, then Jobs 2–8, then Job 11. Jobs 9–10 are optional and not on the default first-run path. Do not assume automatic cross-job dependency unless operators configure it manually in Databricks.

Notebook companion jobs follow the same order and gating. For notebook path first pass: start with readiness notebook only, then run one module group at a time.

See [remaining_migration_work_checklist.md](remaining_migration_work_checklist.md) for the consolidated map of ready-to-test staging modules, optional mechanics, gated final flows, final-parity prerequisites, and DE production adaptation inputs.

**SQL placeholders vs job parameters:** readiness/module SQL may use `{{source_catalog}}`, `{{target_schema}}`, etc.; workflow YAML uses job parameters. Ensure consistent substitution when running SQL manually or in Databricks tasks. `gate_global_scope.sql` uses `{{job.parameters.*}}`. Defaults below.

---

## Staging smoke-test / seed-load run path

Intended purpose: staging validation in `main.regtech_ops_stg` — not final parity.

**First execution:** Job 1 only, then Jobs 2–8 one-by-one after readiness evidence is accepted, then Job 11. Jobs 9–10 remain optional.

| Parameter | Default |
| --- | --- |
| `source_catalog` / `source_schema` | `main` / `regtech` |
| `target_catalog` / `target_schema` | `main` / `regtech_ops_stg` |
| `object_prefix` | `bi_output_regtechops_` |
| `run_mode` | `development_structural_test` |
| `dry_run` | `true` (default safe mode) |
| `staging_execution_approved` | `false` (must be `true` for `dry_run=false`) |
| `enable_masked_customer_structural_tests` | `false` |
| `enable_manual_seed_testing_checks` | `false` |
| `skip_delivery_steps` | `true` |

**Default critical path:** source readiness → static refs → price/currency/split → non-price Reg_Ext → regulation movements → hedge/liquidity ext → ASIC2 structural → MIFID2_ext non-PII → validation summary.

**Optional groups (not in default path):** masked customer (`enable_masked_customer_structural_tests`); manual seed (`enable_manual_seed_testing_checks`). Neither is required for the first smoke-test pass.

### dry_run modes

| `dry_run` | Mode | GATE-03 |
| --- | --- | --- |
| `true` (default) | Readiness/check-only; template-safe | PASS |
| `false` | Staging execution in `development_structural_test` only | PASS_WITH_LIMITS when `staging_execution_approved=true` and MAG-18 closed |

`dry_run=false` is **not** production execution. Writes remain `main.regtech_ops_stg` only. First runs should keep `dry_run=true` until MAG-18 and explicit staging approval.

- `run_mode=development_structural_test`
- Writes target `main.regtech_ops_stg` only (`bi_output_regtechops_` / `bi_output_regtechops_seed_`)
- Read `main.regtech` when DE-migrated; enforced by GATE-06 in `gate_global_scope.sql`
- Approved CSV seed loads via `databricks/sql/11_seed_testing/` when optional manual seed group is enabled — see [manual_seed_testing_plan.md](manual_seed_testing_plan.md)
- Masked customer optional group: `enable_masked_customer_structural_tests=true`, `allow_masked_customer_sources=true`, MAG-05 CLOSED

Allowed outcomes:

- Seed table load and row-count/key validation
- Ext/staging/audit table smoke tests
- Schema/required-column checks
- Row-count and join-path checks against `main.regtech` read sources

Not allowed:

- Writes to `main.regtech`
- Final parity or production readiness claims
- Regulatory delivery/upload/response

## Development / structural-test run path

Intended purpose: structural validation only (subset of staging smoke-test path).

- `run_mode=development_structural_test`
- `dry_run=true` (default) for first-pass readiness checks
- `dry_run=false` only with `staging_execution_approved=true` and MAG-18 — not production
- `dev_customer_source_mode=masked_fallback` only when explicitly approved
- `allow_masked_customer_sources=true` only for structural checks
- `enable_validation_only=true`

Allowed outcomes:

- Schema/required-column checks
- Row-count and join-path checks
- Validation package evidence capture

Not allowed:

- Final parity sign-off
- Final customer/NPD parity certification (NPD seed test is staging evidence only until PII/MAG gates close)

## Parity run path (pre-final)

Intended purpose: final parity readiness checks after blocker closure.

- `run_mode=final_parity_production`
- `dry_run=true` until final go/no-go sign-off
- `dev_customer_source_mode=pii_required`
- `allow_masked_customer_sources=false`
- `require_unmasked_pii_for_parity=true`

Required inputs:

- Unmasked PII sources available or formal approval exception documented.
- Storage/catalog/access blockers closed.
- History/seed decisions approved.

## Final production-candidate run path

This remains blocked in Step 17B and requires explicit approval.

Preconditions:

- Manual approvals all closed.
- Validation evidence complete and accepted.
- SQL Server baseline comparison completed where required.
- Separate deployment authorization granted.

## Validation evidence required

- Module-level validation outputs in execution order.
- Cross-module validation outputs from `databricks/sql/09_validation/`.
- Gate wrapper outputs from `databricks/sql/10_workflow/gates/`.
- Per-phase staging evidence per [staging_execution_evidence_log.md](staging_execution_evidence_log.md) — stored **outside repo**.
- SQL Server baseline evidence per [validation_evidence_plan.md](validation_evidence_plan.md) — extracts requested via [baseline_scenario_request.md](baseline_scenario_request.md); required for **final parity**, not first staging pass.
- Documented unresolved deltas and owner decisions.

## Manual approval and stop/go references

| Run type | Governance reference |
| --- | --- |
| Development dry run | `docs/workflow_governance_controls.md` — Development dry run may proceed only when |
| Parity run | `docs/workflow_governance_controls.md` — Parity run may proceed only when |
| Production-candidate run | `docs/workflow_governance_controls.md` — Production-candidate run may proceed only when |

Record approvals using placeholders in `docs/manual_approval_gates.md` (Jira ticket, owner, date, evidence location).

## Rollback and stop criteria

Stop immediately if:

- Any blocker in `docs/open_blockers_for_execution.md` reopens.
- Run mode/policy mismatch is detected (for example masked fallback in final parity mode).
- Required approvals are missing.
- Validation packages report unresolved hard-gate failures.
- Out-of-scope actions are requested (delivery/upload/response or production deployment).

Rollback action in this step:

- Halt further staging runs; do not promote to production schedules or final parity paths.
- Keep workflow definitions **template-only / `do_not_deploy`** (no production deployment).
- Revert to validation-only / `dry_run=true` mode where applicable and update blocker/decision docs.
- Approved `development_structural_test` runs may resume only after stop criteria are cleared — this is **not** production readiness.

## What not to run

- Do not deploy `mifid_phase1_staging_smoke_test.yml` or other skeletons until blockers/MAG gates allow.
- Do not deploy staging jobs to **production schedules** or adapt them as production-grade without DE's separate program.
- Do not write to `main.regtech` from RegTech staging jobs.
- Do not run regulatory delivery/upload/response logic.
- Do not activate final NPD_TRAX, final Failed_TRAX, Hedge report, or PII customer parity from the smoke-test workflow.
- Do not claim final regulatory parity without MAG closure.

**Permitted (when approved):** execute staging-only smoke-test and seed-load jobs scoped to `main.regtech_ops_stg` per this runbook.
