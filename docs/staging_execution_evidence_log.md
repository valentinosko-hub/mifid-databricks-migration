# Staging Execution Evidence Log — Template

## Purpose

Template for recording **MiFID RegTechOps staging smoke-test** run evidence. This file defines the log schema and example rows. **Do not store PII, raw extracts, or full query outputs in Git.**

**Status:** Evidence template only. Populate a **working copy in secure storage** (SharePoint, ticket system, Databricks volume path, etc.) for each run.

**First-run plan:** [staging_first_run_plan.md](staging_first_run_plan.md)

---

## Policy

| Rule | Detail |
| --- | --- |
| Storage | Evidence files and outputs live **outside Git** |
| Repo file | This document is the schema/template reference only |
| Staging success | **Not** final parity signoff |
| Final parity | Requires SQL Server baseline comparison ([validation_evidence_plan.md](validation_evidence_plan.md)), MAG-16, and closure of applicable MAG gates |
| PII | No customer-identifying samples in log entries or attachments |
| NOC / old Databricks attempt | Reference-only |

---

## Run header (copy per execution)

```text
=== Staging Run Header ===
run_id:           RUN-YYYYMMDD-###
report_date:      YYYY-MM-DD
git_branch:       _______________
git_commit:       _______________
workflow_job_1:   mifid_staging_readiness_job_do_not_deploy
workflow_job_2:   mifid_staging_ext_tables_job_do_not_deploy
workflow_combined: mifid_phase1_staging_smoke_test_skeleton_do_not_deploy
source_catalog:   main
source_schema:    regtech
target_catalog:   main
target_schema:    regtech_ops_stg
object_prefix:    bi_output_regtechops_
run_mode:         development_structural_test
dry_run:          true
staging_execution_approved: false
owner:            _______________
started_at_utc:   _______________
completed_at_utc: _______________
evidence_root:    [secure path — not Git]
parity_claim:     NO — staging structural evidence only
```

---

## Evidence log table

Copy this table into your external working copy for each run. One row per phase/task group (or per validation file if finer granularity is needed).

| run_id | report_date | phase / task group | source catalog | source schema | target catalog | target schema | run_mode | dry_run | status | row_count_before | row_count_after | validation_file | validation_result | error_summary | evidence_link | owner | timestamp_utc |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 0 — pre-run | main | regtech | main | regtech_ops_stg | development_structural_test | true | PASS / FAIL / STOP | — | — | gate_global_scope.sql | GATE-01–08 summary | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Job 1 / Phase 1 — readiness | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | mifid_staging_readiness_job; 12_staging_readiness/04→gate→01→02→03; catalog-scoped information_schema or manual fallback | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 2 — static_reference_checks | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | validation/01_*–07_* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 3 — price_currency_split_ext_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 03_pre_regulation_ext/03_* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 4 — non_price_reg_ext_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 03_pre_regulation_ext/06_* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 5 — regulation_movement_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 04_regulation_movements/* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 6 — hedge_liquidity_ext_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 05_hedge_liquidity/* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 7 — asic2_structural_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 06_asic2_subset/* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 8 — mifid2_ext_non_pii_staging | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | 07_mifid2_ext/* | | | [secure link] | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 9 — masked_customer (optional) | main | regtech | main | regtech_ops_stg | development_structural_test | true | SKIPPED | — | — | — | N/A — not run first pass | | | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 10 — manual_seed (optional) | main | regtech | main | regtech_ops_stg | development_structural_test | true | SKIPPED | — | — | 11_seed_testing/04_* | N/A — not run first pass | | | | |
| RUN-YYYYMMDD-001 | YYYY-MM-DD | Phase 11 — validation_summary | main | regtech | main | regtech_ops_stg | development_structural_test | true | | | | gate_cross_module_readiness.sql (primary); 09_validation/07_* supporting | | | [secure link] | | |

### Column definitions

| Column | Description |
| --- | --- |
| `run_id` | Unique run identifier (e.g. `RUN-20260605-001`) |
| `report_date` | Report date under test |
| `phase / task group` | Maps to [staging_first_run_plan.md](staging_first_run_plan.md) phase |
| `source catalog` / `source schema` | Read policy — default `main` / `regtech` |
| `target catalog` / `target schema` | Write policy — default `main` / `regtech_ops_stg` |
| `run_mode` | Default `development_structural_test` |
| `dry_run` | Default `true` for first pass |
| `status` | `PASS`, `FAIL`, `STOP`, `SKIPPED`, `PASS_WITH_LIMITS` |
| `row_count_before` | Pre-run / source count where applicable |
| `row_count_after` | Post-run / staging count where applicable |
| `validation_file` | SQL file or gate executed |
| `validation_result` | Short result summary (no PII) |
| `error_summary` | Failure reason if status ≠ PASS |
| `evidence_link` | URL or path to secure storage artifact |
| `owner` | Operator name or role |
| `timestamp_utc` | Phase completion time (UTC) |

---

## Status values

| Status | Meaning |
| --- | --- |
| `PASS` | Phase completed; no blocking issues |
| `PASS_WITH_LIMITS` | Completed with documented limits (e.g. dev fallback source, structural-only) |
| `FAIL` | Validation failed; investigate before retry |
| `STOP` | Run halted per stop criteria in [staging_first_run_plan.md](staging_first_run_plan.md) |
| `SKIPPED` | Optional phase not executed (default first pass) |

---

## Stop event log (if run halted)

| run_id | stop_code | stop_reason | phase | owner | timestamp_utc | evidence_link |
| --- | --- | --- | --- | --- | --- | --- |
| | S1–S10 | | | | | |

Stop codes: see [staging_first_run_plan.md](staging_first_run_plan.md) § Stop criteria.

---

## Final parity disclaimer (required footer per run)

```text
This staging run does NOT constitute final regulatory parity signoff.
Final parity requires:
- SQL Server baseline comparison per docs/validation_evidence_plan.md
- MAG-16 and applicable MAG gate closure
- Unmasked PII or formal exception for customer/NPD parity (MAG-06)
- NPD_TRAX remains final-flow last (MAG-10)
- Hedge activation gated on RecordID registry (MAG-12/MAG-13)
```

---

## Related documents

- [staging_first_run_plan.md](staging_first_run_plan.md)
- [reporting_job_preparation_plan.md](reporting_job_preparation_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
- [manual_approval_gates.md](manual_approval_gates.md)
