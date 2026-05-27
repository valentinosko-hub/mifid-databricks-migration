# Reconciliation Plan (Phase 1)

This plan defines reconciliation scope and execution order for migration validation in `main.regtech_ops_stg`. It is documentation-only in this step.

## Current focus

- Step 12B4 final validation/reconciliation package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`
- Step 13B1 ETORO scaffold/documentation/output-contract package for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`

## Out of scope for this step

- Step 13B2/13B3 ETORO projection and validation logic
- `MIFID2_Hedge_Report`
- `MIFID2_NPD_TRAX`
- File delivery (`CSV`, `7z`, `SFTP`, TRAX/Cappitech upload/response handling)
- Production deployment

## Gate prerequisites before Step 12 activation

- Step 5B1 price/split source gates resolved.
- Step 5B2 non-price Pre_Regulation gates resolved.
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
  - ETORO read-only validation/reconciliation package.

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

## Step 13B1 stop condition

- Step 13B1 ends when ETORO scaffold and dependency gates are authored and documented.
- Activation/execution of ETORO projection begins in Step 13B2 only.
- ETORO validation package implementation begins in Step 13B3 only.
