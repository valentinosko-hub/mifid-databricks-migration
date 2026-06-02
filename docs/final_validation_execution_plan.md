# Final Validation Execution Plan (Step 16B1)

This plan defines the cross-module validation order to execute after Databricks module execution is enabled.

Scope:
- Validation/readiness sequencing only.
- No business-logic activation.
- No workflow/orchestration implementation.
- No delivery/upload/response handling.

## Proposed execution order

1. Static reference checks.
2. Source access / required-column checks.
3. Pre_Regulation staging checks.
4. Regulation movement checks.
5. Hedge liquidity/SCD checks.
6. ASIC2 compatibility checks.
7. `MIFID2_ext` checks.
8. Customer output checks.
9. Main report output checks.
10. ETORO checks.
11. Hedge report checks.
12. NPD_TRAX checks.
13. Cross-output reconciliation.
14. SQL Server baseline comparison, if available.

## Cross-module execution notes

- Run each module's SELECT-only validation package first; execute placeholder-dependent checks only when required placeholder sources are materialized.
- Keep source-access and storage-blocker checks as hard gates before downstream report-level reconciliation.
- Treat history-sensitive checks as coverage-limited until approved seed/cutover policies are in place.
- Keep SQL Server baseline comparisons optional and gated until normalized baseline sources are provided.

## Evidence capture expectations

- Persist validation result sets by step/module in the execution runbook.
- Capture unresolved gate outputs from:
  - `databricks/sql/09_validation/07_phase1_readiness_summary.sql`
  - `databricks/sql/09_validation/08_cross_module_validation_manifest.sql`
  - `databricks/sql/09_validation/09_cross_module_dependency_gate_checks.sql`
- Track go/no-go decisions against `docs/open_blockers_for_execution.md` and `docs/validation_gates.md`.
