# Phase 1D / Steps 5-7 - Unresolved Dependencies

This file tracks dependencies from `docs/dependency_coverage_matrix.md` that are not yet fully resolved for phase-1 implementation and validation.

## Active unresolved items

| dependency | why unresolved | impact if not resolved | required decision/action | blocking for phase 1 |
| --- | --- | --- | --- | --- |
| `Reg_CurrencyPrice_Ext` source column parity (`History.CurrencyPrice_Active`) | Candidate (`main.trading.bronze_etoro_trade_currencyprice`) has not yet been runtime-profiled against the full SSIS-selected column set | Staging build can fail at execution time or silently diverge if columns are missing/renamed | Run `databricks/sql/03_pre_regulation_ext/01_price_currency_source_profiling.sql` and confirm all required columns before execution | Yes |
| `Reg_Ext_DailyMaxPrices` source column parity (`History.CurrencyPriceMaxDate`) | Candidate (`main.dealing.bronze_pricelog_history_currencypricemaxdate`) has not yet been runtime-profiled against required columns | Price/max-date staging parity can drift or fail at runtime | Run source profiling and confirm required columns before execution | Yes |
| `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection | Two candidate mappings are documented and both are plausible | Price/split parity differences in MiFID and movement outputs | Choose source after candidate comparison checks (columns, run-window row counts, min/max dates, duplicate `PriceRateID`, `InstrumentID` coverage, freshness) | Yes (for full parity) |
| `Reg_Ext_T_PriceCandle60Min` source shape confirmation | Candidate mapping exists, but required columns are not yet runtime-validated in target environment | Latest-price extraction may fail if source schema differs | Confirm `InstrumentID`, `BidLast`, `AskLast`, `DateFrom` via profiling before execution | Yes |
| `MIFID2_Hedge_Report.RecordID` identity behavior | SQL Server uses `IDENTITY(100000001,1)` but Databricks has no direct equivalent behavior by default | Record sequencing drift and potential downstream mismatch | Decide deterministic generation strategy and document it | Yes |
| ASIC2 replacement for legacy `ASIC_Transactions` | `SP_MIFID2_ETORO_Report` still references legacy object shape | MiFID ETORO output may not match intended ASIC2 source-of-truth | Finalize compatibility layer/table mapping from `ASIC2_Transactions` fields | Yes |
| `CDE_Execution_timestamp -> OpenTime` mapping | Mapping is marked approximate, not fully validated | ETORO transaction timing fields may mismatch legacy output | Validate field-level transformation and timezone handling | Yes |
| Historical seed strategy for `MIFID2_NPD_TRAX` | Full historical backfill is out of scope; optional seed policy not finalized | Backdated reconciliation windows may fail parity | Define minimal seed approach for validation-only windows | No (unless older validation window is requested) |
| Historical seed strategy for `ASIC2_Transactions` | Same as above; history required only for some parity windows | Backdated ETORO parity may diverge | Define optional seed/rebuild boundaries and triggers | No (unless older validation window is requested) |
| Materialization choice for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` | Both SSIS-created staging and mapped gold equivalents exist | Inconsistent lineage and row-count mismatches between flows | Step 5B2 decision gate: prefer prefixed snapshots from certified gold only after row-count/schema parity passes; otherwise recreate SSIS-compatible materialized logic from run-date inputs | Yes (for deterministic reproducibility) |
| `Reg_Ext_MigrationInOut_STG` source reconstruction | SSIS builds `##TRAN_DATA` from multiple operational sources before loading the staging table | Incorrect migration/in-out rows can affect movement and MiFID report logic | Confirm Databricks equivalents for the temp-table inputs and validate reconstructed row counts against SQL Server | Yes |
| Step 5B2 expected source access/schema validation | Several non-price sources are expected but not yet confirmed in runtime schema (`CustomerLatinName`, `Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Dictionary.Currency`, `Dictionary.CurrencyType`) | Staging SQL may fail or silently diverge if expected sources/columns differ | Run `databricks/sql/03_pre_regulation_ext/04_non_price_source_profiling.sql` and document missing columns before authoring executable staging SQL | Yes |
| `Reg_Instruments_ext` gold/FIRDS replacement shape | SSIS builds the object from raw trade joins, while phase 1 prefers certified gold/FIRDS sources | Missing columns such as visibility, currency IDs, or `IsFuture` can break downstream instrument logic | Validate `main.regtech.gold_regtech_reg_instruments_scd` / full-description coverage against the SSIS output contract before materialization | Yes |
| `Reg_Regulation_Movments_Positions` Step 6 source parity | Active movement load depends on migration population, position/history branches, and post-load instrument/price enrichment | Movement rows, branch composition, and MIFID report filters can drift if join/date logic diverges | Validate Step 6 source contracts via `databricks/sql/04_regulation_movements/01_regulation_movments_source_profiling.sql` before enabling executable staging SQL | Yes |
| `Reg_Regulation_Movments_Positions` price enrichment dependency | Step 6 post-load `EOD_Price` depends on split-price staging source choice still unresolved in Step 5B1 | Missing or incorrect `EOD_Price`/`Symbol` enrichment for movement rows | Resolve/validate `Reg_Ext_CurrencyPriceMaxDateWithSplit` parity before activating Step 6 enrichment logic | Yes |
| Step 7 liquidity source required-column/access profiling | Step 7 mapping sources are confirmed, but runtime source schema/access has not yet been profiled in target workspace | Hedge-liquidity staging activation can fail or drift if columns/access differ | Run `databricks/sql/05_hedge_liquidity/01_hedge_liquidity_source_profiling.sql` and resolve missing columns/access before un-gating Step 7 staging SQL | Yes |
| Step 7 sensitive-column handling for `Reg_LiquidtyAcount_Ext` | SQL Server SSIS selected `Username`, `Password`, `SettingsXML`, but phase-1 staging excludes sensitive fields | Potential downstream shape mismatch if a consumer expects legacy sensitive columns | Confirm whether a compatibility object with masked/null placeholders is needed; keep normal staging object free of raw secrets | Yes |
| `Reg_LiquidtyAcount_SCD` seed/cutover strategy | Step 7 SCD is persistent history and cannot use unconditional full replace pattern | Incorrect cutover can break SCD history and hedge-report dependencies | Approve seed/rebuild vs incremental cutover strategy before activating SCD templates in `databricks/sql/05_hedge_liquidity/03_reg_liquidtyacount_scd.sql` | Yes |
| `Reg_LiquidtyAcount_SCD` removed-account `IsLast` behavior | SQL Server removed-account update does not explicitly set `IsLast = 0`; parity vs data-quality behavior must be explicit | Silent correction can break parity; strict parity can leave edge-case current flags | Preserve SQL Server behavior by default; if correction is desired, document and approve as intentional known difference before execution | Yes |
| Step 7 LEI completeness dependency | Hedge-liquidity mapping depends on gsheet LEI coverage for active/report-relevant accounts | Missing LEI can cause downstream hedge report/data-quality failures | Execute Step 7 LEI completeness checks and decide remediation policy for active accounts with missing LEI | Yes |
| `Ext_MigrationInOut_Population` support-copy representation | SQL Server uses RegSupportDB support copy for cross-DB join behavior | Persistent/non-persistent mismatch can add lineage confusion or duplicate state | Represent as non-persistent CTE/temp relation in Databricks Step 6 flow; do not introduce a separate persistent business target | No |
| `dbo.ReplaceChar` parity implementation | Function behavior is strict (trim-before-replace, specific character map) | Customer identifier/name outputs can drift from SQL Server | SQL authored in Step 4; execute targeted unit tests and compare against SQL Server outputs | Yes |
| `Reg_DWH_StaticPosition` dependency treatment | Referenced in ASIC2 SPs but investigated as stale/legacy | Potential confusion about whether to include stale join path | Keep conditional/excluded unless proven to affect MiFID-consumed fields | No |
| Audit/control persistence scope (`Reg_SSIS_Log`, `Reports_Control`, SQL Agent metadata) | Needed for lineage and reconciliation governance but not always required for table generation | Reduced observability and harder run diagnostics | Decide minimum audit/control artifacts to replicate in phase 1 | No |

## Explicitly non-blocking by current phase scope

- Delivery/file handling (`CSV`, `7z`, `SFTP`, `TRAX/Cappitech upload`, response processing) remains out of scope for phase 1.
- Optional/reference packages (`MIFID2_TRAX_BACKREP2025.dtsx`, `BestEX_Daily.dtsx`) remain reference-only.
- NOC and old Databricks attempt remain reference-only and are not implementation authorities.

## Recommended resolution order

1. Complete Step 5B1 source profiling for `Reg_CurrencyPrice_Ext` and `Reg_Ext_DailyMaxPrices`.
2. Resolve `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection from candidate comparison evidence.
3. Complete Step 5B1 runtime validation for `Reg_Ext_T_PriceCandle60Min`.
4. Finalize ASIC2 compatibility mapping for ETORO (`OpenTime` included).
5. Decide `RecordID` strategy for `MIFID2_Hedge_Report`.
6. Lock staging-vs-gold materialization policy for migration/in-out tables using Step 5B2 parity profiling.
7. Confirm Step 5B2 expected source access/schema before authoring active non-price staging SQL.
8. Confirm Step 6 movement source contracts and join/date parity before activating Step 6 staging DDL.
9. Complete Step 7 liquidity source profiling and close required-column/access gaps.
10. Decide Step 7 SCD seed/cutover strategy and removed-account `IsLast` parity/correction policy.
11. Confirm Step 7 sensitive-column compatibility needs (if any) without exposing secrets.
