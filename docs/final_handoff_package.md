# Final Handoff Package (Step 18B)

## Purpose

This package consolidates the **final role-based handoff** for phase-1 MiFID SQL Server / SSIS → Databricks table-generation migration. It ties together Step 18A audit conclusions, blocker registers, governance controls, and next actions for Engineering, Data Platform, RegTech SME, Validation, and Management.

**Audience:** Engineers, analysts, DE/Data Platform, RegTech SME, Validation/QA, Manager/PM.

**Navigation:** [handoff_index.md](handoff_index.md)

---

## Staging-only execution strategy (RegTechOps)

Databricks jobs and workflows in this repository are **staging-only RegTechOps jobs**. They generate and test migration, staging, audit, and reporting tables in `main.regtech_ops_stg`. They are **not** production-grade jobs and must **not** create or overwrite production objects.

| Policy | Detail |
| --- | --- |
| **Read sources** | `main.regtech` (and other catalogs) when DE-migrated sources are available; DE is migrating SQL Server / `RegReportDB_Prod` tables into `main.regtech` via the general pipeline |
| **Write target** | `main.regtech_ops_stg` only |
| **Generated object prefix** | `bi_output_regtechops_` |
| **Seed object prefix** | `bi_output_regtechops_seed_` |
| **Control/registry prefix** | `bi_output_regtechops_` |
| **DE production role** | Data Engineering will later use these staging jobs/workflows as **implementation input** and adapt them to meet production criteria — outside this repository's scope |

**Allowed now:** staging-only job/workflow skeletons; staging smoke-test jobs; approved CSV seed loads into `main.regtech_ops_stg` seed tables; ext/staging/audit table tests that do not require final PII or final production state; `development_structural_test` mode; masked customer fallback for structural tests only.

**Not allowed:** writes to `main.regtech`; production readiness claims; final regulatory parity without validation; production schedules; CSV/SFTP/TRAX/Cappitech delivery; response handling; seed CSVs or PII samples in Git.

See also: [workflow_execution_runbook.md](workflow_execution_runbook.md), [execution_prerequisites.md](execution_prerequisites.md), [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md), [baseline_scenario_request.md](baseline_scenario_request.md), [validation_evidence_plan.md](validation_evidence_plan.md).

---

## Package index

| Document | Role |
| --- | --- |
| [final_repository_audit.md](final_repository_audit.md) | Step 18A objective audit |
| [final_handoff_package.md](final_handoff_package.md) | This package |
| [final_manager_handoff_summary.md](final_manager_handoff_summary.md) | Manager-ready summary |
| [final_handoff_summary.md](final_handoff_summary.md) | Engineering handoff entry |
| [de_data_platform_action_list.md](de_data_platform_action_list.md) | DE/Data Platform actions |
| [regtech_sme_decision_list.md](regtech_sme_decision_list.md) | SME decisions |
| [post_blocker_execution_plan.md](post_blocker_execution_plan.md) | Sequence after blockers close |
| [historical_seed_inventory.md](historical_seed_inventory.md) | BI-21 MCP seed-critical inventory |
| [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md) | Baseline dates and extract constraints |
| [baseline_scenario_request.md](baseline_scenario_request.md) | SQL Server baseline scenario request package (copyable template) |
| [validation_evidence_plan.md](validation_evidence_plan.md) | Baseline parity validation expectations |
| [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md) | Hedge RecordID registry design |
| [open_blockers_for_execution.md](open_blockers_for_execution.md) | Blocker register |
| [manual_approval_gates.md](manual_approval_gates.md) | MAG-01–17 (authoritative) |
| [workflow_governance_controls.md](workflow_governance_controls.md) | Run modes and stop/go |

---

## Completion attestation

| Attestation | Status |
| --- | --- |
| Phase-1 preparation repository complete | **Yes** (per Step 18A audit) |
| All in-scope module SQL templates authored (gated) | **Yes** |
| Module validation packages authored | **Yes** |
| Cross-module readiness package (16B1) | **Yes** |
| Workflow definitions template-only / `do_not_deploy` (17B + staging jobs) | **Yes** — template-only definitions; not deployed to production schedules; approved staging smoke-test execution permitted under controls — not final parity or production |
| Governance / manual approvals documented (17C) | **Yes** |
| Step 18B handoff package | **Yes** (this document set) |
| Staging-only RegTechOps jobs/workflows authored | **Yes** (skeleton; not production-grade) |
| Staging smoke-test / seed-load execution | **Permitted** under approved staging controls (`development_structural_test`, prerequisites, MAG gates) — not production or final parity |
| Databricks execution performed (full parity) | **No** |
| Workflow deployed to production schedules | **No** |
| Production deployment to `main.regtech` | **No** |
| Final parity / production execution-ready | **No** — blockers and MAG gates remain open |

Attestation date: _TBD_ (record when program accepts handoff).

---

## What has been authored

- **SQL:** Gated templates under `databricks/sql/` (config, static, UDFs, Pre_Regulation, movements, hedge liquidity, ASIC2, MIFID2_ext, outputs, cross-module validation, workflow gates).
- **Hedge RecordID registry package:** Gated design templates under `databricks/sql/08_outputs/10_hedge_recordid_registry/` (scaffold, seed, allocation, SELECT-only validation).
- **Workflow:** Template-only / `do_not_deploy` definitions — `mifid_phase1_staging_jobs.yml`, `mifid_phase1_staging_smoke_test.yml`, `mifid_phase1_table_generation.yml`, and `databricks/sql/10_workflow/`.
- **Notebook wrappers:** Template-only companion wrappers under `databricks/notebooks/mifid_staging/` and `mifid_phase1_staging_notebook_jobs.yml` (staging support only; not production-grade).
- **Docs:** Analysis, profiling, gates, reconciliation, readiness, workflow, governance, Step 18A audit, Step 18B handoff (this package).
- **Target convention:** `main.regtech_ops_stg` only; `bi_output_regtechops_` for generated objects; `bi_output_regtechops_seed_` for seed tables.
- **Staging jobs:** Non-production RegTechOps job/workflow skeletons intended as DE implementation input.

Business logic authority remains **read-only** under `reference/mifid_databricks_migration_context/`. NOC and old Databricks attempt docs remain **reference-only**.
Repository/Cursor-authored workflow and notebook definitions remain the source of truth; accepted Databricks UI/Genie/workspace edits must be copied back into Git to avoid drift.

---

## What has not been executed (final parity / production)

- No final-parity module activation or un-gated DML claiming regulatory sign-off.
- No writes to `main.regtech` production schema from this repository's jobs.
- No SQL Server baseline reconciliation runs claiming final parity (until MAG gates close).
- No production workflow schedules or production-grade orchestration.
- No regulatory delivery: CSV export to TRAX paths, 7z, SFTP, TRAX upload, or TRAX response processing.

**Permitted under staging-only policy:** staging smoke-test runs, approved CSV seed loads into `main.regtech_ops_stg` seed tables (e.g. initial `MIFID2_NPD_TRAX` feasibility test), and structural tests of ext/staging/audit tables in `development_structural_test` mode.

---

## Blocker checklist

Use [open_blockers_for_execution.md](open_blockers_for_execution.md) as the canonical register. Summary:

### Access (open)

- [ ] `main.pii_data.bronze_etoro_customer_customer`
- [ ] `main.pii_data.bronze_etoro_history_customer`

### History / seed (approved direction; MCP metadata confirmed 2026-06-05; extract ownership pending)

- [ ] Assign seed extraction ownership and secure landing (see [historical_seed_inventory.md](historical_seed_inventory.md))
- [ ] Extract/load nine seed-critical tables; validate row counts and keys
- [ ] `MIFID2_Hedge_Report` seed + RecordID registry ([hedge_recordid_registry_design.md](hedge_recordid_registry_design.md))
- [ ] Hedge RecordID registry package gates closed (`databricks/sql/08_outputs/10_hedge_recordid_registry/`) before Step 14 activation
- [ ] `MIFID2_NPD_TRAX` seed implementation (initial feasible staging seed/load test — `bi_output_regtechops_seed_*`; not final parity until PII/validation gates close)
- [ ] `MIFID2_Failed_TRAX` / NPD shared history implementation
- [ ] `ASIC2_Transactions` / `ASIC2_Positions` history implementation (ASIC2_Positions chunked)
- [ ] `Reg_LiquidtyAcount_SCD` historical validity implementation
- [ ] `Reg_MigrationInOut_Population` / `Reg_RegulationInOutDailyData` / `Reg_Regulation_Movments_Positions` historical replay implementation

### SME / certification (open)

- [ ] `CurrencyPriceMaxDateWithSplit` selected-source validation (D-05 / MAG-14)
- [ ] CFI / `InstrumentClassification` exact SQL Server parity (D-14 / MAG-15)
- [ ] Hedge `RecordID` approved-direction implementation and validation (D-12 / MAG-12)
- [ ] Hedge `TransactionReferenceNumber` exact SQL Server parity (D-13 / MAG-13)
- [ ] Required-column certifications batch (D-21 / MAG-02)
- [ ] SQL Server baseline scope (D-23 / MAG-16)

### Resolved (do not re-open without new evidence)

- Static reference tables with explicit LOCATION (internal accounts, special-char dictionary, EDNF mapping)
- Several trading/general sources confirmed accessible (certification may still be pending)
- `Reg_CurrencyPrice_Ext` primary source selected: `main.dealing.bronze_pricelog_history_currencyprice`
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` primary source selected: `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`
- `main.trading.bronze_etoro_trade_currencyprice` downgraded to readable-but-not-preferred fallback/reference
- `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` downgraded to readable with required columns present

---

## Approval checklist

Authoritative register: [manual_approval_gates.md](manual_approval_gates.md). Record approvals **externally** (Jira or designated log); do not store PII or secrets in the repo.

| Gate range | Topic | Typical status |
| --- | --- | --- |
| MAG-01–03 | Access and source/column readiness | OPEN |
| MAG-04 | Static references | PARTIAL |
| MAG-05–06 | Masked dev vs final PII | OPEN |
| MAG-07–11 | History/seed families | OPEN |
| MAG-08 | Migration materialization | OPEN |
| MAG-12–15 | Hedge and classification | OPEN |
| MAG-16–17 | Baseline and final validation | OPEN |

Legacy Step 17B checklist: [workflow_manual_approval_checkpoints.md](workflow_manual_approval_checkpoints.md) — historical; **MAG register supersedes** for new runs.

---

## Role-based action lists

### DE / Data Platform

**Primary doc:** [de_data_platform_action_list.md](de_data_platform_action_list.md)

1. Continue SQL Server / `RegReportDB_Prod` migration into `main.regtech` via the general DE pipeline (production path — separate from RegTech staging jobs).
2. Keep selected price/hedge source classifications current in profiling and blocker registers (no longer active storage blockers).
3. Grant `main.pii_data` for final parity.
4. Certify selected primary price/split-price source contracts and complete required-column certifications.
5. Support historical seed extraction/access and assign extract ownership; land approved CSV seeds in secure storage (not Git).
6. Later: adapt RegTech staging jobs to production criteria (outside this repo); confirm warehouse/SP write permissions for `main.regtech_ops_stg` only.

### RegTech SME

**Primary doc:** [regtech_sme_decision_list.md](regtech_sme_decision_list.md)

1. Confirm masked tables are dev-only; approve final PII path.
2. Sign implementation plans for approved history/seed strategy (NPD, Failed TRAX, ASIC2, liquidity SCD, migration/regulation in-out).
3. Sign migration/regulation in-out materialization.
4. Approve hedge RecordID implementation detail (natural key + registry) and transaction-reference exact parity evidence.
5. Sign CFI/classification exact parity evidence where gated.
6. Nominate baseline scenario dates per [baseline_scenario_request.md](baseline_scenario_request.md) (19 scenario families).
7. Agree baseline comparison dates and final go/no-go criteria (D-23 / MAG-16).

### Validation / QA

1. Own MAG-02, MAG-16, MAG-17 evidence with DE and SQL Server team.
2. Issue baseline extract requests using template in [baseline_scenario_request.md](baseline_scenario_request.md).
3. Run SELECT-only validation packages per [final_validation_execution_plan.md](final_validation_execution_plan.md) after blockers close.
4. Execute cross-module checks in `databricks/sql/09_validation/`.
5. Capture baseline comparison results per [validation_evidence_plan.md](validation_evidence_plan.md); document deltas in [known_differences.md](known_differences.md).
6. Block go/no-go if hard gates fail or masked sources appear in final parity mode.

### Manager / PM

**Primary doc:** [final_manager_handoff_summary.md](final_manager_handoff_summary.md)

1. Prioritize `main.pii_data` access and source-certification/historical-seed implementation readiness.
2. Schedule SME sessions for history/seed and hedge/classification decisions.
3. Enforce **no final-parity or production execution** until blockers and MAG closures are evidenced; staging-only smoke tests and seed loads may proceed per staging policy.
4. Accept Step 18A audit and this package as preparation-complete, not final-parity execution-ready.
5. Approve transition to controlled final-parity execution only when [transition criteria](#transition-criteria-to-execution-enablement) are met.

---

## Do-not-run boundaries

Do **not** run from this repository or approve others to run:

| Boundary | Reason |
| --- | --- |
| Deploy staging jobs to production schedules or `main.regtech` | Staging-only; production adaptation is DE's separate program |
| Un-gated DML claiming final regulatory parity | Blockers and validations not closed |
| Writes to `main.regtech` from RegTech staging jobs | Staging writes must target `main.regtech_ops_stg` only |
| Use masked customer tables for final parity | Policy violation; MAG-06 not satisfied |
| CSV / 7z / SFTP / TRAX upload / TRAX response | Out of phase-1 scope |
| Writes to `main.regtech` production | Out of phase-1 scope |
| Treat NOC or old Databricks attempt as build authority | Reference-only |

---

## Transition criteria to execution enablement

Move from **documentation-only** to **controlled execution enablement** only when **all** apply:

1. **Blockers:** No unresolved hard blockers in `open_blockers_for_execution.md` (or formal waiver with evidence).
2. **Decisions:** Applicable items in `remaining_decisions.md` closed and reflected in MAG register.
3. **Approvals:** Required MAG gates **CLOSED** with external evidence for the intended run mode.
4. **Profiling:** `source_profiling_results.md` updated post-remediation.
5. **Plan:** Team commits to [post_blocker_execution_plan.md](post_blocker_execution_plan.md) (SELECT-only first, then gated activation).
6. **Go/no-go:** Manager/Validation explicit NO-GO lifted for the specific run type (`development_structural_test` vs `final_parity_production`).
7. **Workflow:** Workflow deployment remains a **later** gate after module validation and MAG-17.

Until final-parity criteria are met, the repository remains **ready for staging-only execution, blocker resolution, and planning** — not final-parity or production deployment.

---

## Related audit conclusion (Step 18A)

From [final_repository_audit.md](final_repository_audit.md):

> Repository is ready for blocker-resolution and controlled execution planning, but not ready for Databricks execution or production deployment while blockers remain open.

---

## Quick start by role

| Role | Start here |
| --- | --- |
| Engineer / analyst | [final_handoff_summary.md](final_handoff_summary.md) → [repository_inventory.md](repository_inventory.md) |
| DE / Data Platform | [de_data_platform_action_list.md](de_data_platform_action_list.md) |
| RegTech SME | [regtech_sme_decision_list.md](regtech_sme_decision_list.md) |
| Validation / QA | [final_validation_execution_plan.md](final_validation_execution_plan.md) → [post_blocker_execution_plan.md](post_blocker_execution_plan.md) |
| Manager / PM | [final_manager_handoff_summary.md](final_manager_handoff_summary.md) |
