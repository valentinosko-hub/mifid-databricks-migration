# SQL Server Baseline Extract Plan (RegReportDB_Prod)

## Purpose

Documents how SQL Server baseline extracts and historical seed loads should be planned for phase-1 MiFID Databricks parity — **planning only**; no execution performed from this repository.

**Authoritative request package:** [baseline_scenario_request.md](baseline_scenario_request.md) — scenarios, table lists, copyable request template.  
**Validation expectations:** [validation_evidence_plan.md](validation_evidence_plan.md)

**Evidence:** BI-21 MCP metadata (2026-06-05) and manual SQL aggregates (evidence outside repo). Inventory detail: [historical_seed_inventory.md](historical_seed_inventory.md).

**Status:** Repository is **not production-ready**. NOC and old Databricks attempt materials remain reference-only.

---

## Environment policy

| Setting | Value |
| --- | --- |
| DE migration target | `main.regtech` (general pipeline from `RegReportDB_Prod`) |
| RegTech staging reads | `main.regtech` when DE-migrated sources available |
| RegTech staging writes | `main.regtech_ops_stg` only |
| Generated prefix | `bi_output_regtechops_` |
| Seed prefix | `bi_output_regtechops_seed_` |
| Manual seed test prefix | `bi_output_regtechops_seed_test_` |

---

## Three extract types

| Type | Use | Storage |
| --- | --- | --- |
| **Baseline-date extract** | Parity comparison for **selected report dates** | Secure storage; evidence outside repo |
| **Full-history seed** | Stateful tables: Hedge, NPD, ASIC2, SCD, migration/regulation | Secure storage → `bi_output_regtechops_seed_*` |
| **Staging-only manual seed test** | Development/testing in staging only | Secure storage → `bi_output_regtechops_seed_test_*`; controlled CSV OK |

See [baseline_scenario_request.md](baseline_scenario_request.md) for full scenario and table lists.

---

## Required baseline scenarios (summary)

RegTech / Validation must nominate concrete dates for:

1. Normal trading day  
2. High-volume day  
3. RegChange activity day  
4. Hedge activity day  
5. NPD_TRAX retry/rejection day  
6. Customer identity-change day  
7. Partial-close / removed OP partials day  
8. Split activity day  
9. Futures activity day  
10. ETORO / ASIC2 activity day  
11. Same-day open/close day  
12. Missed-trade / back-reporting case (if available)  
13. UK/FCA branch activity  
14. EU branch activity  
15. Seychelles branch activity (if applicable)  
16. ME branch activity (if applicable)  
17. Exclusion-applied day — excluded CID  
18. Exclusion-applied day — excluded instrument  
19. Exclusion-applied day — excluded position / transaction reference  

---

## Final output tables — baseline-date extracts

Per approved baseline date (selected-date filter; not full-history unless Type 2 approved separately):

- `dbo.MIFID2_Customer`
- `dbo.MIFID2_RegChange_Customer`
- `dbo.MIFID2_Report` — **no full export unless explicitly approved**
- `dbo.MIFID2_ME_Report`
- `dbo.MIFID2_Removed_OP_Partials`
- `dbo.MIFID2_ETORO_Report`
- `dbo.MIFID2_Hedge_Report` (baseline slices; full history = Type 2)
- `dbo.MIFID2_NPD_TRAX` (baseline slices; full history = Type 2; **final-flow last**)

---

## Staging / reconciliation tables — baseline-date extracts

- `dbo.MIFID2_ext_Customer`, `dbo.MIFID2_ext_RegChange_Customer`
- `dbo.MIFID2_ext_Position`, `dbo.MIFID2_ext_RegChange_Position`, `dbo.MIFID2_ext_PositionChangeLog`
- `dbo.MIFID2_ext_Mirror`, `dbo.MIFID2_ext_HedgeExecutionLog`
- `dbo.MIFID2_Failed_TRAX`
- `dbo.Reg_CurrencyPrice_Ext`, `dbo.Reg_Ext_CurrencyPriceMaxDateWithSplit`, `dbo.Reg_Ext_DailyMaxPrices`
- `dbo.Reg_Ext_T_PriceCandle60Min`, `dbo.Reg_Ext_HistorySplitRatio`
- `dbo.Reg_Ext_Trade_GetInstrument`, `dbo.Reg_Ext_Trade_InstrumentMetaData`
- `dbo.Reg_Ext_DictionaryCurrency`, `dbo.Reg_Ext_DictionaryCurrencyType`, `dbo.Reg_Instruments_ext`
- `dbo.Reg_MigrationInOut_Population`, `dbo.Reg_RegulationInOutDailyData`, `dbo.Reg_Regulation_Movments_Positions`
- `dbo.Reg_LiquidtyAcount_SCD`, `dbo.Reg_Ext_LiquidityAccountID`, `dbo.Reg_LiquidtyAcount_Ext`
- `dbo.Reg_HedgeServerToLiquidityAccount_Ext`, `dbo.Reg_Ext_LiquidityProviders`

---

## Full-history seed tables (Type 2)

| Object | Rationale | Volume note |
| --- | --- | --- |
| `MIFID2_Hedge_Report` | `RecordID` continuity; registry; back-reporting | ~33.5M rows; monthly chunks **2022-07 – 2026-06** |
| `MIFID2_NPD_TRAX` | Retry / REPL / latest-row logic | ~4.6M rows; monthly chunks **2019-02 – 2026-06** |
| `MIFID2_Failed_TRAX` | NPD-dependent; if available/needed | Scope TBD |
| `ASIC2_Transactions` | ETORO parity windows | ~7.2M rows; reconcile counts |
| `ASIC2_Positions` | Prior-day dependencies | **~210M rows** — chunked mandatory |
| `ASIC2_Removed_OP_Partials` | ASIC2 lifecycle | ~315K rows |
| `Reg_LiquidtyAcount_SCD` | Hedge liquidity validity | ~1.1K rows |
| `Reg_MigrationInOut_Population` | Movement replay | ~2.8M rows; chunk by `RunDate` |
| `Reg_RegulationInOutDailyData` | Regulation replay | ~8.6M rows; chunk by `ReportDate` |
| `Reg_Regulation_Movments_Positions` | Movement inputs | ~17.8M rows; chunk by `ReportDate` |

`MIFID2_Hedge_Report` and `MIFID2_NPD_TRAX` are **feasible full-history seed candidates**.  
Hedge final activation remains gated on RecordID registry validation (MAG-12).

---

## Extraction rules

1. **Do not full-export `dbo.MIFID2_Report`** unless RegTech SME / Validation explicitly approves.
2. **`MIFID2_Hedge_Report` and `MIFID2_NPD_TRAX`** — feasible full-history seed candidates (chunked).
3. **`ASIC2_Positions`** — high-volume; controlled/chunked extraction mandatory.
4. **Format:** Prefer Parquet or Delta; controlled CSV only for Type 3 staging manual seed tests.
5. **Every extract manifest:** source server/database/table; extraction timestamp; row count; min/max date; schema/DDL or column list; checksum/hash if available; owner/contact; baseline scenario tag; extract type.
6. **No PII or raw extracts in Git.**
7. **PII-sensitive extracts** — approved secure storage only.
8. **Baseline evidence** — outside repo.
9. **Preserve `RecordID`** exactly on Hedge seed load.
10. **Final customer/NPD parity** — unmasked PII or formal exception (MAG-06); masked customer development-only.

---

## Row-count validation requirements

1. **Pre-load:** SQL Server count per chunk and table total  
2. **Post-load:** Databricks count per chunk and table total  
3. **Reconciliation:** Document discrepancies before module activation  

Known variances to reconcile at extract:

| Table | Notes |
| --- | --- |
| `MIFID2_Hedge_Report` | MCP vs manual aggregate (~63K delta) — reconcile before sign-off |
| `ASIC2_Transactions` | MCP `count_rows` vs `get_table_size` vs manual — use manual + monthly sums as primary |

Full validation checklist: [validation_evidence_plan.md](validation_evidence_plan.md)

---

## Scope boundaries

### In scope

- Baseline-date extracts per approved scenarios (D-23 / MAG-16)
- Full-history seeds for stateful tables
- Staging-only manual seed tests
- Secure landing-zone expectations

### Out of scope

- Full export of `dbo.MIFID2_Report` (unless explicitly approved)
- Regulatory delivery: CSV to TRAX, 7z, SFTP, upload/response
- Production deployment to `main.regtech` from RegTech staging jobs
- Storing seed CSVs, PII samples, or raw outputs in Git

---

## Execution ownership (pending)

| Activity | Owner | Status |
| --- | --- | --- |
| Scenario date nomination | RegTech SME + Validation | **Pending** |
| Extract execution | DBA / SQL Server team | **Pending** |
| Landing path and retention | DE / Data Platform | **Pending** |
| Seed load to `main.regtech_ops_stg` | Engineering (gated) | **Pending** |
| Validation evidence | Validation Owner (MAG-16) | **Pending** |

Use request template in [baseline_scenario_request.md](baseline_scenario_request.md).

---

## Related documents

- [baseline_scenario_request.md](baseline_scenario_request.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
- [historical_seed_inventory.md](historical_seed_inventory.md)
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
- [history_seed_requirements.md](history_seed_requirements.md)
- [manual_seed_testing_plan.md](manual_seed_testing_plan.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md)
- [remaining_decisions.md](remaining_decisions.md) (D-23)
