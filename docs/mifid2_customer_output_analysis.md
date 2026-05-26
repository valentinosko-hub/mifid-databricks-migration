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
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` history/current availability:
  required by Step 9 `MIFID2_Failed_TRAX` latest-row derivation, which directly affects Step 10 failed-customer supplementation.
- `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar` parity validation:
  required before Step 10 activation to avoid name/PIN normalization drift.

## SQL Server parity logic preserved in Step 10 template

The Step 10 SQL template preserves the following behavior from `SP_MIFID2_Customer`:

- Build customer population from:
  - `MIFID2_ext_Customer`
  - plus failed-TRAX CIDs not present in `MIFID2_ext_Customer`
- Apply candidate-population exclusions to both branches (`MIFID2_ext_Customer` and failed-TRAX-only rows):
  - `CountryID = 250`
  - `PlayerLevelID = 4` unless CID exists in `InternalAccounts`
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
- Exclude CIDs listed in (applied to the full combined candidate population before final insert):
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
- `TraxEntity` / `TraxAccount` derivation for non-corporate flow

## Detailed source-to-target mapping (Step 10 template)

Main source CTE inputs:

- `ext_customers` from `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
- `failed_customers` from `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax` where CID is absent from same-day ext-customer snapshot
- Country and internal enrichment from:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- Exclusion filter from:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`

Target-column derivations:

- Identity/regulatory core:
  - `CID` <- `COALESCE(source.CID, 0)`
  - `RegulationID` <- `COALESCE(source.RegulationID, 0)` (`4/10 -> 4` normalization from ext-customer branch)
  - `PlayerLevelID` <- `COALESCE(source.PlayerLevelID, 0)`
  - `CountryID` <- `CASE WHEN COALESCE(NULLIF(CitizenshipCountryID,0), CountryID)=144 THEN 143 ELSE COALESCE(NULLIF(CitizenshipCountryID,0), CountryID) END`
  - `ReportDate` <- run parameter (`{{report_date}}`)
- Deposit/date:
  - `FTD` <- `COALESCE(FirstTimeDepositSuccessDate, TIMESTAMP '2015-04-26')`
  - Step 10 keeps `FirstTimeDepositSuccessDate` as consumer-layer fallback input (no invented upstream source).
- Copy-fund enrichment (gated on unresolved mapping):
  - `CopyFund` <- `CASE WHEN funds.FundAccountID IS NOT NULL THEN 1 ELSE 0 END`
  - `CopyFundName` <- `funds.FundName`
  - `FundTypeID` <- `funds.FundType`
  - `FundType` <- decode `FundTypeID` (`1=People`, `2=Partners`, `3=Market`)
- Country and entity/account:
  - `Country` <- `vw_ext_country.Abbreviation`
  - `IsUKReport` <- `CASE WHEN RegulationID=2 THEN 1 ELSE 0 END`
  - `IsEUReport` <- `CASE WHEN RegulationID IN (1,9,11) THEN 1 ELSE 0 END`
  - `NotAllowedCONCAT` <- country in (`67,95,102,126,164,191`)
  - `TraxEntity` / `TraxAccount` <- SQL Server-equivalent non-corporate branching
- Name normalization:
  - base names <- `UPPER(fn_replacechar(source.FirstName/LastName))`
  - language tag <- Unicode-range checks on normalized names
  - optional translation <- `reg_ext_customerlatinname` for non-ASIC (`RegulationID <> 4`) language-tagged rows
  - blank fallback <- copy non-empty side into empty first/last field
  - final replacement <- `І -> I`, `Ё -> Е`
- PIN/LEI logic:
  - `Lei` <- `COALESCE(source.Lei, internal_accounts.LEI)` for ext-customer branch
  - `IDType` <- account/LEI branching (`CopyFund=3`, LEI/corporate=2, else individual=1)
  - `PIN_Type` <- `'LEI'` when LEI length is 20 or `AccountTypeID=2`, else source `PIN_Type`
  - `PIN_LEI`:
    - valid LEI/corporate path -> uppercase LEI
    - non-LEI path with PIN -> `CountryAbbreviation + UPPER(TRIM(PIN))`
    - no-concat countries (`67,95,102,126,164,191`) -> PIN only

## Idempotent load pattern

Step 10 template uses report-date scoped idempotency:

1. `DELETE` target rows for `ReportDate = {{report_date}}`
2. `INSERT` the rebuilt dataset for the same report date

This preserves rerun safety without requiring full-table replacement.

## Gating rule and activation boundary

Step 10 output SQL is intentionally non-executable by default (commented template) until all gates are resolved:

- Step 9 customer/failed-trax staging activation gates
- Step 9 `MIFID2_NPD_TRAX` history/current gate used by failed-TRAX latest-row derivation
- `Reg_Ext_CustomerLatinName` source/profile gate
- `Dictionary.Ext_TradeFund` Databricks mapping confirmation
- ReplaceChar parity validation gate

No `main.regtech` production objects are created in this step.

## Step 10 SQL artifacts

Created in this step:

- `databricks/sql/08_outputs/01_mifid2_customer.sql`
- `databricks/sql/08_outputs/01_mifid2_customer_validation.sql`

Both artifacts are authoring-only templates. No SQL execution is performed.

## Validation coverage in Step 10 SQL

`databricks/sql/08_outputs/01_mifid2_customer_validation.sql` includes templates for:

- target schema parity:
  - column existence
  - column order
  - data type mapping
  - nullability
  - precision/scale where relevant
- source/dependency visibility checks for Step 10 gates
- row counts:
  - by `ReportDate`
  - by `ReportDate`, `RegulationID`
- duplicate checks:
  - `ReportDate`,`CID`
  - `ReportDate`,`CID`,`RegulationID`
- required-field null checks:
  - `CID`, `RegulationID`, `PlayerLevelID`, `CountryID`, `FTD`, `ReportDate`
- exclusion checks:
  - excluded CIDs absent
  - `CountryID = 250` absent
  - `PlayerLevelID = 4` without internal account check
- country normalization checks:
  - no `CountryID = 144` in output
  - source precedence and 144->143 normalization consistency
  - country-abbreviation coverage
- ReplaceChar/name checks:
  - ReplaceChar sample outputs
  - uppercase-name behavior
  - Latin-name source coverage and Chinese translation consistency
  - blank first/last fallback checks
  - final Cyrillic replacement checks (`І`, `Ё`)
- PIN/LEI checks:
  - `AccountTypeID = 2` -> `PIN_Type = 'LEI'`
  - valid LEI rows -> uppercase LEI in `PIN_LEI`
  - non-LEI PIN rows:
    - concat country abbreviation + PIN for normal countries
    - PIN-only behavior for no-concat countries
- source-to-output contribution checks:
  - ext-customer contribution
  - failed-TRAX-only contribution
  - expected final count vs actual final count after filters
