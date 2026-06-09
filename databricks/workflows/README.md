# Workflow Skeletons (Step 17B + Staging Jobs)

This folder contains **template-only** workflow artifacts for Phase 1 MiFID work in `main.regtech_ops_stg`.

**Template-only / `do_not_deploy` workflow definitions.** Approved staging smoke-test runs are permitted under `development_structural_test` controls and documented MAG/staging approval. Production deployment and scheduling remain blocked.

## Workflows

| File | Purpose | Status |
| --- | --- | --- |
| `mifid_phase1_staging_jobs.yml` | **Canonical** split staging jobs (Jobs 1–11, manual one-by-one sequence) | Template-only; **do not deploy** |
| `mifid_phase1_staging_smoke_test.yml` | Combined readiness + ext validation (backward reference) | Template-only; **do not deploy** |
| `mifid_phase1_table_generation.yml` | Full table/report generation ordering skeleton | Template-only; **do not deploy** |

Shared parameter defaults: `databricks/config/workflow_parameters.yml`  
Job creation plan: `docs/staging_workflow_job_creation_plan.md`

---

## Staging jobs package (`mifid_phase1_staging_jobs.yml`)

Eleven template jobs — names include `do_not_deploy`. No schedule. `dry_run=true` default. **No automatic cross-job triggers** — operators run jobs manually one-by-one in order.

| Job | Name | When to run |
| --- | --- | --- |
| **1** | `mifid_staging_readiness_job_do_not_deploy` | **Always first** — readiness SQL 04→gate→01→02→03 |
| **2** | `mifid_staging_static_reference_job_do_not_deploy` | After Job 1 evidence accepted |
| **3** | `mifid_staging_price_currency_split_job_do_not_deploy` | After Job 2 |
| **4** | `mifid_staging_non_price_reg_ext_job_do_not_deploy` | After Job 3 |
| **5** | `mifid_staging_regulation_movement_job_do_not_deploy` | After Job 4 |
| **6** | `mifid_staging_hedge_liquidity_job_do_not_deploy` | After Job 5 |
| **7** | `mifid_staging_asic2_structural_job_do_not_deploy` | After Job 6 |
| **8** | `mifid_staging_mifid2_ext_non_pii_job_do_not_deploy` | After Job 7 |
| **9** | `mifid_staging_manual_seed_testing_job_do_not_deploy` | Optional — manual seed mechanics only |
| **10** | `mifid_staging_hedge_recordid_registry_job_do_not_deploy` | Optional — Hedge RecordID registry |
| **11** | `mifid_staging_validation_summary_job_do_not_deploy` | Run after Job 8 for cross-module readiness/evidence |

### Environment policy

- **Read:** `main.regtech` (primary)
- **Metadata:** catalog-scoped `information_schema` (`main.information_schema.*`) — **not** `system.information_schema`
- **Write:** `main.regtech_ops_stg` with `bi_output_regtechops_` prefix
- **Defaults:** `run_mode=development_structural_test`, `dry_run=true`, `skip_delivery_steps=true`

### Job 1 tasks (readiness)

1. `target_schema_safety_checks` → `12_staging_readiness/04_*.sql`
2. `global_scope_gate` → `gates/gate_global_scope.sql`
3. `source_table_existence_checks` → `12_staging_readiness/01_*.sql`
4. `required_column_checks` → `12_staging_readiness/02_*.sql`
5. `row_count_date_range_checks` → `12_staging_readiness/03_*.sql`

Stop on `FAIL`/`BLOCK`. Manual inline checks allowed if metadata permissions block automation.

### Job groups 2–8 and 11 (critical path)

`static_reference` → `price_currency_split` → `non_price_reg_ext` → `regulation_movement` → `hedge_liquidity` → `asic2_structural` → `mifid2_ext_non_pii` → `validation_summary`

Primary SQL paths use existing structural/validation files. Where exact one-task-per-table mapping is still being finalized, YAML includes explicit TODO notes (no new business logic added).

### Optional jobs 9–10

- **Manual seed:** `11_seed_testing/*` — CSV in secure storage only; no final NPD_TRAX activation
- **RecordID registry:** `08_outputs/10_hedge_recordid_registry/*` — no final Hedge report activation

### Excluded from all staging jobs

Final NPD_TRAX, Failed_TRAX, Hedge report, customer/NPD parity, delivery/upload/response, production schedules, `main.regtech` writes.

---

## Combined smoke-test workflow (`mifid_phase1_staging_smoke_test.yml`)

Single-workflow backward view of readiness + critical-path checks. Prefer split jobs for execution. Optional seed/RecordID: use Jobs 9–10 in `mifid_phase1_staging_jobs.yml`.

---

## Table-generation workflow (`mifid_phase1_table_generation.yml`)

Broader Phase 1 ordering skeleton including customer outputs, reports, hedge, and NPD placeholders. Remains execution-gated separately.

---

## Important status (all workflows)

- Template-only / `do_not_deploy` workflow definitions — approved staging smoke-test runs permitted under controls; not production deployment artifacts
- No workflow deployment to production schedules from this repo step without explicit authorization
- No CSV/7z/SFTP delivery, TRAX upload, or response handling
- No production deployment to `main.regtech`
- Repository is **not production-ready**
- DE may adapt job definitions later for production criteria
- Repository/Cursor-authored YAML+docs remain source of truth; copy accepted Databricks UI/Genie edits back into Git to avoid drift

## Policy reminders

- Masked customer: development/structural-test only when `enable_masked_customer_structural_tests=true` and MAG-05 CLOSED
- Final parity: `main.pii_data` + MAG-06
- NPD_TRAX: **final-flow last** (MAG-10)
- Hedge: gated on RecordID registry (MAG-12/MAG-13)
- NOC and old Databricks attempt: reference-only

## Related docs

- `docs/staging_workflow_job_creation_plan.md`
- `docs/staging_first_run_plan.md`
- `docs/reporting_job_preparation_plan.md`
- `docs/workflow_execution_runbook.md`
- `docs/manual_approval_gates.md`
