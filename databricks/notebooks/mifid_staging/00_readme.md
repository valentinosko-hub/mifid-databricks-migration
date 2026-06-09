# MiFID Staging Notebook Wrappers

This folder contains **staging-only notebook wrappers** for the MiFID RegTechOps migration.
They are companion artifacts to repository SQL templates under `databricks/sql/`.

## Scope and safety

- Target write schema: `main.regtech_ops_stg` only.
- Never write to `main.regtech`.
- Persistent object prefix remains `bi_output_regtechops_`.
- No delivery/upload/response logic in wrappers.
- `dry_run=true` by default.
- `dry_run=false` is gated and requires `staging_execution_approved=true` while still remaining staging-only.

## Shared notebook parameters

- `source_catalog`
- `source_schema`
- `target_catalog`
- `target_schema`
- `object_prefix`
- `report_date`
- `run_mode`
- `dry_run`
- `skip_delivery_steps`
- `allow_masked_customer_sources`
- `require_unmasked_pii_for_parity`
- `enable_manual_seed_testing_checks`
- `enable_masked_customer_structural_tests`
- `staging_execution_approved`

Defaults are aligned with `databricks/config/workflow_parameters.yml`.

## Execution model

Notebook wrappers are intentionally conservative:

- They reference existing repository SQL files.
- They do not rewrite business SQL logic.
- They do not execute SQL by default.
- Optional notebook paths remain optional and gated.

Legacy/old Databricks-style executable notebooks (embedded business SQL, direct `spark.sql`, table writes) are excluded from this folder. Only approved wrapper notebooks listed in `docs/notebook_job_execution_plan.md` belong here.

## Source of truth

Repository/Cursor-authored YAML, notebook wrappers, and docs remain the source of truth.
If Databricks UI/Genie/workspace edits are accepted, copy them back to this repo and commit to avoid drift.
