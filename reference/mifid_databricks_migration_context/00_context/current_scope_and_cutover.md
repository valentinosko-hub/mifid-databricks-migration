# Current Scope and Cutover Strategy

## Scope
The current phase is Databricks table/report generation only.

The goal is to create the MiFID-required staging and reporting tables in `main.regtech_ops_stg` and prove that they match the current SQL Server/SSMS outputs for selected report dates.

## Out of scope for now
- CSV generation.
- 7z compression.
- SFTP delivery.
- Cappitech upload.
- TRAX upload.
- TRAX response-file handling.
- Full historical backfill.
- Production deployment.

## Historical strategy
Do not block the first implementation on a full historical backfill.

Some procedures depend on historical rows:
- `MIFID2_NPD_TRAX`
- `ASIC2_Transactions`

Implement current/future table-generation logic first. If exact validation for older dates requires historical seed data, document the exact dependency and support an optional seed/rebuild step. Data Engineering can load historical data later once the target tables exist.
