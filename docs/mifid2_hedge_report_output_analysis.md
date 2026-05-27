# Step 14A/14B1 - MIFID2 Hedge Report Output Analysis

This document captures the Step 14 analysis baseline and Step 14B1 scaffolding boundary for `MIFID2_Hedge_Report`.

## Scope (Step 14B1)

- Scaffold/output-contract/dependency-gate authoring only for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`
- Document source dependencies, branch behavior, exclusions, and activation gates from SQL Server procedures:
  - `SP_MIFID_HedgeEU_Report.sql`
  - `SP_MIFID_HedgeUK_Report.sql`
- Author scaffold SQL artifact:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_scaffolding.sql`

## Out of scope for Step 14B1

- Actual EU branch projection.
- Actual EU-UK branch projection.
- Actual UK branch projection.
- Final `DELETE`/`INSERT` report load logic.
- Final `RecordID` implementation behavior.
- `MIFID2_NPD_TRAX`.
- File delivery (`CSV`, `7z`, `SFTP`, TRAX/Cappitech upload, response handling).
- Production deployment/orchestration activation.

## SQL Server authorities

- Stored procedures:
  - `reference/mifid_databricks_migration_context/01_sql_server_stored_procedures/core_mifid/SP_MIFID_HedgeEU_Report.sql`
  - `reference/mifid_databricks_migration_context/01_sql_server_stored_procedures/core_mifid/SP_MIFID_HedgeUK_Report.sql`
- DDL:
  - `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_Hedge_Report.sql`

## Target object

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`

## EU procedure summary

`SP_MIFID_HedgeEU_Report` composes two report branches with `RegulationReportID = 1`:

- Direct EU rows:
  - `ExecutionFlow = 'EU'`
  - projected `rowSource = 'EU'`
- EU-reportable real-stock rows via UK flow:
  - `ExecutionFlow = 'UK' AND IsReal = 1`
  - projected `rowSource = 'EU-UK'`

Core EU filters/conditions (analysis baseline):

- `Units > 0`
- `Success = 1`
- `ExecutionTime >= {{report_date}}`
- `ExecutionTime < {{report_date}} + 1 day`
- Liquidity account / LEI mapping joins and SCD valid-time join
- Instrument MiFID eligibility and metadata enrichment

## UK procedure summary

`SP_MIFID_HedgeUK_Report` composes UK rows with `RegulationReportID = 2` and `rowSource = 'UK'`.

Core UK filters/conditions (analysis baseline):

- `Units > 0`
- `EMSOrderID IS NULL`
- `Success = 1`
- `ExecutionTime >= {{report_date}}`
- `ExecutionTime < {{report_date}} + 1 day`
- `LP.eToroEntity = '213800FLAB1OVA8OHT72'`
- Instrument eligibility uses FCA-specific branch condition (`IsMifidByFCA = 1` path)
- HBC order enrichment path is part of UK branch behavior

## Source dependency map (Step 14B1)

EU direct dependencies:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`

UK direct dependencies:

- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`

Shared instrument/dictionary dependencies:

- `main.regtech.gold_regtech_reg_instruments_scd`
- `main.regtech.gold_regtech_reg_instruments_full_description`
- `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`

## EDNF / IB enrichment dependency map

- `main.general.gold_ednf_coretrades`
- `main.general.gold_ib_u1059976_open_positions_all`
- `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
- `main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`

These remain activation-gated in Step 14B1 until join coverage is profiled for hedge report windows.

## Exclusion semantics (critical)

Exclusion sources for hedge report rows:

- `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
- `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`

Scope rule:

- `table_name = '[MIFID2_Hedge_Report]'` means row-level exclusion scoped to this report.
- It does **not** mean the entire `MIFID2_Hedge_Report` output should be empty.

Expected behavior to port in later steps:

- Exclude only rows with matching `InstrumentID` under hedge table scope.
- Exclude only rows with matching generated transaction-reference/position-equivalent key under hedge table scope.

## Transaction reference behavior (gated)

Both SQL Server hedge procedures derive `TransactionReferenceNumber` from:

- normalized `ProviderExecID`,
- `RowID`,
- run `StartDate` / report date,
- fallback to liquidity-provider + date + row id when normalized provider execution id is not usable.

Step 14B1 documents this behavior only. Final implementation is deferred to Step 14B2/14B3.

## Output schema summary

- DDL contract source: `MIFID2_Hedge_Report.sql`
- SQL Server uniqueness intent:
  - `(ReportDate, RegulationReportID, TransactionReferenceNumber)`
- Branch fields requiring explicit parity handling:
  - `RegulationReportID`
  - `rowSource`
  - `LiquidityAccountID`
  - `EMSOrderID`

## RecordID issue (blocking gate)

SQL Server target defines:

- `RecordID INT IDENTITY(100000001,1)`

Step 14B1 keeps `RecordID` unresolved and gated. Approved strategy options to evaluate later:

- deterministic `row_number()` over stable branch/order key + offset `100000000`,
- nullable/placeholder `RecordID` during gated template authoring,
- explicitly approved non-parity behavior (only by later signoff).

Non-deterministic identity behavior is not accepted by default in Step 14B1.

## Activation gates (Step 14B1 carry-forward)

- `MIFID2_ext_HedgeExecutionLog` activation and source-contract readiness.
- `Reg_Ext_HedgeExecutionLog` activation and source-contract readiness.
- `Reg_Ext_HedgeHBCOrderLog` activation and source-contract readiness.
- Liquidity account SCD readiness (`Reg_Ext_LiquidityAccountID` + `Reg_LiquidtyAcount_SCD`) for report windows.
- LEI coverage completeness for active/report-relevant liquidity accounts.
- Instrument/dictionary dependency readiness for requested report dates.
- EDNF/IB mapping and join-coverage evidence.
- Exclusion mapping readiness and report-scoped semantics validation.
- Transaction-reference derivation parity signoff.
- RecordID strategy signoff.

## Planned implementation split

- Step 14B1 (this step):
  - hedge output analysis + scaffold + output contract + gate documentation.
- Step 14B2:
  - source preparation and branch source CTE authoring (still gated).
- Step 14B3:
  - final EU/EU-UK/UK projection template and report-date load template (gated until dependencies pass).
- Step 14B4:
  - read-only validation/reconciliation package for schema, row counts, duplicates, branch evidence, exclusions, and aggregate checks.
