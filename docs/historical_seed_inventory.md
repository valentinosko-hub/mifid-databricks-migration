# Historical Seed Inventory (BI-21 MCP + Manual SQL Evidence)

## Purpose

Canonical inventory of **seed-critical** SQL Server objects in `RegReportDB_Prod.dbo` that require historical extraction into Databricks Ops staging before parity validation and module activation.

**Evidence sources:**

- BI-21 MCP metadata discovery (`user-mssql-bi21`, read-only tools against `AZR-WE-BI-21` / `RegReportDB_Prod`) — **2026-06-05**
- Manual SQL aggregate checks (read-only ADS) — evidence retained **outside this repository** (no PII, no raw query outputs in Git)

**Policy:** Seed all history required for reporting, retry logic, SCD validity, missed-trade back-reporting, identity continuity, and SQL Server baseline comparison. If minimum safe window cannot be proven, seed all available history. See [history_seed_requirements.md](history_seed_requirements.md).

**Status:** Metadata confirmed; extraction implementation and ownership remain **pending**.

---

## Seed inventory table

| Seed object | SQL Server source | Databricks seed target | Seed all history? | Date column | Primary / business key | Identity / RecordID | Row count | Min date / max date | Owner | Extraction method | Validation method | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `MIFID2_Hedge_Report` | `RegReportDB_Prod.dbo.MIFID2_Hedge_Report` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report` | **Yes** | `ReportDate` | Unique NCI: `(ReportDate, RegulationReportID, TransactionReferenceNumber)`; `RecordID` int NOT NULL | SQL Server identity: seed `100000001`, increment `1`, last `136314953`; historical `RecordID` must be preserved exactly; registry required for future allocation | MCP: **33,460,325**; manual aggregate: **33,524,034** (reconcile at extract) | **2022-07** – **2026-06** (monthly evidence outside repo) | Pending assignment | Chunked by `ReportDate` month; Parquet/Delta landing in secure storage; preserve `RecordID` on load | Row count vs SQL Server; duplicate `RecordID` = 0; duplicate business key = 0; `RecordID` range min/max; registry reconciliation; monthly distribution vs chunk plan | **Metadata confirmed** — extract pending |
| `MIFID2_NPD_TRAX` | `RegReportDB_Prod.dbo.MIFID2_NPD_TRAX` | `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` | **Yes** | `ReportDate` | Clustered unique PK: `(ReportDate, Entity, CID)` | No `RecordID`; latest-row logic by `(CID, RegulationID)` downstream | **4,576,382** | **2019-02** – **2026-06** (monthly evidence outside repo) | Pending assignment | Chunked by `ReportDate` month | Row count; duplicate PK check = 0; monthly distribution; `(CID, RegulationID)` latest-row coverage for parity windows | **Metadata confirmed** — extract pending |
| `ASIC2_Transactions` | `RegReportDB_Prod.dbo.ASIC2_Transactions` | `main.regtech_ops_stg.bi_output_regtechops_asic2_transactions` | **Yes** | `ReportDate` (clustered NCI) | Report-scoped business keys per module validation package | No identity column | MCP `count_rows`: **7,237,370**; `get_table_size`: **14,474,740**; manual count: **7,245,856** — **reconciliation required at extract** | **2024-09** – **2026-06** (monthly evidence outside repo) | Pending assignment | Chunked by `ReportDate` month | Row count reconciliation (MCP vs manual vs post-load); monthly distribution; key/null checks per Step 8 validation | **Metadata confirmed** — row-count discrepancy open; extract pending |
| `ASIC2_Positions` | `RegReportDB_Prod.dbo.ASIC2_Positions` | `main.regtech_ops_stg.bi_output_regtechops_asic2_positions` | **Yes** | `DateID` (NCI) | Position keys per Step 8 validation (`ReportDate` / position identifiers) | No identity column | **210,187,712** (~35.9 GB reserved) | Min/max **TBD** at extract (high-volume; monthly profiling recommended) | Pending assignment | **Chunked extraction required** (by `DateID` or equivalent month partitions) | Per-chunk row counts; sum vs SQL Server total; prior-day dependency checks for transaction parity | **Metadata confirmed** — chunked extract plan required |
| `ASIC2_Removed_OP_Partials` | `RegReportDB_Prod.dbo.ASIC2_Removed_OP_Partials` | `main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials` | **Yes** | `ReportDate` (typical; confirm at extract) | Keys per Step 8 validation | No identity column | **315,091** | Min/max **TBD** at extract | Pending assignment | Full or chunked by `ReportDate` | Row count; open/close branch checks | **Metadata confirmed** — extract pending |
| `Reg_LiquidtyAcount_SCD` | `RegReportDB_Prod.dbo.Reg_LiquidtyAcount_SCD` | `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd` | **Yes** | SCD validity columns (`StartDate` / `EndDate` or equivalent — confirm at extract) | SCD grain per Step 7 validation | No identity column | **1,120** | Validity window **TBD** at extract | Pending assignment | Full seed (small table); prefer incremental cutover only if parity windows preserved | SCD validity coverage; `IsLast` / removed-account behavior parity | **Metadata confirmed** — cutover plan pending |
| `Reg_MigrationInOut_Population` | `RegReportDB_Prod.dbo.Reg_MigrationInOut_Population` | `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` | **Yes** | `RunDate` (clustered index) | Migration snapshot keys per Step 6 validation | No identity column | **2,848,347** | Min/max **TBD** at extract | Pending assignment | Chunked by `RunDate` | Row count by `RunDate`; snapshot parity vs gold fallback if used | **Metadata confirmed** — extract pending |
| `Reg_RegulationInOutDailyData` | `RegReportDB_Prod.dbo.Reg_RegulationInOutDailyData` | `main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata` | **Yes** | `ReportDate` (clustered index) | Keys per downstream consumers | No identity column | **8,625,324** | Min/max **TBD** at extract | Pending assignment | Chunked by `ReportDate` | Row count by `ReportDate`; replay determinism checks | **Metadata confirmed** — extract pending |
| `Reg_Regulation_Movments_Positions` | `RegReportDB_Prod.dbo.Reg_Regulation_Movments_Positions` | `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions` | **Yes** | `ReportDate` (clustered index) | `(ReportDate, CID, PositionID)` per Step 6 validation | No identity column | **17,820,202** | Min/max **TBD** at extract | Pending assignment | Chunked by `ReportDate` | Row count; duplicate checks; branch composition by `RegulationID` | **Metadata confirmed** — extract pending |

---

## MCP metadata summary (all nine tables exist)

| Table | Columns | Reserved (MB) | Index / key notes |
| --- | ---: | ---: | --- |
| `MIFID2_Hedge_Report` | 96 | 6,389.51 | Clustered index + unique NCI on `(ReportDate, RegulationReportID, TransactionReferenceNumber)`; no FKs returned |
| `MIFID2_NPD_TRAX` | 39 | 1,107.48 | Clustered unique PK `(ReportDate, Entity, CID)`; NCIs around `AcceptedTRAX` |
| `ASIC2_Transactions` | 145 | 3,784.41 | NCI on `ReportDate` |
| `ASIC2_Positions` | 19 | 35,927.73 | NCI on `DateID` |
| `ASIC2_Removed_OP_Partials` | 24 | 43.38 | — |
| `Reg_LiquidtyAcount_SCD` | 9 | 0.21 | — |
| `Reg_MigrationInOut_Population` | 7 | 118.26 | Clustered index on `RunDate` |
| `Reg_RegulationInOutDailyData` | 23 | 813.02 | Clustered index on `ReportDate` |
| `Reg_Regulation_Movments_Positions` | 20 | 2,027.70 | Clustered index on `ReportDate` |

---

## Manual SQL aggregate highlights (evidence outside repo)

### `MIFID2_Hedge_Report`

- Identity: seed `100000001`, increment `1`, last value `136314953`
- `RecordID` range: min `100253434`, max `136314953`; distinct = total rows; **duplicate RecordID rows = 0**
- Business key `(ReportDate, RegulationReportID, TransactionReferenceNumber)`: **duplicate_row_count = 0**
- Monthly distribution: **2022-07** through **2026-06** — use for extraction chunk planning

### `MIFID2_NPD_TRAX`

- PK `(ReportDate, Entity, CID)`: **duplicate_row_count = 0**
- Monthly distribution: **2019-02** through **2026-06**

### `ASIC2_Transactions`

- Manual row count: **7,245,856** (narrows MCP `count_rows` vs `get_table_size` discrepancy; post-extract reconciliation still required)
- Monthly distribution: **2024-09** through **2026-06**

---

## Related documents

- [history_seed_requirements.md](history_seed_requirements.md) — approved seed policy by module
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md) — baseline dates and extract constraints
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md) — Hedge `RecordID` registry
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md) — execution sequence after blockers
- [remaining_decisions.md](remaining_decisions.md) — open decisions and ownership gaps
