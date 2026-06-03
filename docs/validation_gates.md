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

## Step 17B workflow gate-wrapper mapping

Step 17B introduces non-executing gate-wrapper SQL for orchestration skeleton checks:

- `databricks/sql/10_workflow/gates/gate_global_scope.sql`
- `databricks/sql/10_workflow/gates/gate_module_validation_chain.sql`
- `databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql`

Gate-to-wrapper mapping:

| Validation gate | Workflow wrapper check |
| --- | --- |
| Gate 1 Scope gate | `gate_global_scope.sql` (`scope_gate`, delivery/upload exclusion checks) |
| Gate 2 Naming/environment gate | `gate_global_scope.sql` (`environment_naming_gate`) |
| Gate 3 Source-of-truth gate | `gate_module_validation_chain.sql` (module manifest and source-of-truth chain expectations) |
| Gate 4 SSIS staging coverage gate | `gate_module_validation_chain.sql` (module sequence and staging-scope references) |
| Gate 5 Final output target gate | `gate_module_validation_chain.sql` (output module placeholders and dependency ordering) |
| Gate 6 Static/reference availability gate | `gate_global_scope.sql` + `gate_cross_module_readiness.sql` (`static_reference_availability`) |
| Gate 7 Mapping quality gate | `gate_cross_module_readiness.sql` policy and approval checkpoint statuses |
| Gate 8 Data validation checklist gate | `gate_module_validation_chain.sql` + `gate_cross_module_readiness.sql` validation completion checks |
| Gate 9 Open-questions governance gate | `gate_cross_module_readiness.sql` decision and approval status checks |

## Step 16 final gate categories

The consolidated gate categories for cross-module execution readiness are:

### Source access

- Confirmed visibility for required upstream objects.
- No unresolved no-schema-access or no-catalog-access blockers for active execution paths.

### Source quality

- No unresolved storage/data scan failures on required execution inputs.
- Required-column contracts are certified for each module activation path.

### Schema parity

- Target output contracts match SQL Server intent (column presence/order/type/nullability/precision).
- Schema differences are documented and explicitly approved before activation.

### Row-count parity

- Module-level row counts and key distributions are validated by `ReportDate` and regulation dimensions.
- Cross-output reconciliation checks are complete for dependent modules.

### History seed

- Stateful modules have explicit seed/cutover policy:
  - `MIFID2_NPD_TRAX`
  - `MIFID2_Failed_TRAX`
  - `ASIC2_Transactions`
  - `Reg_LiquidtyAcount_SCD`

### Business decision

- Open business/SME parity decisions are closed (for example hedge `RecordID` and transaction-reference parity).
- Classification and parity-sensitive rules are approved where currently gated.

### Execution readiness

- All module validation packages pass in execution order.
- Placeholder-dependent checks are either resolved with materialized sources or remain explicitly gated and excluded from go/no-go.

### Deployment readiness

- Production deployment remains blocked until execution-readiness gates pass and deployment-specific approvals are complete.
- Step 16B1 itself is documentation/validation consolidation only and does not perform deployment actions.
- Step 17B workflow assets remain template-only and do not perform deployment actions.
