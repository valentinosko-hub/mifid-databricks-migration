# MiFID Databricks Migration

This repository contains the MiFID SQL Server / SSIS to Databricks migration work.

## Current phase

Build MiFID table-generation parity in Databricks Ops staging.

Target environment:

main.regtech_ops_stg

All persistent objects created in this schema must start with:

bi_output_regtechops_

## Scope

In scope for this phase:
- Databricks staging/report table generation
- SSIS-created staging/ext table recreation
- ASIC2-compatible MiFID subset
- validation and reconciliation SQL

Out of scope for this phase:
- CSV export
- 7z compression
- SFTP delivery
- Cappitech/TRAX upload
- TRAX response handling
- production deployment
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
- [Workflow skeleton design (Step 17B)](docs/workflow_skeleton_design.md)
- [Workflow orchestration plan (Step 17B)](docs/workflow_orchestration_plan.md)
- [Workflow execution runbook (Step 17B)](docs/workflow_execution_runbook.md)
- [Workflow manual approval checkpoints (Step 17B)](docs/workflow_manual_approval_checkpoints.md)
- [Workflow governance controls (Step 17C)](docs/workflow_governance_controls.md)
- [Manual approval gates (Step 17C)](docs/manual_approval_gates.md)

**Status:** Phase-1 preparation and Step 18B handoff documentation are complete per the [final repository audit (Step 18A)](docs/final_repository_audit.md) and [final handoff package (Step 18B)](docs/final_handoff_package.md). SQL templates, validation packages, a Step 17B workflow skeleton, and Step 17C governance documentation are authored. The repository is ready for blocker resolution and controlled execution planning, but **not** ready for Databricks execution or production deployment while blockers/gates remain open. Active source-access blockers are currently limited to `main.pii_data` customer/history access; other source issues were downgraded to validation/implementation gates. Manager-approved masked customer tables may be used for temporary development/structural testing only and must not be treated as final regulatory parity sources.
