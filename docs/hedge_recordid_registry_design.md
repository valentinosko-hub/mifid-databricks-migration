# Hedge RecordID Registry Design

## Purpose

Design documentation for `MIFID2_Hedge_Report.RecordID` allocation continuity between SQL Server and Databricks — **design only**; no registry implementation in this phase.

**Evidence:** Manual SQL aggregates on `RegReportDB_Prod.dbo.MIFID2_Hedge_Report` (2026-06-05; evidence outside repo). MCP metadata confirms `RecordID` int NOT NULL and unique NCI on `(ReportDate, RegulationReportID, TransactionReferenceNumber)`.

**Decision:** D-12 / MAG-12 — direction approved; natural-key final signoff pending SME.

---

## SQL Server identity metadata (observed)

| Property | Value |
| --- | --- |
| `seed_value` | `100000001` |
| `increment_value` | `1` |
| `last_value` | `136314953` |

Historical SQL Server `RecordID` values **must be preserved exactly** on seed load. Databricks must not re-sequence or regenerate historical IDs.

---

## Observed historical RecordID range

| Metric | Value |
| --- | --- |
| `min_recordid` | `100253434` |
| `max_recordid` | `136314953` |
| `total_rows` | `33,524,034` |
| `distinct_recordid` | `33,524,034` |
| `duplicate_recordid_rows` | **0** |

Note: MCP `count_rows` reported `33,460,325` — reconcile at extract time; manual aggregate used for registry design.

---

## Business key uniqueness (observed)

Key checked: `(ReportDate, RegulationReportID, TransactionReferenceNumber)`

| Metric | Value |
| --- | --- |
| `duplicate_row_count` | **0** |
| `duplicate_group_count` | **0** |

This key is the **proposed registry natural key** for mapping trades to existing `RecordID` values across reruns and back-reporting.

---

## Registry requirements

### Core rules

1. **Preserve** all historical SQL Server `RecordID` values on initial seed
2. **Map** each trade to `RecordID` via natural business key (proposed: `ReportDate` + `RegulationReportID` + `TransactionReferenceNumber`)
3. **Reuse** existing `RecordID` when the same trade appears on rerun (no reassignment)
4. **Allocate** new `RecordID` only for genuinely new or back-reported missed trades
5. **Continue** future allocation from `MAX(RecordID) + 1` after seed (expected next: `136314954` based on observed max)

### Persistent control table

A **persistent registry / control table** is required in `main.regtech_ops_stg` (exact name TBD at implementation). It must survive reruns and support audit.

**Simple per-run `row_number()` allocation is not acceptable** — it would break SQL Server parity and missed-trade identity continuity.

### Proposed registry columns (illustrative)

| Column | Purpose |
| --- | --- |
| `record_id` | Allocated / preserved `RecordID` |
| `report_date` | Natural key component |
| `regulation_report_id` | Natural key component |
| `transaction_reference_number` | Natural key component |
| `source_system` | e.g. `SQL_SERVER_SEED`, `DATABRICKS_NEW` |
| `first_seen_run_id` | Provenance |
| `last_seen_run_id` | Rerun tracking |
| `created_at` / `updated_at` | Audit |

Exact schema is an implementation task gated by MAG-12 closure.

---

## Validation checks (required before Hedge activation)

| Check | Pass criteria |
| --- | --- |
| Duplicate `RecordID` | Zero duplicates in output and registry |
| Duplicate business key | Zero duplicate groups on natural key |
| Max `RecordID` continuity | New allocations strictly greater than seeded max unless reusing known ID |
| No reassignment on rerun | Same natural key → same `RecordID` across runs |
| Missing registry rows | Every output row with new allocation has registry entry |
| Registry / output reconciliation | Output `RecordID` set matches registry for seeded + new rows |

Run validation via Step 14B4 packages after registry exists; capture evidence externally.

---

## Relationship to `TransactionReferenceNumber` parity (D-13)

- `TransactionReferenceNumber` must match SQL Server/SSMS values **exactly** (hard parity)
- Natural key includes `TransactionReferenceNumber`; expression drift breaks both parity and registry lookup
- Registry design assumes TRN values are stable for a given trade once reported

---

## Remaining SME question

**Confirm final natural key** and whether any additional fields are required for rerun / back-reporting identity (e.g. branch-specific qualifiers, provider execution id normalization, or regulation-report variant fields).

Until signoff:

- Use `(ReportDate, RegulationReportID, TransactionReferenceNumber)` as the **working** natural key
- Document any SME-approved extensions in this file and close D-12 / MAG-12

---

## Related documents

- [historical_seed_inventory.md](historical_seed_inventory.md)
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
- [history_seed_requirements.md](history_seed_requirements.md) (Step 14)
- [remaining_decisions.md](remaining_decisions.md) (D-12, D-13)
- [regtech_sme_decision_list.md](regtech_sme_decision_list.md) (Item 9)
