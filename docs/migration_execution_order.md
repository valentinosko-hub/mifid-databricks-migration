# Phase 1C - Migration Execution Order

This order is the canonical phase-1 implementation sequence for documentation and table/report generation scope.

## Required implementation order

1. Static references and UDFs
   - Confirm and use already-available static/reference inputs.
   - Finalize parity behavior for `dbo.ReplaceChar`.
2. Pre_Regulation_Ext staging
   - Build/refresh `Reg_Ext_*` and price/currency/split staging from package logic.
3. Regulation movement staging
   - Build/refresh `Reg_Regulation_Movments_Positions`.
4. Hedge liquidity mapping staging
   - Build/refresh hedge liquidity mapping staging and support `Reg_LiquidtyAcount_SCD`.
5. ASIC2-compatible MiFID subset
   - Build/refresh ASIC2 staging and compatibility inputs used by MiFID ETORO.
6. MIFID2_ext staging
   - Build/refresh `MIFID2_ext_*` and `MIFID2_Failed_TRAX`.
7. Customer outputs
   - Generate `MIFID2_Customer`.
8. RegChange customer outputs
   - Generate `MIFID2_RegChange_Customer`.
9. Main MIFID2_Report / ME / removed partials
   - Generate `MIFID2_Report`, `MIFID2_ME_Report`, `MIFID2_Removed_OP_Partials`.
10. ETORO report
    - Generate `MIFID2_ETORO_Report` using ASIC2-compatible source-of-truth logic.
11. Hedge report
    - Generate `MIFID2_Hedge_Report`.
12. NPD_TRAX table
    - Generate `MIFID2_NPD_TRAX` table output only.
13. Validation/reconciliation
    - Execute validation gates and reconciliation checks.
14. Workflow skeleton
    - Document and scaffold orchestration skeleton for repeatable phase-1 runs.

## Step 17B workflow task IDs (skeleton only)

Step 17B adds a non-executing task-chain skeleton in:

- `databricks/workflows/mifid_phase1_table_generation.yml`

Task groups and IDs:

1. `preflight_readiness_checks`
2. `static_references_and_udfs`
3. `pre_regulation_ext_staging`
4. `regulation_movements`
5. `hedge_liquidity_scd`
6. `asic2_compatible_subset`
7. `mifid2_ext_staging`
8. `customer_outputs`
9. `main_report_outputs`
10. `etoro_report`
11. `hedge_report`
12. `npd_trax_table_generation`
13. `validation_packages`
14. `final_readiness_summary`

Step 17B status:

- Skeleton/template only.
- Not deployment-ready.
- Must remain execution-gated until blockers and manual approvals are closed.

## Alignment notes

- This sequence is consistent with SQL Agent/SSIS flow intent while preserving phase-1 scope boundaries.
- File handling and response processing remain out of scope for this phase.
- NOC and old Databricks attempt materials remain reference-only and are not implementation authority.
