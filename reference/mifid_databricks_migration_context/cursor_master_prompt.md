# Cursor master prompt: MiFID migration to Databricks Ops staging

You are migrating MiFID table-generation logic from SQL Server / SSIS into Databricks.

## Current target environment

- Target catalog: `main`
- Target schema: `regtech_ops_stg`
- Mandatory object prefix: `bi_output_regtechops_`

Every persistent object created in `main.regtech_ops_stg` must start with `bi_output_regtechops_`. Objects without this prefix may be deleted by the overnight cleanup process.

## Current scope

In scope for this phase:

- Create MiFID staging/report tables in `main.regtech_ops_stg`.
- Recreate SSIS-created staging/ext tables needed by MiFID.
- Recreate MiFID stored procedure table-generation logic.
- Recreate the ASIC2-compatible subset needed by MiFID ETORO.
- Recreate regulation movement staging needed by `MIFID2_Report`.
- Recreate hedge liquidity mapping needed by Hedge EU/UK reports.
- Create validation and reconciliation SQL.
- Create a dependency coverage matrix before implementation.

Out of scope for this phase unless explicitly requested:

- CSV export
- 7z compression
- SFTP delivery
- Cappitech upload
- TRAX upload
- TRAX response-file processing
- production deployment into `main.regtech`
- full historical backfill

Historical data should be recreated or seeded only if needed for validation. Do not block the initial implementation on full historical backfill for `MIFID2_NPD_TRAX` or `ASIC2_Transactions`.

## First task

Before writing implementation code, create:

- `docs/dependency_coverage_matrix.md`
- `docs/unresolved_dependencies.md`
- `docs/ssis_created_staging_tables.md`
- `docs/static_reference_tables.md`
- `docs/final_output_tables.md`

Classify every object as one of:

- raw source
- SSIS-created staging table
- static/reference table
- final MiFID output
- audit/control table
- conditional/legacy dependency
- out of scope

For each object, document:

- old SQL Server name
- object type
- producer package or stored procedure
- consuming package/procedure
- Databricks source table if available
- Databricks target/compatibility object name
- status: Resolved / Needs implementation / Needs confirmation / Conditional / Out of scope
- validation checks required
- open questions

Important: do not treat old `*_Ext`, `MIFID2_ext_*`, `Reg_Ext_*`, or `ASIC2_ext_*` tables as missing raw sources if SSIS creates them. Use SSIS package logic to recreate them as Databricks workflow steps.

## Authoritative source material

Use SQL Server stored procedures, DDLs, SQL Agent jobs, Reports_Control, and SSIS packages as authoritative.

Use the old Databricks attempt only as reference/discovery material. Do not copy its implementation logic unless explicitly instructed.

Use NOC documents only as flow discovery. The NOC procedure was not implemented, so do not treat its SLAs, metrics, statuses, or thresholds as production logic.

## ASIC decision

ASIC2 is the current authoritative ASIC reporting process. Legacy ASIC still runs but should not be used as the MiFID migration source of truth.

Create a MiFID-owned ASIC2-compatible table/view in `main.regtech_ops_stg`, with the required prefix, to replace the old `dbo.ASIC_Transactions` dependency used by `SP_MIFID2_ETORO_Report`.

## Static references already available

- EDNF-to-InstrumentID temporary table: `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
- Internal accounts: `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`
- Dictionary special character lookup: `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`

## Important open decisions

- Currency / price / split source choices must be validated from SSIS logic before implementation.
- File delivery, compression, SFTP, TRAX/Cappitech response handling are out of scope for this phase.
- Historical seed/backfill is optional and should be documented where exact parity requires it.
