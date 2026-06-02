# Step 15 - MIFID2_NPD_TRAX Output Analysis (Steps 15B1-15B3)

This document defines Step 15B1-15B3 scope for `MIFID2_NPD_TRAX` migration into:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`

Step 15B1/15B2 are template-only and document output contract, dependency gates, and staged generation flow.

## Scope

In scope for Step 15B1-15B3:

- Output target contract for `bi_output_regtechops_mifid2_npd_trax`
- SQL Server procedure boundary for table generation
- Dependency map and profiling gate carry-forward
- History/cutover dependency notes
- Step split definition for 15B2/15B3

Out of scope for Step 15B1-15B3:

- Full NPD_TRAX table-generation SQL implementation
- TRAX file generation/export
- TRAX upload or SFTP flow
- TRAX response ingestion/update
- `SP_MIFID2_NPD_TRAX_Response_Update`
- 7z/compression and Cappitech upload
- Production deployment

## Procedure and Package Boundary

Authoritative table-generation procedure:

- `reference/mifid_databricks_migration_context/01_sql_server_stored_procedures/core_mifid/SP_MIFID2_NPD_TRAX.sql`

Authoritative target DDL:

- `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/dbo.MIFID2_NPD_TRAX.sql`

SSIS boundary:

- `MIFID2 TRAX.dtsx` executes `SP_MIFID2_NPD_TRAX(@StartDate)` before file/upload/response tasks.
- Response import/status update logic and `SP_MIFID2_NPD_TRAX_Response_Update` are out of Step 15B1 scope.

## Output Schema Contract Summary

Target table contract is sourced from `dbo.MIFID2_NPD_TRAX.sql` and includes:

- Core keys/identity fields: `ReportDate`, `CID`, `ReportTypeID`, `Entity`, `RegulationID`, `AccountTypeID`, `IDType`
- TRAX identity payload: `OrigPINType`, `PIN`, `NotAllowedCONCAT`, `Action`, `InternalCode`, `CountryofNationality`, `PassportNumber`, `NationalID`, `FirstNames`, `Surnames`, `DateofBirth`
- Delivery-state payload used by table generation: `AcceptedTRAX`, `ErrorDescription`, `RowNum`, `TraxAccount`, `NonLatinOrEmptyName`, `UpdateDate`
- Response-related fields present in DDL (out-of-scope for Step 15B1 implementation): `ErrorColumn`, `FailedSinceDate`, `DateFixedTRAX`

SQL Server PK intent is `(ReportDate, Entity, CID)` and should be validated via duplicate checks in Databricks validation SQL.

## Direct Inputs for NPD_TRAX Table Generation

Direct Step 15A inputs to carry into Step 15B2:

- Prior/current `MIFID2_NPD_TRAX` history
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`

Not direct inputs for Step 15B2 unless later evidence proves otherwise:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`

## AcceptedTRAX and Response Boundary

Table-generation behavior to preserve in Step 15B2:

- Sendable rows carry `AcceptedTRAX = NULL`.
- Invalid non-Latin/empty-name rows carry `AcceptedTRAX = 0`.
- Invalid-name rows carry `ErrorDescription = 'Not Sent. Invalid Name detected'`.
- Prior rejected/null rows can be retried.
- Prior accepted rows can emit `REPL` when identity fields changed.

Out of scope for Step 15B1 and Step 15B2:

- Response file import
- Response status update into NPD rows
- `SP_MIFID2_NPD_TRAX_Response_Update`

## History/Cutover Requirement

`MIFID2_NPD_TRAX` generation is history-aware:

- Previous NPD rows are required for exact new-vs-existing, retry, `REPL`, and `AcceptedTRAX` parity.
- Forward-only cutover can start clean for current validation windows, but behavior will differ from seeded historical parity.
- Historical parity windows require prior latest NPD rows seeded by `(CID, RegulationID)` logic.
- `MIFID2_Failed_TRAX` also depends on latest NPD history, creating an explicit Step 9 <-> Step 15 history/cutover dependency loop.

## Profiling and Dependency Gates

Carry-forward gates from latest profiling docs:

- `main.pii_data.bronze_etoro_customer_customer`: No schema access
- `main.pii_data.bronze_etoro_history_customer`: No schema access
- Customer outputs remain gated while unmasked PII access is blocked
- Upstream final outputs remain gated until their own dependencies pass
- Prior `MIFID2_NPD_TRAX` history/seed policy remains unresolved
- `MIFID2_Failed_TRAX` remains history-gated

Additional open platform blockers that still affect upstream closure:

- `main.trading.bronze_etoro_trade_currencyprice`: Storage/data scan failure
- `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`: Storage/data scan failure
- `dwh_daily_process` candidate sources: No catalog access

## Planned Step 15 Split

- Step 15B1: Scaffold, output contract, dependency gates (this document + gated SQL scaffold)
- Step 15B2: Gated table-generation template (authored, fully commented/non-active)
- Step 15B3: Validation/reconciliation package for schema, counts, duplicates, nulls, AcceptedTRAX state, source-to-output checks, and seed-window checks

## Step 15B2 Gated CTE Template

Step 15B2 template artifact:

- `databricks/sql/08_outputs/09_mifid2_npd_trax.sql`

CTE flow authored in Step 15B2 (commented/non-active):

1. `run_parameters` (`{{report_date}}`)
2. `prior_latest_ids` and `prior_latest_rows` (history-aware latest row per `CID`/`RegulationID`)
3. `failed_retry_candidates` (prior `AcceptedTRAX = 0` or `NULL`)
4. `reg_change_customers` (from `MIFID2_Report` where `RegChange IN (1,2)` and report-date match)
5. `customer_all_candidates` (customer + reg-change customer union with exclusion filtering)
6. `new_candidates` (`NEWM` candidates absent from prior latest ids)
7. `existing_changed_candidates` (existing rows with identity-field changes, `REPL`/prior action behavior)
8. `retry_candidates` + `candidate_union`
9. `final_candidates` (invalid-name handling, AcceptedTRAX/ErrorDescription behavior)
10. `final_candidates_with_rownum` (sendable rows only, `AcceptedTRAX IS NULL`)

Step 15B2 history-aware behavior documented in template:

- Uses prior latest NPD state for new-vs-existing/retry/`REPL`.
- Keeps history/cutover parity hard-gated until seed policy is approved.
- Does not fabricate prior NPD history.

Step 15B2 AcceptedTRAX/invalid-name behavior documented in template:

- Invalid rows set `AcceptedTRAX = 0` and `ErrorDescription = 'Not Sent. Invalid Name detected'`.
- Sendable rows retain `AcceptedTRAX = NULL`.
- RowNum is assigned only to sendable rows.
- RowNum ordering remains hard-gated pending exact SQL Server parity confirmation.

Step 15B2 response/delivery boundaries:

- `SP_MIFID2_NPD_TRAX_Response_Update` is out of scope.
- Response import/status updates are out of scope.
- File/export/upload/SFTP/7z/Cappitech flows are out of scope.

Step 15B2 activation gates:

- Upstream customer/report outputs must be available and gate-cleared.
- PII source-access blockers must be resolved or approved alternative formally accepted.
- Prior/current NPD history seed policy must be approved.
- Final DML remains commented until all gates pass.

## Step 15B3 Validation and Reconciliation Package

Step 15B3 validation artifact:

- `databricks/sql/08_outputs/09_mifid2_npd_trax_validation.sql`

Step 15B3 package scope:

- SELECT-only validation for `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`
- no CREATE/INSERT/UPDATE/DELETE/MERGE/DROP behavior
- no response handling/file delivery logic

Validation categories covered:

1. Schema parity:
   - column names, order, type/nullability checks
   - precision/scale checks where relevant
   - response columns (`ErrorColumn`, `FailedSinceDate`, `DateFixedTRAX`) included in contract checks
2. Duplicate checks:
   - PK intent `(ReportDate, Entity, CID)`
3. Required null checks:
   - `ReportDate`, `CID`, `ReportTypeID`, `Entity`
4. Row counts:
   - by `ReportDate`, `Entity`, `RegulationID`, `Action`, `AcceptedTRAX`
5. AcceptedTRAX checks:
   - sendable rows (`AcceptedTRAX IS NULL`)
   - invalid rows (`AcceptedTRAX = 0`, expected invalid-name error text)
   - prior rejected/null retry-eligibility posture
6. RowNum checks:
   - RowNum assigned only for sendable rows
   - RowNum nullability for non-sendable rows
   - partition summaries by `Entity`
   - exact SQL Server ordering parity remains gated
7. History/seed checks:
   - prior latest row coverage by `(CID, RegulationID)`
   - missing-seed and forward-only warnings
   - seed coverage via max prior `ReportDate`
8. Exclusion checks:
   - excluded CIDs absent
   - exclusion source bound to `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
9. Source-to-output checks:
   - customer-all/new/existing-changed/failed-retry/final-output counts as gated placeholders
10. Optional SQL Server baseline comparison:
    - gated placeholder for normalized SQL Server baseline
    - key and row-count deltas when available

Gated/deferred checks in Step 15B3:

- Placeholder-dependent candidate-source checks:
  - `{{npd_customer_all_source}}`
  - `{{npd_new_candidates_source}}`
  - `{{npd_existing_changed_source}}`
  - `{{npd_failed_retry_source}}`
- Optional baseline placeholder:
  - `{{sqlserver_npd_trax_baseline_source}}`
- Exact SQL Server RowNum ordering parity remains hard-gated until explicit ordering contract approval.

## Step 15 Deliverables

- `docs/mifid2_npd_trax_output_analysis.md`
- `databricks/sql/08_outputs/09_mifid2_npd_trax_scaffolding.sql`
- `databricks/sql/08_outputs/09_mifid2_npd_trax.sql`
- `databricks/sql/08_outputs/09_mifid2_npd_trax_validation.sql`

