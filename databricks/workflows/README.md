# Step 17B Workflow Skeleton

This folder contains **template-only** workflow artifacts for Phase 1 MiFID table/report generation in `main.regtech_ops_stg`.

## Important status

- `mifid_phase1_table_generation.yml` is a **non-executing skeleton**.
- It is not an approved deployment artifact.
- Do not deploy or execute it until blockers are closed and manual approvals are recorded.

## What this skeleton is for

- Representing task-group order and dependencies.
- Defining parameter placeholders and run modes.
- Documenting gate checkpoints before any execution enablement.

## What this skeleton does not do

- No workflow deployment.
- No Databricks job creation in workspace.
- No activation of business transformation SQL.
- No CSV/7z/SFTP delivery.
- No TRAX/Cappitech upload or response handling.
- No production deployment to `main.regtech`.

## Policy reminders

- Development/structural-test mode may use masked customer fallback only when explicitly enabled:
  - `main.general.bronze_etoro_customer_customer_masked`
  - `main.general.bronze_etoro_history_customer_masked`
- Final parity mode requires unmasked PII sources or formal approval:
  - `main.pii_data.bronze_etoro_customer_customer`
  - `main.pii_data.bronze_etoro_history_customer`
- NOC and old Databricks attempt artifacts remain reference-only.

See:
- `docs/workflow_skeleton_design.md`
- `docs/workflow_orchestration_plan.md`
- `docs/workflow_execution_runbook.md`
- `docs/workflow_manual_approval_checkpoints.md`
