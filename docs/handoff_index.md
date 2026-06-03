# Handoff Index (Step 18B)

Single navigation entry for phase-1 MiFID Databricks migration handoff. All artifacts below are **documentation and gated templates** unless explicitly noted; execution remains blocked while open blockers and manual approvals remain.

## Audit and final package

| Document | Purpose |
| --- | --- |
| [final_repository_audit.md](final_repository_audit.md) | Objective Step 18A repository audit (structure, safety, blockers) |
| [final_handoff_package.md](final_handoff_package.md) | Step 18B consolidated role-based handoff package |
| [final_manager_handoff_summary.md](final_manager_handoff_summary.md) | Manager-ready status and support needed |
| [final_handoff_summary.md](final_handoff_summary.md) | Primary engineering handoff entry (Steps 16B2 + 18B) |

## Readiness and blockers

| Document | Purpose |
| --- | --- |
| [final_readiness_assessment.md](final_readiness_assessment.md) | Cross-module readiness state |
| [final_validation_execution_plan.md](final_validation_execution_plan.md) | Validation order after execution enablement |
| [open_blockers_for_execution.md](open_blockers_for_execution.md) | Consolidated execution blocker register |
| [execution_prerequisites.md](execution_prerequisites.md) | Prerequisites before any Databricks execution |
| [remaining_decisions.md](remaining_decisions.md) | Open decisions with D-to-MAG mapping |
| [repository_inventory.md](repository_inventory.md) | SQL and doc file locator |

## Workflow and governance

| Document | Purpose |
| --- | --- |
| [workflow_skeleton_design.md](workflow_skeleton_design.md) | Step 17B skeleton design and run modes |
| [workflow_orchestration_plan.md](workflow_orchestration_plan.md) | Task graph and orchestration format |
| [workflow_execution_runbook.md](workflow_execution_runbook.md) | Pre-run checklist and stop criteria |
| [workflow_governance_controls.md](workflow_governance_controls.md) | Governance model and run-mode policy |
| [manual_approval_gates.md](manual_approval_gates.md) | Authoritative MAG register (MAG-01–17) |

## Role-based action lists (Step 18B)

| Document | Audience |
| --- | --- |
| [de_data_platform_action_list.md](de_data_platform_action_list.md) | Data Engineering / Data Platform |
| [regtech_sme_decision_list.md](regtech_sme_decision_list.md) | RegTech SME / business owners |
| [post_blocker_execution_plan.md](post_blocker_execution_plan.md) | Engineering / Validation after blockers close |

## Authority and reference-only material

- SQL Server / SSIS / DDL lineage: `reference/mifid_databricks_migration_context/` (**read-only**; do not modify).
- NOC documents and old Databricks attempt materials: **reference-only**; not implementation authority for this migration.

## Non-execution posture

The repository is **not execution-ready** until blockers in [open_blockers_for_execution.md](open_blockers_for_execution.md) close and manual approvals in [manual_approval_gates.md](manual_approval_gates.md) are recorded externally.
