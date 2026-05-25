# Batch 2 ingestion notes

This package version includes the second batch of uploaded artifacts, including ASIC2_Transactions DDL, SSIS metadata CSVs, SQL Agent job scripts, MiFID NPD/TRAX artifacts, Synapse IB table DDL, and Dictionary reference DDLs.

Notable additions:
- `ASIC2_Transactions.sql` added to `02_sql_server_ddls/asic2_tables/`
- SQL Agent job scripts and job metadata added to `04_sql_agent_jobs/`
- SSIS metadata CSVs added to `05_ssis/metadata/`
- `SP_MIFID2_NPD_TRAX.sql` added to core MiFID stored procedures
- `dbo.MIFID2_NPD_TRAX.sql` added to target output DDLs
- `SP_Reg_LiquidtyAcount_SCD.sql` added to supporting stored procedures
- `LP_IB_U1059976_Open_Positions_All.sql` added to external Synapse table DDLs
- `Ext_Country.sql` and `Ext_TradeFund.sql` added to source/reference DDLs

Reminder: all persistent Databricks objects created in `main.regtech_ops_stg` must start with `bi_output_regtechops_`.
