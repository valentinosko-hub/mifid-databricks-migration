# Step 12B1-12B3 - MIFID2 Report Output Analysis

This document captures Step 12B1 scaffolding, Step 12B2 intermediate position/trade population templates, and Step 12B3 final branch projection templates for the three report targets below.

## Scope (Step 12 module targets)

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`

## Out of scope (Step 12B1-12B3)

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`
- Full position/trade population CTE implementation
- Final report branch projections
- File delivery / upload / response handling / production deployment

## SQL Server authorities for this module

- Stored procedure authority:
  - `reference/mifid_databricks_migration_context/01_sql_server_stored_procedures/core_mifid/SP_MIFID_Report.sql`
- DDL authorities:
  - `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_Report.sql`
  - `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_ME_Report.sql`
  - `reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_Removed_OP_Partials.sql`

## Target object names

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`

## Output schema contracts

### 1) MIFID2_Report contract

- Databricks target: `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- Contract source: `MIFID2_Report.sql`
- Column contract: full 100-column projection from SQL Server DDL (mapped to Databricks types) is captured explicitly in:
  - `databricks/sql/08_outputs/03_mifid2_report_scaffolding.sql`
  - `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql`
- `UpdateDate` is nullable and must remain nullable; no invented default is allowed.

### 2) MIFID2_ME_Report contract

- Databricks target: `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- Contract source: `MIFID2_ME_Report.sql`
- Column contract: same shape as `MIFID2_Report` DDL contract in practice for this migration scope and represented explicitly in the Step 12B1 scaffolding/validation SQL.
- `UpdateDate` is nullable and must remain nullable; no invented default is allowed.

### 3) MIFID2_Removed_OP_Partials contract

- Databricks target: `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`
- Contract source: `MIFID2_Removed_OP_Partials.sql`
- Contract columns and decimal precision/scale are represented explicitly in Step 12B1 SQL scaffolding/validation.
- Critical parity rule: all inserts must use explicit target column lists (no implicit ordinal insert).

## Primary keys / uniqueness intent

- `MIFID2_Report` uniqueness intent (SQL Server unique key equivalent for validation):
  - `ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`
- `MIFID2_ME_Report` analogous uniqueness checks:
  - `ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`
- `MIFID2_Removed_OP_Partials` business-key checks (validation intent for Step 12B1 foundation):
  - `ReportDate`, `CID`, `PositionID`, `OriginalPositionID`, `OpenORClose`
  - Additional open/close lifecycle checks to be finalized in Step 12B2/B3.

## Report branches identified in SP_MIFID_Report

- EU / CySEC
- UK / FCA
- FCA-flow-in-EU
- Seychelles
- ME

## Important SQL Server behavior to preserve

- Report-date scoped delete/insert behavior for report targets.
- Batched delete loops (`DELETE TOP (4000)`) by report date before inserts.
- Same-day open+close synthetic open-row handling in partial-close flows.
- Partial close removal logic with side-table persistence in `MIFID2_Removed_OP_Partials`.
- Removed partials staging behavior appears in both regular and RegChange flows.
- RegChange logic based on migration intervals (`ValidFrom`, `ValidTo`, rank, prev/current regulation).
- Mirror/copy handling (`MirrorID`, `CopyFund`, `FundType` driven fields).
- Split logic for position amount adjustments.
- GBX price conversion/division by 100 behavior.
- `UpdateDate` is nullable for `MIFID2_Report` and `MIFID2_ME_Report`; no invented default.
- `MIFID2_Removed_OP_Partials` must use explicit insert column lists.

## Required upstream dependencies and statuses

| dependency group | dependency object | status for Step 12B1 | notes |
| --- | --- | --- | --- |
| Customer outputs | `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer` | implemented/gated | Step 10 activation gates still tracked. |
| Customer outputs | `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer` | implemented/gated | Step 11 activation gates still tracked. |
| Step 9 staging | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position` | implemented/gated | Source contract must be cleared before report activation. |
| Step 9 staging | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position` | implemented/gated | Reg-change interval parity still gated. |
| Step 9 staging | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog` | implemented/gated | Needed for open/close lifecycle and partial handling. |
| Step 9 staging | `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror` | implemented/gated | Needed for mirror/copy logic. |
| Reg-change/movement | `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` | implemented/gated | Step 6 parity evidence still required for full activation. |
| Reg-change/movement | `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions` | implemented/gated | Movement-stage gate remains unresolved. |
| Reg-change/movement | `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata` | expected source/access pending | Mapping known; usage confirmation remains pending for this module. |
| Instrument metadata | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata` | expected source/access pending | Also blocks special-char conversion dependency. |
| Instrument metadata | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument` | expected source/access pending | Required-column profiling pending. |
| Instrument metadata | `main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext` | expected source/access pending | Shape confirmation vs gold/FIRDS outputs pending. |
| Instrument metadata | `main.regtech.gold_regtech_reg_instruments_scd` | implemented/gated | Certified source; coverage validation required. |
| Instrument metadata | `main.regtech.gold_regtech_reg_instruments_full_description` | implemented/gated | Certified source; coverage validation required. |
| Instrument special-char | `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion` | implemented/gated | Depends on `Reg_Ext_Trade_InstrumentMetaData` profiling. |
| Currency/dictionary/split | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency` | expected source/access pending | Required-column/access profiling pending. |
| Currency/dictionary/split | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype` | expected source/access pending | Required-column/access profiling pending. |
| Currency/dictionary/split | `main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio` | expected source/access pending | Split-ratio source/filter parity still gated. |
| Exclusions/static refs | `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments` | implemented/gated | Validation foundation includes exclusion checks. |
| Exclusions/static refs | `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids` | implemented/gated | Validation foundation includes exclusion checks. |
| Exclusions/static refs | `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids` | implemented/gated | Used in related customer/regchange lineage; report-level use validated in later steps. |
| Exclusions/static refs | `{{isin_for_instrumentid_341_source}}` | expected source/access pending | Required-column profiling pending; source adapter must provide normalized logical columns (`InstrumentID`, `OverrideISIN`, optional effective/report date). |
| Exclusions/static refs | `MIFID2_Instruments_To_Exclude` mapped equivalent | unresolved | Mapping/availability must be confirmed before activation. |
| Futures metadata | `main.trading.bronze_etoro_trade_futuresmetadata` | expected source/access pending | Treat as expected mapping, not unknown; required columns pending profiling (`InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`). |
| Out of scope outputs | ETORO/Hedge/NPD_TRAX report outputs | out of scope | Explicitly excluded from Step 12B1. |

## Gates that remain unresolved after Step 12B1

- Price/split source gates from Step 5B1.
- Non-price `Pre_Regulation_Ext` gates from Step 5B2.
- Movement/reg-change gates from Step 6.
- Step 9 position and reg-change position staging gates.
- `InstrumentMetaData_SpecialChar_Conversion` dependency on profiled `Reg_Ext_Trade_InstrumentMetaData`.
- Futures metadata required-column profiling gate.
- Excluded instruments/position IDs / `MIFID2_Instruments_To_Exclude` mapping-parity gate.
- Source profiling/access pending gates for dictionary/instrument/migration dependencies.
- Removed partials explicit-column parity enforcement gate.
- `MIFID2_Report` / `MIFID2_ME_Report` `UpdateDate` nullable no-default caution gate.

## Step 12B1 implementation artifacts

- SQL scaffolding:
  - `databricks/sql/08_outputs/03_mifid2_report_scaffolding.sql`
- Validation foundation:
  - `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql`

Step 12B1 stops here by design. Step 12B2, Step 12B3, and Step 12B4 remain TODO-scaffolded only.

## Step 12B2 scope and boundary

Step 12B2 authors gated templates for intermediate population only:

- Main position population from `MIFID2_ext_Position` + `MIFID2_Customer`.
- Reg-change position population from `MIFID2_ext_RegChange_Position` + `MIFID2_RegChange_Customer`.
- Position change-log latest-row logic.
- Mirror/copy-fund enrichment.
- Same-day open+close synthetic open-row handling.
- Partial-close replacement logic and removed-partial candidate logic.
- Split-adjusted quantity logic for `IsCompletedOpenPositions = 1`.
- RegChange intermediate logic (`0/1/2`) up to unified trade pool.
- Price/currency intermediate logic used before final branch inserts (including GBX divide-by-100).
- Instrument intermediate logic used before final branch inserts.
- Customer EU/UK report-eligibility flag preparation from pre-branch intermediate population.
- SQL Server 10-second migration/open exception parity:
  - keep NULL-as-not-true behavior for missing movement rows in the 10-second condition.

Step 12B2 stop point:

- Unified intermediate trade pool (`#tradesFinal` equivalent), plus pre-branch customer EU/UK flags.

Step 12B2 explicit exclusions:

- Final report branch inserts (EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, ME).
- Final inserts into:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- Finalization insert into `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`.

## Step 12B2 SQL artifacts

- Intermediate population template:
  - `databricks/sql/08_outputs/04_mifid2_report_position_population.sql`
- Intermediate validation template:
  - `databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql`

Both are intentionally gated/commented and non-executable for final outputs in this step.

## Step 12B2 CTE/materialization strategy

Primary strategy:

- Use local CTE templates to mirror SQL Server temp-table flow, preserving business logic sequence while avoiding active writes.

Optional materialized checkpoints (still gated/commented):

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates`

Checkpoint safety rule:

- Do not materialize optional checkpoints with dummy one-column schemas.
- Add checkpoint DDL only after full schemas are derived from final Step 12B2 CTE outputs.

Naming rule:

- Any persistent intermediate in this module must be in `main.regtech_ops_stg` and start with `bi_output_regtechops_`.

## Step 12B2 logic deferred to Step 12B3

Deferred to final projection step:

- EU/CySEC final report insert branch.
- UK/FCA final report insert branch.
- FCA-flow-in-EU final report insert branch.
- Seychelles final report insert branch.
- ME final report insert branch.
- Any final-write orchestration into `MIFID2_Report` / `MIFID2_ME_Report`.
- Final-write orchestration into `MIFID2_Removed_OP_Partials`.

FuturesMetaData boundary:

- `FuturesMetaData` is referenced in final branch projection paths, not in pre-branch unified trade-pool population.
- Therefore, FuturesMetaData remains a Step 12B3 activation gate, not a Step 12B2 implementation dependency.

## Step 12B2 carried-forward gates

Step 12B2 remains gated on:

- Step 5B1/5B2 price and split dependencies.
- Step 6 migration/movement parity dependencies.
- Step 9 position/regchange/changelog/mirror staging dependencies.
- Step 10/11 customer output readiness.
- `InstrumentMetaData_SpecialChar_Conversion` profiling/coverage dependency.
- `Dictionary.Ext_TradeFund` Databricks mapping dependency.
- `MIFID2_Instruments_To_Exclude` mapping parity dependency.
- `Reg_Ext_DictionaryCurrency` profiling/availability dependency for pre-branch instrument metadata enrichment.
- Explicit-column insert rule for removed partials finalization.

## Step 12B2 validation coverage

Step 12B2 validation templates cover:

- Source row counts.
- Intermediate row counts.
- Main vs reg-change counts.
- Open/close and same-day open+close counts.
- Partial-close and removed-partial candidate counts.
- RegChange distribution checks (`0/1/2`) and migration exception evidence placeholders.
- Split-adjustment and GBX checks.
- Instrument coverage checks.
- Duplicate business-key checks.
- Required null checks.
- Source-to-intermediate reconciliation checks.

Validation gating note:

- Checkpoint-dependent validation blocks are optional and must not run until optional checkpoint tables are materialized.
- Split/GBX parity cannot be treated as proven until audit fields are materialized:
  - `AmountRatioSplit`
  - `IsSplitAdjusted`
  - `IsGBX`
  - `InitForexRateBeforeGBX`
  - `InitForexRateAfterGBX`
  - `EndForexRateBeforeGBX`
  - `EndForexRateAfterGBX`

Removed-partials scope rule:

- Explicit-column candidate insert must be activated only as part of the full Step 12B2 CTE stack where `removed_partial_candidates` is defined.
- Standalone removed-partials candidate insert statements are not valid.

Step 12B3 boundary in validation:

- FuturesMetaData validations are deferred to Step 12B3 because they apply to final branch projection logic.

## Step 12B3 scope and boundary

Step 12B3 starts from the Step 12B2 unified trade pool (`#tradesFinal` equivalent) and does not re-author Step 12B2 pre-branch population logic.

Scope in Step 12B3:

- Final branch projections into:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- Removed partials finalization into:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`

Out of scope in Step 12B3:

- `MIFID2_ETORO_Report`, `MIFID2_Hedge_Report`, `MIFID2_NPD_TRAX`
- file delivery/export/upload/response/deployment logic

## Step 12B3 SQL artifacts

- Branch projection templates:
  - `databricks/sql/08_outputs/05_mifid2_report_branch_projections.sql`
- Branch-projection validation templates:
  - `databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql`

Both artifacts are intentionally gated/commented and remain non-executable until upstream dependencies are cleared.

## Step 12B3 branch projection summary

### MIFID2_Report branches

- EU / CySEC:
  - `RegulationReportID = 1`
  - source regulation filter from `OrigRegulationID = 1`
  - transaction reference strips `UK`
  - `BackReportingIndicator = 0`
- UK / FCA:
  - `RegulationReportID = 2`
  - source regulation filter from `OrigRegulationID = 2`
  - transaction reference strips `UK`
  - UK-specific CID exclusion is applied
  - `BackReportingIndicator = 0`
- FCA-flow-in-EU:
  - `RegulationReportID = 1`
  - source regulation filter from `OrigRegulationID = 2`
  - requires both `IsMifidByFCA = 1` and `IsMifid = 1`
  - transaction reference keeps `PositionIDOut` (retains UK marker)
  - `BackReportingIndicator = 0`
- Seychelles:
  - `RegulationReportID = 1`
  - source regulation filter from `OrigRegulationID = 9`
  - transaction reference suffix: `SC + yyyymmdd`
  - `BackReportingIndicator = 0`

### MIFID2_ME_Report branch

- ME:
  - target table is `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - `RegulationReportID = 1`
  - source regulation filter from `OrigRegulationID = 11`
  - transaction reference suffix: `ME + yyyymmdd`
  - `BackReportingIndicator = 0`

## Step 12B3 source-to-target mapping summary

Core mapping behavior preserved in templates:

- `DateID = yyyyMMdd(report_date)`, `ReportDate = report_date`.
- `RegulationID` output is taken from `OrigRegulationID` (trade-occurrence regulation).
- `RegChange` is propagated from Step 12B2 trades-final source.
- Trading timestamp uses open/close event (`OpenORClose`) with second-level adjustment parity pattern.
- Quantity/price mapping remains open-close dependent:
  - quantity from `AmountInUnitsDecimal`
  - price from `InitForexRate` (open) / `EndForexRate` (close)
  - `PriceType` from instrument-type/currency-type behavior.
- `UpdateDate` is explicitly kept nullable and unpopulated in projections.

## Step 12B3 instrument/FIRDS and FuturesMetaData behavior

- Step 12B3 templates consume Step 12B2-prepared metadata path and keep final instrument projection behavior branch-aware (ISIN/full-name/CFI/asset class).
- `InstrumentClassification`/CFI output in branch templates is now hard-gated (`NULL`) until exact SQL Server branch-specific mappings are ported:
  - HARD GATE covers EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, and ME variants.
  - simplified fallback mapping is intentionally removed to avoid accidental non-parity activation.
- `main.trading.bronze_etoro_trade_futuresmetadata` is treated as Step 12B3-only dependency.
- Futures required-column gate remains explicit:
  - `InstrumentID`
  - `CFICode`
  - `ExpirationDateTime`
  - `Multiplier`
- Futures branch activation remains gated until required-column profiling is approved.

## Step 12B3 exclusions and removed partials finalization

- Exclusion logic in branch templates includes:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
  - UK branch: `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
  - UK branch support for `{{isin_for_instrumentid_341_source}}` (gated required-column contract: `InstrumentID`, `OverrideISIN`, optional effective/report date)
- `MIFID2_Instruments_To_Exclude` remains mapped-source gated and is retained as a dependency gate in templates.

Removed partials finalization behavior:

- Uses scoped/materialized Step 12B2 candidates input (`{{removed_partial_candidates_source}}`).
- Uses explicit target column list only.
- No out-of-scope CTE reference is allowed.

## Step 12B3 final output gates and activation constraints

- All final delete/insert statements remain commented.
- Branch templates are non-activating while Step 5/6/9/10/11 gates are unresolved.
- `InstrumentMetaData_SpecialChar_Conversion` and futures profiling gates are carried forward.
- `UpdateDate` no-default rule is preserved explicitly.

## Step 12B3 validation coverage

`05_mifid2_report_branch_projection_validation.sql` adds templates for:

- schema presence/width checks (with detailed contract checks still anchored in `03_mifid2_report_validation_foundation.sql`)
- row counts by report date, regulation report id, regulation id, regchange, branch
- duplicate checks for report/ME uniqueness intent and removed-partials business key
- required-null checks for report/ME required fields and `BackReportingIndicator`
- branch behavior checks for EU/UK/FCA-flow/Seychelles/ME transaction-reference patterns
- instrument coverage checks for category-specific ISIN/CFI rules plus SCD/full-description/special-char coverage:
  - real stock/ETF rows require ISIN and should not be flagged for expected blank CFI.
  - futures coverage must be identified from pre-output `IsFuture` metadata (`{{report_metadata_source}}` / `{{trades_final_source}}` enrichment), not from output-populated futures fields.
  - non-real, non-future CFD CFI checks remain hard-gated until exact branch-specific CFI mapping is ported.
- exclusion checks (instruments/positions and optional mapped `MIFID2_Instruments_To_Exclude`)
- removed-partials candidate-to-output reconciliation templates
- aggregate checks (quantity/price/economic fields by branch)
