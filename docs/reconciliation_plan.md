# Reconciliation Plan (Phase 1)

This plan defines reconciliation scope and execution order for migration validation in `main.regtech_ops_stg`. It is documentation-only in this step.

## Current focus

- Step 12B1 scaffolding and validation foundation only for:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`

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
- Futures metadata columns profiled in `main.trading.bronze_etoro_trade_futuresmetadata`.
- Exclusion source mappings confirmed, including `MIFID2_Instruments_To_Exclude` equivalent.
- `UpdateDate` no-default rule approved for `MIFID2_Report` and `MIFID2_ME_Report`.
- Removed partials explicit-column insert parity rule enforced.

## Step 12B1 reconciliation coverage

1. Schema parity:
   - Report / ME / Removed_OP_Partials column names, order, types, nullability, decimal precision-scale.
2. Row counts:
   - By `ReportDate`, `RegulationReportID`, `RegulationID`, `RegChange`.
3. Duplicate checks:
   - `ReportDate` + `RegulationReportID` + `TransactionReferenceNumber` + `BackReportingIndicator`.
   - Position/open-close lifecycle business keys.
   - Removed partials business keys.
4. Required null checks:
   - Mandatory identifiers, datetime fields, quantity and price fields.
5. Exclusion checks:
   - Excluded instruments and position IDs absent.
   - Placeholder gate for `MIFID2_Instruments_To_Exclude`.
6. Instrument coverage:
   - `Reg_Instruments_SCD`, `Reg_Instruments_Full_Description`,
   - `InstrumentMetaData_SpecialChar_Conversion`,
   - `FuturesMetaData`.
7. Movement/RegChange checks:
   - Counts by `RegChange`,
   - Movement-stage coverage,
   - `IsOpenedAfterLastMigration` distribution,
   - Migration customer counts.
8. Removed partial checks:
   - Removed partial count,
   - Source-to-removed reconciliation placeholders,
   - Same-day open/close checks.
9. Aggregates:
   - Quantity and price aggregates by branch/report ID.
10. Source-to-output checks:
   - Customers to output,
   - Positions to output,
   - Reg-change positions to output,
   - Movement source to output.

## Execution order once gates pass

1. Run schema contract checks for all three targets.
2. Run dependency visibility/coverage checks.
3. Run row-count and duplicate checks.
4. Run required-null and exclusion checks.
5. Run instrument/movement/regchange checks.
6. Run removed-partials and aggregate checks.
7. Compare source-to-output placeholders and classify deltas.
8. Record outcomes in `docs/known_differences.md` and unresolved follow-ups in `docs/unresolved_dependencies.md`.

## Planned evidence output

- SQL result sets from:
  - `databricks/sql/08_outputs/03_mifid2_report_validation_foundation.sql`
- Updated gate decisions and known-difference notes:
  - `docs/unresolved_dependencies.md`
  - `docs/known_differences.md`
  - `docs/history_seed_requirements.md`

## Stop condition for Step 12B1

- Step 12B1 ends when scaffolding and validation foundations are in place and all unresolved gates are documented.
- Full branch/business logic migration starts in Step 12B2/12B3 only.
