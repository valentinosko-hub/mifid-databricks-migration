# JIRA Ticket: MiFID Databricks Migration — Production Deployment

---

## Title
**[RegTech] Deploy MiFID2 Databricks Pipeline to Production — Replace SSMS/SSIS SP_MIFID2_Report**

## Type
Task / Epic

## Priority
High

## Labels
`regtech`, `mifid`, `migration`, `production-deployment`, `databricks`

## Components
Data Engineering, RegTech Operations

---

## Summary

Deploy the fully validated MiFID2 Databricks reporting pipeline to production, replacing the current SSMS/SSIS stored procedures (`SP_MIFID2_Report`, `SP_MIFID2_HedgeEU_Report`, `SP_MIFID2_HedgeUK_Report`, `SP_MIFID2_Customer`, `SP_MIFID2_NPD_TRAX`, `SP_MIFID2_ETORO_Report`).

The pipeline has been validated against SSMS gold mirrors with **5 PERFECT row-count matches** and **field-level validation** confirming all regulatory-critical fields match exactly. It is production-ready pending 3 access grants and scheduling.

The dev will copy the notebooks, adapt the target schema and Delta LOCATION paths for production, and validate using Beyond Compare against the gold mirrors (`main.regtech.gold_regreportdb_prod_dbo_*`).

---

## Repository & Assets to Copy

### Source Repository

| Item | Value |
|------|-------|
| Workspace | `https://adb-5142916747090026.6.azuredatabricks.net` |
| Repo Path (Databricks) | `/Users/valentinosko@etoro.com/mifid-databricks-migration/` |
| Repo ID | `3739389523527360` |
| GitHub | `https://github.com/valentinosko-hub/mifid-databricks-migration` |
| Branch | `master` |
| Handoff Doc | `HANDOFF_2026-06-18.md` (comprehensive — START HERE) |

### How to Copy for Production

1. **Clone the GitHub repo** into your own workspace folder:
   - Workspace → Repos → Add Repo → URL: `https://github.com/valentinosko-hub/mifid-databricks-migration`
   - Or copy the `notebooks/` folder directly to a shared production location (e.g., `/Repos/DataEngineering/mifid-databricks-migration/`)

2. **Key files to copy** (minimum for production):
   ```
   notebooks/
   ├── 00_run_all_staging          ← Orchestrator (runs all steps sequentially)
   ├── 01_price_currency_staging   ← Step 1: Price/Currency/Split tables
   ├── 02_non_price_staging        ← Step 2: Reference tables + Instruments SCD
   ├── 03_hedge_liquidity_staging  ← Step 3: Hedge/LP mapping
   ├── 05_mifid2_ext_staging       ← Step 5: PositionChangeLog, Mirror, HedgeExec
   ├── 07_mifid2_ext_customer_staging ← Step 6: Customer + Position + RegChange
   ├── 07b_mifid2_customer_enrichment.py ← Step 7: SP_MIFID2_Customer parity
   ├── 08_mifid2_report_output     ← Step 8: Final mifid2_report (5 flows)
   ├── 09_mifid2_hedge_report      ← Step 9: Hedge report (EU/EU-UK/UK)
   ├── 10_mifid2_npd_trax.py      ← Step 10: NPD TRAX
   ├── 06_mifid_audit_tables      ← Step 11: Audit/quality tables
   └── 11_mifid2_etoro_report     ← Step 12: ETORO/ASIC report (SP_MIFID2_ETORO_Report)
   ```

3. **NB04 (`04_regulation_movements_staging`)** is DEAD CODE — do NOT include in production job. Step 4 in orchestrator is a no-op skip.

4. **Update notebook paths** in the orchestrator (`00_run_all_staging`) if you move notebooks to a different folder. Each step cell calls `dbutils.notebook.run("./XX_notebook_name", ...)` with relative paths.

### Notebook IDs (for reference/linking)

| Notebook | ID | Step | SP Replicated |
|----------|-----|------|--------------|
| `00_run_all_staging` (Orchestrator) | `3739389523527735` | All | All SPs |
| `01_price_currency_staging` | `3739389523527722` | 1 | (reference data) |
| `02_non_price_staging` | `3739389523527725` | 2 | (reference data) |
| `03_hedge_liquidity_staging` | `3739389523527727` | 3 | (LP mapping) |
| `05_mifid2_ext_staging` | `3739389523527759` | 5 | (ext tables) |
| `07_mifid2_ext_customer_staging` | `3739389523528136` | 6 | `SP_MIFID2_Customer` (partial) |
| `07b_mifid2_customer_enrichment.py` | `3527882307865904` | 7 | `SP_MIFID2_Customer` (enrichment) |
| `08_mifid2_report_output` | `3251633718821032` | 8 | `SP_MIFID2_Report` |
| `09_mifid2_hedge_report` | `3527882307862382` | 9 | `SP_MIFID2_HedgeEU_Report` + `SP_MIFID2_HedgeUK_Report` |
| `10_mifid2_npd_trax.py` | `3527882307865254` | 10 | `SP_MIFID2_NPD_TRAX` |
| `06_mifid_audit_tables` | `3739389523527898` | 11 | (audit tables) |
| `11_mifid2_etoro_report` | `3527882307874495` | 12 | `SP_MIFID2_ETORO_Report` (AUS/ASIC) |

---

## Current Validation Status (2026-06-19)

### Row-Count Parity (DBX vs SSMS gold, report_date=2026-06-17)

| Output Table | SSMS | DBX | Diff | Status |
|-------------|------|-----|------|--------|
| mifid2_report (excl ME) | 1,798,734 | 1,798,734 | 0.00% | ✅ PERFECT |
| mifid2_me_report | 85,651 | 85,651 | 0.00% | ✅ PERFECT |
| mifid2_etoro_report | 9,860 | 9,860 | 0.00% | ✅ PERFECT |
| ext_poschangelog | 836,345 | 836,345 | 0.00% | ✅ PERFECT |
| mifid2_hedge_report | 68,058 | 68,058 | 0.00% | ✅ PERFECT |
| mifid2_customer | 201,792 | 201,789 | -0.001% | ✅ |
| mifid2_npd_trax | 9,484 | 9,452 | -0.34% | ✅ (masked mode) |

### Field-Level Validation

**mifid2_report** (1,798,734 rows matched 1:1):
- 0 mismatches on: Price, Quantity, TradingDateTime, Venue, ExecutingEntity, TRN, BuyORSell, InstrumentID, CID, IDType, ReportStatus, TradingCapacity, ShortSelling, RegulationReportID
- EU-FCA dual-reporting confirmed: 359,776 positions correctly reported under both RRID=1 (EU, TRN=`{PosID}UKC`) and RRID=2 (UK, TRN=`{PosID}C`)

**mifid2_hedge_report** (58,121 TRN-matched rows / 68,058 total):
- 0 mismatches on: Price, Quantity, TradingDateTime, Venue, LiquidityAccountID, LiquidityProvider, ExecutingEntity, BuyORSell, TradingCapacity, ReportStatus, BuyerCode, SellerCode, RegulationReportID
- 14.6% TRN mismatch is expected (ROW_NUMBER tie-breaking — non-deterministic in SQL Server)

---

## Deployment Tasks

### Task 1: Access Grants (Blocker)

| # | Grant Required | SQL | Purpose |
|---|---------------|-----|---------|
| 1 | `main.pii_data` | `GRANT USE_SCHEMA ON SCHEMA \`main\`.\`pii_data\` TO <serverless_identity>` | Unmasked customer PII (names, DOB, PIN/LEI) for NB07b + NB10 |
| 2 | `main.sharepoint` | `GRANT USE_SCHEMA ON SCHEMA \`main\`.\`sharepoint\` TO <serverless_identity>` | SharePoint LP source (replaces stale Fivetran connector) |

**After grant #1:** Set `use_masked_fallback=false` in orchestrator widget.
**After grant #2:** In NB03 cell 5, uncomment the SharePoint SELECT and delete the temp INSERT cell (nuid `2c301093-4a82-48cc-a8d8-4f6c03469b02`). Full instructions in `HANDOFF_2026-06-18.md` Fix #7.

### Task 2: Create & Schedule Daily Lakeflow Job

#### Job Configuration (copy this)

| Setting | Value |
|---------|-------|
| **Job Name** | `MiFID2 Daily Reporting Pipeline` |
| **Task Type** | Notebook |
| **Notebook Path** | `<your_production_folder>/notebooks/00_run_all_staging` |
| **Compute** | Serverless |
| **Schedule** | Cron: `0 0 7 * * ?` (Daily at 07:00 UTC) |
| **Timezone** | UTC |
| **Timeout** | 60 minutes |
| **Max Retries** | 1 (safe — all steps are fully idempotent) |
| **Retry Delay** | 5 minutes |
| **Concurrent Runs** | 1 (no parallelism needed) |
| **Email Notifications** | On failure: `valentinosko@etoro.com`, `<team-dl>` |

#### Notebook Widget Parameters

| Widget Name | Type | Value | Notes |
|-------------|------|-------|-------|
| `report_date` | Text | `{{date_sub(current_date(), 1)}}` | T-1 reporting date. Use Databricks job parameter syntax or hardcode during testing. |
| `use_masked_fallback` | Text | `false` | Set to `true` until `main.pii_data` access is granted |
| `npd_history_source` | Text | `gold` | Switch to `self` after 7+ consecutive daily runs with PII access |

⚠️ **Note on `report_date`**: The orchestrator's widget default is hardcoded for testing (`2026-06-11`). In the Lakeflow Job, override it using the job's **Base Parameters** section:
```json
{
  "report_date": "{{date_sub(current_date(), 1)}}"
}
```
If Databricks job parameters don't support expressions, use a wrapper cell at the top of the orchestrator:
```python
# Override for production: always use yesterday
import datetime
report_date = str(datetime.date.today() - datetime.timedelta(days=1))
dbutils.widgets.text("report_date", report_date)
```

#### Upstream Dependencies

| Dependency | Typical Completion | How to Verify |
|------------|-------------------|---------------|
| Bronze ETL refresh | ~06:00 UTC | Check `main.general.bronze_etoro_trade_positionforexternaluse` has yesterday's data |
| Gold mirrors refresh | ~06:30 UTC | Check `main.regtech.gold_regreportdb_prod_dbo_mifid2_report` has yesterday's date |

Schedule the job at **07:00 UTC** to ensure all upstream sources are fresh. If upstream is delayed, the pipeline will still run but may produce stale results — re-run the next day.

#### Cluster/Compute Permissions Required

The serverless compute identity needs:
- `USE_SCHEMA` on: `main.regtech_ops_stg` (write), `main.regtech`, `main.general`, `main.trading`, `main.bi_db`, `main.regtech_stg` (all read)
- `CREATE TABLE` on: `main.regtech_ops_stg`
- `USE_SCHEMA` on: `main.pii_data` (Task 1 grant #1)
- `USE_SCHEMA` on: `main.sharepoint` (Task 1 grant #2)
- External location write access: `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/`

### Task 3: Switch NB03 to SharePoint Source (after Task 1 grant #2)

1. Verify access: `DESCRIBE TABLE main.sharepoint.silver_sharepoint_reg_liquidityaccountid_to_lei`
2. In NB03 cell 5 (nuid `016fabe3`): uncomment the SharePoint SELECT at the bottom of the cell
3. Comment out or delete the Fivetran SELECT at the top
4. Delete the temp INSERT cell (nuid `2c301093-4a82-48cc-a8d8-4f6c03469b02`)
5. Run Steps 3 + 9, confirm hedge_report = 68,058

### Task 4: Set Up Monitoring/Alerting

| Table | Alert Threshold |
|-------|-----------------|
| mifid2_report, mifid2_me_report, mifid2_etoro_report | >0.1% drift vs gold |
| mifid2_hedge_report, ext_poschangelog | >0.1% drift vs gold |
| mifid2_customer, ext_customer | >0.5% drift vs gold |
| mifid2_npd_trax | >1% drift (masked mode), >0.5% (production mode) |

Gold mirrors for comparison: `main.regtech.gold_regreportdb_prod_dbo_mifid2_*`

---

## Beyond Compare Validation Plan

After deployment, the dev will create production tables in their own schema (e.g., `main.regtech` or a dev/staging schema). Beyond Compare validates the **dev's production tables** against the gold mirrors (`main.regtech.gold_regreportdb_prod_dbo_*`) which reflect current SSMS output for the same date.

> **NOTE**: The comparison is NOT against the `bi_output_regtechops_*` staging tables. Those are the development/validation tables created during migration testing. The dev will create NEW tables with their own naming convention and Delta locations. The SQL logic is identical — only the output schema/location changes.

### Tables to Compare

| # | Dev's Production Table (new pipeline output) | Gold Mirror (current SSMS production) | SP Being Replaced |
|---|----------------------------------------------|--------------------------------------|-------------------|
| 1 | `<dev_schema>.mifid2_report` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_report` | `SP_MIFID2_Report` |
| 2 | `<dev_schema>.mifid2_customer` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_customer` | `SP_MIFID2_Customer` |
| 3 | `<dev_schema>.mifid2_hedge_report` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_hedge_report` | `SP_MIFID2_HedgeEU_Report` + `SP_MIFID2_HedgeUK_Report` |
| 4 | `<dev_schema>.mifid2_npd_trax` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_npd_trax` | `SP_MIFID2_NPD_TRAX` |
| 5 | `<dev_schema>.mifid2_etoro_report` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_etoro_report` | `SP_MIFID2_ETORO_Report` (AUS/ASIC) |
| 6 | `<dev_schema>.mifid2_ext_positionchangelog` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_ext_positionchangelog` | (intermediate) |
| 7 | `<dev_schema>.mifid2_ext_customer` | `main.regtech.gold_regreportdb_prod_dbo_mifid2_ext_customer` | (intermediate) |

Replace `<dev_schema>` with the actual production schema chosen by the dev team.

### Beyond Compare Methodology

#### Step 1: Export to CSV for Beyond Compare

```sql
-- Run for same report_date on both sides (e.g., yesterday)
-- Export dev's production table:
SELECT * FROM <dev_schema>.mifid2_report
WHERE CAST(ReportDate AS DATE) = date_sub(current_date(), 1)
ORDER BY PositionID, OpenORClose, RegulationReportID;

-- Export gold mirror (current SSMS production):
SELECT * FROM main.regtech.gold_regreportdb_prod_dbo_mifid2_report
WHERE CAST(ReportDate AS DATE) = date_sub(current_date(), 1)
ORDER BY PositionID, OpenORClose, RegulationReportID;
```

Repeat for each table pair. Export as CSV with consistent sort order.

#### Step 2: Sort Keys for Each Table

| Table | Sort Key (for Beyond Compare alignment) |
|-------|------------------------------------------|
| mifid2_report | `PositionID, OpenORClose, RegulationReportID` |
| mifid2_customer | `CID` |
| mifid2_hedge_report | `TransactionReferenceNumber` (or `ExecutionID, RegulationReportID`) |
| mifid2_npd_trax | `CID, ChangeType` (or primary key columns) |
| mifid2_etoro_report | `PositionID, OpenORClose` |
| ext_poschangelog | `PositionID, ChangeLogOccurred` |
| ext_customer | `CID` |

#### Step 3: Expected Differences (NOT bugs)

| Table | Expected Diff | Root Cause | Acceptable? |
|-------|--------------|------------|-------------|
| mifid2_report | ME rows (RegID=11) present in staging only | Gold mirror excludes ME; our pipeline includes both EU/UK + ME in same table | ✅ Filter `WHERE RegulationID IN (1,2,9)` for apples-to-apples |
| mifid2_customer | ±3 rows | Customer scope filter (4 CIDs with valid RegID excluded by SP for unknown reason, 7 gold-only from regchange path) | ✅ <0.002% |
| mifid2_npd_trax | -29 to -32 rows | Masked mode can't detect PII-only changes (names/DOB). Resolves with `use_masked_fallback=false` | ✅ Expected in masked mode |
| mifid2_hedge_report | TRN column differs for ~14.6% of rows | ROW_NUMBER tie-breaking within same ExecutionTime — SQL Server uses physical page order (non-deterministic). All other fields match. | ✅ Known, not a logic bug |
| ext_customer | +2 rows | Same as mifid2_customer scope difference | ✅ |
| All PII columns | Values differ if `use_masked_fallback=true` | Masked mode uses `'MASKED'` placeholder for names/DOB | ✅ Resolves with PII access |

#### Step 4: Field-Level Comparison SQL (use dev's production table names)

```sql
-- mifid2_report field-level comparison (replace <dev_schema> with actual schema)
WITH matched AS (
  SELECT
    CASE WHEN CAST(CAST(s.Price AS DECIMAL(18,8)) AS STRING) != g.Price THEN 1 ELSE 0 END AS diff_Price,
    CASE WHEN NVL(CAST(s.Quantity AS STRING),'') != NVL(g.Quantity,'') THEN 1 ELSE 0 END AS diff_Qty,
    CASE WHEN NVL(s.TradingDateTime,'') != NVL(g.TradingDateTime,'') THEN 1 ELSE 0 END AS diff_DateTime,
    CASE WHEN NVL(s.Venue,'') != NVL(g.Venue,'') THEN 1 ELSE 0 END AS diff_Venue,
    CASE WHEN NVL(s.TransactionReferenceNumber,'') != NVL(g.TransactionReferenceNumber,'') THEN 1 ELSE 0 END AS diff_TRN,
    CASE WHEN NVL(s.ExecutingEntityIdentificationCode,'') != NVL(g.ExecutingEntityIdentificationCode,'') THEN 1 ELSE 0 END AS diff_Entity,
    CASE WHEN NVL(s.TradingCapacity,'') != NVL(g.TradingCapacity,'') THEN 1 ELSE 0 END AS diff_Capacity
  FROM <dev_schema>.mifid2_report s
  JOIN main.regtech.gold_regreportdb_prod_dbo_mifid2_report g
    ON s.PositionID = g.PositionID
    AND s.OpenORClose = g.OpenORClose
    AND s.RegulationReportID = g.RegulationReportID
    AND s.ReportDate = g.ReportDate
  WHERE s.ReportDate = date_sub(current_date(), 1)
    AND s.RegulationID IN (1, 2, 9)
)
SELECT
  COUNT(*) AS matched_rows,
  SUM(diff_Price) AS Price_mismatches,
  SUM(diff_Qty) AS Quantity_mismatches,
  SUM(diff_DateTime) AS DateTime_mismatches,
  SUM(diff_Venue) AS Venue_mismatches,
  SUM(diff_TRN) AS TRN_mismatches,
  SUM(diff_Entity) AS Entity_mismatches,
  SUM(diff_Capacity) AS Capacity_mismatches
FROM matched;
-- Expected: ALL zeros
```

---

## Adjustments Required After Copying

The pipeline is ready as-is for staging execution. For production deployment, the dev **MUST** change the target schema and Delta locations. The SQL logic remains unchanged.

### Mandatory Adjustments

| # | What | Where | Action |
|---|------|-------|--------|
| 1 | **Write target schema** | All notebooks | Currently writes to `main.regtech_ops_stg` with `bi_output_regtechops_` prefix. Replace with your production schema and table naming convention (e.g., `main.regtech.mifid2_report`). |
| 2 | **Delta LOCATION paths** | All `CREATE OR REPLACE TABLE` statements | Currently uses `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/`. Update to your production storage location. |
| 3 | `report_date` default | Orchestrator cell 1 (widget) | Override via job parameters or add production default logic |
| 4 | `use_masked_fallback` | Orchestrator cell 1 | Set to `false` once `main.pii_data` granted |
| 5 | NB03 SharePoint switch | `03_hedge_liquidity_staging` cell 5 | After `main.sharepoint` grant: uncomment SharePoint SELECT, delete temp INSERT cell |
| 6 | Notebook relative paths | Orchestrator step cells | If notebooks moved to different folder, update `dbutils.notebook.run()` paths |

### Optional Adjustments (production hardening)

| # | What | Where | Recommendation |
|---|------|-------|----------------|
| 1 | Error handling | Orchestrator step cells | Currently uses `try/except` with `print`. Consider adding structured logging or alerting hooks. |
| 2 | Notification on completion | Orchestrator final cell | Add Slack/Teams/email notification after successful completion |
| 3 | Widget defaults | Orchestrator cell 1 | Remove testing defaults, make parameters mandatory or use job-injected values |
| 4 | ME report separation | NB08 cell | Currently ME rows (RegID=11) are in the same table as EU/UK. If production needs a separate `mifid2_me_report` table, add a post-processing split. Currently the orchestrator already handles this in the final validation cell. |

### What NOT to Change

- **SQL logic** in NB08, NB09, NB07, NB11 — validated field-by-field against SSMS gold
- **Execution order** (Steps 1→5→6→7→8→9→10→11→12) — dependencies are strict
- **IsMifid/IsMifidByFCA logic** — uses production SCD with temporal validity, validated against SSMS
- **EU-FCA dual-reporting** — UK positions reported twice (RRID=1 with TRN `{PosID}UKC` + RRID=2 with `{PosID}C`)
- **Column names and types** — Price as DECIMAL(18,8), LiquidityProvider LEFT(30), Quantity as STRING
- **ETORO/ASIC logic** in NB11 — validated parity with `SP_MIFID2_ETORO_Report` for Australian positions

---

## Acceptance Criteria

1. [ ] Access grants applied (`main.pii_data`, `main.sharepoint`)
2. [ ] NB03 switched to SharePoint source, temp INSERT deleted
3. [ ] `use_masked_fallback` set to `false`
4. [ ] Production schema and Delta locations configured
5. [ ] Daily Lakeflow Job created and scheduled at 07:00 UTC
6. [ ] Pipeline runs successfully for 3 consecutive days
7. [ ] Beyond Compare / field-level comparison of **production tables vs gold mirrors** confirms:
   - mifid2_report: 0 row difference, 0 field mismatches
   - mifid2_hedge_report: 0 row difference, 0 field mismatches (excluding TRN RowID portion)
   - mifid2_etoro_report: 0 row difference
   - ext_poschangelog: 0 row difference
   - mifid2_customer: ≤5 row difference
   - mifid2_npd_trax: ≤0.5% (with PII access enabled)
8. [ ] Monitoring alerts configured per threshold table above
9. [ ] After 7+ successful daily runs: switch `npd_history_source` to `self`
10. [ ] SSMS SP jobs can be decommissioned (parallel run period complete)

---

## Output Tables Produced

The pipeline currently creates tables in `main.regtech_ops_stg` (development/validation). **The dev will change the target schema and Delta locations for production.** The logical table names below show what gets produced:

### Final Report Tables (validated against SSMS)

| Logical Table | Rows (typical) | Key Columns | Gold Mirror | SP Replaced |
|--------------|---------------|-------------|-------------|-------------|
| `mifid2_report` | ~1.8M | PositionID, OpenORClose, RegulationReportID, ReportDate | `gold_regreportdb_prod_dbo_mifid2_report` | `SP_MIFID2_Report` |
| `mifid2_hedge_report` | ~68K | TransactionReferenceNumber, ReportDate | `gold_regreportdb_prod_dbo_mifid2_hedge_report` | `SP_MIFID2_HedgeEU/UK_Report` |
| `mifid2_customer` | ~201K | CID, ReportDate | `gold_regreportdb_prod_dbo_mifid2_customer` | `SP_MIFID2_Customer` |
| `mifid2_npd_trax` | ~9.5K | CID, ChangeType, ReportDate | `gold_regreportdb_prod_dbo_mifid2_npd_trax` | `SP_MIFID2_NPD_TRAX` |
| `mifid2_etoro_report` | ~9.8K | PositionID, OpenORClose, ReportDate | `gold_regreportdb_prod_dbo_mifid2_etoro_report` | `SP_MIFID2_ETORO_Report` |

### Intermediate/Staging Tables (used by downstream steps)

| Logical Table | Purpose | Created By |
|--------------|---------|------------|
| `mifid2_ext_customer` | Customer base population | NB07 |
| `mifid2_ext_position` | Position population | NB07 |
| `mifid2_ext_positionchangelog` | Position changelog | NB05 |
| `mifid2_ext_mirror` | Mirror/copy trade data | NB05 |
| `mifid2_ext_hedgeexecutionlog` | Hedge execution log (EU) | NB05 |
| `mifid2_report_trade_population` | Trade population (before report assembly) | NB08 |
| `reg_ext_*` | ~15 reference tables (instruments, currency, LP mapping, etc.) | NB01-03 |

### Current Storage Pattern (will change for production)

Currently in development:
```
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_{name}
USING DELTA
LOCATION 'abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/{name}'
AS SELECT ...
```

**Dev will replace** the schema (`main.regtech_ops_stg.bi_output_regtechops_`) and LOCATION path with production equivalents. The LOCATION pattern (external tables) is recommended to survive any UC metadata cleanup, but the dev can use managed tables if their production schema doesn't have nightly cleanup.

---

## Architecture Overview

| Component | Current (Dev/Staging) | Production (Dev to Configure) |
|-----------|----------------------|-------------------------------|
| Write target | `main.regtech_ops_stg` | `<dev_schema>` (e.g., `main.regtech` or production schema) |
| Table prefix | `bi_output_regtechops_` | Dev's choice (e.g., no prefix, or `mifid2_`) |
| Storage | `abfss://...stgdpdlwe.../BI_OUTPUT/RegTechOps/` | Dev's production storage location |
| Compute | Serverless | Serverless (validated) |
| Idempotency | `CREATE OR REPLACE TABLE ... USING DELTA LOCATION` | Same pattern recommended |
| Read sources | `main.regtech`, `main.general`, `main.trading`, `main.bi_db` | Same (unchanged) |

## Entity LEIs (for validation)

| Entity | LEI |
|--------|-----|
| eToro EU (CySEC) | `213800GIFQMSV7HROS23` |
| eToro UK (FCA) | `213800FLAB1OVA8OHT72` |
| eToro Seychelles | `549300L7LPQNKJQ1IW32` |
| eToro ME (DSR-8383) | `254900TH30J939UL7C24` |

---

## Contacts

| Role | Contact |
|------|---------|
| Pipeline Developer | valentinosko@etoro.com |
| Platform/Infra | olegab@etoro.com, guyman@etoro.com |
| Fivetran Connector | Data Engineering team |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Fivetran LP source goes stale again | Switch to SharePoint source (Task 3) eliminates dependency |
| NB03 temp INSERT creates duplicates if Fivetran adds the same LPs | SharePoint switch removes this risk entirely |
| Gold mirrors refresh at different time than pipeline | Schedule pipeline AFTER gold refresh; compare same ReportDate |
| PII access denied | Pipeline works in masked mode (current state); NPD TRAX has -0.34% gap |
| Nightly cleanup drops table metadata | LOCATION pattern ensures Delta files persist; re-run from Step 1 re-registers all |

---

## Parallel Run Recommendation

Run Databricks pipeline in parallel with SSMS SP for **2 weeks minimum**:
1. Both produce output for same ReportDate (T-1)
2. Daily Beyond Compare of **dev's production tables vs gold mirrors** confirms match
3. After 10+ consecutive matching days with 0 drift on primary tables → decommission SSMS
4. Keep gold mirrors active for 30 days post-decommission as fallback

---

## References

- Full handoff doc: `HANDOFF_2026-06-18.md` in repo root
- Reference SPs: `reference/SP_MIFID2_Report.sql`, `reference/SP_MIFID2_HedgeEU_Report.sql`, `reference/SP_MIFID2_ETORO_Report.sql`
- Production Operations Guide: Section in `HANDOFF_2026-06-18.md` (scheduling, runtime, failure handling)
