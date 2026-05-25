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

## Alignment notes

- This sequence is consistent with SQL Agent/SSIS flow intent while preserving phase-1 scope boundaries.
- File handling and response processing remain out of scope for this phase.
