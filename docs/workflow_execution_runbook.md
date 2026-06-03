# Workflow Execution Runbook (Step 17B Skeleton; Step 17C Governance)

This runbook defines how to use the Step 17B workflow skeleton as a readiness and governance artifact. It is not an approval to execute Databricks workflow tasks.

Governance controls and manual approval workflow: `docs/workflow_governance_controls.md`, `docs/manual_approval_gates.md`.

## Pre-run policy notes

NOC and old Databricks attempt materials remain reference-only and are not implementation authority.

## Pre-run checklist

Before any execution enablement, confirm:

- `docs/open_blockers_for_execution.md` blockers are closed or formally waived.
- `docs/execution_prerequisites.md` checklist is completed.
- Required decisions in `docs/remaining_decisions.md` are approved.
- Manual approvals in `docs/manual_approval_gates.md` are recorded (Step 17C; supersedes checklist use of `docs/workflow_manual_approval_checkpoints.md` for new runs).
- Stop/go criteria in `docs/workflow_governance_controls.md` are satisfied for the intended run type.
- `run_mode`, `dry_run`, and customer-source policy parameters are set correctly.
- `skip_delivery_steps=true` and no delivery/upload/response tasks are included.

## Development / structural-test run path

Intended purpose: structural validation only.

- `run_mode=development_structural_test`
- `dry_run=true`
- `dev_customer_source_mode=masked_fallback` only when explicitly approved
- `allow_masked_customer_sources=true` only for structural checks
- `enable_validation_only=true`

Allowed outcomes:

- Schema/required-column checks
- Row-count and join-path checks
- Validation package evidence capture

Not allowed:

- Final parity sign-off
- Final customer/NPD parity certification

## Parity run path (pre-final)

Intended purpose: final parity readiness checks after blocker closure.

- `run_mode=final_parity_production`
- `dry_run=true` until final go/no-go sign-off
- `dev_customer_source_mode=pii_required`
- `allow_masked_customer_sources=false`
- `require_unmasked_pii_for_parity=true`

Required inputs:

- Unmasked PII sources available or formal approval exception documented.
- Storage/catalog/access blockers closed.
- History/seed decisions approved.

## Final production-candidate run path

This remains blocked in Step 17B and requires explicit approval.

Preconditions:

- Manual approvals all closed.
- Validation evidence complete and accepted.
- SQL Server baseline comparison completed where required.
- Separate deployment authorization granted.

## Validation evidence required

- Module-level validation outputs in execution order.
- Cross-module validation outputs from `databricks/sql/09_validation/`.
- Gate wrapper outputs from `databricks/sql/10_workflow/gates/`.
- Documented unresolved deltas and owner decisions.

## Manual approval and stop/go references

| Run type | Governance reference |
| --- | --- |
| Development dry run | `docs/workflow_governance_controls.md` — Development dry run may proceed only when |
| Parity run | `docs/workflow_governance_controls.md` — Parity run may proceed only when |
| Production-candidate run | `docs/workflow_governance_controls.md` — Production-candidate run may proceed only when |

Record approvals using placeholders in `docs/manual_approval_gates.md` (Jira ticket, owner, date, evidence location).

## Rollback and stop criteria

Stop immediately if:

- Any blocker in `docs/open_blockers_for_execution.md` reopens.
- Run mode/policy mismatch is detected (for example masked fallback in final parity mode).
- Required approvals are missing.
- Validation packages report unresolved hard-gate failures.
- Out-of-scope actions are requested (delivery/upload/response or production deployment).

Rollback action in this step:

- Keep workflow skeleton non-executing.
- Revert to validation-only mode and update blocker/decision docs.

## What not to run

- Do not deploy `databricks/workflows/mifid_phase1_table_generation.yml`.
- Do not execute Databricks jobs from this skeleton.
- Do not run delivery/upload/response logic.
- Do not run production deployment logic.
