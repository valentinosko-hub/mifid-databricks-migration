# Step 9 - MIFID2_ext Staging Analysis

This document captures Step 9 only (`MIFID2_ext` staging from `MIFID2.dtsx`). It excludes final MiFID outputs and all file-delivery/production activities.

## Step 9 scope

In-scope Step 9 objects:

- `MIFID2_ext_Customer`
- `MIFID2_ext_RegChange_Customer`
- `MIFID2_ext_Position`
- `MIFID2_ext_RegChange_Position`
- `MIFID2_ext_PositionChangeLog`
- `MIFID2_ext_Mirror`
- `MIFID2_ext_HedgeExecutionLog`
- `MIFID2_Failed_TRAX`

Target objects (all in ops staging and prefixed):

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`

Out of scope in Step 9:

- `MIFID2_Customer`
- `MIFID2_RegChange_Customer`
- `MIFID2_Report`
- `MIFID2_ETORO_Report`
- `MIFID2_Hedge_Report`
- `MIFID2_NPD_TRAX`
- File delivery (`CSV`, `7z`, `SFTP`, `TRAX/Cappitech upload`, response handling)
- Production deployment and full historical backfill

## Source mapping status applied in Step 9

Confirmed mappings:

- `Customer.Customer` -> `main.general.bronze_etoro_customer_customer`
- `History.Customer` -> `main.pii_data.bronze_etoro_history_customer`
- `History.BackOfficeCustomer` -> `main.general.bronze_etoro_history_backofficecustomer` (confirmed mapping; required-column profiling pending)
- `Customer.ExtendedUserField` -> `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield`
- `Dictionary.ExtendedUserValueType` -> `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype`
- `Dictionary.Country` -> `main.general.bronze_etoro_dictionary_country`
- `Dictionary.Label` -> `main.general.bronze_etoro_dictionary_label`
- `Trade.PositionForExternalUse` -> `main.bi_db.bronze_etoro_trade_positionforexternaluse`
- `History.PositionForExternalUse` -> `main.trading.bronze_etoro_history_position_datafactory`
- `History.PositionChangeLog` -> `main.trading.bronze_etoro_history_positionchangelog`
- `History.Mirror` -> `main.trading.bronze_etoro_history_mirror`
- `Hedge.ExecutionLog` -> `main.dealing.bronze_etoro_hedge_executionlog`

Step 9 expected/access-pending or gated dependencies:

- PIN/UserAPI source shape used in customer and failed-TRAX flows (discovery/profiling required)
- `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` parity and representation for reg-change flows (Step 6 dependency)
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` historical/current availability for `MIFID2_Failed_TRAX` seed windows

Important source rule for position staging:

- For `MIFID2_ext_Position` and `MIFID2_ext_RegChange_Position`, use `Trade.PositionForExternalUse` and `History.PositionForExternalUse` as the source contract.
- Do not substitute broad `Trade.Position` / `History.Position` for these Step 9 objects unless package logic explicitly requires it.

## SSIS filter parity to preserve

Main customer flow:

- `History.BackOfficeCustomer` as-of: `ValidFrom < @EndDate AND ValidTo >= @EndDate`
- `RegulationID IN (1,2,9,11)`
- `AccountTypeID NOT IN (7,9)`
- `LabelID NOT IN (26,30)`
- `ReportDate = @StartDate`
- Customer population limited to CIDs with qualifying report-day positions

Main position flow:

- Position windows based on `@StartDate` / `@EndDate`
- History branch includes `OpenOccurred >= '2015-04-26'`
- Open/close day-window filters preserved
- Position population is constrained by filtered customer CIDs

Reg-change customer flow:

- Current non-MiFID account filter: `RegulationID NOT IN (1,2,9,11)`
- `AccountTypeID NOT IN (7,9)`
- `PrevRegulationID IN (1,2,9,11)` from migration-population dependency
- `LabelID NOT IN (26,30)`
- Customer population limited to CIDs with qualifying reg-change positions

Reg-change position flow:

- Same position sources/windows as main position
- Interval split/filter conditions based on `RegValidFrom`, `RegValidTo`, `NewRegulationID`, `PrevRegulationID`, `RegChangeRank`

Position change-log flow:

- `Occurred >= @StartDate AND Occurred < @EndDate`
- `ChangeTypeID = 0`

Mirror flow:

- `MirrorOperationID = 1`
- `Occurred >= @StartDate AND Occurred < @StartDate + 1 day`
- `CopyFund = 1` derived when parent CID has `AccountTypeID = 9`

Hedge execution flow:

- `ExecutionTime >= @StartDate AND ExecutionTime < @EndDate`
- Exclude `(ProviderExecID IS NULL AND OrderState = 4)`

Failed TRAX flow:

- CIDs derived from latest row per CID in `MIFID2_NPD_TRAX`
- `AcceptedTRAX = 0 OR AcceptedTRAX IS NULL`
- No `@StartDate` filter in source-CID selection
- Output `ReportDate = @StartDate`

## Formal DDL and schema handling

Formal DDL availability in reference package:

- `MIFID2_Failed_TRAX`: formal DDL exists (`02_sql_server_ddls/ssis_created_staging_tables/MIFID2_Failed_TRAX.sql`)
- Other seven `MIFID2_ext_*` objects: formal DDL not found in that DDL folder

Schema handling rule used in Step 9:

- Where formal DDL exists, keep that contract authoritative.
- Where formal DDL is absent, schema contract is **derived from SSIS metadata + consumer stored procedure usage**.
- No columns are silently synthesized.

## Reconstructed output-column contracts

Customer / reg-change customer contract:

- `CID`, `GCID`, `PlayerLevelID`, `PlayerStatusID`, `CountryID`, `LabelID`, `FirstName`, `LastName`, `BirthDate`, `RegulationID`, `AccountTypeID`, `Lei`, `CountryIDByIP`, `curFirstName`, `curLastName`, `curBirthDate`, `CitizenshipCountryID`, `PIN_ID`, `PIN_Type`, `PIN`, `UAPI_CountryID`, `ReportDate`
- Note: `FirstTimeDepositSuccessDate` is handled in consumer procedure logic and is not loaded by SSIS in this staging layer.

Position / reg-change position contract:

- `PositionID`, `ParentPositionID`, `CID`, `OpenOccurred`, `CloseOccurred`, `InitForexRate`, `EndForexRate`, `AmountInUnitsDecimal`, `InstrumentID`, `IsBuy`, `Leverage`, `LastOpConversionRate`, `MirrorID`, `InitExecutionID`, `EndExecutionID`, `HedgeServerID`, `IsSettled`, `InitForexPriceRateID`, `EndForexPriceRateID`, `LastOpPriceRate`, `OriginalPositionID`, `InitialUnits`, `ReportDate`

Position change-log contract:

- `PositionID`, `ChangeLogLastOpPriceRate`, `ChangeLogOccurred`, `ChangeTypeID`, `IsSettled`

Mirror contract:

- `MirrorID`, `ParentCID`, `MirrorOperationID`, `Occurred`, `CopyFund`

Hedge execution-log contract:

- `OrderID`, `HedgeServerID`, `InstrumentID`, `IsBuy`, `Units`, `ExecutionRate`, `ProviderExecID`, `ExecutionTime`, `Success`, `LogTime`, `LiquidityAccountID`, `EMSOrderID`

Failed TRAX contract:

- `CID`, `GCID`, `PlayerLevelID`, `PlayerStatusID`, `CountryID`, `LabelID`, `FirstName`, `LastName`, `BirthDate`, `CountryIDByIP`, `curFirstName`, `curLastName`, `curBirthDate`, `CitizenshipCountryID`, `PIN_ID`, `PIN_Type`, `PIN`, `UAPI_CountryID`, `ReportDate`

## Materialization and gating policy

Materialization policy:

- All Step 9 objects are authored as materialized Delta staging tables (not views) because `MIFID2.dtsx` is truncate/reload snapshot logic.

Execution policy:

- Source profiling SQL is authored first.
- `CREATE OR REPLACE TABLE` sections remain commented for objects whose source access/required-column contracts are not fully confirmed.

Current Step 9 authoring status:

- Gated templates are authored for all eight Step 9 targets.
- Closest to executable after profiling: `MIFID2_ext_PositionChangeLog`, `MIFID2_ext_Mirror`, `MIFID2_ext_HedgeExecutionLog`.
- Must remain gated: `MIFID2_ext_Customer`, `MIFID2_ext_RegChange_Customer`, `MIFID2_ext_Position`, `MIFID2_ext_RegChange_Position`, `MIFID2_Failed_TRAX`.

## Step 9 SQL artifacts

Created under `databricks/sql/07_mifid2_ext/`:

- `01_mifid2_ext_source_profiling.sql`
- `02_customer_ext_staging.sql`
- `03_position_ext_staging.sql`
- `04_positionchangelog_mirror_ext_staging.sql`
- `05_hedge_ext_staging.sql`
- `06_failed_trax_staging.sql`
- `07_mifid2_ext_validation.sql`

All artifacts are profiling-first and gate-first templates only in this step. No SQL is executed.

## Validation coverage required in Step 9

Step 9 validation SQL includes templates for:

- Source required-column checks
- Target required-column checks
- Row counts by `ReportDate`
- Row counts by `RegulationID` where applicable
- Duplicate checks:
  - customer: `ReportDate`, `CID`
  - position: `ReportDate`, `PositionID`
  - reg-change position: `ReportDate`, `PositionID`
  - change log: `PositionID`, `ChangeLogOccurred`, `ChangeTypeID`
  - mirror: `MirrorID`
  - hedge execution: `OrderID`, `ExecutionTime`, `ProviderExecID`
  - failed TRAX: `ReportDate`, `CID`
- Null checks for key fields (`CID`, `PositionID`, `InstrumentID`, `ReportDate`, `RegulationID`, position open/close fields, hedge execution keys)
- Customer as-of checks (`History.Customer`, `History.BackOfficeCustomer`)
- Position date-window checks
- `PositionChangeLog` `ChangeTypeID = 0` checks
- Mirror `CopyFund` checks
- Failed TRAX latest-row and accepted-status checks
- Source-to-stage count checks where practical

## History/cutover dependencies to keep explicit

- `MIFID2_Failed_TRAX` depends on historical/current `MIFID2_NPD_TRAX` rows; do not fabricate historical rows.
- Step 9 remains compatible with validation-window seeding only; full historical backfill stays out of scope.
- Reg-change staging depends on Step 6 migration-population parity behavior for date-window and regulation-transition logic.
