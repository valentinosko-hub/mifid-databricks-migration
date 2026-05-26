# Phase 1A - Final Output Tables

Authoritative source for SQL Server schemas:
`reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables`

Target naming rule applied in this phase:
- Catalog/schema: `main.regtech_ops_stg`
- Required prefix: `bi_output_regtechops_`

## SQL Server final outputs to Databricks targets

| SQL Server final output table | SQL Server DDL file | Databricks target table |
| --- | --- | --- |
| `dbo.MIFID2_Customer` | `MIFID2_Customer.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer` |
| `dbo.MIFID2_RegChange_Customer` | `MIFID2_RegChange_Customer.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer` |
| `dbo.MIFID2_Report` | `MIFID2_Report.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_report` |
| `dbo.MIFID2_ME_Report` | `MIFID2_ME_Report.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report` |
| `dbo.MIFID2_ETORO_Report` | `MIFID2_ETORO_Report.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report` |
| `dbo.MIFID2_Hedge_Report` | `MIFID2_Hedge_Report.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report` |
| `dbo.MIFID2_Removed_OP_Partials` | `MIFID2_Removed_OP_Partials.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials` |
| `dbo.MIFID2_NPD_TRAX` | `dbo.MIFID2_NPD_TRAX.sql` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` |

## Phase 1A schema notes from uploaded SQL Server DDLs

- `dbo.MIFID2_Hedge_Report` contains `RecordID INT IDENTITY(100000001,1)`; identity behavior must be explicitly handled in Databricks design.
- `dbo.MIFID2_Report` and `dbo.MIFID2_ME_Report` define nullable `UpdateDate` with no default in the uploaded DDL.
- `dbo.MIFID2_Removed_OP_Partials` includes `OpenORClose` as `NOT NULL`; insert logic should always use explicit column lists.
- SQL Server storage/index options in DDLs (clustered/nonclustered index definitions, filegroups, compression clauses) are not 1:1 migrated as physical Databricks storage settings.

## Step 10-11 status (`MIFID2_Customer` and `MIFID2_RegChange_Customer`)

- Authored Step 10 SQL artifacts:
  - `databricks/sql/08_outputs/01_mifid2_customer.sql`
  - `databricks/sql/08_outputs/01_mifid2_customer_validation.sql`
- Authored Step 11 SQL artifacts:
  - `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql`
  - `databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql`
- Current status:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer` is authored as a gated template and is not activated.
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer` is authored as a gated template and is not activated.
- Blocking gates before activation:
  - Step 9 `MIFID2_ext_Customer` / `MIFID2_Failed_TRAX` activation prerequisites
  - Step 9 `MIFID2_ext_RegChange_Customer` activation prerequisites
  - `Reg_Ext_CustomerLatinName` source/profile confirmation
  - `Dictionary.Ext_TradeFund` Databricks mapping confirmation
- Scope boundary preserved:
  - No implementation in this step for `MIFID2_Report`, `MIFID2_ME_Report`, `MIFID2_ETORO_Report`, `MIFID2_Hedge_Report`, or `MIFID2_NPD_TRAX`.
