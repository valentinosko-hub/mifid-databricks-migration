# Step 10 - Hedge RecordID Registry / Control (Design Package)

## Purpose

This package defines a **persistent RecordID registry/control design** for
`MIFID2_Hedge_Report` in `main.regtech_ops_stg`.

The package is authored as **gated templates only**:

- No SQL execution is performed by this repository update.
- No Hedge output activation is performed.
- No writes to `main.regtech` are included.

## Files

| File | Role |
| --- | --- |
| `01_hedge_recordid_registry_scaffold.sql` | Commented/gated registry DDL scaffold with fixed `LOCATION` placeholder |
| `02_hedge_recordid_seed_from_sql_server.sql` | Commented/gated seed template preserving SQL Server historical `RecordID` values |
| `03_hedge_recordid_allocation_template.sql` | Commented/gated future allocation template (reuse existing IDs, allocate only unseen keys from `MAX+1`) |
| `04_hedge_recordid_validation.sql` | SELECT-only validation checks for duplicates, preservation, continuity, and reconciliation |

## Source options for seed design template

- `{{de_migrated_mifid2_hedge_report_source}}` (preferred when DE-migrated history is available), or
- `main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report` for staging/manual seed tests.

## Core design rules

1. Preserve historical SQL Server `RecordID` values exactly.
2. Reuse existing `RecordID` for already-known business keys.
3. Allocate new IDs only for genuinely new/back-reported trades.
4. Continue allocation from `MAX(RecordID) + 1` using deterministic order for unseen rows only.
5. Do not use non-deterministic identity behavior.
6. Do not use per-run `row_number` logic that can reassign existing IDs.

## Gating conditions (must be satisfied before any uncomment/run)

- Historical source availability confirmed (DE-migrated or approved seed-test source).
- Historical seed data validation passed.
- Registry table creation approved with fixed external location.
- `RecordBusinessKey` natural-key signoff completed by SME.
- Registry validation checks passed.

Until these gates are closed, this package remains design-only and non-executing.
