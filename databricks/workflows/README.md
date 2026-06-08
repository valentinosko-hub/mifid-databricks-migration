# Workflow Skeletons (Step 17B + Staging Smoke Test)

This folder contains **template-only** workflow artifacts for Phase 1 MiFID work in `main.regtech_ops_stg`.

## Workflows

| File | Purpose | Status |
| --- | --- | --- |
| `mifid_phase1_staging_smoke_test.yml` | Ext/staging/audit structural smoke tests | Template-only; **do not deploy** |
| `mifid_phase1_table_generation.yml` | Full table/report generation ordering skeleton | Template-only; **do not deploy** |

Shared parameter defaults: `databricks/config/workflow_parameters.yml`

## Staging smoke-test workflow (`mifid_phase1_staging_smoke_test.yml`)

Non-production orchestration for validating ext/staging/audit tables before final reporting activation.

- **Read:** `main.regtech` (primary); dev fallback to confirmed alternate schemas documented only in run evidence
- **Write:** `main.regtech_ops_stg` with `bi_output_regtechops_` prefix
- **Defaults:** `run_mode=development_structural_test`, `dry_run=true`, `staging_execution_approved=false`, no schedule
- **Default critical path (9 tasks):** source readiness → static refs → price/currency/split → non-price Reg_Ext → regulation movements → hedge/liquidity ext → ASIC2 structural → MIFID2_ext non-PII → validation summary
- **Optional groups (commented manual blocks; not required for first pass):**
  - `masked_customer_structural_tests` — `enable_masked_customer_structural_tests=false`; also `allow_masked_customer_sources=true` + MAG-05
  - `manual_seed_testing_checks` — `enable_manual_seed_testing_checks=false`; seed tables + manifest evidence

**dry_run:** `true` = readiness/check-only (default). `false` allowed only with `staging_execution_approved=true`, `development_structural_test`, and MAG-18 — still `main.regtech_ops_stg` only.

**Audit/evidence (SELECT-only; no active audit writes):** `gate_global_scope.sql`; optional `02_audit_logging.sql`; external log TODO `docs/staging_execution_evidence_log.md`.

**Not included (gated):** final NPD_TRAX, final Hedge report, final PII customer parity, delivery/upload/response/production.

See `docs/reporting_job_preparation_plan.md` and `docs/workflow_execution_runbook.md`.

## Table-generation workflow (`mifid_phase1_table_generation.yml`)

Broader Phase 1 ordering skeleton including customer outputs, reports, hedge, and NPD table generation placeholders. Remains execution-gated separately from the smoke-test workflow.

## Important status (both workflows)

- Non-executing skeletons — not approved deployment artifacts
- Do not deploy or execute until blockers are closed and manual approvals are recorded
- No workflow deployment or Databricks job creation from this repo step
- No activation of business transformation SQL from YAML alone
- No CSV/7z/SFTP delivery, TRAX/Cappitech upload, or response handling
- No production deployment to `main.regtech`

## Policy reminders

- Development/structural-test mode may use masked customer fallback only when explicitly enabled and MAG-05 is CLOSED:
  - `main.general.bronze_etoro_customer_customer_masked`
  - `main.general.bronze_etoro_history_customer_masked`
- Final parity mode requires unmasked PII sources or formal approval (MAG-06):
  - `main.pii_data.bronze_etoro_customer_customer`
  - `main.pii_data.bronze_etoro_history_customer`
- NOC and old Databricks attempt artifacts remain reference-only.

## Related docs

- `docs/reporting_job_preparation_plan.md`
- `docs/workflow_skeleton_design.md`
- `docs/workflow_orchestration_plan.md`
- `docs/workflow_execution_runbook.md`
- `docs/manual_approval_gates.md`
- `docs/workflow_governance_controls.md`
