# Dependency Coverage Matrix Instruction for Cursor

Before writing implementation code, create a dependency coverage matrix.

Create:
- `docs/dependency_coverage_matrix.md`
- `docs/unresolved_dependencies.md`
- `docs/ssis_created_staging_tables.md`
- `docs/static_reference_tables.md`
- `docs/final_output_tables.md`

The matrix must compare:
1. Every object referenced by the SQL stored procedures.
2. Every object created/read by the SSIS packages.
3. Every SQL Agent job dependency.
4. Every known Databricks source mapping.
5. Every target object that must be created in `main.regtech_ops_stg`.

Classify each object as:
- raw source
- SSIS-created staging table
- static/reference table
- final MiFID output
- audit/control table
- conditional/legacy dependency
- out of scope

For every object, include:
- old SQL Server name
- producer package or stored procedure
- consuming procedure/package
- Databricks source table if available
- Databricks target/compatibility object name
- status: Resolved / Needs implementation / Needs confirmation / Conditional / Out of scope
- validation checks required
- open questions

Important:
Do not treat old `*_Ext`, `MIFID2_ext_*`, `Reg_Ext_*`, `ASIC2_ext_*`, or other staging tables as missing raw sources if SSIS creates them.
Use SSIS package logic to recreate them as Databricks workflow steps.

All Databricks objects created in `main.regtech_ops_stg` must start with:
`bi_output_regtechops_`.
