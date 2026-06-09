# Notebook Job Execution Plan — MiFID Staging Wrappers

## Purpose

Defines the **notebook-based companion workflow package** for MiFID staging execution support.
These notebooks are wrapper controls around repository SQL templates and remain **staging-only**.

## Scope boundaries

- Template-only / `do_not_deploy` notebook jobs.
- No production schedules.
- No production deployment.
- No writes to `main.regtech`.
- Write target remains `main.regtech_ops_stg` only.
- No delivery/upload/response paths in notebook wrappers.

## Source of truth

Repository/Cursor-authored notebooks, workflow YAML, and docs are authoritative.
If Databricks UI/Genie/workspace edits are accepted, copy them back to this repo and commit to prevent drift.

## Artifacts

| Artifact | Path |
| --- | --- |
| Notebook wrapper folder | `databricks/notebooks/mifid_staging/` |
| Notebook workflow package | `databricks/workflows/mifid_phase1_staging_notebook_jobs.yml` |
| SQL-task workflow package (unchanged) | `databricks/workflows/mifid_phase1_staging_jobs.yml` |
| Shared parameters | `databricks/config/workflow_parameters.yml` |

## Approved wrapper notebooks only

The staging wrapper package includes only these notebooks:

- `00_job_parameters.py`
- `01_readiness_checks.py`
- `02_static_reference_checks.py`
- `03_price_currency_split_staging.py`
- `04_non_price_reg_ext_staging.py`
- `05_regulation_movement_staging.py`
- `06_hedge_liquidity_staging.py`
- `07_asic2_structural_staging.py`
- `08_mifid2_ext_non_pii_staging.py`
- `09_optional_masked_customer_structural.py`
- `10_optional_manual_seed_testing.py`
- `11_optional_hedge_recordid_registry.py`
- `12_validation_summary.py`
- `99_common_utils.py`

Legacy/old Databricks-style executable notebooks are excluded from the staging wrapper package. The current package uses wrapper notebooks that reference governed SQL templates and shared staging guards.

## Parameter policy

All wrapper notebooks read shared parameters:

- `source_catalog`, `source_schema`
- `target_catalog`, `target_schema`
- `object_prefix`, `report_date`
- `run_mode`, `dry_run`, `skip_delivery_steps`
- `allow_masked_customer_sources`, `require_unmasked_pii_for_parity`
- `enable_manual_seed_testing_checks`, `enable_masked_customer_structural_tests`
- `staging_execution_approved`

Defaults remain:

- `source_catalog=main`, `source_schema=regtech`
- `target_catalog=main`, `target_schema=regtech_ops_stg`
- `object_prefix=bi_output_regtechops_`
- `run_mode=development_structural_test`
- `dry_run=true`
- `skip_delivery_steps=true`
- optional feature flags false by default

## Safety guards

Notebook wrappers enforce:

- target schema safety (`main.regtech_ops_stg` only; not `regtech`)
- no delivery/upload/response scope
- no write target in `main.regtech`
- dry-run-first behavior
- guarded non-dry-run path requires `staging_execution_approved=true`

## Execution sequence

Default one-by-one order:

1. `mifid_notebook_staging_readiness_job_do_not_deploy` (required first)
2. Jobs 2–8 module wrappers (one at a time)
3. `mifid_notebook_staging_validation_summary_job_do_not_deploy`

Optional only:

- Job 9 manual seed testing
- Job 10 Hedge RecordID registry

## Gated exclusions

- Final `MIFID2_NPD_TRAX` remains last and gated.
- Final `MIFID2_Failed_TRAX` remains gated on NPD history.
- Final Hedge activation remains gated on RecordID registry validation.
- Final customer/NPD parity remains gated on PII access or formal exception.

## Evidence policy

- Store evidence outside Git in approved secure storage.
- Do not commit raw CSVs, extracts, PII samples, credentials, or `.env` files.
- Use `docs/staging_execution_evidence_log.md` as schema/template only.
