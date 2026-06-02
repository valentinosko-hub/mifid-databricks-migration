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
- full historical backfill

Reference material is under:

reference/mifid_databricks_migration_context/

Do not modify reference files directly.

## Final handoff and readiness (Step 16)

Start here when continuing implementation or validation:

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

**Status:** SQL templates and validation packages are authored; Databricks execution has not been performed. Manager-approved masked customer tables may be used for temporary development/structural testing only. Final parity remains blocked until `main.pii_data` access and other prerequisites in the blocker and decision documents are resolved.
