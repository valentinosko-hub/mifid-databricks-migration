# Reconciliation Plan (Phase 1)

This plan defines reconciliation scope and execution order for migration validation in `main.regtech_ops_stg`. It is documentation-only in this step.

Latest source profiling integration:
- Profiling summary: `docs/source_profiling_results.md`
- Access blockers and DE actions: `docs/access_blockers.md`
- Profiling input: `MiFID_Source_Profiling (1).csv`

## Current focus

- Step 12B4 final validation/reconciliation package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`
- Step 13 ETORO staged package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
  - Step 13B1: scaffold/output contract
  - Step 13B2: gated projection template
  - Step 13B3: read-only validation/reconciliation package
- Step 14 Hedge staged package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`
  - Step 14B1: scaffold/output contract/dependency gates
  - Step 14B2: source-preparation templates + SELECT-only source-preparation validation
- Step 15 NPD TRAX staged package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`
  - Step 15B1: scaffold/output contract/dependency gates
  - Step 15B2: gated table-generation template (authored)
  - Step 15B3: read-only validation/reconciliation package (authored)

## Out of scope for this step

- Active/ungated Step 13B2 ETORO projection execution
- Active/ungated Step 14B2 source CTE execution
- Active/ungated Step 14B3 hedge branch projection/load execution
- Active/ungated Step 15B2 NPD table-generation execution
- TRAX response import/status updates (`SP_MIFID2_NPD_TRAX_Response_Update`)
- File delivery (`CSV`, `7z`, `SFTP`, TRAX/Cappitech upload/response handling)
- Production deployment

## Source profiling gate status

### Gates improved by latest profiling

- Static reference availability for internal accounts, special-char dictionary, and EDNF mapping tables with explicit external LOCATION.
- Source visibility for position, mirror, changelog, hedge execution, liquidity provider, instrument dictionary, futures metadata, migration gold, split-ratio, price-candle, EDNF/IB, and SharePoint exclusion sources.
- Mapping confidence for `Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Dictionary.Currency`, `Dictionary.CurrencyType`, and `FuturesMetaData`.

### Gates that remain open

- `Reg_CurrencyPrice_Ext` primary source selected (`main.dealing.bronze_pricelog_history_currencyprice`); `main.trading.bronze_etoro_trade_currencyprice` is readable but not preferred. Execution remains gated by required-column certification, date-window validation, and SQL Server baseline comparison (MAG-14 / D-05).
- Step 7 hedge-server mapping source (`main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`) is readable with required columns present; execution remains gated by duplicate/key/coverage validation and liquidity SCD seed implementation (D-09 / MAG-11).
- `Reg_Ext_CurrencyPriceMaxDateWithSplit` primary source selected (`main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`); `dwh_daily_process` split-price objects are fallback/reference only (not an active access blocker for primary-path activation).
- Customer and NPD_TRAX customer-dependent paths blocked by no schema access on `main.pii_data` customer tables (masked tables are dev/structural fallback only).
- Historical seed strategy direction is approved; seed implementation and extract ownership remain pending for parity/retry/SCD/baseline windows (`docs/history_seed_requirements.md`).
- Required-column certification still pending for many confirmed-accessible sources before module activation.

## Gate prerequisites before Step 12 activation

- Close Step 5B1 price/split source gates using selected primary sources (`main.dealing.bronze_pricelog_history_currencyprice`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`) plus required-column certification and SQL Server baseline/date-window validation.
- Resolve Step 5B2 non-price required-column certification for accessible sources (`GetInstrument`, `InstrumentMetaData`, dictionary currency/type).
- Complete Step 7 hedge-server duplicate/key/coverage validation and implement approved liquidity SCD seed/cutover (D-09 / MAG-11) before hedge SCD and Step 14 hedge activation reconciliation.
- Grant PII schema access or approve a formal regulatory exception before customer-module reconciliation (masked tables do not close this gate).
- Use `dwh_daily_process` / `main.dwh` split-price candidates only as fallback/reference if primary-source validation requires comparison evidence.
- Step 6 movement/reg-change parity gates resolved.
- Step 9 position/reg-change-position staging gates resolved.
- `InstrumentMetaData_SpecialChar_Conversion` dependency cleared.
- Futures metadata columns profiled in `main.trading.bronze_etoro_trade_futuresmetadata` before Step 12B3 (not required to author Step 12B2 templates).
- Exclusion source mappings confirmed, including `MIFID2_Instruments_To_Exclude` equivalent.
- `UpdateDate` no-default rule approved for `MIFID2_Report` and `MIFID2_ME_Report`.
- Removed partials explicit-column insert parity rule enforced.

## Step 12B2 reconciliation coverage

1. Schema parity:
   - Intermediate checkpoint schema checks (if materialized) for trade population, customer flags, removed-partials candidates.
2. Row counts:
   - Source row counts and intermediate row counts by report date.
3. Duplicate checks:
   - Intermediate trade business keys (`CID`, `PositionID`, `OpenORClose`, `RegChange`).
   - Removed partial candidate business keys (`ReportDate`, `CID`, `PositionID`, `OriginalPositionID`, `OpenORClose`).
4. Required null checks:
   - Mandatory intermediate identifiers, datetime fields, quantity and rate fields.
5. Exclusion checks:
   - Excluded-instrument mapping parity in pre-branch population.
6. Instrument coverage:
   - `Reg_Instruments_SCD`, `Reg_Instruments_Full_Description`,
   - `InstrumentMetaData_SpecialChar_Conversion`.
   - Futures metadata checks are deferred to Step 12B3.
7. Movement/RegChange checks:
   - Counts by `RegChange`,
   - movement-stage coverage and migration interval coverage,
   - `IsOpenedAfterLastMigration` distribution and 10-second exception evidence,
   - SQL Server parity for 10-second exception null behavior (missing movement rows must not satisfy the `> 10` predicate).
8. Removed partial checks:
   - Removed partial candidate counts,
   - Source-to-candidate reconciliation placeholders,
   - Same-day open/close checks.
9. Aggregates:
   - Quantity and rate aggregates by open/close and reg-change classes.
   - Split/GBX parity proofs only after audit fields are materialized (`AmountRatioSplit`, `IsSplitAdjusted`, `IsGBX`, before/after GBX rates).
10. Source-to-output checks:
   - Customers to intermediate,
   - positions/reg-change positions to intermediate,
   - movement source to intermediate.

## Execution order once gates pass

1. Run source visibility/required-column checks for Step 12B2 dependencies.
2. Run dependency visibility/coverage checks.
3. Materialize optional checkpoints only if full derived schemas are defined (no dummy schema checkpoints).
4. Run source/intermediate row-count and duplicate checks.
5. Run required-null, open/close, and same-day checks.
6. Run partial/split/GBX and reg-change checks.
7. Run instrument coverage and source-to-intermediate reconciliation checks.
8. Classify deltas and carry unresolved issues into Step 12B3 gates.
9. Record outcomes in `docs/known_differences.md` and unresolved follow-ups in `docs/unresolved_dependencies.md`.

## Planned evidence output

- SQL result sets from:
  - `databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql`
- Updated gate decisions and known-difference notes:
  - `docs/unresolved_dependencies.md`
  - `docs/known_differences.md`
  - `docs/history_seed_requirements.md`

## Stop condition for Step 12B2

- Step 12B2 ends when intermediate pre-branch templates and validation templates are authored, gated, and documented.
- Final branch/business logic migration starts in Step 12B3 only.

## Step 12B3 reconciliation coverage

1. Schema parity:
   - `MIFID2_Report`, `MIFID2_ME_Report`, `MIFID2_Removed_OP_Partials` contracts.
2. Row counts:
   - by `ReportDate`, `RegulationReportID`, `RegulationID`, `RegChange`, and branch classification.
3. Duplicate checks:
   - report/ME uniqueness intent (`ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`).
   - removed-partials lifecycle business keys.
4. Required null checks:
   - report/ME required keys and economic timestamp/quantity/price fields.
   - `BackReportingIndicator` population checks.
5. Branch behavior checks:
   - EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, ME counts and transaction-reference suffix behavior.
6. Instrument/futures coverage checks:
   - category-specific ISIN/CFI population checks:
     - real stock/ETF rows require ISIN.
     - expected blank CFI for real stock/ETF rows is not treated as failure.
     - non-real, non-future CFD CFI checks remain gated until exact branch mapping is ported.
   - SCD/full-description/special-char conversion coverage.
   - FuturesMetaData coverage for futures candidates identified from pre-output metadata (`IsFuture = 1`), not output-populated fields.
7. Exclusion checks:
   - excluded instruments absent.
   - excluded positions absent.
   - UK excluded CID behavior.
   - optional `MIFID2_Instruments_To_Exclude` parity check once mapping is confirmed.
8. Removed partial finalization checks:
   - candidate vs final row counts.
   - candidate-to-output key reconciliation.
   - explicit-column insert checklist.
9. Aggregates:
   - branch-level quantity/price/economic field aggregates.

## Step 12B3 execution order once gates pass

1. Re-run Step 12B2 boundary validation and confirm trades-final source contract.
2. Validate Step 12B3 source gates (metadata, exclusions, futures columns, removed-partials candidates).
   - includes hard gate on exact branch-specific `InstrumentClassification` mapping and required-column contract for `{{isin_for_instrumentid_341_source}}`.
3. Execute final branch inserts for report and ME tables (report-date scoped).
4. Execute removed partials finalization insert with explicit target columns.
5. Run Step 12B3 validation SQL:
   - `databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql`
6. Run baseline schema contract checks:
   - `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql`
7. Record deltas and update:
   - `docs/known_differences.md`
   - `docs/unresolved_dependencies.md`

## Stop condition for Step 12B3

- Step 12B3 ends when final branch templates, removed-partials finalization templates, and Step 12B3 validation SQL are authored and documented as gated artifacts.
- Activation remains blocked until upstream dependency gates are resolved and validation evidence is accepted.

## Step 12B4 reconciliation package

Step 12B4 introduces read-only final validation/reconciliation packaging only:

- `databricks/sql/08_outputs/06_mifid2_report_final_reconciliation.sql`

Step 12B4 consolidates checks across Step 12B1/B2/B3 validation artifacts and does not implement any new report business logic.

## Step 12B4 execution order

1. Run schema checks.
2. Run final output row counts.
3. Run branch counts.
4. Run duplicate/null checks.
5. Run source-to-output reconciliation.
6. Run removed partial reconciliation.
7. Run instrument/futures/exclusion checks.
8. Run aggregate checks.
9. Review gated checks that could not run due to missing materialized sources.

## Step 12B4 gated checks

Keep these sections optional/gated in B4 until dependencies are available:

- `{{trades_final_source}}` source-to-output reconciliation
- `{{report_metadata_source}}` IsFuture-driven futures coverage
- `{{removed_partial_candidates_source}}` candidate-to-output removed-partials reconciliation
- `{{mifid2_instruments_to_exclude_source}}` mapped exclusion parity check
- `{{isin_for_instrumentid_341_source}}` override-source profile checks
- split/GBX audit-field checks (`AmountRatioSplit`, `IsSplitAdjusted`, `IsGBX`, before/after GBX rates)

## Planned evidence output for Step 12B4

- SQL result sets from:
  - `databricks/sql/08_outputs/06_mifid2_report_final_reconciliation.sql`
- Carry-forward schema/parity references:
  - `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql`
  - `databricks/sql/08_outputs/04_mifid2_report_position_population_validation.sql`
  - `databricks/sql/08_outputs/05_mifid2_report_branch_projection_validation.sql`
- Updated gate/delta documentation:
  - `docs/known_differences.md`
  - `docs/unresolved_dependencies.md`

## Step 13 planned split and reconciliation boundary

Step 13 implementation is split as:

- Step 13B1:
  - ETORO documentation + scaffold + output contract + dependency gates only.
  - No active ETORO projection SQL.
  - No ETORO validation package SQL.
- Step 13B2:
  - ETORO projection implementation from ASIC2-compatible source and ETORO metadata/enrichment joins.
- Step 13B3:
  - ETORO read-only validation/reconciliation package:
    - `databricks/sql/08_outputs/07_mifid2_etoro_report_validation.sql`

## Step 13B3 reconciliation coverage

1. Schema parity:
   - ETORO table presence/width and required-column contract checks (name/order/type/nullability where available).
2. Row counts:
   - by `ReportDate`, `RegulationReportID`, `RegulationID`, `OpenORClose`, `RegChange`.
3. Duplicate checks:
   - uniqueness intent (`ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`, `BackReportingIndicator`).
   - optional `PositionID`/`OpenORClose` duplicate lens.
4. Required-null checks:
   - ETORO required fields (`RegulationReportID`, `DateID`, `ReportDate`, `CID`, `RegulationID`, `PositionID`, `InstrumentID`, `OpenORClose`, `BuyORSell`, `TransactionReferenceNumber`, `TradingDateTime`, `Quantity`, `Price`, `PriceCurrency`, `RegChange`).
5. Source-to-output reconciliation:
   - source/output count checks from `bi_output_regtechops_vw_mifid2_asic_transactions`.
   - anti-joins on `DateID`, `ReportDate`, `PositionID`, `OpenORClose`.
   - `RegChange` count comparison.
6. OpenTime/TradingDateTime checks:
   - source OpenTime parseability.
   - output `TradingDateTime` format (`yyyy-MM-ddTHH:mm:ssZ`).
   - source-to-output formatted timestamp checks.
7. Quantity/Price parity:
   - aggregate and row-level checks (`Volume` vs `Quantity`, `OpenPrice` vs `Price`).
   - conditional StaticPosition fallback impact remains gated.
8. Instrument/dictionary/exclusion checks:
   - SCD/full-description/special-char/dictionary coverage.
   - `AssetClass` coverage and `InstrumentClassification` hard-gate posture.
   - report-scoped exclusion checks for `table_name = '[MIFID2_ETORO_Report]'`.
9. History/seed checks:
   - source/output date-window coverage.
   - optional SQL Server baseline reconciliation placeholders.

## Step 13B3 execution order once gates pass

1. Confirm Step 13B2 projection activation and Step 8 compatibility-source readiness for `{{report_date}}`.
2. Run schema parity and required-column checks.
3. Run ETORO row-count, duplicate, and required-null checks.
4. Run source-to-output reconciliation and RegChange distribution checks.
5. Run OpenTime/TradingDateTime parity checks.
6. Run Quantity/Price aggregate and row-level parity checks.
7. Run instrument/dictionary coverage and exclusion-scope checks.
8. Run history/seed window checks and optional SQL Server baseline comparisons if baseline source is available.
9. Record deltas and gate outcomes in:
   - `docs/known_differences.md`
   - `docs/unresolved_dependencies.md`
   - `docs/history_seed_requirements.md`

## Planned evidence output for Step 13B3

- SQL result sets from:
  - `databricks/sql/08_outputs/07_mifid2_etoro_report_validation.sql`
- Supporting ETORO projection/source references:
  - `databricks/sql/08_outputs/07_mifid2_etoro_report.sql`
  - `databricks/sql/06_asic2_subset/05_mifid_asic_compatibility_view.sql`
- Updated gate/delta documentation:
  - `docs/mifid2_etoro_report_output_analysis.md`
  - `docs/known_differences.md`
  - `docs/unresolved_dependencies.md`
  - `docs/history_seed_requirements.md`

## Step 13 gate prerequisites before ETORO activation

- Step 8 compatibility activation for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- Accepted field-level parity for ETORO-consumed compatibility fields:
  - `CDE_Execution_timestamp -> OpenTime`
  - `Quantity -> Volume`
  - `OpenPrice`
- `InstrumentMetaData_SpecialChar_Conversion` readiness for ETORO report-date windows.
- `Reg_Ext_DictionaryCurrency` and `Reg_Ext_DictionaryCurrencyType` contract readiness.
- `Reg_Instruments_SCD` / `Reg_Instruments_Full_Description` coverage for ETORO windows.
- Exclusion source freshness/contract parity for ETORO table scope.
- Exact `InstrumentClassification` mapping parity from `SP_MIFID2_ETORO_Report`.
- ASIC2 history seed coverage for requested ETORO reconciliation windows.

## Step 13 stop conditions

- Step 13B1 ends when ETORO scaffold and dependency gates are authored and documented.
- Activation/execution of ETORO projection begins in Step 13B2 only.
- Step 13B3 ends when the ETORO read-only validation/reconciliation package is authored and documented.
- Runtime execution evidence remains gated until Step 13B2 activation and Step 8 compatibility-source gates pass.

## Step 14 planned split and reconciliation boundary

Step 14 implementation is split as:

- Step 14B1:
  - hedge documentation + scaffold + output contract + dependency gates only.
  - no active hedge branch projection/load execution.
- Step 14B2:
  - source preparation and branch source CTE authoring (EU, EU-UK, UK candidate sets), still dependency-gated.
- Step 14B3:
  - final hedge projection/load templates for EU/EU-UK/UK branches (still gated until dependencies pass).
  - output validation execution is deferred to Step 14B4 (no Step 14B3 runtime validation package).
- Step 14B4:
  - hedge read-only validation/reconciliation package.

Hedge report validation is intentionally deferred to Step 14B4.

## Step 14B2 source-preparation validation evidence requirements

Step 14B2 evidence is read-only and limited to source-preparation scope:

1. Source row counts:
   - EU source rows, EU-UK source rows, UK source rows.
2. Source date-window checks:
   - `ExecutionTime >= report_date` and `< report_date + 1 day` for EU/UK source families.
3. Source filter checks:
   - `Units > 0`, `Success = 1`,
   - UK `EMSOrderID IS NULL`,
   - EU/EU-UK execution-flow conditions,
   - UK entity and FCA MiFID eligibility path.
4. Required-column/source-contract checks:
   - hedge execution, liquidity account/SCD, HBC order, EDNF/IB, instrument/dictionary dependencies.
5. Coverage checks:
   - liquidity account and LEI coverage,
   - SCD validity-window coverage at `ExecutionTime`,
   - EDNF/IB mapping and join coverage,
   - instrument/dictionary/special-char coverage.
6. Exclusion-source scope checks:
   - instrument and position/transaction-reference exclusion sources with `table_name = '[MIFID2_Hedge_Report]'`,
   - explicit evidence that scope is row-level report filtering, not full-table suppression.
7. Source-to-branch-preparation checks:
   - expected branch source rows versus prepared EU / EU-UK / UK counts.
8. Optional checkpoint checks (gated):
   - run only if optional checkpoint objects are explicitly materialized with full schemas.

## Step 14B2 planned evidence output

- SQL result sets from:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation_validation.sql`
- Supporting source-preparation artifact:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation.sql`
- Updated gate/delta documentation:
  - `docs/mifid2_hedge_report_output_analysis.md`
  - `docs/unresolved_dependencies.md`
  - `docs/known_differences.md`
  - `docs/history_seed_requirements.md`

## Step 14B3 projection-template evidence requirements

Step 14B3 evidence is template-level and gating-focused:

1. Branch projection templates:
   - EU direct branch template (`ExecutionFlow='EU'`, `RegulationReportID=1`, `rowSource='EU'`).
   - EU-UK branch template (`ExecutionFlow='UK' AND IsReal=1`, `RegulationReportID=1`, `rowSource='EU-UK'`).
   - UK branch template (`EMSOrderID IS NULL`, UK entity filter, FCA eligibility, `RegulationReportID=2`, `rowSource='UK'`).
2. Transaction reference template parity:
   - SQL Server-style expression pattern included and clearly documented as approval-gated before activation.
3. RecordID deterministic template:
   - deterministic ordering key is explicitly defined for `row_number()`-based strategy.
   - activation remains gate-controlled pending approval.
4. Exclusion template parity:
   - instrument and generated transaction-reference/position-key exclusions are scoped by `table_name = '[MIFID2_Hedge_Report]'`.
   - no full-table suppression behavior.
5. DML gating:
   - final report-date `DELETE` / `INSERT` remains commented/non-active.

## Step 14B3 planned evidence output

- SQL/template artifact:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report.sql`
- Supporting source-preparation artifacts:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation.sql`
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation_validation.sql`
- Updated gate/delta documentation:
  - `docs/mifid2_hedge_report_output_analysis.md`
  - `docs/unresolved_dependencies.md`
  - `docs/known_differences.md`
  - `docs/history_seed_requirements.md`

## Step 14B4 reconciliation coverage

1. Schema parity:
   - `MIFID2_Hedge_Report` column contract, type/nullability expectations, and RecordID handling acceptance.
2. Row counts:
   - by `ReportDate`, `RegulationReportID`, and `rowSource` (`EU`, `EU-UK`, `UK`).
3. Duplicate checks:
   - uniqueness intent (`ReportDate`, `RegulationReportID`, `TransactionReferenceNumber`).
4. Required-null checks:
   - hedge required identifiers and branch-critical fields (`TransactionReferenceNumber`, `RegulationReportID`, `rowSource`).
5. EU/UK branch evidence requirements:
   - EU branch evidence for `ExecutionFlow='EU'`.
   - EU-UK branch evidence for `ExecutionFlow='UK' AND IsReal=1` under `RegulationReportID=1`.
   - UK branch evidence for UK-specific source path and filters (`EMSOrderID IS NULL`, UK entity filter, FCA eligibility path).
6. Exclusion checks:
   - report-scoped exclusions for instruments and generated position/transaction reference keys with `table_name = '[MIFID2_Hedge_Report]'`.
7. Coverage checks:
   - liquidity-account/LEI coverage.
   - instrument/dictionary coverage.
   - EDNF/IB mapping and join coverage.
8. Aggregate checks:
   - quantity/price aggregates by branch and report date.
9. RecordID deterministic behavior checks:
   - evidence that approved strategy is stable across reruns for the same `ReportDate`.

## Step 14B4 validation execution order

1. Run Step 14 gate-summary block and confirm dependency status visibility.
2. Run schema/required-column parity checks for hedge output contract.
3. Run row-count and branch-count checks by `ReportDate`, `RegulationReportID`, and `rowSource`.
4. Run duplicate and required-null checks.
5. Run liquidity/LEI/SCD validity and coverage checks.
6. Run EDNF/IB and instrument/dictionary coverage checks.
7. Run exclusion-scope and exclusion-absence checks.
8. Run RecordID and TransactionReferenceNumber gate checks.
9. Run aggregate checks by branch/instrument/liquidity dimensions.
10. Run optional/gated source-to-output branch reconciliation only when branch-source placeholders are materialized.

## Step 14B4 SQL Server baseline comparison

- SQL Server baseline comparison remains optional and gated in Step 14B4.
- When a normalized SQL Server baseline source is provided, compare at minimum:
  - row counts by branch and report date,
  - duplicate-key behavior,
  - TransactionReferenceNumber parity,
  - aggregate quantity/price metrics.
- Do not invent a baseline source; keep baseline checks optional/gated until provided.

## Evidence output for Step 14B4

- SQL result sets from Step 14 hedge validation package:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_validation.sql`
- Supporting hedge source/projection artifacts:
  - `databricks/sql/08_outputs/08_mifid2_hedge_report_scaffolding.sql`
  - Step 14B2 hedge source-preparation artifacts:
    - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation.sql`
    - `databricks/sql/08_outputs/08_mifid2_hedge_report_source_preparation_validation.sql`
  - Step 14B3 hedge final projection/load artifact (gated template authored):
    - `databricks/sql/08_outputs/08_mifid2_hedge_report.sql`
- Updated gate/delta documentation:
  - `docs/mifid2_hedge_report_output_analysis.md`
  - `docs/known_differences.md`
  - `docs/unresolved_dependencies.md`
  - `docs/history_seed_requirements.md`
  - `docs/source_profiling_results.md`
  - `docs/access_blockers.md`

## Step 15 planned split and reconciliation boundary

- Step 15B1:
  - scaffold/output contract/dependency-gate authoring only for `bi_output_regtechops_mifid2_npd_trax`.
  - no active NPD DML execution.
- Step 15B2:
  - gated/commented table-generation template for `SP_MIFID2_NPD_TRAX` parity flow is authored in `databricks/sql/08_outputs/09_mifid2_npd_trax.sql`.
  - report-date DML remains commented/non-active until gates pass.
- Step 15B3:
  - read-only validation/reconciliation package for schema/count/duplicate/null/source-to-output/AcceptedTRAX/history checks.

## Step 15 gate prerequisites before activation

- Upstream output gates:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- PII source-access gates:
  - `main.pii_data.bronze_etoro_customer_customer` (no schema access)
  - `main.pii_data.bronze_etoro_history_customer` (no schema access)
- History/cutover gate:
  - approved `MIFID2_NPD_TRAX` / Failed TRAX historical seed implementation (D-06 / D-07 / MAG-07–09) for exact new-vs-existing/retry/REPL parity; extract ownership and load sequencing remain pending.
- Step 9 coupling gate:
  - `MIFID2_Failed_TRAX` latest-row behavior depends on `MIFID2_NPD_TRAX` history.
- Response boundary gate:
  - response import/update and `SP_MIFID2_NPD_TRAX_Response_Update` remain out of Step 15B1/B2 table-generation scope.

Step 15B2 CTE/template coverage (authored, non-active):

- `run_parameters`
- `prior_latest_ids` + latest-row history join
- `failed_retry_candidates`
- `reg_change_customers`
- `customer_all_candidates`
- `new_candidates`
- `existing_changed_candidates`
- `retry_candidates`/union
- `final_candidates` + sendable-row `RowNum`
- commented report-date `DELETE` + CTE-attached `INSERT`

## Step 15B3 reconciliation coverage (authored)

1. Schema parity:
   - contract parity to `dbo.MIFID2_NPD_TRAX.sql` including response-related columns present in DDL.
2. Row counts:
   - counts by `ReportDate`, `Entity`, `Action`, `AcceptedTRAX`.
3. Duplicate checks:
   - uniqueness intent on (`ReportDate`,`Entity`,`CID`).
4. Required null checks:
   - required identity/report columns and key TRAX fields.
5. Source-to-output checks:
   - new/existing/retry/failed/excluded-path contribution counts.
6. AcceptedTRAX checks:
   - sendable rows (`NULL`), invalid-name rows (`0`), retry posture for prior rejected/null rows.
7. History/seed checks:
   - prior latest-row availability by `(CID, RegulationID)` and coverage warnings for forward-only windows.
8. SQL Server baseline comparison:
   - optional/gated and only when normalized baseline source is provided.

## Step 15B3 validation execution order

1. Run Step 15 gate-summary block and confirm dependency status visibility.
2. Run schema parity checks (column presence/order/type/nullability/precision/scale).
3. Run duplicate and required-null checks.
4. Run row-count summaries by `ReportDate`, `Entity`, `RegulationID`, `Action`, and `AcceptedTRAX`.
5. Run AcceptedTRAX/invalid-name behavior checks.
6. Run RowNum checks (sendable-only assignment, non-sendable nullability, entity partition summaries).
7. Run history/seed checks (prior latest-row coverage and forward-only warnings).
8. Run exclusion checks against report-date output.
9. Run placeholder-dependent source-to-output checks only when candidate sources are materialized.
10. Run optional SQL Server baseline comparison only when a normalized baseline source is provided.

## Step 15B3 evidence requirements

- SQL result sets from:
  - `databricks/sql/08_outputs/09_mifid2_npd_trax_validation.sql`
- Supporting Step 15 artifacts:
  - `databricks/sql/08_outputs/09_mifid2_npd_trax_scaffolding.sql`
  - `databricks/sql/08_outputs/09_mifid2_npd_trax.sql`
- Updated gate/delta documentation:
  - `docs/mifid2_npd_trax_output_analysis.md`
  - `docs/unresolved_dependencies.md`
  - `docs/known_differences.md`
  - `docs/history_seed_requirements.md`

## DE/Data Platform action list (from latest profiling)

1. Grant schema access to `main.pii_data.bronze_etoro_customer_customer` and `main.pii_data.bronze_etoro_history_customer` (only active access blockers), or approve a formal regulatory exception.
2. Support historical seed extraction/access and assign extract ownership per approved strategy (`docs/history_seed_requirements.md`, `docs/de_data_platform_action_list.md`).
3. Complete required-column certification and baseline/date-window validation for selected primary price sources:
   - `main.dealing.bronze_pricelog_history_currencyprice` (`Reg_CurrencyPrice_Ext`)
   - `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` (`Reg_Ext_CurrencyPriceMaxDateWithSplit`)
4. Complete Step 7 duplicate/key/coverage validation for `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` (readable; no longer a storage blocker).
5. Keep `main.trading.bronze_etoro_trade_currencyprice` and `dwh_daily_process` / `main.dwh` split-price objects as fallback/reference only unless comparison evidence is explicitly required.

## Step 16 final consolidation gate

- Step 16 consolidates all validation layers across:
  - static references / UDFs
  - Pre_Regulation staging
  - regulation movements
  - hedge liquidity/SCD
  - ASIC2-compatible subset
  - `MIFID2_ext` staging
  - final MiFID output modules (`Customer`, `RegChange_Customer`, `Report`, `ME_Report`, `Removed_OP_Partials`, `ETORO_Report`, `Hedge_Report`, `NPD_TRAX`)
- Step 16 does not add or activate business transformation logic.
- Step 16 is the readiness gate before:
  - any execution un-gating,
  - workflow/orchestration implementation,
  - deployment and operational run sequencing.
