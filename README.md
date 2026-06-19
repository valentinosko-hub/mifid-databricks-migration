# MiFID Databricks Migration

Replacement of the SSMS/SSIS MiFID2 regulatory reporting pipeline with Databricks notebooks.

## Status: PRODUCTION-READY (2026-06-19)

The pipeline is fully validated against SSMS gold and ready for production deployment.

| Table | SSMS | DBX | Match |
|-------|------|-----|-------|
| mifid2_report (excl ME) | 1,798,734 | 1,798,734 | ✅ PERFECT (field-level validated) |
| mifid2_me_report | 85,651 | 85,651 | ✅ PERFECT |
| mifid2_etoro_report | 9,860 | 9,860 | ✅ PERFECT |
| ext_poschangelog | 836,345 | 836,345 | ✅ PERFECT |
| mifid2_hedge_report | 68,058 | 68,058 | ✅ PERFECT (field-level validated) |
| mifid2_customer | 201,792 | 201,789 | ✅ -0.001% |
| mifid2_npd_trax | 9,484 | 9,452 | ✅ -0.34% (masked mode only) |

## Quick Start

1. Open `notebooks/00_run_all_staging` (orchestrator)
2. Set `report_date` widget to desired date (T-1)
3. Run All — takes ~25-35 min on serverless
4. Check final validation cell (cell 15) for row counts

## Production Deployment — START HERE

**➡️ [`HANDOFF_2026-06-18.md`](HANDOFF_2026-06-18.md)** — Complete handoff document with:
- Production Operations Guide (scheduling, runtime, idempotency, monitoring)
- Production Deployment Checklist (4 tasks before go-live)
- Field-level validation results
- All remaining gaps with root cause analysis
- Quick verification SQL for post-run checks

## Production Blockers (3 items)

| # | Blocker | Action | Owner |
|---|---------|--------|-------|
| 1 | `main.pii_data` access | `GRANT USE_SCHEMA ON SCHEMA main.pii_data TO <identity>` | DBA/IT |
| 2 | `main.sharepoint` access | `GRANT USE_SCHEMA ON SCHEMA main.sharepoint TO <identity>` | DBA/Platform |
| 3 | Daily Lakeflow Job | Schedule at 07:00 UTC with `report_date=date_sub(current_date(),1)` | Data Engineering |

Until blocker #1 is resolved, run with `use_masked_fallback=true` (current default).
Until blocker #2 is resolved, NB03 uses a temporary INSERT workaround for 10 LPs.

## Architecture

| Setting | Value |
|---------|-------|
| Write target | `main.regtech_ops_stg` |
| Table prefix | `bi_output_regtechops_` |
| Storage | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/` |
| Compute | Serverless (validated) |
| Idempotency | All tables use `CREATE OR REPLACE TABLE ... USING DELTA LOCATION` |
| Read sources | `main.regtech`, `main.general`, `main.trading`, `main.bi_db` |

## Notebooks (Execution Order)

| Step | Notebook | Runtime | Description |
|------|----------|---------|-------------|
| 1 | `01_price_currency_staging` | ~2 min | Price/Currency/Split foundation tables |
| 2 | `02_non_price_staging` | ~3 min | Non-price reference + Instruments (production SCD) |
| 3 | `03_hedge_liquidity_staging` | ~1 min | Hedge/LP mapping (⚠️ temp INSERT for 10 LPs until SharePoint enabled) |
| 4 | ~~`04_regulation_movements_staging`~~ | skip | REMOVED — all consumers use gold directly |
| 5 | `05_mifid2_ext_staging` | ~12 min | PositionChangeLog, Mirror, HedgeExecutionLog |
| 6 | `07_mifid2_ext_customer_staging` | ~15 min | Customer, Position, RegChange (masked fallback) |
| 7 | `07b_mifid2_customer_enrichment` | ~2 min | SP_MIFID2_Customer parity enrichment |
| 8 | `08_mifid2_report_output` | ~8 min | Final mifid2_report (5 flows + partial close) |
| 9 | `09_mifid2_hedge_report` | ~2 min | Hedge report (EU + EU-UK + UK branches) |
| 10 | `10_mifid2_npd_trax` | ~3 min | NPD TRAX (NEW + EXIST + FAILED paths) |
| 11 | `06_mifid_audit_tables` | ~7 min | Audit log, quality checks, XREF integrity |
| 12 | `11_mifid2_etoro_report` | ~1 min | ETORO/ASIC report (Australian positions) |

All notebooks are orchestrated by `00_run_all_staging`. Total runtime: ~25-35 min.

## Key Parameters

| Parameter | Default | Production | Notes |
|-----------|---------|------------|-------|
| `report_date` | `2026-06-11` | `date_sub(current_date(), 1)` | T-1 reporting date |
| `use_masked_fallback` | `true` | `false` (after PII access) | Controls NB07b + NB10 PII access |
| `npd_history_source` | `gold` | `self` (after daily scheduling) | NPD TRAX history comparison |

## Repository Structure

```
mifid-databricks-migration/
├── HANDOFF_2026-06-18.md    ← PRIMARY HANDOFF DOC (start here)
├── README.md                ← This file
├── notebooks/               ← All production notebooks (NB00-NB11)
├── reference/               ← Original SSMS stored procedures (read-only)
├── docs/                    ← Historical planning docs (pre-implementation phase)
└── databricks/              ← Legacy SQL templates and workflow YAMLs (superseded by notebooks/)
```

## Entity LEIs

- eToro EU (CySEC): `213800GIFQMSV7HROS23`
- eToro UK (FCA): `213800FLAB1OVA8OHT72`
- eToro Seychelles: `549300L7LPQNKJQ1IW32`
- eToro ME (DSR-8383): `254900TH30J939UL7C24`

## Historical Reference

The `docs/` folder contains ~55 planning documents from the original Cursor-based development phase (Steps 1-18B). These are retained for historical reference but are **superseded** by:
- `HANDOFF_2026-06-18.md` — current state, production ops, remaining work
- `notebooks/00_run_all_staging` cell 1 — parity tables and execution notes

Key historical docs:
- [Implementation module plan](docs/implementation_module_plan.md)
- [Migration execution order](docs/migration_execution_order.md)
- [Source-to-Databricks mapping](docs/source_to_databricks_mapping_review.md)
- [Final output tables](docs/final_output_tables.md)

## Contacts

- Pipeline developer: valentinosko@etoro.com
- Platform/infra: olegab@etoro.com, guyman@etoro.com
