# Manual CSV Seed Testing Plan (Staging-Only)

## Purpose

Documents the **manual CSV seed testing package** for RegTech staging validation in `main.regtech_ops_stg`. This is **staging-only** — not production-grade, not final regulatory parity, and not a substitute for DE's general SQL Server → `main.regtech` migration pipeline.

**SQL package:** `databricks/sql/11_seed_testing/`

---

## Scope boundaries

### In scope

- Gated/commented SQL templates to load manually exported CSV seed files into **temporary staging seed test tables**
- SELECT-only validation SQL for row counts, keys, dates, and RecordID stats
- Initial targets: `MIFID2_NPD_TRAX` (feasible first test) and `MIFID2_Hedge_Report`

### Out of scope

- Creating production tables or writing to `main.regtech`
- Regulatory CSV delivery, SFTP, TRAX upload, or response handling
- Storing CSV files, extracts, PII samples, or credentials in Git
- Final `bi_output_regtechops_mifid2_npd_trax` / `bi_output_regtechops_mifid2_hedge_report` module activation (remains gated)

---

## Environment policy

| Setting | Value |
| --- | --- |
| Target catalog | `main` |
| Target schema | `main.regtech_ops_stg` |
| Generated object prefix | `bi_output_regtechops_` |
| Manual seed test tables | `bi_output_regtechops_seed_test_*` |
| CSV source | Approved secure ADLS / Databricks Volume path — **not Git** |
| Read sources (module runs) | `main.regtech` when DE-migrated sources exist |
| Write target | `main.regtech_ops_stg` only |

---

## Manual seed test tables

| Table | Purpose | SQL Server reference count (evidence outside repo) |
| --- | --- | --- |
| `main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax` | Temporary NPD CSV seed test asset | ~4,576,382 (MCP); validate against export manifest |
| `main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report` | Temporary Hedge CSV seed test asset | ~33,524,034 (manual aggregate); validate against export manifest |

These tables are **temporary test assets**. They support staging smoke tests and structural validation only. They do **not** close final parity gates for Step 14/15 module activation.

---

## DE production migration (authoritative)

Data Engineering migrates SQL Server / `RegReportDB_Prod` tables into **`main.regtech`** via the **general DE pipeline**. That path remains authoritative for production source migration.

RegTech staging jobs in this repository:

- May **read** `main.regtech` once DE-migrated sources are available
- Use manually loaded seed test tables only for **staging history/retry experiments** before full seed pipeline is operational
- Will be adapted by DE for production criteria in a **separate program**

---

## Secure CSV handling

1. Export CSV from SQL Server / approved read-only tooling into **approved secure storage** (ADLS or Databricks Volume).
2. **Do not** commit CSV files, extracts, PII samples, or raw query outputs to Git.
3. **NPD_TRAX** exports may contain PII-sensitive fields (`FirstNames`, `Surnames`, `DateofBirth`, `PIN`, etc.) — use restricted ACLs; do **not** place in broad/shared unsecured locations.
4. Record export manifest externally: file path, row count, min/max `ReportDate`, export timestamp, approver.
5. Replace `{{approved_*}}` placeholders in SQL templates with approved paths at run time only.

---

## Execution sequence

| Step | Action | Artifact |
| --- | --- | --- |
| 1 | Obtain approved secure CSV path and SQL Server export row count | External manifest (not Git) |
| 2 | Review `databricks/sql/11_seed_testing/00_seed_testing_readme.md` | Package readme |
| 3 | Uncomment/run `01_create_manual_seed_external_tables.sql` only after path approval | External CSV + seed test Delta tables |
| 4 | Uncomment/run load template (`02_*` or `03_*`) for target table | Loaded seed test table |
| 5 | Run `04_manual_seed_validation.sql` (SELECT-only) | Validation evidence |
| 6 | Document results externally; do not claim final NPD/Hedge parity | Staging evidence only |

Run under `development_structural_test` mode per [workflow_execution_runbook.md](workflow_execution_runbook.md).

---

## Per-table validation requirements

### `MIFID2_NPD_TRAX` seed test

- CSV with header row
- Schema/column contract vs SQL Server DDL
- Row count vs SQL Server exported count
- Duplicate check on `(ReportDate, Entity, CID)`
- Field presence checks: `AcceptedTRAX`, `ErrorDescription`, `FailedSinceDate`
- Final Step 15 NPD activation **remains gated** (PII, history, MAG gates)

### `MIFID2_Hedge_Report` seed test

- CSV with header row
- Schema/column contract vs SQL Server DDL
- Row count vs SQL Server exported count
- Duplicate `RecordID` check (expect 0)
- Duplicate business key on `(ReportDate, RegulationReportID, TransactionReferenceNumber)` (expect 0)
- `RecordID` min/max vs observed SQL Server range (min `100253434`, max `136314953`)
- Final Step 14 Hedge activation **remains gated** (RecordID registry, TRN parity, MAG gates)

### Hedge RecordID registry seed design input (staging tests)

When DE-migrated historical source is not yet available, approved staging seed table
`main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report` may be used as
the **design-time source** placeholder for the gated registry seed template:

- `databricks/sql/08_outputs/10_hedge_recordid_registry/02_hedge_recordid_seed_from_sql_server.sql`

This supports registry/control testing design only and does not close final Step 14 gates.

---

## Safety rules

1. All CREATE / COPY / INSERT templates are **commented/gated** — uncomment only with explicit approval.
2. Use explicit `LOCATION` placeholders; paths must be approved and secure.
3. No production tables; no writes to `main.regtech`.
4. No delivery/upload/response logic in seed testing package.
5. Masked customer fallback remains development/structural-test only.
6. `TransactionReferenceNumber` and CFI / `InstrumentClassification` exact SQL Server parity requirements remain unchanged for final activation.

---

## Related documents

- [historical_seed_inventory.md](historical_seed_inventory.md)
- [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md) (Phase 0.5)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
- [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md)
- `databricks/sql/08_outputs/10_hedge_recordid_registry/README.md`
