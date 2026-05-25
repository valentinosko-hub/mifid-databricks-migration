# Ingested uploaded files in this package version

This package includes the latest uploaded batch placed into the agreed folder structure.

## Stored procedures

- `01_sql_server_stored_procedures/supporting/SP_InstrumentMetaData_SpecialChar_Conversion.sql`
- `01_sql_server_stored_procedures/asic2/SP_ASIC2_Instrument_Automation.sql`
- `01_sql_server_stored_procedures/asic2/SP_ASIC2_PositionReport.sql`
- `01_sql_server_stored_procedures/asic2/SP_ASIC2_PositionReport_Agg.sql`

## Source/reference DDLs

- `02_sql_server_ddls/source_reference_tables/Dictionary_Ext_SpecialChar.sql`
- `02_sql_server_ddls/source_reference_tables/InternalAccounts.sql`
- `02_sql_server_ddls/source_reference_tables/ISO_Currencies_Static.sql`

## SSIS-created/intermediate DDLs

- `02_sql_server_ddls/ssis_created_staging_tables/Reg_Instruments_ext.sql`
- `02_sql_server_ddls/ssis_created_staging_tables/InstrumentMetaData_SpecialChar_Conversion.sql`

## ASIC2 DDLs

- `02_sql_server_ddls/asic2_tables/ASIC2_ext_PositionChangeLog.sql`
- `02_sql_server_ddls/asic2_tables/ASIC2_ext_OpenPositions_PositionsReport.sql`
- `02_sql_server_ddls/asic2_tables/ASIC2_Removed_OP_Partials.sql`
- `02_sql_server_ddls/asic2_tables/ASIC2_InstrumentMetaData.sql`
- `02_sql_server_ddls/asic2_tables/ASIC2_Positions.sql`
- `02_sql_server_ddls/asic2_tables/ASIC2_Customer_PositionReport.sql`

## Legacy ASIC reference only

- `02_sql_server_ddls/legacy_asic_reference_only/ASIC_ext_OpenPositions_PositionsReport.sql`
- `02_sql_server_ddls/legacy_asic_reference_only/ASIC_ext_PositionChangeLog.sql`

## SQL Agent / control metadata

- `04_sql_agent_jobs/PROD - Regulations - ASIC2.sql`
- `04_sql_agent_jobs/Reports_Control.csv`

## Reference data

- `07_reference_data/Dictionary_Ext_SpecialChar.csv`

## Still to add from earlier collection for a complete Cursor package

- Core MiFID stored procedures
- Core MiFID output table DDLs
- SQL Agent jobs for ALL_NEW, MIFID2, MIFID2 TRAX, Movments Report, HedgeServerToLiquidity, Reg Instrument SCD, Reg_Instruements_Operation, Reg_Every_30_Minutes
- `eToro_RegulatoryReports_PROD.ispac`
- Selected `.dtsx` packages
- SSIS metadata CSVs
- `RegTech fivetran.xlsx`, if you want Cursor to inspect it directly
- Old Databricks attempt ZIP, only as reference-only

## Uploaded batch 2 ingested

Placed files:

- `ASIC2_Transactions.sql` -> `02_sql_server_ddls/asic2_tables/ASIC2_Transactions.sql`
- `ssis_environment_variables_masked.csv` -> `05_ssis/metadata/ssis_environment_variables_masked.csv`
- `ssis_environment_references.csv` -> `05_ssis/metadata/ssis_environment_references.csv`
- `ssis_parameters.csv` -> `05_ssis/metadata/ssis_parameters.csv`
- `job_schedules.csv` -> `04_sql_agent_jobs/job_schedules.csv`
- `job_steps.csv` -> `04_sql_agent_jobs/job_steps.csv`
- `PROD - Regulations - Reg_Every_30_Minutes.sql` -> `04_sql_agent_jobs/PROD - Regulations - Reg_Every_30_Minutes.sql`
- `PROD - Regulations - ALL_NEW.sql` -> `04_sql_agent_jobs/PROD - Regulations - ALL_NEW.sql`
- `PROD - Regulations - Reg_Instruements_Operation.sql` -> `04_sql_agent_jobs/PROD - Regulations - Reg_Instruements_Operation.sql`
- `PROD - Regulations - Reg Instrument SCD.sql` -> `04_sql_agent_jobs/PROD - Regulations - Reg Instrument SCD.sql`
- `PROD - Regulation HedgeServerToLiquidity_Mapping.sql` -> `04_sql_agent_jobs/PROD - Regulation HedgeServerToLiquidity_Mapping.sql`
- `PROD - Regulations - MIFID2 TRAX.sql` -> `04_sql_agent_jobs/PROD - Regulations - MIFID2 TRAX.sql`
- `PROD - Regulations - MIFID2.sql` -> `04_sql_agent_jobs/PROD - Regulations - MIFID2.sql`
- `PROD - Regulations - Movments Report.sql` -> `04_sql_agent_jobs/PROD - Regulations - Movments Report.sql`
- `SP_Reg_LiquidtyAcount_SCD.sql` -> `01_sql_server_stored_procedures/supporting/SP_Reg_LiquidtyAcount_SCD.sql`
- `dbo.MIFID2_NPD_TRAX.sql` -> `02_sql_server_ddls/target_output_tables/dbo.MIFID2_NPD_TRAX.sql`
- `SP_MIFID2_NPD_TRAX.sql` -> `01_sql_server_stored_procedures/core_mifid/SP_MIFID2_NPD_TRAX.sql`
- `LP_IB_U1059976_Open_Positions_All.sql` -> `02_sql_server_ddls/source_reference_tables/synapse_source_tables/LP_IB_U1059976_Open_Positions_All.sql`
- `Ext_Country.sql` -> `02_sql_server_ddls/source_reference_tables/Ext_Country.sql`
- `Ext_TradeFund.sql` -> `02_sql_server_ddls/source_reference_tables/Ext_TradeFund.sql`

## Batch 2 uploaded files ingested
Ingested on: 2026-05-22T10:38:05.326995Z

| Source file | Destination in package |
|---|---|
| `ASIC2_Transactions.sql` | `02_sql_server_ddls/asic2_tables/ASIC2_Transactions.sql` |
| `ssis_environment_variables_masked.csv` | `05_ssis/metadata/ssis_environment_variables_masked.csv` |
| `ssis_environment_references.csv` | `05_ssis/metadata/ssis_environment_references.csv` |
| `ssis_parameters.csv` | `05_ssis/metadata/ssis_parameters.csv` |
| `job_schedules.csv` | `04_sql_agent_jobs/job_schedules.csv` |
| `job_steps.csv` | `04_sql_agent_jobs/job_steps.csv` |
| `PROD - Regulations - Reg_Every_30_Minutes.sql` | `04_sql_agent_jobs/PROD - Regulations - Reg_Every_30_Minutes.sql` |
| `PROD - Regulations - ALL_NEW.sql` | `04_sql_agent_jobs/PROD - Regulations - ALL_NEW.sql` |
| `PROD - Regulations - Reg_Instruements_Operation.sql` | `04_sql_agent_jobs/PROD - Regulations - Reg_Instruements_Operation.sql` |
| `PROD - Regulations - Reg Instrument SCD.sql` | `04_sql_agent_jobs/PROD - Regulations - Reg Instrument SCD.sql` |
| `PROD - Regulation HedgeServerToLiquidity_Mapping.sql` | `04_sql_agent_jobs/PROD - Regulation HedgeServerToLiquidity_Mapping.sql` |
| `PROD - Regulations - MIFID2 TRAX.sql` | `04_sql_agent_jobs/PROD - Regulations - MIFID2 TRAX.sql` |
| `PROD - Regulations - MIFID2.sql` | `04_sql_agent_jobs/PROD - Regulations - MIFID2.sql` |
| `PROD - Regulations - Movments Report.sql` | `04_sql_agent_jobs/PROD - Regulations - Movments Report.sql` |
| `SP_Reg_LiquidtyAcount_SCD.sql` | `01_sql_server_stored_procedures/supporting/SP_Reg_LiquidtyAcount_SCD.sql` |
| `dbo.MIFID2_NPD_TRAX.sql` | `02_sql_server_ddls/target_output_tables/dbo.MIFID2_NPD_TRAX.sql` |
| `SP_MIFID2_NPD_TRAX.sql` | `01_sql_server_stored_procedures/core_mifid/SP_MIFID2_NPD_TRAX.sql` |
| `LP_IB_U1059976_Open_Positions_All.sql` | `02_sql_server_ddls/external_synapse_tables/LP_IB_U1059976_Open_Positions_All.sql` |
| `Ext_Country.sql` | `02_sql_server_ddls/source_reference_tables/Ext_Country.sql` |
| `Ext_TradeFund.sql` | `02_sql_server_ddls/source_reference_tables/Ext_TradeFund.sql` |

## Batch 3 uploaded files ingested

| Source file | Destination in package |
|---|---|
| `MIFID2_Instruments_To_Exclude.sql` | `02_sql_server_ddls/source_reference_tables/MIFID2_Instruments_To_Exclude.sql` |
| `MIFID2_Failed_TRAX.sql` | `02_sql_server_ddls/ssis_created_staging_tables/MIFID2_Failed_TRAX.sql` |
| `Reg_Ext_HistorySplitRatio.sql` | `02_sql_server_ddls/source_reference_tables/Reg_Ext_HistorySplitRatio.sql` |
| `Reg_Ext_Trade_InstrumentMetaData.sql` | `02_sql_server_ddls/source_reference_tables/Reg_Ext_Trade_InstrumentMetaData.sql` |
| `Reg_Ext_Trade_GetInstrument.sql` | `02_sql_server_ddls/source_reference_tables/Reg_Ext_Trade_GetInstrument.sql` |
| `dbo.Reg_Ext_HedgeHBCOrderLog.sql` | `02_sql_server_ddls/source_reference_tables/dbo.Reg_Ext_HedgeHBCOrderLog.sql` |
| `Reg_Ext_HedgeOrderLog.sql` | `02_sql_server_ddls/source_reference_tables/Reg_Ext_HedgeOrderLog.sql` |
| `Dealing_staging.LP_EdnF_CoreTrades.sql` | `02_sql_server_ddls/external_synapse_tables/Dealing_staging.LP_EdnF_CoreTrades.sql` |
| `Dealing_staging.LP_IB_U1059976_Open_Positions_All.sql` | `02_sql_server_ddls/external_synapse_tables/Dealing_staging.LP_IB_U1059976_Open_Positions_All.sql` |
| `MIFID2_Hedge_Report.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_Hedge_Report.sql` |
| `MIFID2_RegChange_Customer.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_RegChange_Customer.sql` |
| `MIFID2_Report.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_Report.sql` |
| `MIFID2_Customer.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_Customer.sql` |
| `MIFID2_ETORO_Report.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_ETORO_Report.sql` |
| `MIFID2_Removed_OP_Partials.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_Removed_OP_Partials.sql` |
| `MIFID2_ME_Report.sql` | `02_sql_server_ddls/target_output_tables/MIFID2_ME_Report.sql` |
| `[SP_Reg_US_Reconsile].sql` | `01_sql_server_stored_procedures/reference_other_regulatory_us/[SP_Reg_US_Reconsile].sql` |
| `[SP_Reg_US_ROrders].sql` | `01_sql_server_stored_procedures/reference_other_regulatory_us/[SP_Reg_US_ROrders].sql` |
| `[SP_Reg_US_NOrders].sql` | `01_sql_server_stored_procedures/reference_other_regulatory_us/[SP_Reg_US_NOrders].sql` |
| `SP_Reg_US_Customers.sql` | `01_sql_server_stored_procedures/reference_other_regulatory_us/SP_Reg_US_Customers.sql` |

Note: US regulatory procedures are reference-only unless a direct MiFID dependency is identified.

## Batch 4 filtered additions

Relevant and included:

- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_Customer.sql
- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_RegChange_Customer.sql
- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_Report.sql
- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_ETORO_Report.sql
- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_HedgeEU_Report.sql
- 01_sql_server_stored_procedures/core_mifid/SP_MIFID_HedgeUK_Report.sql
- 01_sql_server_stored_procedures/supporting/SP_RegInRegOutPopulation.sql
- 01_sql_server_stored_procedures/supporting/SP_Reg_Instruments_SCD.sql
- 01_sql_server_stored_procedures/asic2/SP_ASIC2_TransactionsReport.sql
- 01_sql_server_stored_procedures/asic2/SP_ASIC2_PositionReport.sql
- 01_sql_server_stored_procedures/asic2/SP_ASIC2_PositionReport_Agg.sql
- 01_sql_server_stored_procedures/asic2/SP_ASIC2_Instrument_Automation.sql

Intentionally not included in active folders:

- SP_Reg_US_Customers.sql
- [SP_Reg_US_NOrders].sql
- [SP_Reg_US_ROrders].sql
- [SP_Reg_US_Reconsile].sql
- SP_ASIC_CollateralReport.sql
- SP_ASIC_TransactionsReport_Hedge.sql
- SP_ASIC_PositionReport_Agg_Hedge.sql

## Batch 5 - SSIS project archive and selected package extraction

Included:

- `05_ssis/full_project_archive/eToro_RegulatoryReports_PROD.ispac`
- `05_ssis/selected_packages/Project.params`
- `05_ssis/selected_packages/MIFID2.dtsx`
- `05_ssis/selected_packages/MIFID2 TRAX.dtsx`
- `05_ssis/selected_packages/Pre_Regulation_Ext.dtsx`
- `05_ssis/selected_packages/Regulation_Movments_Report.dtsx`
- `05_ssis/selected_packages/HedgeServerToLiquidity_Mapping.dtsx`
- `05_ssis/selected_packages/Reg_Instrument_Operation.dtsx`
- `05_ssis/selected_packages/ASIC2.dtsx`
- `05_ssis/selected_packages/optional_reference/MIFID2_TRAX_BACKREP2025.dtsx`
- `05_ssis/selected_packages/optional_reference/BestEX_Daily.dtsx`
