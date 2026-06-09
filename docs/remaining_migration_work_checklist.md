# Remaining MiFID Migration Work Checklist

## Purpose

Consolidated **post-notebook-package** checklist for what RegTech/DE/Validation may do next in staging versus what remains gated for final parity and production adaptation.

**Status:** Staging package is authored. Repository is **not production-ready**. No final regulatory parity claim is permitted from this checklist alone.

**Repository authority:** Cursor-authored YAML, notebook wrappers, SQL templates, and docs remain the source of truth. If Databricks UI, Genie, or workspace edits are accepted, copy them back into this repository and commit to avoid drift.

**Execution paths:**

| Path | Artifacts |
| --- | --- |
| SQL-task staging jobs | `databricks/workflows/mifid_phase1_staging_jobs.yml` |
| Notebook companion jobs | `databricks/workflows/mifid_phase1_staging_notebook_jobs.yml`, `databricks/notebooks/mifid_staging/` |
| Notebook execution plan | [notebook_job_execution_plan.md](notebook_job_execution_plan.md) |
| First-run sequence | [staging_first_run_plan.md](staging_first_run_plan.md) |
| Evidence template | [staging_execution_evidence_log.md](staging_execution_evidence_log.md) (populate outside Git) |

**Defaults (staging):** `target_schema=regtech_ops_stg`, `dry_run=true`, `skip_delivery_steps=true`, `run_mode=development_structural_test`.

---

## 1. Ready to test in staging now

Default critical path — run **one job/notebook at a time** after readiness evidence is accepted. Use SQL-task jobs and/or notebook companion wrappers; both reference the same governed SQL templates.

| Order | Module / job group | SQL-task job | Notebook job | Notebook wrapper |
| --- | --- | --- | --- | --- |
| 1 | Readiness checks | `mifid_staging_readiness_job_do_not_deploy` | `mifid_notebook_staging_readiness_job_do_not_deploy` | `01_readiness_checks.py` |
| 2 | Static/reference checks | `mifid_staging_static_reference_job_do_not_deploy` | `mifid_notebook_staging_static_reference_job_do_not_deploy` | `02_static_reference_checks.py` |
| 3 | Price/currency/split ext staging | `mifid_staging_price_currency_split_job_do_not_deploy` | `mifid_notebook_staging_price_currency_split_job_do_not_deploy` | `03_price_currency_split_staging.py` |
| 4 | Non-price Reg_Ext staging | `mifid_staging_non_price_reg_ext_job_do_not_deploy` | `mifid_notebook_staging_non_price_reg_ext_job_do_not_deploy` | `04_non_price_reg_ext_staging.py` |
| 5 | Regulation movement staging | `mifid_staging_regulation_movement_job_do_not_deploy` | `mifid_notebook_staging_regulation_movement_job_do_not_deploy` | `05_regulation_movement_staging.py` |
| 6 | Hedge liquidity structural staging | `mifid_staging_hedge_liquidity_job_do_not_deploy` | `mifid_notebook_staging_hedge_liquidity_job_do_not_deploy` | `06_hedge_liquidity_staging.py` |
| 7 | ASIC2 structural staging | `mifid_staging_asic2_structural_job_do_not_deploy` | `mifid_notebook_staging_asic2_structural_job_do_not_deploy` | `07_asic2_structural_staging.py` |
| 8 | MIFID2_ext non-PII staging | `mifid_staging_mifid2_ext_non_pii_job_do_not_deploy` | `mifid_notebook_staging_mifid2_ext_non_pii_job_do_not_deploy` | `08_mifid2_ext_non_pii_staging.py` |
| 9 | Validation summary | `mifid_staging_validation_summary_job_do_not_deploy` | `mifid_notebook_staging_validation_summary_job_do_not_deploy` | `12_validation_summary.py` |

**Staging test checklist (per run):**

- [ ] Job 1 readiness run first; stop on `FAIL`/`BLOCK`; review `TODO`/`SKIP`/`RUN_MANUAL` before Job 2
- [ ] Use catalog-scoped `information_schema` (`main.information_schema.*`); not `system.information_schema`
- [ ] Keep `dry_run=true` for first pass unless MAG-18 and `staging_execution_approved=true`
- [ ] Record evidence in secure storage using [staging_execution_evidence_log.md](staging_execution_evidence_log.md) template
- [ ] Confirm writes remain `main.regtech_ops_stg` only (`bi_output_regtechops_` prefix)
- [ ] Do not claim final parity from staging structural evidence

**Not in default first pass:** optional seed, RecordID registry, masked-customer structural path.

---

## 2. Optional staging mechanics

Run only when explicitly needed. Not required for the default first smoke-test pass.

| Item | Enable / prerequisite | SQL-task job | Notebook job | Notebook wrapper |
| --- | --- | --- | --- | --- |
| Manual NPD CSV seed-load mechanics | `enable_manual_seed_testing_checks=true`; CSV in secure storage only | `mifid_staging_manual_seed_testing_job_do_not_deploy` | `mifid_notebook_staging_optional_seed_testing_job_do_not_deploy` | `10_optional_manual_seed_testing.py` |
| Manual Hedge CSV seed mechanics | Same as above; mechanics only | (Job 9 task group) | (Job 9) | `10_optional_manual_seed_testing.py` |
| Hedge RecordID registry test | Hedge/history seed available; SME natural-key signoff path | `mifid_staging_hedge_recordid_registry_job_do_not_deploy` | `mifid_notebook_staging_hedge_recordid_registry_job_do_not_deploy` | `11_optional_hedge_recordid_registry.py` |
| Masked customer structural tests | `enable_masked_customer_structural_tests=true` and `allow_masked_customer_sources=true`; MAG-05 | (commented in smoke-test YAML) | (no dedicated job) | `09_optional_masked_customer_structural.py` |

**Optional mechanics rules:**

- Current NPD CSV is for **load-mechanics testing only**; regenerate final NPD CSV when the NPD step is reached
- No CSV/extract files in Git
- Optional paths do **not** activate final NPD_TRAX, Failed_TRAX, or Hedge report flows

See [manual_seed_testing_plan.md](manual_seed_testing_plan.md), [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md).

---

## 3. Still gated

Do **not** activate from default staging SQL-task or notebook workflows.

| Gated flow | Gate / dependency | Notes |
| --- | --- | --- |
| Final `MIFID2_NPD_TRAX` | MAG-10; NPD history — **final-flow last** | Manual seed mechanics ≠ final flow |
| Final `MIFID2_Failed_TRAX` | NPD history dependency | Gated on NPD readiness |
| Final `MIFID2_Hedge_Report` | MAG-12/MAG-13; RecordID registry validation | Registry test ≠ final report activation |
| Final `MIFID2_Report` parity | MAG-16/MAG-17; baseline comparison | Not first-pass staging scope |
| Final `MIFID2_ETORO_Report` parity | MAG-16/MAG-17; baseline comparison | Not first-pass staging scope |
| Final customer/NPD parity | MAG-06; `main.pii_data` or formal exception | Masked customer dev-only |
| Production scheduling | Separate DE program + deployment authorization | All repo jobs are `do_not_deploy` |
| Delivery / upload / response | Out of phase-1 repo scope | No TRAX/SFTP/7z/response paths |

---

## 4. Required before final parity

All items below must be evidenced **outside Git** unless already documented as template-only in this repo.

| Requirement | Owner / reference | Checklist |
| --- | --- | --- |
| Unmasked PII access or formal exception | DE + RegTech; MAG-06 | [ ] `main.pii_data` customer/history access granted or exception documented |
| SQL Server baseline dates and extracts | Validation + DBA/DE; MAG-16 | [ ] Scenarios nominated per [baseline_scenario_request.md](baseline_scenario_request.md) |
| DE-migrated source availability in `main.regtech` | DE general pipeline | [ ] Required upstream objects present or fallback documented |
| Source readiness validation | RegTech/Validation | [ ] `12_staging_readiness/*` PASS or accepted manual evidence |
| Historical seed validation | DE + RegTech; MAG-07–11 | [ ] Seed row counts, keys, date ranges validated per [historical_seed_inventory.md](historical_seed_inventory.md) |
| Hedge RecordID registry validation | RegTech SME + Validation; MAG-12 | [ ] `08_outputs/10_hedge_recordid_registry/*` validation pass |
| TransactionReferenceNumber exact parity | SME + Validation; MAG-13 | [ ] SQL Server comparison evidence captured |
| CFI / InstrumentClassification exact parity | SME + Validation; MAG-15 | [ ] SQL Server comparison evidence captured |
| NPD_TRAX history/current seed validation | RegTech + Validation; MAG-10 | [ ] History/current state validated before final NPD activation |
| Validation evidence stored outside Git | Validation | [ ] Per [validation_evidence_plan.md](validation_evidence_plan.md) and [staging_execution_evidence_log.md](staging_execution_evidence_log.md) |
| MAG approvals closed for intended run mode | Manager/Validation | [ ] Applicable MAG-01–17 entries CLOSED in [manual_approval_gates.md](manual_approval_gates.md) |

Final parity remains blocked until the above close for the intended `final_parity_production` run mode.

---

## 5. Required for DE production adaptation

This repository provides **implementation input** only. DE owns production hardening and deployment outside this repo.

### Inputs DE should use from this repo

| Input | Location |
| --- | --- |
| SQL-task workflow definitions | `databricks/workflows/mifid_phase1_staging_jobs.yml` |
| Notebook companion workflows | `databricks/workflows/mifid_phase1_staging_notebook_jobs.yml` |
| Notebook wrappers | `databricks/notebooks/mifid_staging/` |
| Parameter defaults | `databricks/config/workflow_parameters.yml` |
| SQL templates and validation packages | `databricks/sql/` |
| Environment assumptions | `docs/workflow_execution_runbook.md`, [execution_prerequisites.md](execution_prerequisites.md) |
| Evidence log schema | [staging_execution_evidence_log.md](staging_execution_evidence_log.md) |
| Open blockers | [open_blockers_for_execution.md](open_blockers_for_execution.md) |
| Remaining decisions | [remaining_decisions.md](remaining_decisions.md) |

### Production hardening (DE-owned; not in this repo)

| Area | DE action |
| --- | --- |
| Schedules | Define production cadence separately; repo jobs remain unscheduled |
| Service principal | Production identity, least-privilege grants |
| Permissions | Separate read (`main.regtech`) vs write targets per production policy |
| Retries | Production retry/timeout policy |
| Alerts | Operational monitoring and failure notification |
| Monitoring | Job run metrics, data-quality alerts, SLA tracking |
| Deployment process | CI/CD or DABs promotion path distinct from `do_not_deploy` skeletons |
| Secrets | Secret store / Databricks secrets scope — never in Git |
| Production target handling | Production write schema/catalog decisions outside `regtech_ops_stg` staging scope |

**Policy reminder:** Copy accepted Databricks UI/Genie changes back to this repo before treating workspace edits as authoritative.

---

## Immediate next Databricks actions (staging)

1. Import/sync notebook wrappers from `databricks/notebooks/mifid_staging/` if using notebook path
2. Keep all jobs template-only / `do_not_deploy` / unscheduled
3. Run **Job 1 / readiness notebook only** with `dry_run=true`
4. Record readiness evidence externally; resolve `RUN_MANUAL`/`TODO` rows before Job 2
5. Run Jobs 2–8 / notebooks one group at a time; then validation summary (Job 11)
6. Skip optional Jobs 9–10 on first pass unless explicitly needed
7. Do not enable delivery, production schedules, or `main.regtech` writes

---

## Related documents

- [notebook_job_execution_plan.md](notebook_job_execution_plan.md)
- [staging_first_run_plan.md](staging_first_run_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md)
- [final_handoff_package.md](final_handoff_package.md)
- [open_blockers_for_execution.md](open_blockers_for_execution.md)
- [manual_approval_gates.md](manual_approval_gates.md)
