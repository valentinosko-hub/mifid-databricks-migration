# Validation Baselines

Validation baselines can be added later.

Cursor should create reconciliation SQL first.

Later, collect row counts for selected report dates:
- normal day
- month-end day
- RegChange-heavy day
- hedge-heavy day
- NPD/TRAX-heavy day

Suggested outputs to validate:
- `MIFID2_Customer`
- `MIFID2_RegChange_Customer`
- `MIFID2_Report`
- `MIFID2_ME_Report`
- `MIFID2_ETORO_Report`
- `MIFID2_Hedge_Report`
- `MIFID2_Removed_OP_Partials`
- `MIFID2_NPD_TRAX`
- ASIC2-compatible MiFID staging table
