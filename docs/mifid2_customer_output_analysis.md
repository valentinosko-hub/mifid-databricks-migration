# Step 10 - MIFID2_Customer Output Analysis

This document captures Step 10 only (`MIFID2_Customer` output). It excludes all other final MiFID outputs and all delivery/deployment/backfill flows.

## Step 10 scope

In scope:

- SQL Server logic source: `SP_MIFID2_Customer.sql`
- Target DDL source: `MIFID2_Customer.sql`
- Databricks output target: `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
- Gated SQL authoring for report-date output generation
- Validation SQL authoring for schema/data-quality/reconciliation checks

Out of scope in Step 10:

- `MIFID2_RegChange_Customer`
- `MIFID2_Report`
- `MIFID2_ME_Report`
- `MIFID2_ETORO_Report`
- `MIFID2_Hedge_Report`
- `MIFID2_NPD_TRAX`
- CSV/7z/SFTP/TRAX/Cappitech delivery or response handling
- Production deployment and full historical backfill

## Target output contract (authoritative DDL)

Target table:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`

Column contract from SQL Server DDL (`MIFID2_Customer.sql`):

- `CID`, `RegulationID`, `PlayerLevelID`, `CountryID`, `FTD`, `AccountTypeID`, `Country`, `CopyFund`, `CopyFundName`, `FundTypeID`, `FundType`, `IDType`, `PIN_Type`, `PIN_LEI`, `BirthDate`, `FirstName`, `LastName`, `IsUKReport`, `IsEUReport`, `NotAllowedCONCAT`, `ReportDate`, `TraxEntity`, `TraxAccount`

Primary-key intent to validate in Databricks:

- `ReportDate`, `CID`, `RegulationID`

## Step 10 input dependencies

### Confirmed/used inputs

- Step 9 staging:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`
- Static/reference:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
- Function:
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`

### Required but unresolved/gated inputs

- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`:
  required for translation path used by SQL Server customer-name update logic.
- `Dictionary.Ext_TradeFund` Databricks mapping:
  required for `CopyFund`, `CopyFundName`, `FundTypeID`, `FundType`.
- Step 9 activation prerequisites:
  `MIFID2_ext_Customer` and `MIFID2_Failed_TRAX` remain gate-protected until source profiling and PIN/UserAPI contracts are confirmed.

## SQL Server parity logic preserved in Step 10 template

The Step 10 SQL template preserves the following behavior from `SP_MIFID2_Customer`:

- Build customer population from:
  - `MIFID2_ext_Customer`
  - plus failed-TRAX CIDs not present in `MIFID2_ext_Customer`
- Country normalization:
  - use `CitizenshipCountryID` when non-zero, else `CountryID`
  - remap `144 -> 143`
- Name normalization:
  - uppercase `ReplaceChar` output
  - Chinese/Cyrillic language detection based on Unicode ranges from normalized names
  - optional Latin-name translation path
  - blank first/last fallback swap behavior
  - final replacements: `І -> I`, `Ё -> Е`
- `FTD` fallback:
  - `COALESCE(FirstTimeDepositSuccessDate, '2015-04-26')`
  - no invented upstream source behavior
- `LEI` fallback:
  - `COALESCE(source_lei, internal_accounts.LEI)`
- `IDType`, `PIN_Type`, `PIN_LEI` rules:
  - preserve corporate/LEI/individual branching from SQL Server
- `CopyFund` and fund-type derivation from trade-fund lookup
- `IsUKReport` and `IsEUReport` flags from `RegulationID`
- `NotAllowedCONCAT` flag for country list:
  - `67, 95, 102, 126, 164, 191`
- Exclude CIDs listed in:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
- `TraxEntity` / `TraxAccount` derivation for non-corporate flow

## Idempotent load pattern

Step 10 template uses report-date scoped idempotency:

1. `DELETE` target rows for `ReportDate = {{report_date}}`
2. `INSERT` the rebuilt dataset for the same report date

This preserves rerun safety without requiring full-table replacement.

## Gating rule and activation boundary

Step 10 output SQL is intentionally non-executable by default (commented template) until all gates are resolved:

- Step 9 customer/failed-trax staging activation gates
- `Reg_Ext_CustomerLatinName` source/profile gate
- `Dictionary.Ext_TradeFund` Databricks mapping confirmation

No `main.regtech` production objects are created in this step.

## Step 10 SQL artifacts

Created in this step:

- `databricks/sql/08_outputs/01_mifid2_customer.sql`
- `databricks/sql/08_outputs/01_mifid2_customer_validation.sql`

Both artifacts are authoring-only templates. No SQL execution is performed.
