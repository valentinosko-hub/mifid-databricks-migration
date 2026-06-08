# MiFID Databricks Migration

This repository contains the MiFID SQL Server / SSIS to Databricks migration work.

## Current phase

Build and test MiFID table-generation in **staging-only RegTechOps** jobs targeting Databricks Ops staging. Jobs in this repo are **not production-grade**; Data Engineering will later adapt them for production.

| Setting | Value |
| --- | --- |
| Write target | `main.regtech_ops_stg` only |
| Read sources | `main.regtech` when DE-migrated sources are available |
| Generated prefix | `bi_output_regtechops_` |
| Seed prefix | `bi_output_regtechops_seed_` |

DE migrates SQL Server / `RegReportDB_Prod` into `main.regtech` via the general pipeline (separate from RegTech staging jobs).

## Scope

In scope for this phase:
- Staging-only Databricks job/workflow skeletons and smoke-test jobs
- Databricks staging/report table generation in `main.regtech_ops_stg`
- Approved CSV seed loads into staging seed tables (secure storage; not Git); SQL templates in `databricks/sql/11_seed_testing/`
- SSIS-created staging/ext table recreation
- ASIC2-compatible MiFID subset
- validation and reconciliation SQL
- `development_structural_test` mode (masked customer for structural tests only)

Out of scope for this phase:
- Writes to `main.regtech` from RegTech staging jobs
- Production-grade jobs or production schedules
- Regulatory CSV export/delivery (TRAX paths), 7z, SFTP
- Cappitech/TRAX upload and TRAX response handling
- Claiming final regulatory parity without validation
- Storing seed CSVs or PII samples in Git
- unbounded full historical backfill by default (history seeding follows approved policy in `docs/history_seed_requirements.md`)

Reference material is under:

reference/mifid_databricks_migration_context/

Do not modify reference files directly.

## Final handoff (Step 18B)

Start here for consolidated handoff navigation:

- [Handoff index](docs/handoff_index.md)
- [Final repository audit (Step 18A)](docs/final_repository_audit.md)
- [Final handoff package (Step 18B)](docs/final_handoff_package.md)
- [Final manager handoff summary (Step 18B)](docs/final_manager_handoff_summary.md)
- [Open blockers for execution](docs/open_blockers_for_execution.md)
- [Post-blocker execution plan (Step 18B)](docs/post_blocker_execution_plan.md)
- [Historical seed inventory (BI-21 MCP)](docs/historical_seed_inventory.md)
- [SQL Server baseline extract plan](docs/sql_server_baseline_extract_plan.md)
- [Baseline scenario request package](docs/baseline_scenario_request.md)
- [Validation evidence plan](docs/validation_evidence_plan.md)
- [Hedge RecordID registry design](docs/hedge_recordid_registry_design.md)
- [Manual CSV seed testing plan](docs/manual_seed_testing_plan.md)

Role-based action lists:

- [DE / Data Platform action list](docs/de_data_platform_action_list.md)
- [RegTech SME decision list](docs/regtech_sme_decision_list.md)

## Final handoff and readiness (Step 16–18A)

Engineering entry and readiness detail:

- [Final handoff summary](docs/final_handoff_summary.md)
- [Final readiness assessment](docs/final_readiness_assessment.md)
- [Open blockers for execution](docs/open_blockers_for_execution.md)
- [Final validation execution plan](docs/final_validation_execution_plan.md)
- [Repository inventory](docs/repository_inventory.md)

Additional handoff support:

- [Execution prerequisites](docs/execution_prerequisites.md)
- [Remaining decisions](docs/remaining_decisions.md)
- [Manager status summary](docs/manager_status_summary.md)
- [Customer source policy (masked temporary fallback)](docs/source_to_databricks_mapping_review.md#customer-source-path-policy-temporary-masked-fallback--final-pii-gates)
- [Reporting job preparation plan (staging smoke test)](docs/reporting_job_preparation_plan.md)
- [Workflow skeleton design (Step 17B)](docs/workflow_skeleton_design.md)
- [Workflow orchestration plan (Step 17B)](docs/workflow_orchestration_plan.md)
- [Workflow execution runbook (Step 17B)](docs/workflow_execution_runbook.md)
- Staging smoke-test workflow: `databricks/workflows/mifid_phase1_staging_smoke_test.yml` (default critical path; optional groups skippable)
- Shared workflow parameters: `databricks/config/workflow_parameters.yml` (`dry_run=true` default; `staging_execution_approved=false`)
- [Workflow manual approval checkpoints (Step 17B)](docs/workflow_manual_approval_checkpoints.md)
- [Workflow governance controls (Step 17C)](docs/workflow_governance_controls.md)
- [Manual approval gates (Step 17C)](docs/manual_approval_gates.md)

**Status:** Phase-1 preparation and Step 18B handoff documentation are complete per the [final repository audit (Step 18A)](docs/final_repository_audit.md) and [final handoff package (Step 18B)](docs/final_handoff_package.md). SQL templates, validation packages, staging-only RegTechOps job/workflow skeletons, and Step 17C governance documentation are authored. The repository supports **staging-only** smoke-test and seed-load execution in `main.regtech_ops_stg` but is **not** ready for final-parity execution or production deployment while blockers/gates remain open. Active source-access blockers are limited to `main.pii_data` customer/history access for final parity. Masked customer tables are development/structural-test only. Initial feasible seed test: `MIFID2_NPD_TRAX` into `bi_output_regtechops_seed_*` (staging evidence only). NOC and old Databricks attempt docs remain reference-only.
