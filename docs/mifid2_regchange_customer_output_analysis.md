# Step 11 - MIFID2_RegChange_Customer Output Analysis

This document captures Step 11 only (`MIFID2_RegChange_Customer` output). It excludes all other final MiFID outputs and all delivery/deployment/backfill flows.

## Step 11 scope

In scope:

- SQL Server logic source: `SP_MIFID2_RegChange_Customer.sql`
- Target DDL source: `MIFID2_RegChange_Customer.sql`
- Databricks output target: `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
- Gated SQL authoring for report-date output generation
- Validation SQL authoring for schema/data-quality/reconciliation checks

Out of scope in Step 11:

- `MIFID2_Report`
- `MIFID2_ME_Report`
- `MIFID2_ETORO_Report`
- `MIFID2_Hedge_Report`
- `MIFID2_NPD_TRAX`
- CSV/7z/SFTP/TRAX/Cappitech delivery or response handling
- Production deployment and full historical backfill

## Target output contract (authoritative DDL)

Target table:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`

Column contract from SQL Server DDL (`MIFID2_RegChange_Customer.sql`):

- `CID`, `RegulationID`, `PlayerLevelID`, `CountryID`, `FTD`, `AccountTypeID`, `Country`, `CopyFund`, `CopyFundName`, `FundTypeID`, `FundType`, `IDType`, `PIN_Type`, `PIN_LEI`, `BirthDate`, `FirstName`, `LastName`, `IsUKReport`, `IsEUReport`, `NotAllowedCONCAT`, `ReportDate`, `TraxEntity`, `TraxAccount`

Primary-key intent to validate in Databricks:

- `ReportDate`, `CID`, `RegulationID`

## Step 11 input dependencies

### Confirmed/used inputs

- Step 9 staging:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- Static/reference:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
- Function:
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`

### Required but unresolved/gated inputs

- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`:
  required for translation path used by SQL Server reg-change customer name logic.
- `Dictionary.Ext_TradeFund` Databricks mapping:
  required for `CopyFund`, `CopyFundName`, `FundTypeID`, `FundType`.
- Step 9 reg-change activation prerequisites:
  `MIFID2_ext_RegChange_Customer` remains gate-protected until migration/reg-change and PIN/UserAPI contracts are confirmed.

## SQL Server parity logic preserved in Step 11 template

The Step 11 SQL template preserves the following behavior from `SP_MIFID2_RegChange_Customer`:

- Build customer population from:
  - `MIFID2_ext_RegChange_Customer` only.
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
  - `ISNULL(FirstTimeDepositSuccessDate, '20150426')` in SQL Server
  - Databricks equivalent uses `COALESCE(..., CAST('2015-04-26' AS TIMESTAMP))`
  - if Step 9 reg-change staging does not expose `FirstTimeDepositSuccessDate`, internal projection remains `NULL` and output fallback is preserved.
- `LEI` fallback:
  - `COALESCE(source_lei, internal_accounts.LEI)`
- `IDType`, `PIN_Type`, `PIN_LEI` rules:
  - preserve corporate/LEI/individual branching from SQL Server
- `CopyFund` and fund-type derivation from trade-fund lookup
- `IsUKReport` and `IsEUReport` flags from `RegulationID`
- `NotAllowedCONCAT` flag for country list:
  - `67, 95, 102, 126, 164, 191`
- `TraxEntity` / `TraxAccount` derivation for non-corporate flow

## Step 11 difference vs Step 10 (`MIFID2_Customer`)

- Uses `MIFID2_ext_RegChange_Customer` (not `MIFID2_ext_Customer`).
- Does not union `MIFID2_Failed_TRAX`.
- Does not apply excluded-CID filtering because `SP_MIFID2_RegChange_Customer` does not contain that join.
- Shares the same output DDL contract and most field-derivation logic with Step 10.

## Idempotent load pattern

Step 11 template uses report-date scoped idempotency:

1. `DELETE` target rows for `ReportDate = {{report_date}}`
2. `INSERT` the rebuilt dataset for the same report date

This preserves rerun safety without requiring full-table replacement.

## Gating rule and activation boundary

Step 11 output SQL is intentionally non-executable by default (commented template) until all gates are resolved:

- Step 9 reg-change customer/reg-change migration prerequisites
- PIN/UserAPI source contract gate
- `Reg_Ext_CustomerLatinName` source/profile gate
- `Dictionary.Ext_TradeFund` Databricks mapping gate

No `main.regtech` production objects are created in this step.

## Step 11 SQL artifacts

Created in this step:

- `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql`
- `databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql`

Both artifacts are authoring-only templates. No SQL execution is performed.
