# SQL Server Baseline Extract Plan (RegReportDB_Prod)

## Purpose

Documents how SQL Server baseline extracts and historical seed loads should be planned for phase-1 MiFID Databricks parity — **planning only**; no execution performed from this repository.

**Evidence:** BI-21 MCP metadata (2026-06-05) and manual SQL aggregates (evidence outside repo). Inventory detail: [historical_seed_inventory.md](historical_seed_inventory.md).

**Staging context:** Approved CSV seed extracts may be loaded into `main.regtech_ops_stg` seed tables for staging tests. RegTech staging jobs are not production-grade; DE migrates SQL Server sources to `main.regtech` via the general pipeline and will later adapt staging jobs for production.

---

## Environment policy (staging loads)

| Setting | Value |
| --- | --- |
| Read sources (when available) | `main.regtech` and other DE-migrated catalogs |
| Write target | `main.regtech_ops_stg` only |
| Generated object prefix | `bi_output_regtechops_` |
| Seed object prefix | `bi_output_regtechops_seed_` |
| Control/registry prefix | `bi_output_regtechops_` |

---

## Scope boundaries

### In scope

- Historical **seed** loads for stateful / history-dependent tables (see inventory)
- **Scoped baseline** extracts for parity comparison on selected report dates
- Row-count and key validation requirements
- Secure landing-zone expectations

### Out of scope (unless explicitly approved)

- Full export of `dbo.MIFID2_Report` — **do not full-export** unless RegTech SME / Validation explicitly approves scope and storage; use selected baseline dates only
- Regulatory delivery: CSV export to TRAX paths, 7z, SFTP, TRAX upload/response
- Production deployment to `main.regtech` from RegTech staging jobs
- Storing seed CSVs, PII samples, or raw query outputs in Git

### In scope for staging tests

- Approved CSV **seed** extracts landed in secure storage and loaded into `main.regtech_ops_stg` with `bi_output_regtechops_seed_` or `bi_output_regtechops_seed_test_` prefix
- Initial feasible seed test: `MIFID2_NPD_TRAX` (~4.6M rows) — staging validation only until PII and MAG gates close
- Manual CSV seed testing SQL package: `databricks/sql/11_seed_testing/` — see [manual_seed_testing_plan.md](manual_seed_testing_plan.md)
- Temporary manual seed test tables: `bi_output_regtechops_seed_test_mifid2_npd_trax`, `bi_output_regtechops_seed_test_mifid2_hedge_report`

---

## Baseline date strategy

### Huge final output tables

For large final outputs (e.g. `MIFID2_Report`, `MIFID2_Hedge_Report`, `MIFID2_NPD_TRAX`, `MIFID2_ETORO_Report`):

- Select **explicit baseline report dates** per module (MAG-16 / D-23) rather than defaulting to full-table export
- Document chosen dates, row-count expectations, and comparison windows in validation evidence (external log)
- Expand baseline windows only when SME/Validation requests older parity proof

### Stateful / history-dependent tables — full seed

These require **full available history** seed (approved policy):

| Object | Rationale | Volume note |
| --- | --- | --- |
| `MIFID2_Hedge_Report` | `RecordID` continuity, missed-trade back-reporting, registry | ~33.5M rows; monthly chunks **2022-07 – 2026-06** |
| `MIFID2_NPD_TRAX` | Retry / REPL / latest-row logic | ~4.6M rows; monthly chunks **2019-02 – 2026-06** |
| `ASIC2_Transactions` | ETORO parity windows | ~7.2M rows (reconcile counts); monthly **2024-09 – 2026-06** |
| `ASIC2_Positions` | Prior-day transaction dependencies | **~210M rows** — **chunked extraction mandatory** |
| `ASIC2_Removed_OP_Partials` | ASIC2 lifecycle branches | ~315K rows |
| `Reg_LiquidtyAcount_SCD` | Hedge liquidity validity | ~1.1K rows — full seed feasible |
| `Reg_MigrationInOut_Population` | Movement / reg-change replay | ~2.8M rows; chunk by `RunDate` |
| `Reg_RegulationInOutDailyData` | Regulation in/out replay | ~8.6M rows; chunk by `ReportDate` |
| `Reg_Regulation_Movments_Positions` | Step 6 / Step 12 movement inputs | ~17.8M rows; chunk by `ReportDate` |

`MIFID2_Hedge_Report` and `MIFID2_NPD_TRAX` are **feasible full-history seed candidates** with month-based chunking.

`ASIC2_Positions` is a **high-volume full-history seed candidate** requiring chunked extraction and per-chunk validation before declaring load complete.

---

## Extraction format expectations

| Requirement | Detail |
| --- | --- |
| Format | Columnar preferred (Parquet) or Delta staging files; preserve SQL Server types where parity-sensitive |
| Chunking | Partition extracts by `ReportDate`, `RunDate`, or `DateID` month (per inventory date columns) |
| Identity columns | `MIFID2_Hedge_Report.RecordID` — **load exact values**; do not regenerate on seed |
| Compression | ZSTD or Snappy acceptable; document codec in runbook |
| Manifest | Per-chunk row count, min/max date, extract timestamp, source server (`AZR-WE-BI-21`) |
| Naming | `{table}_{yyyymm}_part{n}.parquet` or equivalent; no customer-identifying samples in repo paths |

---

## Row-count validation requirements

1. **Pre-load:** SQL Server count per chunk and table total (manual SQL or approved tooling)
2. **Post-load:** Databricks count per chunk and table total
3. **Reconciliation:** Document and resolve discrepancies before module activation

Known discrepancies to reconcile at extract:

| Table | MCP `count_rows` | Other counts | Action |
| --- | ---: | --- | --- |
| `MIFID2_Hedge_Report` | 33,460,325 | Manual aggregate: 33,524,034 | Reconcile definition (filters, snapshot time) before sign-off |
| `ASIC2_Transactions` | 7,237,370 | `get_table_size`: 14,474,740; manual: 7,245,856 | Use manual count + monthly sums as primary extract validation; investigate MCP tool variance |

Validation also includes:

- Duplicate business-key checks (zero expected for Hedge and NPD per manual SQL)
- `RecordID` uniqueness and range checks for Hedge (see [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md))
- Monthly distribution sums equal table total

---

## Secure storage and CSV seed policy

- Land extracts and seed CSVs in **approved secure storage** (Databricks volume, ADLS, or equivalent) — **never Git**
- Load seeds into `main.regtech_ops_stg` tables prefixed `bi_output_regtechops_seed_`
- PII-sensitive extracts must remain in approved secure locations only
- Restrict access to DE/Data Platform and Validation principals on need-to-know basis
- No `.env`, credentials, or connection secrets in repository
- No PII field samples in documentation or commit history
- Retain monthly distribution evidence outside repo; reference summaries only in docs

---

## `dbo.MIFID2_Report` policy

- **Do not** perform full-history export of `dbo.MIFID2_Report` unless explicitly approved
- Baseline comparisons for Step 12 should use **selected report dates** and scoped extracts
- If full seed is later approved, treat as separate MAG-16 scope change with storage and PII review

---

## Execution ownership (pending)

| Activity | Owner status |
| --- | --- |
| Extract job auth / ADS read access | Pending DE assignment |
| Landing path and retention | Pending Data Platform |
| Load into `main.regtech_ops_stg` | Pending Engineering (gated templates only) |
| Validation evidence capture | Pending Validation |

---

## Related documents

- [historical_seed_inventory.md](historical_seed_inventory.md)
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
- [history_seed_requirements.md](history_seed_requirements.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md)
- [remaining_decisions.md](remaining_decisions.md) (D-23 baseline scope)
