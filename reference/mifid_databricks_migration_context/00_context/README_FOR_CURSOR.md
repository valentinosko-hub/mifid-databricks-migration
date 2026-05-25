# MiFID Databricks Migration Context

## Current task
Migrate MiFID table-generation logic from SQL Server / SSIS into Databricks.

## Current target environment
- Catalog: `main`
- Schema: `regtech_ops_stg`
- Mandatory object prefix: `bi_output_regtechops_`

Every persistent object created in `main.regtech_ops_stg` must start with `bi_output_regtechops_`. Objects without this prefix may be deleted by the overnight cleanup process.

## Current scope
Table/report generation only.

### In scope for this phase
- Recreate SSIS-created MiFID staging/ext tables.
- Recreate MiFID stored-procedure logic.
- Recreate the ASIC2-compatible subset needed by MiFID ETORO.
- Recreate regulation movement staging needed by `MIFID2_Report`.
- Recreate hedge liquidity mapping needed by Hedge EU/UK reports.
- Create final MiFID output tables in `main.regtech_ops_stg`.
- Create validation/reconciliation SQL.
- Create dependency coverage documentation.

### Out of scope for this phase unless explicitly added later
- CSV export.
- 7z compression.
- SFTP delivery.
- Cappitech upload.
- TRAX upload.
- TRAX response processing.
- Production deployment into `main.regtech` / production `regtech` schemas.
- Full historical backfill.

## Authoritative sources
Use the following as authoritative for current logic:
- SQL Server stored procedures.
- SQL Server DDLs.
- SQL Agent job scripts and metadata.
- SSIS packages from the exported `.ispac`.
- Current source-to-Databricks mapping files in `06_mappings`.

## Reference-only material
- The old Databricks attempt is reference-only. Do not copy its implementation logic unless explicitly approved.
- NOC documents are reference-only. The NOC procedure was not implemented, so do not treat SLAs, statuses, metrics, or thresholds as production logic.

## Critical implementation rule
Do not treat old `*_Ext`, `MIFID2_ext_*`, `Reg_Ext_*`, `ASIC2_ext_*`, and similar staging tables as missing raw source tables when SSIS creates them. Use the SSIS packages to recreate them as Databricks workflow/staging steps in `main.regtech_ops_stg` using the `bi_output_regtechops_` prefix.
