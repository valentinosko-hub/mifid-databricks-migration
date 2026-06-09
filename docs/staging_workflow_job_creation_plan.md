# Staging Workflow Job Creation Plan — MiFID RegTechOps

## Purpose

Defines **template-only** Databricks workflow job wiring for MiFID RegTechOps staging execution in `main.regtech_ops_stg`. These are staging workflow job definitions only — **not** production deployment artifacts.

**Status:** Template-only. Repository is **not production-ready**. Data Engineering may adapt job definitions later for production criteria.

**Repository authority:** Cursor-authored YAML and docs in this repository remain the **source of truth** for workflow definitions. If Databricks UI, Genie, or manual workspace editing is used to adapt a workflow, the accepted change must be copied back into the repository and committed. Databricks UI/Genie edits must not become untracked workflow drift.

**Workflow files:**

| File | Jobs |
| --- | --- |
| `databricks/workflows/mifid_phase1_staging_jobs.yml` | **Canonical** split jobs 1–4 |
| `databricks/workflows/mifid_phase1_staging_smoke_test.yml` | Combined readiness + ext view (backward reference) |

**Parameters:** `databricks/config/workflow_parameters.yml`

---

## Environment defaults

| Parameter | Default |
| --- | --- |
| `source_catalog` / `source_schema` | `main` / `regtech` |
| `target_catalog` / `target_schema` | `main` / `regtech_ops_stg` |
| `object_prefix` | `bi_output_regtechops_` |
| `run_mode` | `development_structural_test` |
| `dry_run` | `true` |
| `skip_delivery_steps` | `true` |
| `staging_execution_approved` | `false` |
| Schedule | None |
| Deployment | Blocked (`do_not_deploy` job names) |

**Write:** `main.regtech_ops_stg` only — **never** `main.regtech`.

---

## Databricks metadata compatibility

Readiness and validation SQL use **catalog-scoped** `information_schema`:

- `{{source_catalog}}.information_schema.tables` / `.columns` (default `main`)
- `{{target_catalog}}.information_schema.schemata` (default `main`)

**Do not use** `system.information_schema` — it may fail with:

`[INSUFFICIENT_PERMISSIONS] User does not have USE SCHEMA on Schema 'system.information_schema'`

**Fallback:** if automated readiness tasks fail on metadata permissions, operators may run equivalent **manual inline checks** (target safety, gate, source existence, columns) and record evidence in secure storage outside Git before proceeding.

---

## Large-table COUNT guidance

`main.dealing.bronze_pricelog_history_currencyprice` is extremely large. First-run readiness must **not** require full-table `COUNT(*)`. Use report-date or one-hour lookback window checks only (`03_row_count_date_range_checks.sql` `RUN_MANUAL` notes).

---

## Job 1 — `mifid_staging_readiness_job_do_not_deploy`

**Run first.** Stop on `FAIL` / `BLOCK`. Review `TODO` / `SKIP` / `RUN_MANUAL` before Job 2.

| Order | Task | SQL |
| --- | --- | --- |
| 1 | `target_schema_safety_checks` | `12_staging_readiness/04_target_schema_safety_checks.sql` |
| 2 | `global_scope_gate` | `10_workflow/gates/gate_global_scope.sql` |
| 3 | `source_table_existence_checks` | `12_staging_readiness/01_source_table_existence_checks.sql` |
| 4 | `required_column_checks` | `12_staging_readiness/02_required_column_checks.sql` |
| 5 | `row_count_date_range_checks` | `12_staging_readiness/03_row_count_date_range_checks.sql` |

Evidence: external copy of [staging_execution_evidence_log.md](staging_execution_evidence_log.md).

---

## Job 2 — `mifid_staging_ext_tables_job_do_not_deploy`

**Run only after Job 1 passes** or documented acceptance of `TODO` / `SKIP` / `RUN_MANUAL` items.

| Order | Task group | Primary SQL |
| --- | --- | --- |
| 1 | `static_reference_checks` | `validation/02_static_reference_required_columns.sql` |
| 2 | `price_currency_split_ext_staging` | `03_pre_regulation_ext/03_price_currency_validation.sql` |
| 3 | `non_price_reg_ext_staging` | `03_pre_regulation_ext/06_non_price_validation.sql` |
| 4 | `regulation_movement_staging` | `04_regulation_movements/03_regulation_movments_validation.sql` |
| 5 | `hedge_liquidity_ext_staging` | `05_hedge_liquidity/04_hedge_liquidity_validation.sql` |
| 6 | `asic2_structural_staging` | `06_asic2_subset/06_asic2_validation.sql` |
| 7 | `mifid2_ext_non_pii_staging` | `07_mifid2_ext/07_mifid2_ext_validation.sql` |
| 8 | `validation_summary` | **Primary:** `10_workflow/gates/gate_cross_module_readiness.sql`; **supporting:** `09_validation/07_phase1_readiness_summary.sql` |

`dry_run=true` (default): validation/gate SQL only. Staging materialization SQL (`*_staging.sql` with DDL) is documented per module — enable only with `dry_run=false`, `staging_execution_approved=true`, and MAG-18.

**Excluded from Job 2:** `07_mifid2_ext/06_failed_trax_staging.sql`, final NPD_TRAX, final Hedge report, customer PII paths.

---

## Job 3 — `mifid_staging_optional_seed_job_do_not_deploy` (optional)

**Disabled by default.** `enable_manual_seed_testing_checks=false`.

| Task | SQL |
| --- | --- |
| `manual_seed_table_scaffold` | `11_seed_testing/01_create_manual_seed_external_tables.sql` |
| `load_npd_seed_csv_template` | `11_seed_testing/02_load_mifid2_npd_trax_csv_template.sql` |
| `load_hedge_seed_csv_template` | `11_seed_testing/03_load_mifid2_hedge_report_csv_template.sql` |
| `manual_seed_validation` | `11_seed_testing/04_manual_seed_validation.sql` |

Rules:

- CSV in approved secure storage only — **not Git**
- NPD CSV may test load mechanics only; **final NPD CSV regenerated** when NPD step is reached
- **No final NPD_TRAX activation**

See [manual_seed_testing_plan.md](manual_seed_testing_plan.md).

---

## Job 4 — `mifid_staging_hedge_recordid_registry_job_do_not_deploy` (optional)

**After Hedge seed available.** Does not activate final `MIFID2_Hedge_Report`.

| Task | SQL |
| --- | --- |
| `hedge_recordid_registry_scaffold` | `08_outputs/10_hedge_recordid_registry/01_hedge_recordid_registry_scaffold.sql` |
| `hedge_recordid_seed_from_history` | `08_outputs/10_hedge_recordid_registry/02_hedge_recordid_seed_from_sql_server.sql` |
| `hedge_recordid_allocation_template` | `08_outputs/10_hedge_recordid_registry/03_hedge_recordid_allocation_template.sql` |
| `hedge_recordid_validation` | `08_outputs/10_hedge_recordid_registry/04_hedge_recordid_validation.sql` |

Gated until: seed data, natural-key SME signoff (MAG-12), validation pass. See [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md).

---

## Explicitly excluded from all staging jobs

| Exclusion | Gate |
| --- | --- |
| Final `MIFID2_NPD_TRAX` | MAG-10 — **final-flow last** |
| Final `MIFID2_Failed_TRAX` | NPD dependency |
| Final `MIFID2_Hedge_Report` | MAG-12/MAG-13; RecordID registry |
| Final customer/NPD parity | MAG-06; `main.pii_data` |
| Delivery / upload / response | Out of repo scope |
| Production deployment / schedules | Separate DE program |
| Writes to `main.regtech` | Forbidden |

---

## First execution sequence

1. **Job 1 only** — record readiness evidence externally
2. Resolve `RUN_MANUAL` COUNT evidence; close or accept `TODO`/`SKIP`
3. **Job 2** — ext/staging validation path
4. **Jobs 3–4** — only when optional flags and approvals allow

**Cross-job dependencies:** there is **no automatic Databricks trigger** between Job 1 and Job 2 in this skeleton. Operators must run Job 1 first and retain external evidence before starting Job 2. Jobs 3–4 are optional and outside the default critical path.

### SQL placeholders vs job parameters

| Style | Used in |
| --- | --- |
| `{{source_catalog}}`, `{{target_schema}}`, `{{report_date}}`, … | `12_staging_readiness/*`, many module SQL templates |
| `{{job.parameters.source_catalog}}`, … | `gate_global_scope.sql` |

Ensure consistent substitution when executing SQL manually or wiring Databricks SQL tasks. Defaults: `source_catalog=main`, `source_schema=regtech`, `target_catalog=main`, `target_schema=regtech_ops_stg`, `object_prefix=bi_output_regtechops_`, `run_mode=development_structural_test`, `dry_run=true`, `skip_delivery_steps=true`.

Staging readiness/ext success is **not** final regulatory parity signoff.

---

## Remaining blockers / gates (summary)

| Item | Reference |
| --- | --- |
| MAG-18 | Staging execution (`dry_run=false`) |
| MAG-01–04 | Minimum structural smoke test |
| MAG-05 | Masked customer optional path |
| MAG-06 | Final PII parity |
| MAG-10 | NPD_TRAX final flow |
| MAG-12/MAG-13 | Hedge / RecordID |
| MAG-16 | SQL Server baseline |
| `system.information_schema` permissions | Use catalog-scoped or manual checks |
| SQL warehouse ID | Replace placeholder before any deployment authorization |

See [open_blockers_for_execution.md](open_blockers_for_execution.md), [manual_approval_gates.md](manual_approval_gates.md), [post_blocker_execution_plan.md](post_blocker_execution_plan.md).

---

## Related documents

- [staging_first_run_plan.md](staging_first_run_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
- [reporting_job_preparation_plan.md](reporting_job_preparation_plan.md)
- [staging_execution_evidence_log.md](staging_execution_evidence_log.md)
- [databricks/workflows/README.md](../databricks/workflows/README.md)
