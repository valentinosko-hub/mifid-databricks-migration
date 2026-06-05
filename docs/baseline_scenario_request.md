# SQL Server Baseline Scenario Request Package

## Purpose

This document is the **authoritative request package** for RegTech, Validation, DBA, and Data Engineering to provide SQL Server baseline dates and extracts from `RegReportDB_Prod` for Databricks parity validation.

**Status:** Request package only — no extracts performed from this repository.  
**Repository:** Not production-ready. NOC and old Databricks attempt materials remain reference-only.

**Related:** [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md), [validation_evidence_plan.md](validation_evidence_plan.md), [historical_seed_inventory.md](historical_seed_inventory.md)

---

## Environment and policy context

| Policy | Detail |
| --- | --- |
| DE migration | SQL Server / `RegReportDB_Prod` → `main.regtech` via general pipeline |
| RegTech staging reads | `main.regtech` when DE-migrated sources available |
| RegTech staging writes | `main.regtech_ops_stg` only; prefix `bi_output_regtechops_` |
| PII | `main.pii_data` remains open blocker; masked customer fallback is **development-only** |
| Final customer/NPD parity | Requires unmasked PII or formal exception (MAG-06) |
| NPD_TRAX | Remains **final-flow last** (history/state dependency) |
| Hedge activation | Gated on RecordID registry/control validation (MAG-12) |
| TransactionReferenceNumber | Exact SQL Server parity required (D-13) |
| CFI / InstrumentClassification | Exact SQL Server parity required (D-14) |
| Evidence storage | **Outside repo** — no PII or raw extracts in Git |
| Delivery/production | Out of scope |

---

## Three extract types (must be distinguished)

| Type | Purpose | When to use | Landing |
| --- | --- | --- | --- |
| **1. Baseline-date extract** | Compare SQL Server output to Databricks output for **selected report dates** | Parity validation on approved scenario dates | Secure storage → compare against `main.regtech_ops_stg` outputs |
| **2. Full-history seed** | Restore **stateful/history-dependent** tables required for retry, SCD, RecordID continuity, NPD logic | Hedge, NPD, ASIC2 history, SCD, migration/regulation replay | Secure storage → `main.regtech_ops_stg` with `bi_output_regtechops_seed_` prefix |
| **3. Staging-only manual seed test** | Development/testing in staging only; **not production** | Initial feasibility (e.g. NPD_TRAX subset); structural tests | Secure storage → `bi_output_regtechops_seed_test_*` in `main.regtech_ops_stg`; controlled CSV acceptable |

Do not mix extract types in a single request without explicit tagging.

---

## Required baseline scenarios

RegTech / Validation / SME must nominate **concrete report dates** (or date windows) for each scenario below. Dates may overlap; each approved date must carry a **baseline scenario tag**.

| # | Scenario | Validation focus |
| --- | --- | --- |
| 1 | Normal trading day | Baseline row counts and core report shape |
| 2 | High-volume day | Scale, performance-sensitive joins, large `MIFID2_Report` slice |
| 3 | RegChange activity day | `MIFID2_RegChange_Customer`, `MIFID2_ext_RegChange_*`, regulation branches |
| 4 | Hedge activity day | `MIFID2_Hedge_Report`, `MIFID2_ext_HedgeExecutionLog`, liquidity paths |
| 5 | NPD_TRAX retry/rejection day | `MIFID2_NPD_TRAX`, `MIFID2_Failed_TRAX`, `AcceptedTRAX` / `Action` / `RowNum` behavior |
| 6 | Customer identity-change day | Customer/reg-change identity transitions (PII-gated for final parity) |
| 7 | Partial-close / removed OP partials day | `MIFID2_Removed_OP_Partials`, ASIC2 removed partials branches |
| 8 | Split activity day | `Reg_Ext_HistorySplitRatio`, split-adjusted price paths |
| 9 | Futures activity day | Instrument/type branches affecting classification and reporting |
| 10 | ETORO / ASIC2 activity day | `MIFID2_ETORO_Report`, `ASIC2_Transactions`, `ASIC2_Positions` slices |
| 11 | Same-day open/close day | `OpenORClose` and intraday lifecycle branches |
| 12 | Missed-trade / back-reporting case | Hedge back-reporting and RecordID continuity (if available) |
| 13 | UK/FCA branch activity | Branch-specific regulation filters |
| 14 | EU branch activity | Branch-specific regulation filters |
| 15 | Seychelles branch activity | If applicable to reporting scope |
| 16 | ME branch activity | `MIFID2_ME_Report` and ME-specific branches if applicable |
| 17 | Exclusion-applied day — excluded CID | Exclusion logic on customer dimension |
| 18 | Exclusion-applied day — excluded instrument | Instrument exclusion branches |
| 19 | Exclusion-applied day — excluded position / transaction reference | Position/TRN exclusion and hedge matching |

**Minimum coverage request:** at least one approved date per scenario family where production history contains an example; document **TBD / not available** where no suitable date exists.

---

## Final output tables — baseline-date extracts

For **each approved baseline date**, request **selected-date** SQL Server extracts (not full-history unless separately approved as Type 2):

| Table | Extract type | Notes |
| --- | --- | --- |
| `dbo.MIFID2_Customer` | Baseline-date | PII-sensitive; secure storage only; final parity gated on MAG-06 |
| `dbo.MIFID2_RegChange_Customer` | Baseline-date | PII-sensitive; RegChange scenario dates |
| `dbo.MIFID2_Report` | Baseline-date | **Do not full-export** unless explicitly approved; use scenario dates only |
| `dbo.MIFID2_ME_Report` | Baseline-date | ME branch scenario dates |
| `dbo.MIFID2_Removed_OP_Partials` | Baseline-date | Partial-close scenario dates |
| `dbo.MIFID2_ETORO_Report` | Baseline-date | ETORO/ASIC2 scenario dates |
| `dbo.MIFID2_Hedge_Report` | Baseline-date **and** full-history seed | Baseline slices per scenario; full history separately for RecordID registry |
| `dbo.MIFID2_NPD_TRAX` | Baseline-date **and** full-history seed | Baseline slices for retry/rejection scenarios; full history for state logic |

Filter extracts by `ReportDate` (or documented equivalent) matching the approved scenario date.

---

## Staging / reconciliation tables — baseline-date extracts

Request selected-date extracts where needed for staging smoke tests and reconciliation (in addition to DE migration into `main.regtech`):

| Table | Extract type | Notes |
| --- | --- | --- |
| `dbo.MIFID2_ext_Customer` | Baseline-date | PII-sensitive |
| `dbo.MIFID2_ext_RegChange_Customer` | Baseline-date | PII-sensitive |
| `dbo.MIFID2_ext_Position` | Baseline-date | Non-PII structural parity |
| `dbo.MIFID2_ext_RegChange_Position` | Baseline-date | RegChange scenarios |
| `dbo.MIFID2_ext_PositionChangeLog` | Baseline-date | Position lifecycle |
| `dbo.MIFID2_ext_Mirror` | Baseline-date | Mirror/copy paths |
| `dbo.MIFID2_ext_HedgeExecutionLog` | Baseline-date | Hedge activity scenarios |
| `dbo.MIFID2_Failed_TRAX` | Baseline-date | NPD retry/rejection; depends on NPD history context |
| `dbo.Reg_CurrencyPrice_Ext` | Baseline-date | Price window around report date |
| `dbo.Reg_Ext_CurrencyPriceMaxDateWithSplit` | Baseline-date | Split/price carry-forward |
| `dbo.Reg_Ext_DailyMaxPrices` | Baseline-date | Price reconciliation |
| `dbo.Reg_Ext_T_PriceCandle60Min` | Baseline-date | Intraday price paths |
| `dbo.Reg_Ext_HistorySplitRatio` | Baseline-date | Split activity scenarios |
| `dbo.Reg_Ext_Trade_GetInstrument` | Baseline-date | Instrument resolution |
| `dbo.Reg_Ext_Trade_InstrumentMetaData` | Baseline-date | CFI/classification reconciliation |
| `dbo.Reg_Ext_DictionaryCurrency` | Baseline-date | Static/dimension reconciliation |
| `dbo.Reg_Ext_DictionaryCurrencyType` | Baseline-date | Static/dimension reconciliation |
| `dbo.Reg_Instruments_ext` | Baseline-date | Instrument master reconciliation |
| `dbo.Reg_MigrationInOut_Population` | Baseline-date **and** full-history seed | Migration snapshots |
| `dbo.Reg_RegulationInOutDailyData` | Baseline-date **and** full-history seed | Regulation replay |
| `dbo.Reg_Regulation_Movments_Positions` | Baseline-date **and** full-history seed | Movement staging |
| `dbo.Reg_LiquidtyAcount_SCD` | Baseline-date **and** full-history seed | SCD validity |
| `dbo.Reg_Ext_LiquidityAccountID` | Baseline-date | Liquidity structural checks |
| `dbo.Reg_LiquidtyAcount_Ext` | Baseline-date | Liquidity structural checks |
| `dbo.Reg_HedgeServerToLiquidityAccount_Ext` | Baseline-date | Hedge liquidity paths |
| `dbo.Reg_Ext_LiquidityProviders` | Baseline-date | Provider dimension |

---

## Full-history seed tables (Type 2 — separate requests)

These require **full available history** (or approved minimum safe window with SME sign-off). Do not substitute baseline-date-only extracts for final parity on stateful logic.

| Table | Rationale | Volume / chunking |
| --- | --- | --- |
| `dbo.MIFID2_Hedge_Report` | Historical `RecordID` preservation; Hedge RecordID registry; missed-trade back-reporting | ~33.5M rows; monthly chunks by `ReportDate` |
| `dbo.MIFID2_NPD_TRAX` | NPD history; retry; `AcceptedTRAX` / REPL behavior | ~4.6M rows; monthly chunks |
| `dbo.MIFID2_Failed_TRAX` | Dependent on NPD history; if available/needed | Scope TBD with SME |
| `dbo.ASIC2_Transactions` | ETORO/ASIC2 parity windows | ~7.2M+ rows; monthly chunks; reconcile count variance |
| `dbo.ASIC2_Positions` | Prior-day transaction dependencies | **~210M rows** — controlled/chunked extraction mandatory |
| `dbo.ASIC2_Removed_OP_Partials` | ASIC2 lifecycle branches | ~315K rows |
| `dbo.Reg_LiquidtyAcount_SCD` | Hedge liquidity SCD validity | ~1.1K rows — full seed feasible |
| `dbo.Reg_MigrationInOut_Population` | Movement / reg-change replay | ~2.8M rows; chunk by `RunDate` |
| `dbo.Reg_RegulationInOutDailyData` | Regulation in/out replay | ~8.6M rows; chunk by `ReportDate` |
| `dbo.Reg_Regulation_Movments_Positions` | Step 6 / movement inputs | ~17.8M rows; chunk by `ReportDate` |

`MIFID2_Hedge_Report` and `MIFID2_NPD_TRAX` are **feasible full-history seed candidates**.  
`ASIC2_Positions` requires **controlled/chunked** extraction with per-chunk validation.

Detail: [historical_seed_inventory.md](historical_seed_inventory.md)

---

## Extraction rules

1. **Do not full-export `dbo.MIFID2_Report`** unless RegTech SME / Validation explicitly approves scope and storage. Validate using **selected baseline dates** only.

2. **`MIFID2_Hedge_Report` and `MIFID2_NPD_TRAX`** are feasible full-history seed candidates (chunked).

3. **`ASIC2_Positions`** is high-volume — controlled/chunked extraction mandatory; per-chunk row counts required.

4. **Format:** Prefer **Parquet** or **Delta**. Controlled **CSV** acceptable only for staging/manual seed testing (Type 3).

5. **Every extract manifest must include:**

   | Field | Required |
   | --- | --- |
   | Source server / database / table | Yes |
   | Extraction timestamp (UTC) | Yes |
   | Row count | Yes |
   | Min / max relevant date | Yes |
   | Schema / DDL or column list | Yes |
   | Checksum / hash (if available) | Yes |
   | Owner / contact | Yes |
   | Baseline scenario tag | Yes |
   | Extract type (1, 2, or 3) | Yes |

6. **No PII or raw extracts in Git.**

7. **PII-sensitive extracts** — approved secure storage only; access on need-to-know basis.

8. **Baseline evidence** — stored outside repo; docs reference summaries and manifest links only.

9. **`MIFID2_Hedge_Report.RecordID`** — load exact historical values on seed; do not regenerate.

10. **Source server reference:** `AZR-WE-BI-21` / `RegReportDB_Prod` (confirm with DBA if environment differs).

---

## Request template (copy to RegTech / Validation / DBA / DE)

```
=== SQL Server Baseline / Seed Extract Request ===

Request ID:        REQ-____-____
Request date:      YYYY-MM-DD
Requested by:      ____________________
Approval status:   OPEN | APPROVED | REJECTED

--- Scenario ---
Requested scenario:  [e.g. hedge_activity_day | npd_trax_retry_rejection_day | exclusion_excluded_cid]
Baseline scenario tag: SCEN-____
Requested report date(s): YYYY-MM-DD [, YYYY-MM-DD ...]
Date filter column:  ReportDate | RunDate | DateID | other: ________

--- Extract classification ---
Extract type:
  [ ] 1 — Baseline-date extract (selected report date parity)
  [ ] 2 — Full-history seed (stateful / history-dependent)
  [ ] 3 — Staging-only manual seed test (main.regtech_ops_stg; not production)

--- Tables requested ---
Final outputs (baseline-date):
  [ ] dbo.MIFID2_Customer
  [ ] dbo.MIFID2_RegChange_Customer
  [ ] dbo.MIFID2_Report
  [ ] dbo.MIFID2_ME_Report
  [ ] dbo.MIFID2_Removed_OP_Partials
  [ ] dbo.MIFID2_ETORO_Report
  [ ] dbo.MIFID2_Hedge_Report
  [ ] dbo.MIFID2_NPD_TRAX

Staging / reconciliation (baseline-date):
  [ ] dbo.MIFID2_ext_Customer
  [ ] dbo.MIFID2_ext_RegChange_Customer
  [ ] dbo.MIFID2_ext_Position
  [ ] dbo.MIFID2_ext_RegChange_Position
  [ ] dbo.MIFID2_ext_PositionChangeLog
  [ ] dbo.MIFID2_ext_Mirror
  [ ] dbo.MIFID2_ext_HedgeExecutionLog
  [ ] dbo.MIFID2_Failed_TRAX
  [ ] dbo.Reg_CurrencyPrice_Ext
  [ ] dbo.Reg_Ext_CurrencyPriceMaxDateWithSplit
  [ ] dbo.Reg_Ext_DailyMaxPrices
  [ ] dbo.Reg_Ext_T_PriceCandle60Min
  [ ] dbo.Reg_Ext_HistorySplitRatio
  [ ] dbo.Reg_Ext_Trade_GetInstrument
  [ ] dbo.Reg_Ext_Trade_InstrumentMetaData
  [ ] dbo.Reg_Ext_DictionaryCurrency
  [ ] dbo.Reg_Ext_DictionaryCurrencyType
  [ ] dbo.Reg_Instruments_ext
  [ ] dbo.Reg_MigrationInOut_Population
  [ ] dbo.Reg_RegulationInOutDailyData
  [ ] dbo.Reg_Regulation_Movments_Positions
  [ ] dbo.Reg_LiquidtyAcount_SCD
  [ ] dbo.Reg_Ext_LiquidityAccountID
  [ ] dbo.Reg_LiquidtyAcount_Ext
  [ ] dbo.Reg_HedgeServerToLiquidityAccount_Ext
  [ ] dbo.Reg_Ext_LiquidityProviders

Full-history seed only:
  [ ] dbo.MIFID2_Hedge_Report (full history)
  [ ] dbo.MIFID2_NPD_TRAX (full history)
  [ ] dbo.MIFID2_Failed_TRAX
  [ ] dbo.ASIC2_Transactions
  [ ] dbo.ASIC2_Positions (chunked)
  [ ] dbo.ASIC2_Removed_OP_Partials
  [ ] dbo.Reg_LiquidtyAcount_SCD
  [ ] dbo.Reg_MigrationInOut_Population
  [ ] dbo.Reg_RegulationInOutDailyData
  [ ] dbo.Reg_Regulation_Movments_Positions

--- Delivery ---
Output format:     Parquet | Delta | CSV (staging test only)
Chunking plan:     none | monthly by ReportDate | other: ________
Storage location:  [secure path — not Git]
PII classification: PII | non-PII | mixed
Owner:             ____________________
DBA / extract contact: ____________________
Evidence link:       [ticket / share / manifest URL — outside repo]

--- Validation expectations ---
See docs/validation_evidence_plan.md

--- Policy confirmations ---
[ ] No full MIFID2_Report export unless explicitly approved
[ ] No PII/raw extracts committed to Git
[ ] Hedge RecordID preserved exactly on seed load
[ ] NPD_TRAX remains final-flow last
[ ] Hedge final activation gated on RecordID registry
[ ] Final customer/NPD parity gated on unmasked PII (MAG-06)
```

---

## Ownership and approval

| Role | Responsibility | Status |
| --- | --- | --- |
| RegTech SME | Nominate scenario dates; approve exclusion/branch cases | **Pending** |
| Validation Owner | Approve baseline-date portfolio; sign MAG-16 evidence | **Pending** (MAG-16 OPEN) |
| DBA / SQL Server team | Execute extracts; provide manifests | **Pending** |
| DE / Data Platform | Landing zone; load seeds; migrate sources to `main.regtech` | **Pending** |
| Engineering | Load seeds to `main.regtech_ops_stg`; run gated validation SQL | **Pending** |

Decision register: D-23 (baseline dates and scoped extracts) — [remaining_decisions.md](remaining_decisions.md)

---

## Related documents

- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
- [historical_seed_inventory.md](historical_seed_inventory.md)
- [manual_seed_testing_plan.md](manual_seed_testing_plan.md)
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md) — Phase 5 baseline comparisons
