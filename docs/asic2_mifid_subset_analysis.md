# Step 8 - ASIC2-Compatible MiFID Subset Analysis

This document captures Step 8 only (ASIC2-compatible MiFID subset). It excludes `MIFID2_ext` staging, final MiFID outputs, ETORO final report generation, and hedge final report generation.

## Step 8 scope

In-scope Step 8 objects:

- `ASIC2_ext_OpenPositions_PositionsReport`
- `ASIC2_ext_PositionChangeLog`
- `ASIC2_Customer_PositionReport`
- `ASIC2_Positions`
- `ASIC2_InstrumentMetaData`
- `ASIC2_Removed_OP_Partials`
- `ASIC2_Transactions`
- MiFID-owned projected ASIC2 subset
- Compatibility view replacing legacy `dbo.ASIC_Transactions` shape for MiFID ETORO

Target objects (all prefixed and in ops staging):

- `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_positions`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`

Out of scope in Step 8:

- ASIC2 file generation/export delivery
- ASIC2 collateral outputs
- ASIC2 hedge-specific outputs
- ASIC2 aggregate outputs unless proven required for `ASIC2_Positions` or `ASIC2_Transactions`
- Legacy ASIC process as source of truth
- EMIR Refit UPI unless proven to affect MiFID-consumed compatibility fields
- Production deployment and full historical backfill

## ASIC2 source-of-truth and compatibility intent

- ASIC2 is treated as the source-of-truth replacement path for MiFID ETORO dependency shaping.
- Legacy `dbo.ASIC_Transactions` is treated as compatibility shape reference only.
- Step 8 creates a MiFID-owned projection plus compatibility view so later ETORO logic can consume an ASIC2-backed shape.

## Conditional dependency rules applied

`SP_ASIC2_Instrument_Automation`:

- Treated as conditional, not silently ignored.
- If `ASIC2_InstrumentMetaData` can be recreated directly from profiled sources and existing staged dependencies, it remains out of active Step 8 execution.
- If profiling proves `ASIC2_InstrumentMetaData` depends on procedure-only transformations, activation remains gated until that dependency path is documented and implemented.

`SP_ASIC2_PositionReport_Agg` and aggregate outputs:

- Treated as out of scope unless profiling proves direct feed into `ASIC2_Positions`, `ASIC2_Transactions`, or the MiFID compatibility projection.
- If required, this is documented as a conditional prerequisite and execution remains gated.

`Reg_DWH_StaticPosition`:

- Treated as conditional/legacy.
- It does not block Step 8 activation by default.
- It becomes an active dependency only if profiling shows measurable impact on MiFID-consumed fields (especially `OpenPrice` parity path).

EMIR Refit UPI:

- Not treated as direct MiFID dependency in Step 8.
- Validation includes explicit checks to confirm UPI does not affect the required MiFID compatibility fields:
  - `DateID`, `ReportDate`, `CID`, `PositionID`, `InstrumentID`, `OpenORClose`, `IsBuy`, `OpenTime`, `Volume`, `OpenPrice`, `RegChange`

## MiFID compatibility field contract

Compatibility view target:

- `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`

Required exposed columns (exactly 11):

- `DateID`
- `ReportDate`
- `CID`
- `PositionID`
- `InstrumentID`
- `OpenORClose`
- `IsBuy`
- `OpenTime`
- `Volume`
- `OpenPrice`
- `RegChange`

Mapping from `ASIC2_Transactions`:

- `DateID -> DateID`
- `ReportDate -> ReportDate`
- `CID -> CID`
- `PositionID -> PositionID`
- `InstrumentID -> InstrumentID`
- `OpenORClose -> OpenORClose`
- `IsBuy -> IsBuy`
- `Quantity -> Volume`
- `OpenPrice -> OpenPrice`
- `RegChange -> RegChange`
- `CDE_Execution_timestamp -> OpenTime`

`CDE_Execution_timestamp -> OpenTime` remains explicitly unproven and is treated as a gated mapping pending validation evidence.

## OpenTime validation approach

Step 8 validation SQL includes:

- Parse-format checks for `CDE_Execution_timestamp`
- Parse success/failure counts by `ReportDate`
- Comparison between parsed execution timestamp and projected `OpenTime`
- Formatting round-trip checks that re-format parsed timestamps to ETORO-style ISO strings and compare:
  - against original `CDE_Execution_timestamp`
  - against projected `OpenTime` formatted to the same expected representation

No assumption is made that SQL Server appended `Z` implies a real timezone conversion.

## Materialization and gating policy

Step 8 materialization policy:

- Materialized Delta tables for ASIC2 staging targets and MiFID-owned projected subset.
- View for final compatibility shape.
- No active executable `CREATE OR REPLACE` for objects whose source contracts are still expected/access-pending.

Current Step 8 authored status:

- `ASIC2_ext_PositionChangeLog`: gated template authored; source mapping comparatively strongest.
- `ASIC2_ext_OpenPositions_PositionsReport`: gated template authored; source/profile confirmation pending.
- `ASIC2_Customer_PositionReport`: gated template authored; source/profile confirmation pending.
- `ASIC2_InstrumentMetaData`: gated template authored with conditional dependency treatment for automation path.
- `ASIC2_Positions`: gated template authored; aggregate dependency remains conditional.
- `ASIC2_Removed_OP_Partials`: gated template authored.
- `ASIC2_Transactions`: gated template authored.
- `MIFID2_ASIC2_Transactions`: gated template authored.
- Compatibility view: gated template authored with exact 11-column contract.

## History seed requirements in Step 8

Step 8 keeps full backfill out of scope and documents minimum seed expectations:

- Target `ReportDate` data is required.
- Prior-day `ASIC2_Positions` may be required for parity branches in transaction logic.
- Prior `ASIC2_Transactions` may be required for non-MiFID carry-forward fields in some parity windows.

Seed policy is optional-window based for requested validation ranges only.

## Step 8 SQL artifacts

Created under `databricks/sql/06_asic2_subset/`:

- `01_asic2_source_profiling.sql`
- `02_asic2_ext_staging.sql`
- `03_asic2_positions_and_instruments.sql`
- `04_asic2_transactions.sql`
- `05_mifid_asic_compatibility_view.sql`
- `06_asic2_validation.sql`

These files are authored as profiling-first and gate-first templates and are not executed in this step.

