# Step 17B SQL Workflow Wrappers

This folder contains **non-executing** workflow wrapper assets for Step 17B.

## Purpose

- Provide SELECT-only gate/control skeletons for orchestration planning.
- Keep workflow behavior documentation close to SQL module structure.
- Avoid activating any business transformation logic.

## Files

- `00_workflow_parameters.sql`
  - Parameter visibility and policy-evaluation skeleton.
  - SELECT-only.
- `01_run_control.sql`
  - Run-control gate manifest and status placeholders.
  - SELECT-only.
- `02_audit_logging.sql`
  - Audit/event manifest placeholder.
  - SELECT-only.
- `gates/gate_global_scope.sql`
  - Global scope and policy checks.
  - SELECT-only.
- `gates/gate_module_validation_chain.sql`
  - Ordered module/task-chain manifest with validation references.
  - SELECT-only.
- `gates/gate_cross_module_readiness.sql`
  - Blocker and readiness summary placeholder.
  - SELECT-only.

## Restrictions for this step

- No active CREATE TABLE.
- No active INSERT/UPDATE/DELETE/MERGE/DROP.
- No business transformation execution.
- No output loading activation.
- No delivery/upload/response handling.
- No production deployment logic.

## How these wrappers are used

- Referenced by `databricks/workflows/mifid_phase1_table_generation.yml`.
- Act as readiness aids only until blockers and approvals are closed.
