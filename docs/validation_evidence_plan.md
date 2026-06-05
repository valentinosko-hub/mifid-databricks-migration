# Validation Evidence Plan — SQL Server Baseline Parity

## Purpose

Defines **validation expectations** when comparing SQL Server `RegReportDB_Prod` baselines to Databricks staging outputs in `main.regtech_ops_stg` (and DE-migrated reads from `main.regtech`).

**Status:** Planning only — no validation execution from this repository.  
**Repository:** Not production-ready.

**Inputs:** Baseline-date extracts and full-history seeds per [baseline_scenario_request.md](baseline_scenario_request.md).

---

## Evidence principles

| Principle | Detail |
| --- | --- |
| Storage | All raw extracts and comparison outputs **outside Git** |
| PII | Customer baselines require secure storage; final parity gated on MAG-06 |
| Labeling | Tag evidence with baseline scenario ID, report date, extract type, and run timestamp |
| Staging vs final | Staging seed tests are **structural evidence only** — not final parity sign-off |
| Masked customer | Development/structural tests only; no final parity claim |

---

## Standard validation checks (all tables where applicable)

| Check | Description | Pass criteria (default) |
| --- | --- | --- |
| Row-count comparison | SQL Server extract count vs Databricks table count for same scope | Match or documented accepted delta |
| Schema comparison | Column names, types, nullability | Required columns present; type-compatible |
| Required-column comparison | Module `*_validation.sql` required-column manifests | No missing required columns |
| Duplicate-key checks | Business keys and PKs per module | Zero duplicates unless documented exception |
| Null critical-key checks | `ReportDate`, `CID`, `RegulationReportID`, `TransactionReferenceNumber`, etc. | Zero nulls on critical keys |
| SQL Server vs Databricks anti-joins | Rows in SSMS not in DBX and vice versa for scoped date | Zero unexplained rows or SME-approved delta |
| Date-range coverage | Min/max `ReportDate` (or equivalent) | Matches extract manifest |

Capture results in external evidence log; reference ticket/manifest link in MAG-16 record.

---

## Aggregate validation checks

Run where module SQL supports grouped reconciliation:

| Dimension | Tables / modules |
| --- | --- |
| `ReportDate` | All final outputs; ext staging; ASIC2 |
| `RegulationReportID` | Hedge, report family, regulation movements |
| `RegChange` | Customer/reg-change outputs and ext tables |
| `OpenORClose` | Report and position lifecycle branches |
| `rowSource` | Outputs with multi-source composition |
| `Entity` / branch | NPD_TRAX, ME report, branch scenarios |
| `RegulationID` | Regulation movements, branch filters |

Aggregates should match between SQL Server baseline slice and Databricks output for the **same approved baseline date**.

---

## Exact-comparison requirements (hard parity)

These fields require **exact** SQL Server value match — uniqueness or approximate match is **not** sufficient:

| Field / behavior | Module | Gate / decision |
| --- | --- | --- |
| Hedge `TransactionReferenceNumber` | `MIFID2_Hedge_Report` | D-13; MAG-13 |
| CFI / `InstrumentClassification` | Instrument/report paths | D-14; MAG-15 |
| Hedge `RecordID` historical preservation | `MIFID2_Hedge_Report` seed + registry | D-12; MAG-12; [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md) |
| NPD `AcceptedTRAX` / `Action` / `RowNum` behavior | `MIFID2_NPD_TRAX` | MAG-10; latest-row and retry logic |

### Hedge RecordID

- Seed must preserve SQL Server identity values exactly (`100000001` seed, historical range through `136314953`).
- Registry allocation applies only to **new** keys after seed — not historical rows.
- Validate: duplicate `RecordID` = 0; duplicate business key `(ReportDate, RegulationReportID, TransactionReferenceNumber)` = 0.

### NPD_TRAX

- Validate PK `(ReportDate, Entity, CID)` uniqueness.
- For retry/rejection scenarios: compare `AcceptedTRAX`, `Action`, row ordering / `RowNum` behavior against SQL Server baseline for nominated dates.
- `MIFID2_Failed_TRAX` reconciliation depends on NPD history context — run after NPD seed validation.
- NPD remains **final-flow last**; baseline evidence on selected dates does not close full-history parity alone.

---

## Validation by extract type

### Type 1 — Baseline-date extract

1. Confirm extract manifest (row count, min/max date, scenario tag).
2. Run row-count and schema checks for scoped `ReportDate`.
3. Run anti-joins SQL Server ↔ Databricks for scoped keys.
4. Run aggregate checks by `ReportDate`, `RegulationReportID`, `RegChange`, `OpenORClose`, `rowSource` where applicable.
5. Run exact-comparison checks for hedge TRN, CFI, NPD fields on relevant scenarios.
6. Record evidence link; update MAG-16 when Validation Owner accepts.

### Type 2 — Full-history seed

1. Pre-load SQL Server count per chunk and table total.
2. Post-load Databricks count per chunk and table total.
3. Reconcile chunk sums to table total; resolve known variances (e.g. Hedge, ASIC2_Transactions).
4. Duplicate-key and RecordID range checks (Hedge, NPD).
5. SCD validity coverage (`Reg_LiquidtyAcount_SCD`).
6. Monthly distribution vs chunk plan.
7. Do not activate Hedge report DML until registry validation passes.

### Type 3 — Staging-only manual seed test

1. Load via `databricks/sql/11_seed_testing/` templates only.
2. Run `04_manual_seed_validation.sql` (SELECT-only).
3. Label results **staging structural evidence only**.
4. Does not close MAG-10, MAG-12, or MAG-06.

---

## Scenario-specific validation focus

| Scenario tag | Primary checks |
| --- | --- |
| `normal_trading_day` | Core row counts; report shape |
| `high_volume_day` | Scale aggregates; no orphan inflation |
| `regchange_activity_day` | RegChange customer/position ext + outputs |
| `hedge_activity_day` | TRN exact match; hedge execution log |
| `npd_trax_retry_rejection_day` | AcceptedTRAX / Action / RowNum |
| `customer_identity_change_day` | Customer/reg-change deltas (PII-gated final) |
| `partial_close_removed_op_day` | Removed OP partials counts and keys |
| `split_activity_day` | HistorySplitRatio; split-adjusted prices |
| `futures_activity_day` | Classification and instrument branches |
| `etoro_asic2_activity_day` | ETORO report; ASIC2 transaction/position slices |
| `same_day_open_close_day` | OpenORClose distribution |
| `missed_trade_back_reporting` | Hedge RecordID continuity |
| `branch_uk_fca` / `branch_eu` / `branch_sc` / `branch_me` | Branch-filtered aggregates |
| `exclusion_excluded_cid` / `exclusion_excluded_instrument` / `exclusion_excluded_position_trn` | Exclusion logic; zero excluded rows in outputs |

---

## SQL / doc references

| Area | Reference |
| --- | --- |
| Module validation | `databricks/sql/*_validation.sql` per module |
| Cross-module | `databricks/sql/09_validation/07_*`, `08_*`, `09_*` |
| Workflow gates | `databricks/sql/10_workflow/gates/` |
| Seed validation | `databricks/sql/11_seed_testing/04_manual_seed_validation.sql` |
| Hedge registry | `databricks/sql/08_outputs/10_hedge_recordid_registry/04_hedge_recordid_validation.sql` |
| Execution order | [final_validation_execution_plan.md](final_validation_execution_plan.md) |
| Known deltas | [known_differences.md](known_differences.md) (when populated) |

---

## Approval and gates

| Gate | Requirement |
| --- | --- |
| MAG-16 | SQL Server baseline comparison approval — Validation Owner + SQL Server team |
| MAG-10 | NPD_TRAX history/cutover — before final NPD activation |
| MAG-12 | Hedge RecordID strategy — before Hedge activation |
| MAG-13 | Hedge TransactionReferenceNumber parity |
| MAG-15 | CFI / InstrumentClassification parity |
| MAG-06 | Unmasked PII — before final customer/NPD parity |

---

## Related documents

- [baseline_scenario_request.md](baseline_scenario_request.md)
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
- [historical_seed_inventory.md](historical_seed_inventory.md)
- [manual_approval_gates.md](manual_approval_gates.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md) — Phase 5
