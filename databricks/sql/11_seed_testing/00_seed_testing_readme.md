# Step 11 — Manual CSV Seed Testing (Staging-Only)

## Purpose

Gated SQL templates for loading **manually exported** SQL Server CSV seed files into temporary staging seed test tables in `main.regtech_ops_stg`.

**Not production logic.** Not delivery/upload/response. No writes to `main.regtech`.

## Package files

| File | Role |
| --- | --- |
| `01_create_manual_seed_external_tables.sql` | Commented CREATE for external CSV sources + seed test Delta tables |
| `02_load_mifid2_npd_trax_csv_template.sql` | Commented COPY/INSERT load for NPD seed test |
| `03_load_mifid2_hedge_report_csv_template.sql` | Commented COPY/INSERT load for Hedge seed test |
| `04_manual_seed_validation.sql` | SELECT-only validation (no DDL/DML) |

## Target tables

- `main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax`
- `main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report`

## Prerequisites

1. Approved secure CSV path (ADLS or Volume) — **never commit CSV to Git**.
2. PII-sensitive NPD exports must use restricted ACLs (not broad/shared unsecured paths).
3. SQL Server export manifest with row count recorded externally.
4. `main.regtech_ops_stg` write permission for staging principals only.
5. Run mode: `development_structural_test`.

## Placeholders to replace before uncommenting gated SQL

| Placeholder | Meaning |
| --- | --- |
| `{{npd_csv_location}}` | Approved abfss/volume path to NPD CSV folder or file |
| `{{hedge_csv_location}}` | Approved abfss/volume path to Hedge CSV folder or file |
| `{{seed_delta_location_npd}}` | Approved Delta storage path for NPD seed test table |
| `{{seed_delta_location_hedge}}` | Approved Delta storage path for Hedge seed test table |
| `{{sql_server_npd_export_row_count}}` | Row count from SQL Server export manifest |
| `{{sql_server_hedge_export_row_count}}` | Row count from SQL Server export manifest |

## Execution order

1. `01_create_manual_seed_external_tables.sql` (after path approval)
2. `02_*` or `03_*` load template for chosen target
3. `04_manual_seed_validation.sql` (SELECT-only)

## Final activation gates (unchanged)

- Step 15 `bi_output_regtechops_mifid2_npd_trax` remains gated until PII, history, and MAG gates close.
- Step 14 `bi_output_regtechops_mifid2_hedge_report` remains gated until RecordID registry, TRN parity, and MAG gates close.

## Documentation

See `docs/manual_seed_testing_plan.md`.
