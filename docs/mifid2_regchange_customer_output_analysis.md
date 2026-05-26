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
- Step 11 `ReplaceChar` parity approval:
  required before activating executable output SQL to avoid normalization drift.
- Step 9 reg-change activation prerequisites:
  `MIFID2_ext_RegChange_Customer` remains gate-protected until migration/reg-change and PIN/UserAPI contracts are confirmed.
- Step 6 migration/reg-change interval parity:
  Step 9 reg-change staging remains gated until migration population and interval behavior are validated.

## SQL Server parity logic preserved in Step 11 template

The Step 11 SQL template preserves the following behavior from `SP_MIFID2_RegChange_Customer`:

- Build customer population from:
  - `MIFID2_ext_RegChange_Customer` only.
- Apply SQL Server exclusion predicates to the candidate population:
  - `CountryID = 250` excluded
  - `PlayerLevelID = 4` excluded unless CID exists in `InternalAccounts`
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
  - in Step 11, this list controls only the `NotAllowedCONCAT` flag
  - non-LEI `PIN_LEI` still uses `CountryAbbreviation + PIN` (no Step 10-style suppression)
- `TraxEntity` / `TraxAccount` derivation for non-corporate flow

## Detailed source-to-target mapping (Step 11 template)

Main source CTE inputs:

- `regchange_customers` from `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- Internal-account enrichment from:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- Country enrichment from:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
- Latin-name enrichment from:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname`
- Trade-fund enrichment from unresolved mapping placeholder:
  - `{{ext_tradefund_source}}`

Target-column derivations:

- Identity/regulatory core:
  - `CID` <- `COALESCE(source.CID, 0)`
  - `RegulationID` <- `COALESCE(CASE WHEN source.RegulationID IN (4,10) THEN 4 ELSE source.RegulationID END, 0)`
  - `PlayerLevelID` <- `COALESCE(source.PlayerLevelID, 0)`
  - `CountryID` <- `CASE WHEN COALESCE(NULLIF(CitizenshipCountryID,0), CountryID)=144 THEN 143 ELSE COALESCE(NULLIF(CitizenshipCountryID,0), CountryID) END`
  - `ReportDate` <- run parameter (`{{report_date}}`)
- Deposit/date:
  - `FTD` <- `COALESCE(FirstTimeDepositSuccessDate, TIMESTAMP '2015-04-26')`
  - if `FirstTimeDepositSuccessDate` is unavailable upstream, fallback is preserved in final projection.
- Copy-fund enrichment (gated):
  - `CopyFund` <- `CASE WHEN funds.FundAccountID IS NOT NULL THEN 1 ELSE 0 END`
  - `CopyFundName` <- `funds.FundName`
  - `FundTypeID` <- `funds.FundType`
  - `FundType` <- decode `FundTypeID` (`1=People`, `2=Partners`, `3=Market`)
- Country and report flags:
  - `Country` <- `vw_ext_country.Abbreviation`
  - `IsUKReport` <- `CASE WHEN RegulationID=2 THEN 1 ELSE 0 END`
  - `IsEUReport` <- `CASE WHEN RegulationID IN (1,9,11) THEN 1 ELSE 0 END`
  - `NotAllowedCONCAT` <- country in (`67,95,102,126,164,191`)
- Name normalization:
  - base names <- `UPPER(fn_replacechar(source.FirstName/LastName))`
  - language tag <- Unicode checks on normalized names
  - translation <- `reg_ext_customerlatinname` for non-ASIC (`RegulationID <> 4`) language-tagged rows
  - blank fallback <- copy non-empty side into empty first/last
  - final replacement <- `І -> I`, `Ё -> Е`
- PIN/LEI logic:
  - `Lei` <- `COALESCE(source.Lei, internal_accounts.LEI)`
  - `IDType` <- account/LEI branching (`AccountTypeID=9 => 3`, LEI/corporate => 2, else 1)
  - `PIN_Type` <- `'LEI'` when LEI length is 20 or `AccountTypeID=2`, else source `PIN_Type`
  - `PIN_LEI`:
    - valid LEI/corporate path -> uppercase LEI
    - non-LEI path with PIN -> `CountryAbbreviation + PIN`
    - no-concat list does not suppress this concatenation in Step 11
- Trax identifiers:
  - `TraxEntity`, `TraxAccount` <- SQL Server-equivalent non-corporate branching

## Step 11 difference vs Step 10 (`MIFID2_Customer`)

- Uses `MIFID2_ext_RegChange_Customer` (not `MIFID2_ext_Customer`).
- Does not union `MIFID2_Failed_TRAX`.
- Does not apply excluded-CID filtering because `SP_MIFID2_RegChange_Customer` does not contain that join.
- Step 11 no-concat behavior differs from Step 10 template:
  - Step 11 keeps `CountryAbbreviation + PIN` for non-LEI rows even in no-concat countries
  - no-concat list only drives `NotAllowedCONCAT`.
- Shares the same output DDL contract and most field-derivation logic with Step 10.

## Idempotent load pattern

Step 11 template uses report-date scoped idempotency:

1. `DELETE` target rows for `ReportDate = {{report_date}}`
2. `INSERT` the rebuilt dataset for the same report date

This preserves rerun safety without requiring full-table replacement.

## Gating rule and activation boundary

Step 11 output SQL is intentionally non-executable by default (commented template) until all gates are resolved:

- Step 9 reg-change customer source profiling and contract prerequisites
- Step 6 migration population and reg-change interval parity prerequisites
- PIN/UserAPI source contract gate
- `Reg_Ext_CustomerLatinName` source/profile gate
- `Dictionary.Ext_TradeFund` Databricks mapping gate
- `ReplaceChar` parity-validation gate

No `main.regtech` production objects are created in this step.

## Step 11 SQL artifacts

Created in this step:

- `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql`
- `databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql`

Both artifacts are authoring-only templates. No SQL execution is performed.

## Validation coverage in Step 11 SQL

`databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql` includes templates for:

- target schema parity:
  - column existence
  - column order
  - data type mapping
  - nullability
  - precision/scale where relevant
- source/dependency checks:
  - required source columns for reg-change staging, internal accounts, country, and Latin names
  - gate checklist output for unresolved Step 11 dependencies
  - optional TradeFund required-column check placeholder
- row counts:
  - by `ReportDate`
  - by `ReportDate`, `RegulationID`
- duplicate checks:
  - `ReportDate`,`CID`
  - `ReportDate`,`CID`,`RegulationID`
- required-field null checks:
  - `CID`, `RegulationID`, `PlayerLevelID`, `CountryID`, `FTD`, `ReportDate`
- exclusion checks:
  - `CountryID = 250` absent
  - `PlayerLevelID = 4` absent unless internal account exists
- country normalization checks:
  - no `CountryID = 144` in output
  - source precedence and `144->143` normalization consistency
  - country-abbreviation coverage
  - `NotAllowedCONCAT` correctness for countries `67,95,102,126,164,191`
- ReplaceChar/name checks:
  - ReplaceChar sample outputs
  - uppercase-name behavior
  - Latin-name source coverage
  - blank first/last fallback checks
  - final Cyrillic replacement checks (`І`, `Ё`)
- PIN/LEI checks:
  - `AccountTypeID = 2` and LEI typing rules
  - LEI length/uppercase checks
  - non-LEI PIN_LEI population checks
  - Step 11 no-concat behavior (flag only; no PIN concat suppression)
- source-to-output checks:
  - filtered reg-change source contribution count
  - output CIDs outside reg-change source count
  - optional failed-TRAX-only exclusion check (run when failed-trax table exists)
- comparison checks vs Step 10 output:
  - schema parity differences
  - expected CID set separation
  - excluded-CID reference overlap observation (no Step 11 excluded-CID filter by default)
