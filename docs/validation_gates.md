# Phase 1C - Validation Gates

This document defines go/no-go validation gates for Phase 1 (documentation and table/report generation scope only).

## Gate 1 - Scope gate

Must be true:
- Work remains limited to Databricks table/report generation scope.
- No phase-1 delivery implementation (CSV, 7z, SFTP, TRAX/Cappitech upload, response handling).
- No full historical backfill as a hard prerequisite.

## Gate 2 - Naming and environment gate

Must be true:
- Target environment is `main.regtech_ops_stg`.
- Every persistent object uses prefix `bi_output_regtechops_`.
- No production object creation in `main.regtech`.

## Gate 3 - Source-of-truth gate

Must be true:
- ASIC2 is used as source of truth for MiFID ETORO dependency replacement.
- FIRDS certified gold sources are used (`main.regtech.gold_regtech_reg_instruments_scd`, `main.regtech.gold_regtech_reg_instruments_full_description`).
- NOC and old Databricks attempt remain reference-only.

## Gate 4 - SSIS staging coverage gate

Must be true:
- SSIS-created staging families are documented/classified by producer package:
  - `MIFID2_ext_*`
  - `MIFID2_Failed_TRAX`
  - `Reg_Ext_*`
  - `ASIC2_ext_*`
  - `Reg_CurrencyPrice_Ext`
  - `Reg_MigrationInOut_Population`
  - `Reg_RegulationInOutDailyData`
  - `Reg_Regulation_Movments_Positions`

Evidence:
- `docs/ssis_created_staging_tables.md`

## Gate 5 - Final output target gate

Must be true:
- All required MiFID outputs are mapped to prefixed targets in `main.regtech_ops_stg`:
  - `mifid2_customer`
  - `mifid2_regchange_customer`
  - `mifid2_report`
  - `mifid2_me_report`
  - `mifid2_etoro_report`
  - `mifid2_hedge_report`
  - `mifid2_removed_op_partials`
  - `mifid2_npd_trax`

Evidence:
- `docs/final_output_tables.md`

## Gate 6 - Static/reference availability gate

Must be true:
- Required static/reference inputs are documented as available and reusable.

Evidence:
- `docs/static_reference_tables.md`

## Gate 7 - Mapping quality gate

Must be true:
- Confirmed mappings are separated from candidate/conditional mappings.
- Candidate mappings are explicitly marked for resolution (no silent guessing).
- Legacy/reference-only mappings are excluded from implementation authority.

Evidence:
- `docs/source_to_databricks_mapping_review.md`

## Gate 8 - Data validation checklist gate

Before phase sign-off, validation outputs must cover:
- Row counts by `ReportDate`.
- Row counts by `RegulationID` / `RegulationReportID`.
- Business-key duplicate checks.
- Required-field null checks.
- Quantity/price aggregate checks where applicable.
- Hash/checksum-style comparisons where practical.
- Source freshness checks.
- Staging row counts and final output row counts.

## Gate 9 - Open-questions governance gate

Must be true:
- Fixed decisions are explicitly documented.
- Remaining open decisions are tracked with clear next resolution steps.
- Open items do not silently change business logic.

Evidence:
- `docs/open_questions_and_decisions.md`
