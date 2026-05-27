# Step 13A/13B1 - MIFID2 ETORO Report Output Analysis

This document captures the Step 13A analysis baseline and Step 13B1 scaffolding boundary for `MIFID2_ETORO_Report`.

## Scope (Step 13B1)

- Scaffold/output-contract/dependency-gate authoring only for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- Document source replacement rule:
  - Legacy `dbo.ASIC_Transactions` is not the source of truth for migration implementation.
  - Step 8 ASIC2-compatible layer is the source authority for consumed transaction fields.
- Document activation gates and planned split for Step 13B2/13B3.

## Out of scope (Step 13B1)

- Final ETORO projection implementation (`INSERT` business logic).
- ETORO validation/reconciliation SQL package implementation.
- `MIFID2_Hedge_Report`.
- `MIFID2_NPD_TRAX`.
- File delivery (`CSV`, `7z`, `SFTP`, TRAX/Cappitech upload, response handling).
- Production deployment and orchestration activation.

## SQL Server authorities

- Stored procedure authority:
  - `reference/mifid_databricks_migration_context/01_sql_server_stored_procedures/core_mifid/SP_MIFID_ETORO_Report.sql`
- DDL authority:
  - `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_ETORO_Report.sql`

## Target object

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`

## Consumed legacy ASIC_Transactions fields (from SP behavior)

The SQL Server ETORO procedure consumes the following transaction fields from legacy `dbo.ASIC_Transactions`:

- `DateID`
- `ReportDate`
- `CID`
- `PositionID`
- `InstrumentID`
- `OpenORClose`
- `IsBuy`
- `OpenTime` (built from `CDE_Execution_timestamp`)
- `Volume` (from `Quantity`)
- `OpenPrice`
- `RegChange`

These are the exact 11 compatibility fields already defined in Step 8.

## ASIC2 compatibility mapping (Step 8 source of truth)

Step 13 must consume Step 8 compatibility outputs:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`

Field mapping contract:

| ETORO consumed field | ASIC2-compatible source field |
| --- | --- |
| `DateID` | `DateID` |
| `ReportDate` | `ReportDate` |
| `CID` | `CID` |
| `PositionID` | `PositionID` |
| `InstrumentID` | `InstrumentID` |
| `OpenORClose` | `OpenORClose` |
| `IsBuy` | `IsBuy` |
| `OpenTime` | `OpenTime` (derived in Step 8 from `CDE_Execution_timestamp`) |
| `Volume` | `Volume` (derived in Step 8 from `Quantity`) |
| `OpenPrice` | `OpenPrice` |
| `RegChange` | `RegChange` |

## Output schema summary

- Target contract width: 100 columns (same MiFID report-shape family used by ETORO DDL).
- SQL Server uniqueness intent to validate in Databricks:
  - `ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`
- `UpdateDate` behavior:
  - SQL Server ETORO uses `GETUTCDATE()` at insert time.
  - Databricks parity should use current UTC timestamp only when Step 13B2 projection is activated.
  - Step 13B1 remains scaffold-only and does not execute this behavior.

## Core ETORO transformation behavior (analysis baseline)

- Report-date scoped delete/load pattern in SQL Server (`DELETE TOP (4000)` loop by `ReportDate` before insert).
- Regulation constants in ETORO projection:
  - `RegulationReportID = 1`
  - `RegulationID = 1`
  - `BackReportingIndicator = 0`
- Transaction reference pattern:
  - `CAST(PositionID AS VARCHAR) + OpenORClose + 'AUS' + DateID`
- Trading timestamp shape:
  - ISO-like UTC string from `OpenTime`.
- Price/quantity usage:
  - `Volume` feeds output `Quantity`.
  - `OpenPrice` feeds output `Price`.
- Instrument/currency enrichment path:
  - `Reg_Instruments_SCD` (valid-date slice),
  - `Reg_Instruments_Full_Description`,
  - `InstrumentMetaData_SpecialChar_Conversion`,
  - `Reg_Ext_DictionaryCurrency`,
  - `Reg_Ext_DictionaryCurrencyType`.
- ETORO-specific `InstrumentClassification` is explicit case logic by `InstrumentTypeID` and instrument ID groups; this must be ported exactly in Step 13B2.

## Filters and exclusions (analysis baseline)

- `ReportDate = {{report_date}}` window.
- Exclude CIDs:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
- Exclude instruments:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
- Exclude position IDs:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
- Restrict to MiFID-eligible instruments via metadata (`IsMifid = 1` path).

## Dependency gates (Step 13B1 carry-forward)

- Step 8 ASIC2 compatibility view activation.
- `CDE_Execution_timestamp -> OpenTime` parity.
- `Quantity -> Volume` parity.
- `OpenPrice` parity.
- Conditional `Reg_DWH_StaticPosition` fallback impact (only if proven to affect consumed fields such as `OpenPrice`).
- `InstrumentMetaData_SpecialChar_Conversion` readiness for report date.
- `Reg_Ext_DictionaryCurrency` readiness.
- `Reg_Ext_DictionaryCurrencyType` readiness.
- `Reg_Instruments_SCD` / `Reg_Instruments_Full_Description` report-date coverage.
- Excluded CIDs/instruments/position IDs source freshness and schema contract.
- ASIC2 historical seed window coverage for requested reconciliation dates.
- Exact ETORO `InstrumentClassification` mapping port.

## UPI and conditional dependency policy

- EMIR Refit UPI is not a direct Step 13 dependency unless profiling proves an impact on one of the 11 consumed compatibility fields.
- `Reg_DWH_StaticPosition` remains conditional and non-blocking unless fallback-impact profiling shows it affects consumed ETORO fields (especially `OpenPrice`).

## Planned implementation split

- Step 13B1 (this step):
  - Documentation updates + SQL scaffolding + output contract + explicit gates.
  - No active projection SQL and no active validation package.
- Step 13B2:
  - Final ETORO projection template implementation from ASIC2 compatibility + metadata/enrichment joins + exact classification mapping + `UpdateDate` UTC parity activation.
- Step 13B3:
  - ETORO read-only validation/reconciliation package (schema, row-count, duplicates, nulls, field-level parity, exclusion parity, and gate closure evidence).
