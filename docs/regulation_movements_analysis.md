# Step 6 - Regulation Movement Staging Analysis

This document captures Step 6 only (Regulation movement staging) and excludes hedge-liquidity mapping, ASIC2 implementation, `MIFID2_ext` staging, and final MiFID outputs.

Primary target object:

- `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`

Legacy spelling note:

- SQL Server uses `Regulation_Movments` (missing "e").
- Step 6 preserves this spelling in target naming for parity and traceability.

## Active production path in `Regulation_Movments_Report.dtsx`

Step 6 active sequence (`Regulation Movments Report`) performs:

1. Truncate support copy table:
   - `RegSupportDB.dbo.Ext_MigrationInOut_Population`
2. Copy `RunDate = report_date` rows from:
   - `RegReportDB.dbo.Reg_MigrationInOut_Population`
   into the support copy table.
3. Delete movement target rows for report date:
   - `DELETE FROM dbo.Reg_Regulation_Movments_Positions WHERE ReportDate = @StartDate`
4. Load movement rows from a SQL source query that joins migration population to position/history sources.
5. Post-load update to enrich symbol and EOD pricing from instrument SCD and split-price staging.

`Reg_RegulationInOutDailyData` is not used in this active Step 6 load path. It appears in historic/disabled `RegInRegOut` flows and in downstream consumers.

## Source tables used by Step 6 movement load

Core active sources:

- `RegReportDB.dbo.Reg_MigrationInOut_Population` (via copied support table)
- `etoro.Trade.Position`
- `etoro.History.Position`
- `RegReportDB.dbo.Reg_Instruments_SCD` (post-load update)
- `RegReportDB.dbo.Reg_Ext_CurrencyPriceMaxDateWithSplit` (post-load update)

Support-copy object:

- `RegSupportDB.dbo.Ext_MigrationInOut_Population` is a support copy/temp staging artifact for cross-database join convenience.
- Databricks representation should be non-persistent (CTE or temporary relation in the Step 6 SQL flow), not a new persistent business table.

## Step 5 dependency alignment

Already produced/gated in Step 5:

- `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` (gated parity decision)
- `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata` (gated parity decision; not active input for Step 6 load)
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit` (still source-selection gated from Step 5B1)

## Certified gold usage for movement inputs

Confirmed certified gold mappings exist:

- `main.regtech.gold_regtech_reg_migrationinout_population`
- `main.regtech.gold_regtech_reg_regulationinoutdailydata`

Step 6 decision:

- `Reg_MigrationInOut_Population` may be materialized as prefixed run snapshot from certified gold only after schema/filter parity is accepted.
- `Reg_RegulationInOutDailyData` remains gated until output-column parity is confirmed (stored procedure output shape not visible directly in DTSX).

## Date / report-date logic

- `@StartDate` = report date
- `@EndDate` = `DATEADD(day, 1, @StartDate)`
- Target refresh scope is `ReportDate = @StartDate`
- Position filters use report-day end boundary (`< @EndDate`)

## Movement / direction logic (Step 6 object)

`Reg_Regulation_Movments_Positions` uses migration window logic from migration population:

- `RegulationID` = current/new regulation
- `PrevRegulationID` = prior regulation
- `Migration_Occurred` = migration timestamp anchor
- `IsOpenedAfterLastMigration` set by comparison against the latest migration timestamp per CID for the report date

Rows include:

- Open positions branch (`Trade.Position`)
- Closed positions branch (`History.Position`)
- Migration-only rows (no matching position activity)

## Required output columns for movement target

- `ReportDate`
- `CID`
- `RegulationID`
- `PrevRegulationID`
- `Migration_Occurred`
- `PositionID`
- `OpenOccurred`
- `CloseOccurred`
- `IsBuy`
- `Quantity`
- `OpenPrice`
- `ClosePrice`
- `InstrumentID`
- `IsSettled`
- `IsOpenedAfterLastMigration`
- `EOD_Price`
- `Symbol`
- `IsMifid`
- `IsMifidByFCA`
- `UpdateDate`

## Databricks target objects and status (Step 6)

Primary output:

- `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions` (Step 6 target; gated pending profiling)

Supporting persistent snapshots (still gated):

- `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
- `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata`

Non-persistent support copy representation:

- `Ext_MigrationInOut_Population` represented via CTE/temporary relation in Step 6 SQL flow.

## Dependency status summary

Confirmed:

- Gold mapping for migration population and regulation in/out daily data.
- Position/history source families.
- Instrument SCD certified source mapping.

Gated:

- `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection/parity (Step 5B1 unresolved).
- Migration population and regulation-daily-data snapshot policy parity.
- Exact source column/access parity for Step 6 joins.

Expected source / access pending:

- Any Step 6 source field not yet profiled in Databricks runtime schemas.

## Validation required for Step 6

- Row count by `ReportDate`
- Duplicate checks by `ReportDate`, `CID`, `PositionID`
- Null checks for required fields
- Counts by `RegulationID` / `PrevRegulationID`
- `IsOpenedAfterLastMigration` distribution and consistency checks
- Source-to-stage comparisons where practical:
  - migration population (`RunDate = report_date`) vs movement stage coverage
  - position/history branch coverage checks
  - enrichment coverage (`InstrumentID` vs symbol/EOD population)

## Risks

- Legacy spelling risk (`Movments`) must be preserved intentionally for parity.
- Gold-vs-SSIS parity risk for migration snapshots.
- Price dependency risk via unresolved split-price source selection.
- Historical/cutover risk if report-date backfills are required before parity decisions and seed policy are finalized.
