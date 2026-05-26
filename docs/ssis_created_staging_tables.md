# Phase 1B - SSIS-Created Staging Tables

Source scope used for this document:
- `reference/mifid_databricks_migration_context/04_sql_agent_jobs`
- `reference/mifid_databricks_migration_context/05_ssis/selected_packages`
- `reference/mifid_databricks_migration_context/05_ssis/metadata`
- `reference/mifid_databricks_migration_context/06_mappings`

Classification rule used:
- If a table is loaded/truncated/deleted/refreshed by SSIS package logic (data flow or SQL task), classify it as **SSIS-created staging**.

## Pre_Regulation_Ext.dtsx

Classified as SSIS-created staging (producer package: `Pre_Regulation_Ext.dtsx`):

- `Reg_CurrencyPrice_Ext`
- `Reg_Ext_CurrencyPriceMaxDateWithSplit`
- `Reg_Ext_DailyMaxPrices`
- `Reg_Ext_T_PriceCandle60Min`
- `Reg_Ext_MigrationInOut_STG`
- `Reg_MigrationInOut_Population`
- `Reg_RegulationInOutDailyData`
- `Reg_Ext_CustomerLatinName`
- `Reg_Ext_HistorySplitRatio`
- `Reg_Ext_Trade_GetInstrument`
- `Reg_Ext_Trade_InstrumentMetaData`
- `Reg_Ext_DictionaryCurrency`
- `Reg_Ext_DictionaryCurrencyType`
- `Reg_Ext_HedgeExecutionLog`
- `Reg_Ext_HedgeHBCExecutionLog`
- `Reg_Ext_HedgeHBCOrderLog`
- `Reg_Instruments_ext`

Also observed as SSIS-managed in this package:
- `Reg_Ext_HistoryPositionChangeLog`
- `Reg_Ext_DictionaryClosePositionActionType`

## MIFID2.dtsx

Classified as SSIS-created staging (producer package: `MIFID2.dtsx`):

- `MIFID2_ext_Customer`
- `MIFID2_ext_RegChange_Customer`
- `MIFID2_ext_Position`
- `MIFID2_ext_RegChange_Position`
- `MIFID2_ext_PositionChangeLog`
- `MIFID2_ext_Mirror`
- `MIFID2_ext_HedgeExecutionLog`
- `MIFID2_Failed_TRAX`

Produced via package SQL task (`exec dbo.SP_InstrumentMetaData_SpecialChar_Conversion`):
- `InstrumentMetaData_SpecialChar_Conversion`

Consumed (not primary producer in this package):
- `Reg_MigrationInOut_Population`

Step 9 (`MIFID2_ext`) producer/filter notes from `MIFID2.dtsx`:

- `MIFID2_ext_Customer`
  - Truncate + reload snapshot in package.
  - Customer/backoffice as-of logic uses `ValidFrom < @EndDate AND ValidTo >= @EndDate`.
  - Applies `RegulationID IN (1,2,9,11)`, `AccountTypeID NOT IN (7,9)`, `LabelID NOT IN (26,30)`.
- `MIFID2_ext_RegChange_Customer`
  - Truncate + reload snapshot in package.
  - Uses reg-change path with non-MiFID current regulations and migration-population constraints (`PrevRegulationID` gate).
- `MIFID2_ext_Position`
  - Truncate + reload snapshot in package.
  - Uses `Trade.PositionForExternalUse` + `History.PositionForExternalUse` windows.
  - Preserves `OpenOccurred >= '2015-04-26'` where present in history branch.
- `MIFID2_ext_RegChange_Position`
  - Truncate + reload snapshot in package.
  - Uses same position sources plus regulation-change interval constraints.
- `MIFID2_ext_PositionChangeLog`
  - Truncate + reload snapshot in package.
  - Uses `History.PositionChangeLog` day window with `ChangeTypeID = 0`.
- `MIFID2_ext_Mirror`
  - Truncate + reload snapshot in package.
  - Uses `History.Mirror` with `MirrorOperationID = 1` and day window.
  - Derives `CopyFund` by parent CID account-type logic.
- `MIFID2_ext_HedgeExecutionLog`
  - Truncate + reload snapshot in package.
  - Uses `Hedge.ExecutionLog` `ExecutionTime` window and excludes `(ProviderExecID IS NULL AND OrderState = 4)`.
- `MIFID2_Failed_TRAX`
  - Truncate + reload snapshot in package.
  - Uses latest-per-CID `MIFID2_NPD_TRAX` logic with `(AcceptedTRAX = 0 OR AcceptedTRAX IS NULL)`.
  - This table is SSIS-created staging and is not a raw source.

Step 9 materialization policy:

- All `MIFID2_ext_*` and `MIFID2_Failed_TRAX` objects are treated as materialized Delta staging tables in Databricks (not views) because package behavior is truncate/reload run snapshots.

## Regulation_Movments_Report.dtsx

Classified as SSIS-created staging (producer package: `Regulation_Movments_Report.dtsx`):

- `Reg_Ext_MigrationInOut_STG`
- `Reg_MigrationInOut_Population`
- `Reg_Regulation_Movments_Positions`

## HedgeServerToLiquidity_Mapping.dtsx

Classified as SSIS-created staging (producer package: `HedgeServerToLiquidity_Mapping.dtsx`):

- `Reg_HedgeServerToLiquidityAccount_Ext`
- `Reg_LiquidtyAcount_Ext`
- `Reg_Ext_LiquidityAccountID`
- `Reg_Ext_LiquidityProviders`

Produced/refreshed via package SQL task (`exec SP_Reg_LiquidtyAcount_SCD`):
- `Reg_LiquidtyAcount_SCD`

## ASIC2.dtsx

Classified as SSIS-created staging (producer package: `ASIC2.dtsx`):

- `ASIC2_ext_PositionChangeLog`
- `ASIC2_ext_OpenPositions_PositionsReport`
- `ASIC2_Customer_PositionReport`
- `ASIC2_InstrumentMetaData`

Produced via package SP flow (middle/end SQL tasks):
- `ASIC2_Positions`
- `ASIC2_Transactions`
- `ASIC2_Removed_OP_Partials`

## MIFID2 TRAX.dtsx

No `MIFID2_ext_*`/`Reg_Ext_*`/`ASIC2_ext_*` staging family is produced directly by this package.

Package-driven operational outputs observed:
- Executes `SP_MIFID2_NPD_TRAX` to populate `MIFID2_NPD_TRAX`.
- Manages `MIFID2_NPD_TRAX_Response` for TRAX response flow.

## Important classification confirmations

- `MIFID2_ext_*`: classified as **SSIS-created staging** (produced by `MIFID2.dtsx`).
- `Reg_Ext_*`: classified as **SSIS-created staging** where produced by package logic (`Pre_Regulation_Ext.dtsx`, `HedgeServerToLiquidity_Mapping.dtsx`, and related SSIS flows).
- `ASIC2_ext_*`: classified as **SSIS-created staging** (produced by `ASIC2.dtsx`).
- `Reg_CurrencyPrice_Ext`: classified as **SSIS-created staging** (produced/refreshed by package logic).
- `Reg_Regulation_Movments_Positions`: classified as **SSIS-created staging** (produced by `Regulation_Movments_Report.dtsx`).
- `Reg_MigrationInOut_Population`: classified as **SSIS-created staging** (produced/maintained by SSIS package logic).
