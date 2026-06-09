# Staging Readiness SQL Package (SELECT-only)

## Purpose

SELECT-only source and target readiness checks for the **first runnable staging smoke-test groups** (Phases 1–8 per [docs/staging_first_run_plan.md](../../../docs/staging_first_run_plan.md)).

**No DDL/DML.** No writes to `main.regtech`. No table creation. No production deployment.

---

## Databricks metadata compatibility

Use **catalog-scoped** `information_schema` in Unity Catalog:

| Purpose | Views |
| --- | --- |
| Source metadata | `{{source_catalog}}.information_schema.tables`, `.columns`, `.schemata` |
| Target metadata | `{{target_catalog}}.information_schema.tables`, `.columns`, `.schemata` |

**Do not use** `system.information_schema.*` — it may fail with `[INSUFFICIENT_PERMISSIONS] User does not have USE SCHEMA on Schema 'system.information_schema'`.

When `source_catalog` and `target_catalog` both default to `main`, `main.information_schema.*` is equivalent.

---

## Environment parameters

Substitute before execution (workflow jobs may map from `job.parameters.*`):

| Parameter | Default |
| --- | --- |
| `{{source_catalog}}` | `main` |
| `{{source_schema}}` | `regtech` |
| `{{target_catalog}}` | `main` |
| `{{target_schema}}` | `regtech_ops_stg` |
| `{{object_prefix}}` | `bi_output_regtechops_` |
| `{{report_date}}` | `YYYY-MM-DD` |
| `{{skip_delivery_steps}}` | `true` (target safety file only; must substitute exactly `true`) |

---

## Files and run order (Databricks execution)

Run in this order before staging smoke-test Phase 1:

| Order | File | Check groups |
| --- | --- | --- |
| 1 | `04_target_schema_safety_checks.sql` | Target policy — `main.regtech_ops_stg` only; no `main.regtech` writes |
| 2 | `databricks/sql/10_workflow/gates/gate_global_scope.sql` | Global scope gate (GATE-01–08) |
| 3 | `01_source_table_existence_checks.sql` | All manifest sources — table visibility |
| 4 | `02_required_column_checks.sql` | Required-column contracts per source |
| 5 | `03_row_count_date_range_checks.sql` | Row counts and date-window coverage (after 01 passes) |

**Stop on `FAIL`** in steps 1, 2, 3, and 4. Step 5 may return `TODO`, `RUN_MANUAL`, `NOT_RUN`, or `SKIP` rows that must be resolved (manual COUNT evidence) before claiming full readiness.

---

## Reg_CurrencyPrice_Ext source policy

| Source | Object | Readiness role |
| --- | --- | --- |
| **Preferred (required)** | `main.dealing.bronze_pricelog_history_currencyprice` | Required for `Reg_CurrencyPrice_Ext` readiness — `FAIL` if missing |
| **Fallback (optional)** | `main.trading.bronze_etoro_trade_currencyprice` | Readable but not preferred — `SKIP`/`WARN` in 02/03; does **not** satisfy readiness |

---

## Unified result columns

Each file returns:

| Column | Description |
| --- | --- |
| `check_group` | Logical group (e.g. `price_currency_split`) |
| `object_name` | Fully qualified or logical object name |
| `check_name` | e.g. `table_exists`, `required_column`, `row_count`, `target_schema` |
| `expected` | Expected value or rule |
| `actual` | Observed value |
| `status` | `PASS`, `FAIL`, `WARN`, `TODO`, `SKIP`, `NOT_RUN`, `RUN_MANUAL` |
| `notes` | Manifest status, TODO, or remediation hint |

**Stop execution** if any `FAIL` on a required check in files 04, gate, 01, or 02. Document results in external copy of [docs/staging_execution_evidence_log.md](../../../docs/staging_execution_evidence_log.md).

---

## Evidence policy

- Store query outputs in **secure storage outside Git**
- No PII samples in evidence attachments
- Staging readiness pass is **not** final parity signoff
- Failures must halt staging smoke-test progression per first-run stop criteria (S1–S10)
- `03_row_count_date_range_checks.sql` uses catalog-scoped `information_schema` visibility only — execute documented manual COUNTs for `RUN_MANUAL` rows and record evidence externally
- `main.dealing.bronze_pricelog_history_currencyprice` is extremely large — **do not** run full-table `COUNT(*)` for first-run readiness; use report-date or one-hour lookback window only

---

## Manifest / TODO policy

Some `main.regtech` DE-migrated object names are **placeholders** until DE certifies exact gold table names. Rows with `status=TODO`, `RUN_MANUAL`, or `NOT_RUN` require SME/DE confirmation or manual evidence before treating as full readiness PASS.

Primary bronze/dealing sources are more concrete; regtech gold names follow patterns from module `*_source_profiling.sql` files.

Manifest flags in SQL: `is_todo`, `is_optional`, `is_fallback` — consistent across `01`, `02`, and `03`.

---

## Related documents

- [docs/staging_first_run_plan.md](../../../docs/staging_first_run_plan.md)
- [docs/staging_execution_evidence_log.md](../../../docs/staging_execution_evidence_log.md)
- [docs/reporting_job_preparation_plan.md](../../../docs/reporting_job_preparation_plan.md)
