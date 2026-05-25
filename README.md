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
