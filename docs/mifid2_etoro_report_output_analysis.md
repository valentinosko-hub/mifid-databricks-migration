# Step 13A/13B1/13B2/13B3 - MIFID2 ETORO Report Output Analysis

This document captures the Step 13A analysis baseline, Step 13B1 scaffolding boundary, Step 13B2 gated projection-template scope, and Step 13B3 validation/reconciliation package scope for `MIFID2_ETORO_Report`.

## Scope (Step 13B1/13B2)

- Scaffold/output-contract/dependency-gate authoring only for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- Gated Step 13B2 projection template authoring from Step 8 ASIC2 compatibility source:
  - `databricks/sql/08_outputs/07_mifid2_etoro_report.sql`
- Step 13B2 includes gated ETORO projection-template authoring and does not include active execution.
- Document source replacement rule:
  - Legacy `dbo.ASIC_Transactions` is not the source of truth for migration implementation.
  - Step 8 ASIC2-compatible layer is the source authority for consumed transaction fields.
- Document activation gates and planned split for Step 13B2/13B3.

## Scope (Step 13B3)

- Step 13B3 introduces a read-only ETORO validation/reconciliation package:
  - `databricks/sql/08_outputs/07_mifid2_etoro_report_validation.sql`
- Validation package scope is strictly:
  - SELECT-only schema/data-quality/reconciliation checks
  - no activation DML (`INSERT`/`DELETE`/`UPDATE`/`MERGE`) and no DDL.
- Step 13B3 validates the Step 13B2 ETORO output contract against:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- Placeholder-dependent checks remain gated/commented until dependency contracts are confirmed.

## Out of scope for Step 13B2

- Active / ungated ETORO projection execution.
- ETORO validation / reconciliation SQL package implementation, which belongs to Step 13B3.
- `MIFID2_Hedge_Report`.
- `MIFID2_NPD_TRAX`.
- File delivery (`CSV`, `7z`, `SFTP`, TRAX/Cappitech upload, response handling).
- Production deployment and orchestration activation.

## Out of scope for Step 13B3

- Active ETORO projection execution changes (belongs to Step 13B2 activation path).
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
  - Gated ETORO projection-template authoring from ASIC2 compatibility + metadata/enrichment joins + exact classification mapping + `UpdateDate` UTC parity representation.
  - No active/ungated execution in Step 13B2.
- Step 13B3:
  - ETORO read-only validation/reconciliation package (schema, row-count, duplicates, nulls, field-level parity, exclusion parity, and gate closure evidence).

## Step 13B2 projection template artifact

- SQL artifact:
  - `databricks/sql/08_outputs/07_mifid2_etoro_report.sql`
- Target output object:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- Source object (compatibility layer):
  - `{{asic_compatibility_source}}` (expected mapping: `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`)
- Report-date parameter placeholder:
  - `{{report_date}}`
- Exclusion placeholders:
  - `{{excluded_cids_source}}`
  - `{{excluded_instruments_source}}`
  - `{{excluded_position_ids_source}}`

## Step 13B2 exact source-to-target mappings represented

The Step 13B2 template explicitly represents the required mappings:

| target field | Step 13B2 mapping |
| --- | --- |
| `RegulationReportID` | `1` |
| `RegulationID` | `1` |
| `DateID` | source `DateID` |
| `ReportDate` | source `ReportDate` |
| `CID` | source `CID` |
| `PositionID` | source `PositionID` |
| `InstrumentID` | source `InstrumentID` |
| `OpenORClose` | source `OpenORClose` |
| `BuyORSell` | source `IsBuy` |
| `TransactionReferenceNumber` | `PositionID + OpenORClose + 'AUS' + DateID` |
| `TradingDateTime` | source `OpenTime` formatted `yyyy-MM-ddTHH:mm:ssZ` |
| `Quantity` | source `Volume` |
| `Price` | source `OpenPrice` |
| `RegChange` | source `RegChange` |
| `PriceType` | `'BSPS'` when `CurrencyTypeID = 4`, else `'MNTR'` |
| `PriceCurrency` | `SUBSTRING(SellAbbreviation, 1, 3)` |
| `InstrumentFullName` | `LEFT(InstrumentFullName, 50) + ' CFD'` |
| `UnderlyingInstrumentCode` | `ISINCode` |
| `AssetClass` | `'Equity'` for currency types `4,5,6`, else dictionary currency type name |
| `UpdateDate` | current UTC timestamp equivalent (gated final template only) |

## Step 13B2 dependencies and filters represented

- Compatibility source filter:
  - source `ReportDate = {{report_date}}`
- Instrument metadata eligibility filters:
  - `IsMifid = 1`
  - `Tradable = 1`
  - `{{report_date}} >= ValidFrom`
  - `{{report_date}} < ValidTo`
- Dependency joins:
  - `main.regtech.gold_regtech_reg_instruments_scd`
  - `main.regtech.gold_regtech_reg_instruments_full_description`
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`

## Exclusion table semantics (critical clarification)

`table_name = '[MIFID2_ETORO_Report]'` scopes exclusion rows to this report. It does not exclude the entire ETORO output table.

Step 13B2 logic is scoped as:

- Exclude matching instruments for this report based on:
  - `InstrumentID` match and `table_name = '[MIFID2_ETORO_Report]'`
- Exclude matching positions for this report based on:
  - `PositionID` match and `table_name = '[MIFID2_ETORO_Report]'`
- Excluded CIDs are removed using the excluded-CIDs source contract.

## Step 13B2 hard gates carried forward

- `CDE_Execution_timestamp -> OpenTime` parity remains a blocking activation gate.
- OpenPrice remains gated for conditional `Reg_DWH_StaticPosition` fallback impact.
- `InstrumentClassification` is hard-gated in the Step 13B2 template unless exact SQL Server mapping is confirmed/ported.
- EMIR Refit UPI remains out of direct dependency scope unless field-impact is proven on the 11 consumed compatibility fields.

## Step 13B3 validation categories (read-only package)

Step 13B3 validation package covers:

- Schema parity checks:
  - table existence/column-count checks
  - information-schema column-order/type/nullability snapshots
  - required-column ordinal/type/nullability checks for ETORO required fields.
- Row-count checks:
  - by `ReportDate`, `RegulationReportID`, `RegulationID`, `OpenORClose`, `RegChange`.
- Duplicate and required-null checks:
  - uniqueness-intent checks on (`ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`)
  - optional position/open-close duplicate lens
  - required-null checks for ETORO mandatory fields.
- Source-to-output reconciliation:
  - source/output counts by date
  - anti-joins by `DateID`, `ReportDate`, `PositionID`, `OpenORClose`
  - `RegChange` distribution parity checks.
- OpenTime/TradingDateTime checks:
  - OpenTime parseability
  - `TradingDateTime` format checks (`yyyy-MM-ddTHH:mm:ssZ`)
  - source formatted OpenTime vs output TradingDateTime checks.
- Quantity/Price parity:
  - aggregate parity by `ReportDate`, `OpenORClose`, `RegChange`
  - row-level mismatch checks where practical.
- Instrument/dictionary/exclusion checks:
  - SCD, full-description, special-char conversion, dictionary currency/type coverage
  - `AssetClass` coverage
  - ETORO report-scoped exclusion behavior checks (`table_name = '[MIFID2_ETORO_Report]'`).
- History/seed checks:
  - source/output date-window coverage summaries
  - placeholder-gated SQL Server baseline reconciliation template.

## Step 13B3 remaining gates

- Step 13B2 ETORO projection activation for requested run windows.
- Step 8 compatibility source activation and contract acceptance.
- OpenTime parity acceptance (`CDE_Execution_timestamp -> OpenTime`).
- OpenPrice parity acceptance; `Reg_DWH_StaticPosition` fallback remains conditional unless proven.
- Exact ETORO `InstrumentClassification` mapping port or approved hard-gate closure.
- Instrument metadata and dictionary dependency readiness for requested report dates.
- ASIC2 seed/history coverage for requested reconciliation windows.
- Optional baseline gate:
  - SQL Server ETORO normalized baseline source required for cross-system anti-join checks.
