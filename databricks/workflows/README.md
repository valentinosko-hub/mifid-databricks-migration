# Workflow Skeletons (Step 17B + Staging Jobs)

This folder contains **template-only** workflow artifacts for Phase 1 MiFID work in `main.regtech_ops_stg`.

**Template-only / `do_not_deploy` workflow definitions.** Approved staging smoke-test runs are permitted under `development_structural_test` controls and documented MAG/staging approval. Production deployment and scheduling remain blocked.

## Workflows

| File | Purpose | Status |
| --- | --- | --- |
| `mifid_phase1_staging_jobs.yml` | **Canonical** split staging jobs (readiness, ext, optional seed, RecordID) | Template-only; **do not deploy** |
| `mifid_phase1_staging_smoke_test.yml` | Combined readiness + ext validation (backward reference) | Template-only; **do not deploy** |
| `mifid_phase1_table_generation.yml` | Full table/report generation ordering skeleton | Template-only; **do not deploy** |

Shared parameter defaults: `databricks/config/workflow_parameters.yml`  
Job creation plan: `docs/staging_workflow_job_creation_plan.md`

---

## Staging jobs package (`mifid_phase1_staging_jobs.yml`)

Four template jobs — names include `do_not_deploy`. No schedule. `dry_run=true` default. **No automatic cross-job triggers** — run Job 1 before Job 2 manually; Jobs 3–4 optional.

| Job | Name | When to run |
| --- | --- | --- |
| **1** | `mifid_staging_readiness_job_do_not_deploy` | **Always first** — readiness SQL 04→gate→01→02→03 |
| **2** | `mifid_staging_ext_tables_job_do_not_deploy` | After Job 1 PASS or accepted TODO/SKIP/RUN_MANUAL |
| **3** | `mifid_staging_optional_seed_job_do_not_deploy` | Optional — manual seed mechanics only |
| **4** | `mifid_staging_hedge_recordid_registry_job_do_not_deploy` | Optional — Hedge RecordID registry test |

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

### Job 2 task groups (ext/staging validation)

`static_reference_checks` → `price_currency_split_ext_staging` → `non_price_reg_ext_staging` → `regulation_movement_staging` → `hedge_liquidity_ext_staging` → `asic2_structural_staging` → `mifid2_ext_non_pii_staging` → `validation_summary`

Primary SQL: module `*_validation.sql` files. Staging materialization (`*_staging.sql`) gated for `dry_run=false` + MAG-18.

### Optional jobs 3–4

- **Seed:** `11_seed_testing/*` — CSV in secure storage only; no final NPD_TRAX
- **RecordID:** `08_outputs/10_hedge_recordid_registry/*` — no final Hedge report

### Excluded from all staging jobs

Final NPD_TRAX, Failed_TRAX, Hedge report, customer/NPD parity, delivery/upload/response, production schedules, `main.regtech` writes.

---

## Combined smoke-test workflow (`mifid_phase1_staging_smoke_test.yml`)

Single-workflow view of Job 1 + Job 2 chains. Prefer split jobs for first execution. Optional seed/RecordID: use Jobs 3–4 in `mifid_phase1_staging_jobs.yml`.

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
