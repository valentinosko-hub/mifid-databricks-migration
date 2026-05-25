# Batch 5: SSIS project added

The SSIS project archive `eToro_RegulatoryReports_PROD.ispac` has been added under:

- `05_ssis/full_project_archive/`

The most relevant packages were extracted into:

- `05_ssis/selected_packages/`

Required/current-scope packages extracted:

- `MIFID2.dtsx`
- `MIFID2 TRAX.dtsx`
- `Pre_Regulation_Ext.dtsx`
- `Regulation_Movments_Report.dtsx`
- `HedgeServerToLiquidity_Mapping.dtsx`
- `Reg_Instrument_Operation.dtsx`
- `ASIC2.dtsx`
- `Project.params`

Optional/reference packages extracted:

- `MIFID2_TRAX_BACKREP2025.dtsx`
- `BestEX_Daily.dtsx`

Cursor should use these packages to classify old SQL Server staging tables as SSIS-created tables and to derive Databricks `bi_output_regtechops_*` refresh logic.
