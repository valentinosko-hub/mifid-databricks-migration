# Workflow Skeleton Design (Step 17B)

## Purpose

Define a non-executing Databricks workflow skeleton for MiFID phase-1 table/report generation in `main.regtech_ops_stg` using `bi_output_regtechops_` targets.

This design captures ordering, dependencies, parameters, and approval gates only. It does not activate business SQL.

## Scope

- Task-group orchestration skeleton for modules already authored under `databricks/sql/`.
- Gate wrappers and control manifests under `databricks/sql/10_workflow/`.
- Mode-aware policy handling for temporary masked-customer fallback vs final parity mode.

## Out of scope

- Workflow deployment or execution.
- Databricks job creation in workspace.
- CSV/7z/SFTP delivery.
- Cappitech/TRAX upload.
- TRAX response handling.
- Production deployment to `main.regtech`.
- New business transformation logic.

## Task order and dependencies

1. `preflight_readiness_checks`
2. `static_references_and_udfs`
3. `pre_regulation_ext_staging`
4. `regulation_movements`
5. `hedge_liquidity_scd`
6. `asic2_compatible_subset`
7. `mifid2_ext_staging`
8. `customer_outputs`
9. `main_report_outputs`
10. `etoro_report`
11. `hedge_report`
12. `npd_trax_table_generation`
13. `validation_packages`
14. `final_readiness_summary`

The skeleton encodes strict dependency chaining and keeps execution gated through `dry_run`, policy guards, and manual approval checkpoints.

## Run parameters

- `report_date`
- `catalog` (default `main`)
- `schema` (default `regtech_ops_stg`)
- `object_prefix` (default `bi_output_regtechops_`)
- `run_mode` (`development_structural_test` or `final_parity_production`)
- `dry_run` (default `true`)
- `dev_customer_source_mode` (`masked_fallback` or `pii_required`)
- `customer_source_policy` (default `temporary_masked_dev_only_v1`)
- `allow_masked_customer_sources` (default `false`)
- `require_unmasked_pii_for_parity` (default `true`)
- `skip_delivery_steps` (default `true`)
- `enable_validation_only` (default `true`)
- `sql_warehouse_id` placeholder
- `git_branch` placeholder

## Gate list

- Source access confirmed.
- Required columns confirmed.
- Storage/data scan blockers resolved.
- Static reference tables available.
- PII source policy approved.
- History/seed policy approved.
- `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` materialization approved.
- ASIC2 seed/history approved.
- NPD_TRAX history/cutover approved.
- Liquidity SCD seed/cutover approved.
- Hedge `RecordID` strategy approved.
- Hedge `TransactionReferenceNumber` parity approved.
- Final validation passed.
- SQL Server baseline comparison completed where required.

## Run modes and masked-customer fallback behavior

### Development / structural-test mode

- May use masked fallback only when explicitly enabled:
  - `main.general.bronze_etoro_customer_customer_masked`
  - `main.general.bronze_etoro_history_customer_masked`
- Allowed use: schema profiling, required-column checks, row counts, join-path checks, gated template development, non-production structural validation.
- Not allowed: final customer parity certification or final NPD parity certification.

### Final parity / production-candidate mode

- Requires unmasked PII sources:
  - `main.pii_data.bronze_etoro_customer_customer`
  - `main.pii_data.bronze_etoro_history_customer`
- Formal approval alternative may be accepted only from data owner / RegTech SME / Compliance.
- Masked fallback must be disabled.

## Validation order

Validation follows `docs/final_validation_execution_plan.md`:

1. Static reference checks
2. Source access / required-column checks
3. Pre_Regulation staging checks
4. Regulation movement checks
5. Hedge liquidity/SCD checks
6. ASIC2 compatibility checks
7. `MIFID2_ext` checks
8. Customer output checks
9. Main report output checks
10. ETORO checks
11. Hedge report checks
12. NPD_TRAX checks
13. Cross-output reconciliation
14. SQL Server baseline comparison (where available)

## What must happen before workflow activation

- Close or formally waive active blockers in `docs/open_blockers_for_execution.md`.
- Close required decisions tracked in `docs/remaining_decisions.md`.
- Complete prerequisites in `docs/execution_prerequisites.md`.
- Record manual approvals in `docs/workflow_manual_approval_checkpoints.md`.
- Keep NOC and old Databricks attempt materials reference-only.
