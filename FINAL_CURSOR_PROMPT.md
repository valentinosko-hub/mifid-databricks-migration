# FINAL CURSOR PROMPT — MiFID SQL Server / SSIS to Databricks Ops Staging

You are a senior Databricks data engineer and SQL Server/SSIS migration specialist.

We are migrating the MiFID table-generation process from SQL Server / SSIS into Databricks. The current goal is to build and validate the Databricks staging/reporting tables in the RegTech Ops staging environment so we can compare them against the current SSMS/SQL Server outputs. Production deployment into the final `regtech` production schema will happen later after validation.

## 1. Current target environment and strict naming rule

Current target catalog/schema:

```text
main.regtech_ops_stg
```

Every persistent object created in `main.regtech_ops_stg` must start with:

```text
bi_output_regtechops_
```

This applies to:

```text
Delta tables
managed tables
views
compatibility views
audit tables
validation/reconciliation tables
UDFs/functions if created in this schema
```

Do not create any persistent object in `main.regtech_ops_stg` without this prefix. Objects that do not follow this prefix may be deleted by the overnight cleanup process.

Use configuration variables where possible:

```text
target_catalog = "main"
target_schema = "regtech_ops_stg"
object_prefix = "bi_output_regtechops_"
```

Do not create objects in production `main.regtech` or any production `regtech` schema in this phase.

## 2. Current phase scope

In scope for this phase:

```text
1. Build Databricks staging/report-table generation logic in main.regtech_ops_stg.
2. Recreate SSIS-created staging/ext tables needed by MiFID.
3. Recreate MiFID stored procedure table-generation logic.
4. Recreate the ASIC2-compatible subset needed by MiFID ETORO.
5. Recreate regulation movement staging needed by MIFID2_Report.
6. Recreate hedge liquidity mapping needed by Hedge EU/UK reports.
7. Create final MiFID output tables in main.regtech_ops_stg.
8. Create validation and reconciliation SQL.
9. Create documentation and dependency coverage matrix before implementation.
```

Out of scope for this phase unless explicitly requested later:

```text
CSV export
7z compression
SFTP delivery
Cappitech upload
TRAX upload
TRAX response-file processing
archive-folder automation
production deployment into main.regtech
```

Historical seed/backfill policy (approved; see `docs/history_seed_requirements.md`):

- Seed all historical data required for reporting, retry logic, SCD validity, missed-trade back-reporting, identity continuity, and SQL Server baseline comparison.
- If the minimum safe historical window cannot be proven, seed all available history for that object.
- Strategy direction is approved; seed implementation, extract ownership, and sequencing remain pending and gated.
- Do not block SQL template authoring on completed seed loads, but do not mark modules execution-ready or claim parity-complete while required historical seed implementation is still pending.

## 3. Important source-of-truth rule

Use these as authoritative current-state sources:

```text
SQL Server stored procedures
SQL Server DDLs
SQL Agent job scripts
Reports_Control.csv
SSIS packages from eToro_RegulatoryReports_PROD.ispac
SSIS metadata CSVs
confirmed source-to-Databricks mapping files
```

Use the previous Databricks attempt only as reference/discovery material. Do not copy its implementation logic unless explicitly instructed.

Use NOC files only for flow discovery. The NOC procedure was not implemented, so do not treat NOC SLAs, statuses, metrics, or thresholds as production logic.

## 4. First required task before implementation

Before writing implementation code, create these documentation files:

```text
docs/dependency_coverage_matrix.md
docs/unresolved_dependencies.md
docs/ssis_created_staging_tables.md
docs/static_reference_tables.md
docs/final_output_tables.md
docs/source_to_databricks_mapping_review.md
docs/migration_execution_order.md
docs/open_questions_and_decisions.md
```

The dependency coverage matrix must compare:

```text
1. Every object referenced by SQL stored procedures.
2. Every object created/read by SSIS packages.
3. Every SQL Agent job dependency.
4. Every known Databricks source mapping.
5. Every target/compatibility object to be created in main.regtech_ops_stg.
```

Classify every object as one of:

```text
raw source
SSIS-created staging table
static/reference table
final MiFID output
audit/control table
conditional/legacy dependency
out of scope
```

For each object, document:

```text
old SQL Server object name
object type
producer package or stored procedure
consuming package/procedure
Databricks source table if available
Databricks target/compatibility object name
status: Resolved / Needs implementation / Needs confirmation / Conditional / Out of scope
validation checks required
open questions
notes
```

Important: do not treat old `*_Ext`, `MIFID2_ext_*`, `Reg_Ext_*`, `ASIC2_ext_*`, or other staging tables as missing raw sources if SSIS creates them. Use SSIS package logic to recreate them as Databricks workflow steps or compatibility tables/views.

## 5. Required target output tables

Create these MiFID output tables in `main.regtech_ops_stg` with the required prefix:

```text
dbo.MIFID2_Customer
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_customer

dbo.MIFID2_RegChange_Customer
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer

dbo.MIFID2_Report
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_report

dbo.MIFID2_ME_Report
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report

dbo.MIFID2_ETORO_Report
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report

dbo.MIFID2_Hedge_Report
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report

dbo.MIFID2_Removed_OP_Partials
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials

dbo.MIFID2_NPD_TRAX
-> main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
```

Use the SQL Server DDLs in `02_sql_server_ddls/target_output_tables/` as the authoritative output schemas.

Do not directly copy SQL Server clustered indexes, nonclustered indexes, filegroups, page compression, or SQL Server storage settings into Databricks. Convert SQL Server keys/unique constraints into data-quality checks and duplicate validation.

Special notes:

```text
MIFID2_Hedge_Report has RecordID as SQL Server IDENTITY(100000001,1). Decide and document how to handle this in Databricks.
MIFID2_Report and MIFID2_ME_Report have nullable UpdateDate with no default in uploaded DDLs. Do not invent a default.
MIFID2_Removed_OP_Partials was inserted without a column list in SQL Server. Rewrite with explicit columns.
```

## 6. Core stored procedures to migrate

Core MiFID stored procedures:

```text
SP_MIFID_Customer.sql
SP_MIFID_RegChange_Customer.sql
SP_MIFID_Report.sql
SP_MIFID_ETORO_Report.sql
SP_MIFID_HedgeEU_Report.sql
SP_MIFID_HedgeUK_Report.sql
SP_MIFID2_NPD_TRAX.sql
```

Supporting procedures:

```text
SP_Reg_LiquidtyAcount_SCD.sql
SP_RegInRegOutPopulation.sql
SP_InstrumentMetaData_SpecialChar_Conversion.sql
SP_Reg_Instruments_SCD.sql  -- lineage/reference for instrument/FIRDS logic
```

ASIC2 procedures needed for MiFID ETORO dependency replacement:

```text
SP_ASIC2_Instrument_Automation.sql
SP_ASIC2_PositionReport.sql
SP_ASIC2_PositionReport_Agg.sql
SP_ASIC2_TransactionsReport.sql
```

Legacy/non-current ASIC procedures should not be used as source of truth for MiFID unless only for comparison.

## 7. SSIS and SQL Agent orchestration

Use these SSIS packages as authoritative for staging/extract logic and execution flow:

```text
MIFID2.dtsx
MIFID2 TRAX.dtsx
Pre_Regulation_Ext.dtsx
Regulation_Movments_Report.dtsx
HedgeServerToLiquidity_Mapping.dtsx
Reg_Instrument_Operation.dtsx
ASIC2.dtsx
```

Optional reference packages:

```text
MIFID2_TRAX_BACKREP2025.dtsx
BestEX_Daily.dtsx
```

Use SQL Agent job scripts and metadata to understand old scheduling/order:

```text
PROD - Regulations - ALL_NEW.sql
PROD - Regulations - MIFID2.sql
PROD - Regulations - MIFID2 TRAX.sql
PROD - Regulations - Movments Report.sql
PROD - Regulation HedgeServerToLiquidity_Mapping.sql
PROD - Regulations - Reg Instrument SCD.sql
PROD - Regulations - Reg_Instruements_Operation.sql
PROD - Regulations - Reg_Every_30_Minutes.sql
PROD - Regulations - ASIC2.sql
job_steps.csv
job_schedules.csv
Reports_Control.csv
ssis_parameters.csv
ssis_environment_references.csv
ssis_environment_variables_masked.csv
```

Known production flow from SSIS/SQL Agent:

```text
ALL_NEW runs Pre_Regulation_Ext.dtsx before Movments Report and MiFID.
Regulation_Movments_Report.dtsx creates Reg_Regulation_Movments_Positions.
MIFID2.dtsx creates MIFID2_ext_* staging tables and runs core MiFID SPs.
MIFID2 TRAX.dtsx runs SP_MIFID2_NPD_TRAX and handles TRAX file/response flow, but file/response processing is out of scope for this phase.
HedgeServerToLiquidity_Mapping.dtsx refreshes liquidity-account mapping and runs SP_Reg_LiquidtyAcount_SCD.
ASIC2.dtsx is the current ASIC process; MiFID should use ASIC2-compatible logic instead of legacy ASIC_Transactions.
```

Do not copy secrets, connection strings, passwords, SFTP credentials, storage keys, or tokens from SSIS/job metadata into generated code. Use placeholders/config variables.

## 8. SSIS-created staging tables to recreate

Do not ask for these as raw source tables. Recreate them from SSIS logic and known Databricks sources.

### MIFID2.dtsx staging

```text
MIFID2_ext_Customer
MIFID2_ext_RegChange_Customer
MIFID2_ext_Position
MIFID2_ext_RegChange_Position
MIFID2_ext_PositionChangeLog
MIFID2_ext_Mirror
MIFID2_ext_HedgeExecutionLog
MIFID2_Failed_TRAX
InstrumentMetaData_SpecialChar_Conversion
```

### Pre_Regulation_Ext.dtsx staging

```text
Reg_CurrencyPrice_Ext
Reg_Ext_CurrencyPriceMaxDateWithSplit
Reg_Ext_DailyMaxPrices
Reg_Ext_T_PriceCandle60Min
Reg_Ext_MigrationInOut_STG
Reg_MigrationInOut_Population
Reg_RegulationInOutDailyData
Reg_Ext_CustomerLatinName
Reg_Ext_HistorySplitRatio
Reg_Ext_Trade_GetInstrument
Reg_Ext_Trade_InstrumentMetaData
Reg_Ext_DictionaryCurrency
Reg_Ext_DictionaryCurrencyType
Reg_Ext_HedgeExecutionLog
Reg_Ext_HedgeHBCExecutionLog
Reg_Ext_HedgeHBCOrderLog
Reg_Instruments_ext
```

### Regulation_Movments_Report.dtsx

```text
Reg_Regulation_Movments_Positions
```

### HedgeServerToLiquidity_Mapping.dtsx

```text
Reg_HedgeServerToLiquidityAccount_Ext
Reg_LiquidtyAcount_Ext
Reg_Ext_LiquidityAccountID
Reg_Ext_LiquidityProviders
Reg_LiquidtyAcount_SCD
```

### ASIC2.dtsx / ASIC2 SP staging

```text
ASIC2_ext_OpenPositions_PositionsReport
ASIC2_ext_PositionChangeLog
ASIC2_Customer_PositionReport
ASIC2_Positions
ASIC2_InstrumentMetaData
ASIC2_Removed_OP_Partials
ASIC2_Transactions
```

Create target objects for these only if needed by the MiFID table-generation flow. All created objects must use `bi_output_regtechops_` prefix.

## 9. Confirmed source-to-Databricks mappings

Use the mappings in:

```text
06_mappings/source_to_datalake_mapping.md
06_mappings/gsheet_excel_fivetran_mapping.md
06_mappings/firds_lineage_mapping.md
06_mappings/static_tables_created_in_regtech_ops_stg.md
```

Important mappings include:

```text
dbo.Reg_Instruments_SCD
-> main.regtech.gold_regtech_reg_instruments_scd

dbo.Reg_Instruments_Full_Description
-> main.regtech.gold_regtech_reg_instruments_full_description

FIRDS/FCA FIRDS gold tables are confirmed certified sources. Do not rebuild raw FIRDS unless required later.

dbo.Reg_MigrationInOut_Population
-> main.regtech.gold_regtech_reg_migrationinout_population

dbo.Reg_RegulationInOutDailyData
-> main.regtech.gold_regtech_reg_regulationinoutdailydata

SYNAPSE LP_EdnF_CoreTrades
-> main.general.gold_ednf_coretrades

SYNAPSE LP_IB_U1059976_Open_Positions_All
-> main.general.gold_ib_u1059976_open_positions_all

Dictionary.Country
-> main.general.bronze_etoro_dictionary_country

Dictionary.Label
-> main.general.bronze_etoro_dictionary_label

Customer.Customer
-> main.general.bronze_etoro_customer_customer

History.Customer
-> main.pii_data.bronze_etoro_history_customer

Customer.ExtendedUserField
-> main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield

Dictionary.ExtendedUserValueType
-> main.compliance.bronze_userapidb_dictionary_extendeduservaluetype

Trade.Position
-> main.trading.silver_etoro_trade_position

History.Position
-> main.trading.bronze_etoro_history_position_datafactory

History.Mirror
-> main.trading.bronze_etoro_history_mirror

History.PositionChangeLog
-> main.trading.bronze_etoro_history_positionchangelog

Trade.PositionForExternalUse
-> main.bi_db.bronze_etoro_trade_positionforexternaluse

History.PositionForExternalUse
-> main.trading.bronze_etoro_history_position_datafactory

Trade.LiquidityAccounts
-> main.trading.bronze_etoro_trade_liquidityaccounts

Trade.LiquidityProviders
-> main.trading.bronze_etoro_trade_liquidityproviders

Trade.LiquidityProviderType
-> main.bi_db.bronze_etoro_trade_liquidityprovidertype

Hedge.HedgeServerToLiquidityAccount
-> main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount

Hedge.ExecutionLog
-> main.dealing.bronze_etoro_hedge_executionlog

Hedge.HBCExecutionLog
-> main.dealing.bronze_etoro_hedge_hbcexecutionlog

Hedge.HBCOrderLog
-> main.dealing.bronze_etoro_hedge_hbcorderlog

Reg_CurrencyPrice_Ext source
-> main.trading.bronze_etoro_trade_currencyprice

Reg_Ext_T_PriceCandle60Min source
-> main.dealing.bronze_candles_candles_t_pricecandle60min

History.CurrencyPriceMaxDate source
-> main.dealing.bronze_pricelog_history_currencypricemaxdate

Reg_Ext_CurrencyPriceMaxDateWithSplit candidate
-> dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit

Reg_Ext_CurrencyPriceMaxDateWithSplit candidate alternative
-> main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit

History.SplitRatio
-> main.dealing.bronze_pricelog_history_splitratio
```

For candidate/duplicate mappings, inspect SSIS logic and required columns before choosing. Do not guess silently.

## 10. Static/reference data already available

These small references are already staged or available:

```text
EDNF-to-InstrumentID mapping
-> main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro

Internal accounts
-> main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts

Dictionary.Ext_SpecialChar
-> main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar

LiquidityAccountID-to-LEI
-> main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei

Excluded CIDs
-> main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids

Excluded instruments
-> main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments

Excluded position IDs
-> main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids

ISIN for InstrumentID 341
-> main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341
```

For EDNF mapping, create a prefixed compatibility view if useful:

```text
main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
```

The EDNF table currently has columns:

```text
InstrumentID
ContractDesc
IB_UnderlyingSymbol
ContractLongName
```

Expose logical names:

```text
instrument_id
contract_desc
contract_long_name
ib_underlying_symbol
```

## 11. dbo.ReplaceChar migration

The SQL Server `dbo.ReplaceChar` function is used by MiFID customer logic. Recreate it exactly enough for parity.

Authoritative mapping:

```text
š -> s
Š -> S
ß -> s
É -> E
é -> e
- -> space
_ -> space
```

Remove:

```text
| \ / ~ { } ; : " , . ] [ ! @ # $ % ^ & * ( ) + = ` ´ ? ¶ ƒ non-breaking-space U+00A0 U+0081 ² U+008F soft-hyphen U+00AD © ¸ digits 0-9
```

Preserve SQL Server behavior: trim before replacement, not after replacement. Do not use Databricks `chr(353)`, `chr(352)`, or `chr(402)` for š/Š/ƒ; use actual Unicode literals or verified mappings.

## 12. Instrument special-character conversion

Migrate `SP_InstrumentMetaData_SpecialChar_Conversion`.

Inputs:

```text
Reg_Ext_Trade_InstrumentMetaData
Dictionary.Ext_SpecialChar
```

Output:

```text
InstrumentMetaData_SpecialChar_Conversion
```

Databricks target:

```text
main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion
```

`Dictionary_Ext_SpecialChar.csv` has no header row. Column order:

```text
Key
Value
UpdateDate
```

Quote `Key` and `Value` with backticks if needed.

Important: SQL Server procedure uses `WHILE @iter < @count`, not `<=`. Do not silently fix this edge case unless explicitly approved. Document whether the Databricks implementation preserves or intentionally corrects it.

## 13. ASIC2 decision

ASIC2 is the current authoritative ASIC reporting process. Legacy ASIC still runs but should not be used as the MiFID migration source of truth.

`SP_MIFID2_ETORO_Report` currently references old `dbo.ASIC_Transactions`; replace this intentionally with ASIC2-compatible logic.

Create:

```text
main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
```

and/or compatibility view:

```text
main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
```

The compatibility view must expose fields expected by the old MiFID ETORO logic:

```text
DateID
ReportDate
CID
PositionID
InstrumentID
OpenORClose
IsBuy
OpenTime
Volume
OpenPrice
RegChange
```

Approximate mapping from ASIC2_Transactions:

```text
DateID -> DateID
ReportDate -> ReportDate
CID -> CID
PositionID -> PositionID
InstrumentID -> InstrumentID
OpenORClose -> OpenORClose
IsBuy -> IsBuy
Quantity -> Volume
OpenPrice -> OpenPrice
RegChange -> RegChange
CDE_Execution_timestamp -> OpenTime
```

Validate this mapping; especially `CDE_Execution_timestamp -> OpenTime`.

Do not require EMIR UPI for MiFID unless ASIC2 subset logic proves that it affects fields consumed by `MIFID2_ETORO_Report`.

`Reg_DWH_StaticPosition` was investigated and should be conditional only: it appears stale/static around 2022 and recent ASIC2_Transactions did not join to it in the checked window. Do not block current MiFID staging implementation on it.

## 14. Currency / price / split staging

`Reg_CurrencyPrice_Ext` appears to be an SSIS-created staging extract from:

```text
main.trading.bronze_etoro_trade_currencyprice
```

Do not manually create dynamic price staging tables before deriving SSIS logic. Inspect `Pre_Regulation_Ext.dtsx` for filters, selected columns, overwrite behavior, date logic, and downstream usage.

Dynamic staging tables should be created/refreshed by the Databricks workflow, not one-time manual uploads.

Validate exact logic for:

```text
Reg_CurrencyPrice_Ext
Reg_Ext_CurrencyPriceMaxDateWithSplit
Reg_Ext_DailyMaxPrices
Reg_Ext_T_PriceCandle60Min
```

For regulatory parity, prefer materialized Delta staging tables refreshed at workflow runtime over simple views when a stable run snapshot is needed.

## 15. Open decisions to document, not guess

Document these as open decisions/gates:

```text
1. Historical seed/backfill implementation and extract ownership for approved objects (NPD_TRAX, Failed_TRAX, ASIC2, Hedge_Report, liquidity SCD, migration/regulation in-out, movements, instrument/FIRDS history as needed).
2. Runbook-level seed/cutover implementation details for objects with approved direction but pending execution (for example Reg_LiquidtyAcount_SCD per D-09 / MAG-11).
3. Required-column certification and SQL Server baseline/date-window validation for selected primary price sources (dealing pricelog tables).
4. Whether any file-delivery work is moved into a later phase.
```

Current agreed scope is table/report generation only. File delivery is phase 2 unless explicitly added.

## 16. Required validation / reconciliation outputs

Create validation SQL/notebooks for:

```text
row counts by ReportDate
row counts by RegulationID / RegulationReportID
business key duplicate checks
required-field null checks
aggregate checks on quantity/price fields where applicable
hash/checksum-style comparison where practical
source freshness checks
staging table row counts
final output table row counts
```

Final tables to validate:

```text
MIFID2_Customer
MIFID2_RegChange_Customer
MIFID2_Report
MIFID2_ME_Report
MIFID2_ETORO_Report
MIFID2_Hedge_Report
MIFID2_Removed_OP_Partials
MIFID2_NPD_TRAX
ASIC2-compatible MiFID staging table
```

Create:

```text
databricks/sql/validation/
docs/reconciliation_plan.md
docs/known_differences.md
docs/history_seed_requirements.md
```

If differences are due to missing historical seed data, document the exact dependency rather than changing business logic.

## 17. Implementation guidance

Prefer Databricks SQL for set-based transformations where practical. Use PySpark only where Databricks SQL becomes too complex, especially for iterative replacement/mapping logic.

Use Delta tables for persisted staging and outputs.

Make each table-generation step idempotent:

```text
For report-date scoped tables: delete/replace rows for the target ReportDate, then insert/rebuild.
For full-refresh staging tables: create or replace / insert overwrite.
For dynamic extracts: refresh inside workflow before dependent report logic.
```

Do not silently skip logic. If something is unclear, add it to docs/unresolved_dependencies.md or docs/open_questions_and_decisions.md.

## 18. Final acceptance criteria for this phase

This phase is complete when:

```text
1. Dependency coverage matrix exists.
2. All SSIS-created MiFID staging tables are classified and implemented or documented.
3. Core MiFID outputs are created in main.regtech_ops_stg with bi_output_regtechops_ prefix.
4. ASIC2-compatible MiFID subset replaces legacy ASIC_Transactions dependency.
5. Regulation movement logic is implemented or clearly staged from certified gold tables/package logic.
6. Hedge liquidity mapping logic is implemented for Hedge EU/UK.
7. Validation/reconciliation SQL exists.
8. Open decisions are documented.
9. No created object in main.regtech_ops_stg violates the bi_output_regtechops_ prefix rule.
10. No target process has a runtime dependency on SSMS/SQL Server except temporary reconciliation during migration.
```
