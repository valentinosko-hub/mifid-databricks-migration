# History Seed Requirements (Phase 1)

This document tracks history-seed expectations for phase-1 table/report generation modules. Full historical backfill remains out of scope unless a validation window explicitly requires it.

## Step 6 - Regulation movement staging

Primary target:

- `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`

## Minimum seed requirements for Step 6 parity windows

To validate a specific `ReportDate`, the following history scope must exist for the same date window:

- Migration population rows for `RunDate = ReportDate`:
  - preferred snapshot: `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
  - certified gold fallback (parity-gated): `main.regtech.gold_regtech_reg_migrationinout_population`
- Position/history sources with events up to report-day end:
  - `main.trading.silver_etoro_trade_position`
  - `main.trading.bronze_etoro_history_position_datafactory`
- Instrument/price enrichment for report date:
  - `main.regtech.gold_regtech_reg_instruments_scd` with valid-from/to coverage
  - split-price source for `OccurredDate = ReportDate` (still gated by Step 5B1 source selection)

## Seed/cutover policy for Step 6

- Phase 1 default: seed only the validation date windows requested by reconciliation checks.
- If older dates are required:
  - expand seed range for migration population and position/history inputs first,
  - then validate movement branch composition and enrichment completeness by date.

## Known Step 6 history risks

- Gold-vs-SSIS parity risk for migration population snapshots may change movement row composition.
- Split-price source selection risk affects `EOD_Price` completeness and value parity.
- Historical cutover risk exists if migration timestamps or position lifecycle events straddle date boundaries around report-date transitions.

## Out of scope

- Full historical backfill of all movement dates.
- Production deployment/cutover workflows.
- File-delivery and response handling flows.
