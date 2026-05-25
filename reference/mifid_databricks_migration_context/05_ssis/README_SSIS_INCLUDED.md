# SSIS package inclusion

This package now includes the exported SSIS project archive and selected DTSX packages.

## Full project archive

- `05_ssis/full_project_archive/eToro_RegulatoryReports_PROD.ispac`

## Selected packages included for the current MiFID table-generation migration

- `05_ssis/selected_packages/MIFID2.dtsx`
- `05_ssis/selected_packages/MIFID2 TRAX.dtsx`
- `05_ssis/selected_packages/Pre_Regulation_Ext.dtsx`
- `05_ssis/selected_packages/Regulation_Movments_Report.dtsx`
- `05_ssis/selected_packages/HedgeServerToLiquidity_Mapping.dtsx`
- `05_ssis/selected_packages/Reg_Instrument_Operation.dtsx`
- `05_ssis/selected_packages/ASIC2.dtsx`
- `05_ssis/selected_packages/Project.params`

## Optional/reference packages included

- `05_ssis/selected_packages/optional_reference/MIFID2_TRAX_BACKREP2025.dtsx`
- `05_ssis/selected_packages/optional_reference/BestEX_Daily.dtsx`

## Important handling rule

Use SSIS packages for dependency discovery, orchestration reconstruction, and staging-table logic.
Do not copy secrets, connection strings, or operational credentials from SSIS into generated Databricks code.
