# Reconciliation Plan (Phase 1)

This plan defines reconciliation scope and execution order for migration validation in `main.regtech_ops_stg`. It is documentation-only in this step.

## Current focus

- Step 12B2 intermediate position/trade population templates only (pre-branch):
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population` (optional checkpoint)
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags` (optional checkpoint)
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates` (optional checkpoint)

## Out of scope for this step

- `MIFID2_ETORO_Report`
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
