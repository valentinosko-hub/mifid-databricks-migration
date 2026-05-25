# Phase 1D - Unresolved Dependencies

This file tracks dependencies from `docs/dependency_coverage_matrix.md` that are not yet fully resolved for phase-1 implementation and validation.

## Active unresolved items

| dependency | why unresolved | impact if not resolved | required decision/action | blocking for phase 1 |
| --- | --- | --- | --- | --- |
| `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection | Two candidate mappings are documented and both are plausible | Price/split parity differences in MiFID and movement outputs | Choose source after SSIS column/filter parity validation (`ext_fcupnl...` vs `fact_currencypricewithsplit`) | Yes (for full parity) |
| `MIFID2_Hedge_Report.RecordID` identity behavior | SQL Server uses `IDENTITY(100000001,1)` but Databricks has no direct equivalent behavior by default | Record sequencing drift and potential downstream mismatch | Decide deterministic generation strategy and document it | Yes |
| ASIC2 replacement for legacy `ASIC_Transactions` | `SP_MIFID2_ETORO_Report` still references legacy object shape | MiFID ETORO output may not match intended ASIC2 source-of-truth | Finalize compatibility layer/table mapping from `ASIC2_Transactions` fields | Yes |
| `CDE_Execution_timestamp -> OpenTime` mapping | Mapping is marked approximate, not fully validated | ETORO transaction timing fields may mismatch legacy output | Validate field-level transformation and timezone handling | Yes |
| Historical seed strategy for `MIFID2_NPD_TRAX` | Full historical backfill is out of scope; optional seed policy not finalized | Backdated reconciliation windows may fail parity | Define minimal seed approach for validation-only windows | No (unless older validation window is requested) |
| Historical seed strategy for `ASIC2_Transactions` | Same as above; history required only for some parity windows | Backdated ETORO parity may diverge | Define optional seed/rebuild boundaries and triggers | No (unless older validation window is requested) |
| Materialization choice for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` | Both SSIS-created staging and mapped gold equivalents exist | Inconsistent lineage and row-count mismatches between flows | Decide whether to materialize SSIS-compatible staging each run or consume certified gold directly | Yes (for deterministic reproducibility) |
| `dbo.ReplaceChar` parity implementation | Function behavior is strict (trim-before-replace, specific character map) | Customer identifier/name outputs can drift from SQL Server | Implement parity-safe function logic and add targeted unit tests | Yes |
| `Reg_DWH_StaticPosition` dependency treatment | Referenced in ASIC2 SPs but investigated as stale/legacy | Potential confusion about whether to include stale join path | Keep conditional/excluded unless proven to affect MiFID-consumed fields | No |
| Audit/control persistence scope (`Reg_SSIS_Log`, `Reports_Control`, SQL Agent metadata) | Needed for lineage and reconciliation governance but not always required for table generation | Reduced observability and harder run diagnostics | Decide minimum audit/control artifacts to replicate in phase 1 | No |

## Explicitly non-blocking by current phase scope

- Delivery/file handling (`CSV`, `7z`, `SFTP`, `TRAX/Cappitech upload`, response processing) remains out of scope for phase 1.
- Optional/reference packages (`MIFID2_TRAX_BACKREP2025.dtsx`, `BestEX_Daily.dtsx`) remain reference-only.
- NOC and old Databricks attempt remain reference-only and are not implementation authorities.

## Recommended resolution order

1. Resolve price/split source selection (`Reg_Ext_CurrencyPriceMaxDateWithSplit`).
2. Finalize ASIC2 compatibility mapping for ETORO (`OpenTime` included).
3. Decide `RecordID` strategy for `MIFID2_Hedge_Report`.
4. Lock staging-vs-gold materialization policy for migration/in-out tables.
5. Implement/test `ReplaceChar` parity function behavior.
