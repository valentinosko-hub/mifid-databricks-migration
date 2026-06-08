# Staging First-Run Plan — MiFID RegTechOps

## Purpose

Step-by-step **manual** staging first-run plan for MiFID RegTechOps smoke-test jobs in `main.regtech_ops_stg`. This document does **not** authorize Databricks job deployment, production execution, or final regulatory parity.

**Status:** Planning and evidence template only. Repository is **not production-ready**.

**Workflow reference:** `databricks/workflows/mifid_phase1_staging_smoke_test.yml`  
**Parameters:** `databricks/config/workflow_parameters.yml`  
**Evidence log:** [staging_execution_evidence_log.md](staging_execution_evidence_log.md)

---

## Environment (first run defaults)

| Parameter | Value |
| --- | --- |
| `source_catalog` | `main` |
| `source_schema` | `regtech` (when DE-migrated sources available) |
| `target_catalog` | `main` |
| `target_schema` | `regtech_ops_stg` |
| `object_prefix` | `bi_output_regtechops_` |
| `run_mode` | `development_structural_test` |
| `dry_run` | `true` (default) |
| `staging_execution_approved` | `false` |
| `enable_masked_customer_structural_tests` | `false` |
| `enable_manual_seed_testing_checks` | `false` |
| `skip_delivery_steps` | `true` |
| Schedule | None |
| Deployment | Blocked (template-only) |

**Read:** `main.regtech` when DE-migrated.  
**Write:** `main.regtech_ops_stg` only — **never** `main.regtech`.

---

## First-run scope

### In scope (default critical path)

Phases 0–8 and 11 — ext/staging/audit structural checks without final PII or final report activation.

### Optional (skip on first pass unless explicitly needed)

- Phase 9 — masked customer structural tests
- Phase 10 — manual CSV seed load mechanics test

### Explicitly out of scope

- Final `MIFID2_NPD_TRAX` activation (MAG-10; remains last in reporting flow)
- Final `MIFID2_Hedge_Report` activation (MAG-12/MAG-13; RecordID registry)
- Final customer/NPD parity (`main.pii_data`; MAG-06)
- Delivery / upload / response / production deployment
- NOC and old Databricks attempt docs (reference-only)

---

## Phase 0 — Pre-run checks

Complete before any phase execution. Record results in [staging_execution_evidence_log.md](staging_execution_evidence_log.md) (external copy) and secure storage.

| # | Check | Pass criteria | Stop if fail |
| --- | --- | --- | --- |
| 0.1 | Git branch/commit | Current branch and commit hash recorded | Unclear repo state |
| 0.2 | Uncommitted changes | Working tree clean or changes explicitly acknowledged | Unreviewed local drift |
| 0.3 | Source parameters | `source_catalog=main`, `source_schema=regtech` | Wrong read policy |
| 0.4 | Target parameters | `target_catalog=main`, `target_schema=regtech_ops_stg`, `object_prefix=bi_output_regtechops_` | Wrong write target |
| 0.5 | No `main.regtech` writes | `target_schema` ≠ `regtech`; GATE-07 policy understood | Write to production schema |
| 0.6 | No delivery tasks | `skip_delivery_steps=true`; no CSV/SFTP/TRAX/upload/response tasks in run scope | Delivery scope detected |
| 0.7 | Evidence storage | Outputs land in **secure storage outside Git**; evidence link recorded | PII/raw outputs in repo |
| 0.8 | Run mode | `run_mode=development_structural_test`, `dry_run=true` for first pass | Final parity path enabled |
| 0.9 | Optional groups off | `enable_masked_customer_structural_tests=false`, `enable_manual_seed_testing_checks=false` | Unapproved optional path |
| 0.10 | MAG minimum | MAG-01–04 reviewed; MAG-18 still OPEN for `dry_run=false` | Missing approvals for intended mode |

**Suggested commands (record output externally, not in Git):**

```text
git branch --show-current
git rev-parse HEAD
git status --short
```

**Gate SQL (readiness):** `databricks/sql/10_workflow/gates/gate_global_scope.sql` — confirm GATE-01–08 PASS.

---

## Phase 1 — source_readiness_checks

**Workflow task:** `source_readiness_checks`

| # | Action | SQL / reference |
| --- | --- | --- |
| 1.1 | Run global scope gate | `databricks/sql/10_workflow/gates/gate_global_scope.sql` |
| 1.2 | Verify `main.regtech` source tables exist where expected | Module `*_source_profiling.sql`; `docs/source_profiling_results.md` |
| 1.3 | Verify required columns | `databricks/sql/validation/02_static_reference_required_columns.sql`; module validations |
| 1.4 | Verify row counts / date ranges where safe | Profiling SQL; no full-table scans on huge objects unless approved |
| 1.5 | Verify `main.regtech_ops_stg` target schema exists | Catalog browse / `DESCRIBE SCHEMA` (external evidence) |

**Stop if:** any expected source missing; required column missing; target schema missing; gate reports BLOCK on write policy.

---

## Phase 2 — static_reference_checks

**Workflow task:** `static_reference_checks`

| # | Action | SQL / reference |
| --- | --- | --- |
| 2.1 | Static reference row counts | `databricks/sql/validation/01_static_reference_row_counts.sql` through `07_*` |
| 2.2 | Required-column checks | `databricks/sql/validation/02_static_reference_required_columns.sql` |
| 2.3 | Static module gates | `databricks/sql/01_static_references/*` |

**Stop if:** required static reference unavailable; required column missing.

---

## Phase 3 — price_currency_split_ext_staging

**Workflow task:** `price_currency_split_ext_staging`

| Target (staging prefix) | Reference SQL |
| --- | --- |
| `Reg_CurrencyPrice_Ext` | `databricks/sql/03_pre_regulation_ext/02_price_currency_staging.sql`, `03_price_currency_validation.sql` |
| `Reg_Ext_CurrencyPriceMaxDateWithSplit` | same |
| `Reg_Ext_DailyMaxPrices` | same |
| `Reg_Ext_T_PriceCandle60Min` | same |
| `Reg_Ext_HistorySplitRatio` | same |

**Stop if:** source missing; required column missing; row count unexpectedly zero for scoped report date.

---

## Phase 4 — non_price_reg_ext_staging

**Workflow task:** `non_price_reg_ext_staging`

| Target | Reference SQL |
| --- | --- |
| `Reg_Ext_Trade_GetInstrument` | `databricks/sql/03_pre_regulation_ext/05_non_price_staging_gates.sql`, `06_non_price_validation.sql` |
| `Reg_Ext_Trade_InstrumentMetaData` | same |
| `Reg_Ext_DictionaryCurrency` | same |
| `Reg_Ext_DictionaryCurrencyType` | same |
| `Reg_Instruments_ext` | same |

**Stop if:** source missing; required column missing; row count unexpectedly zero.

---

## Phase 5 — regulation_movement_staging

**Workflow task:** `regulation_movement_staging`

| Target | Notes |
| --- | --- |
| `Reg_MigrationInOut_Population` snapshot | Structural/snapshot checks for scoped date |
| `Reg_RegulationInOutDailyData` snapshot | Regulation replay inputs |
| `Reg_Regulation_Movments_Positions` | Movement staging |

**Reference SQL:** `databricks/sql/04_regulation_movements/*`

**Stop if:** migration/regulation source missing; required column missing.

---

## Phase 6 — hedge_liquidity_ext_staging

**Workflow task:** `hedge_liquidity_ext_staging`

| Target | Notes |
| --- | --- |
| `Reg_HedgeServerToLiquidityAccount_Ext` | Structural only |
| `Reg_LiquidtyAcount_Ext` | Structural only |
| `Reg_Ext_LiquidityAccountID` | Structural only |
| `Reg_Ext_LiquidityProviders` | Structural only |
| `Reg_LiquidtyAcount_SCD` | **SCD structural checks only** — full historical SCD validation gated (MAG-11) |

**Reference SQL:** `databricks/sql/05_hedge_liquidity/` (structural subset)

**Stop if:** liquidity source missing; SCD structural gate fails unexpectedly.

**Not in scope:** final Hedge report; RecordID registry activation.

---

## Phase 7 — ASIC2 structural staging

**Workflow task:** `asic2_structural_staging`

| Action | Notes |
| --- | --- |
| ASIC2-compatible subset structural checks | No final ETORO parity claim |
| No full `ASIC2_Positions` history load required for first pass | Chunked full-history seed is separate program |

**Reference SQL:** `databricks/sql/06_asic2_subset/` (structural validation subset)

**Stop if:** structural validation hard-gate fails.

---

## Phase 8 — MIFID2_ext non-PII staging

**Workflow task:** `mifid2_ext_non_pii_staging`

| Target | Notes |
| --- | --- |
| `MIFID2_ext_Position` | Non-PII |
| `MIFID2_ext_RegChange_Position` | Non-PII |
| `MIFID2_ext_PositionChangeLog` | Non-PII |
| `MIFID2_ext_Mirror` | Non-PII |
| `MIFID2_ext_HedgeExecutionLog` | Non-PII |
| `MIFID2_Failed_TRAX` | **Gated** — do not activate unless NPD seed/history ready |

**Reference SQL:** `databricks/sql/07_mifid2_ext/` (non-PII subset)

**Stop if:** non-PII ext source missing; `MIFID2_Failed_TRAX` path enabled without NPD context.

---

## Phase 9 — optional masked customer structural tests

**Skip on default first pass.**

| Prerequisite | Value |
| --- | --- |
| `enable_masked_customer_structural_tests` | `true` |
| `allow_masked_customer_sources` | `true` |
| MAG-05 | CLOSED |

**Rules:**

- Masked sources only (`main.general` bronze masked customer tables)
- **No final parity claim**
- Do not enable `main.pii_data` paths

**Stop if:** masked path used without MAG-05; final parity parameters accidentally set.

---

## Phase 10 — optional manual seed testing

**Skip on default first pass.**

| Prerequisite | Value |
| --- | --- |
| `enable_manual_seed_testing_checks` | `true` |
| Seed CSV | Approved secure storage only — **not Git** |

**NPD CSV policy for first run:**

- Current NPD CSV may be used **only** to test CSV load mechanics into `bi_output_regtechops_seed_test_mifid2_npd_trax`
- Final NPD CSV must be **regenerated later** when ready for the NPD reporting step
- **No final NPD_TRAX activation** — staging evidence only

**Reference:** `databricks/sql/11_seed_testing/`, [manual_seed_testing_plan.md](manual_seed_testing_plan.md)

**Stop if:** seed CSV in Git; final NPD flow activated; NPD parity gates treated as closed.

---

## Phase 11 — validation_summary

**Workflow task:** `validation_summary`

| # | Action | SQL / reference |
| --- | --- | --- |
| 11.1 | Module validations (structural-only) | Module `*_validation.sql` where safe |
| 11.2 | Cross-module readiness | `databricks/sql/09_validation/07_phase1_readiness_summary.sql`, `08_*`, `09_*` |
| 11.3 | Cross-module gate | `databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql` |
| 11.4 | Update evidence log | [staging_execution_evidence_log.md](staging_execution_evidence_log.md) — external working copy |

**Label all results:** **staging structural evidence only** — not final parity signoff.

---

## Stop criteria (immediate halt)

Stop the run and document in the evidence log if **any** of the following occur:

| # | Condition |
| --- | --- |
| S1 | Any expected source table/object missing in `main.regtech` (or documented fallback unavailable) |
| S2 | Any required column missing |
| S3 | Row count unexpectedly zero for scoped report date / structural check |
| S4 | Target parameters point to `main.regtech` write |
| S5 | PII / final parity path accidentally enabled (`main.pii_data`, `final_parity_production`, `require_unmasked_pii_for_parity` mis-set) |
| S6 | Delivery / upload / response task appears in run scope |
| S7 | Final NPD_TRAX flow accidentally enabled or NPD parity claimed |
| S8 | Final Hedge report activation attempted without RecordID registry |
| S9 | GATE-01–08 reports BLOCK (except documented PASS_WITH_LIMITS under approved staging policy) |
| S10 | Evidence cannot be stored outside Git |

**On stop:** do not proceed to next phase; update evidence log; escalate per [workflow_governance_controls.md](workflow_governance_controls.md).

---

## Evidence and parity disclaimers

| Statement | Detail |
| --- | --- |
| Evidence location | Files and query outputs stored in **secure storage outside Git** |
| Repo evidence log | [staging_execution_evidence_log.md](staging_execution_evidence_log.md) is a **template**; populate external working copy |
| Staging success | Does **not** constitute final regulatory parity signoff |
| Final parity | Requires SQL Server baseline comparison ([validation_evidence_plan.md](validation_evidence_plan.md)), MAG-16, and applicable MAG closures |
| NOC / old Databricks attempt | Reference-only — not implementation authority |

---

## First-run checklist summary

| Phase | Required first pass? |
| --- | --- |
| 0 — Pre-run | Yes |
| 1 — Source readiness | Yes |
| 2 — Static references | Yes |
| 3 — Price/currency/split | Yes |
| 4 — Non-price Reg_Ext | Yes |
| 5 — Regulation movement | Yes |
| 6 — Hedge/liquidity ext | Yes |
| 7 — ASIC2 structural | Yes |
| 8 — MIFID2_ext non-PII | Yes |
| 9 — Masked customer | **No** (optional) |
| 10 — Manual seed | **No** (optional) |
| 11 — Validation summary | Yes |

---

## Related documents

- [staging_execution_evidence_log.md](staging_execution_evidence_log.md)
- [reporting_job_preparation_plan.md](reporting_job_preparation_plan.md)
- [workflow_execution_runbook.md](workflow_execution_runbook.md)
- [manual_approval_gates.md](manual_approval_gates.md)
- [post_blocker_execution_plan.md](post_blocker_execution_plan.md)
- [baseline_scenario_request.md](baseline_scenario_request.md)
- [validation_evidence_plan.md](validation_evidence_plan.md)
