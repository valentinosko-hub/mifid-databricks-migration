# Remaining Decisions (Step 16B2; aligned Step 18B)

This document consolidates open technical and business decisions that must be closed before Databricks execution and module un-gating.

Role-based closure tracking:

- DE/Data Platform: `docs/de_data_platform_action_list.md`
- RegTech SME: `docs/regtech_sme_decision_list.md`
- Post-blocker sequence: `docs/post_blocker_execution_plan.md`

Source registers:

- `docs/open_blockers_for_execution.md`
- `docs/unresolved_dependencies.md`
- `docs/open_questions_and_decisions.md`
- `docs/history_seed_requirements.md`
- `docs/historical_seed_inventory.md` (BI-21 MCP seed inventory)
- `docs/sql_server_baseline_extract_plan.md`
- `docs/hedge_recordid_registry_design.md`
- `docs/manual_approval_gates.md` (Step 17C approval gate register)

## Policy status (2026-06-05)

**Broad policy decisions are mostly made.** Approved direction covers historical seed strategy, Hedge `RecordID` preservation, hard parity for `TransactionReferenceNumber` and CFI/`InstrumentClassification`, masked-customer dev-only fallback, and phase-1 scope boundaries (no delivery/production).

**Remaining open items** are execution prerequisites and signoffs — not re-litigation of seed-all-history policy:

| # | Remaining item | Owner | Doc reference |
| --- | --- | --- | --- |
| 1 | PII access (`main.pii_data`) or formal exception | DE + RegTech SME/Compliance | D-01 / MAG-06 |
| 2 | Historical seed extraction ownership and landing process | DE / Data Platform | [historical_seed_inventory.md](historical_seed_inventory.md) |
| 3 | Hedge `RecordID` natural business key final signoff | RegTech SME | D-12 / [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md) |
| 4 | SQL Server baseline dates and scoped extracts | Validation + SME | D-23 / [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md) |
| 5 | Execution warehouse / principal / write permissions | Data Platform | [de_data_platform_action_list.md](de_data_platform_action_list.md) |
| 6 | Final validation evidence capture | Validation | MAG-17 / [final_validation_execution_plan.md](final_validation_execution_plan.md) |

## Decision-to-approval gate mapping (Step 17C)

| Decision ID | Manual approval gate (MAG) |
| --- | --- |
| D-01 | MAG-05 (dev masked), MAG-06 (final PII) |
| D-02, D-03 | MAG-02 (source-certification follow-up); MAG-03 historical context only |
| D-04 | MAG-01 |
| D-05 | MAG-14 |
| D-06 | MAG-10 |
| D-07 | MAG-07 |
| D-08 | MAG-09 |
| D-09 | MAG-11 |
| D-10, D-11 | MAG-08 |
| D-12 | MAG-12 |
| D-13 | MAG-13 |
| D-14 | MAG-15 |
| D-15, D-16, D-17, D-18 | MAG-02 (required-column / source contract); D-18 also requires Validation sign-off before customer activation |
| D-19 | MAG-09 (ASIC2 seed/history; OpenTime semantics) |
| D-20 | MAG-15 (classification / exclusion parity family) |
| D-21 | MAG-02 |
| D-22 | MAG-02 (supports MAG-15 / instrument enrichment after staging certified) |
| D-23 | MAG-16 |
| D-24 | MAG-17 (evidence enhancement; non-blocking for minimal forward run) |
| D-25 | MAG-09 / SME module notes (conditional ASIC2 OpenPrice) |

**Traceability rule:** One decision may support closure of multiple MAG gates; closing a MAG gate does not automatically close a decision until this register and `docs/open_blockers_for_execution.md` are updated.

Close decisions by updating this register, `docs/manual_approval_gates.md`, and `docs/open_blockers_for_execution.md`.

## Decision register

| ID | Decision | Options / notes | Owner | Blocks |
| --- | --- | --- | --- | --- |
| D-01 | PII source access / temporary masked fallback policy | **Resolved for dev only:** manager-approved masked tables (`main.general.bronze_etoro_customer_customer_masked`, `main.general.bronze_etoro_history_customer_masked`) for temporary development/structural testing. **Still open for final parity:** grant `main.pii_data` access or obtain formal RegTech SME/Compliance approval to treat masked data as regulatory parity source | DE + Governance + Business + RegTech SME/Compliance | Final identity-field parity and final validation of Customer, RegChange Customer, Failed TRAX, NPD TRAX |
| D-02 | `Reg_CurrencyPrice_Ext` primary source selection | **Resolved (direction):** use `main.dealing.bronze_pricelog_history_currencyprice` as primary. `main.trading.bronze_etoro_trade_currencyprice` is readable but not preferred due to incomplete SSIS-selected shape | DE/Data Platform + Validation | Source certification and baseline/date-window validation before execution |
| D-03 | HedgeServerToLiquidityAccount source readiness | **Resolved (direction):** `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` is readable with required columns (`HedgeServerID`, `LiquidityAccountID`, `AltRatesLiquidityAccountID`) | DE/Data Platform + Validation | Duplicate/key and coverage validation during execution |
| D-04 | `dwh_daily_process` access for split-price comparison | **Downgraded:** no longer active blocker for split-price selection; keep only as fallback/reference access if needed later | DE/Data Platform | None for primary split-price activation path |
| D-05 | CurrencyPriceMaxDateWithSplit source selection | **Resolved (direction):** primary source is `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`; old `dwh_daily_process` and `main.dwh` candidates are fallback/reference only | DE + SME + Validation | Date-window validation + SQL Server baseline comparison |
| D-06 | `MIFID2_NPD_TRAX` seed/cutover | **Approved direction:** seed historical data required for parity/retry; if minimum safe window cannot be proven, seed all available history. MCP: 4,576,382 rows; PK dupes = 0; monthly **2019-02 – 2026-06**. Extract ownership pending. | DE + SME | NPD TRAX, Failed TRAX retry and baseline windows |
| D-07 | `MIFID2_Failed_TRAX` shared seed policy | **Approved direction:** follow D-06 shared history strategy for identity continuity and retry correctness | DE + SME | Failed TRAX staging, Customer output |
| D-08 | `ASIC2_Transactions` seed/history window | **Approved direction:** seed all history required for ETORO parity windows; default to full available history if minimum safe window is unproven. Manual count 7,245,856 narrows MCP discrepancy; post-extract row-count reconciliation still required. Monthly **2024-09 – 2026-06**. | DE + SME | ASIC2 subset, ETORO report |
| D-09 | Liquidity SCD seed/cutover | **Approved direction:** seed historical validity required for SCD/reporting; implementation plan still required | DE + SME | `Reg_LiquidtyAcount_SCD`, hedge report |
| D-10 | Migration population materialization | **Approved direction:** support historical replay/parity windows; implementation mechanism (snapshot vs recreation) still needs runbook-level plan | DE + SME | Movements, reg-change customer/position, report reg-change branches |
| D-11 | Regulation in/out daily data materialization | **Approved direction:** same historical replay/parity policy family as D-10; implementation details pending | DE + SME | Downstream reg-in/out consumers |
| D-12 | Hedge `RecordID` strategy | **Approved direction:** preserve historical SQL Server RecordIDs (seed 100000001, max 136314953, 0 dupes), continue from `MAX+1`, persistent registry required (no per-run row_number). Proposed natural key: `(ReportDate, RegulationReportID, TransactionReferenceNumber)` — **SME final signoff pending**. See [hedge_recordid_registry_design.md](hedge_recordid_registry_design.md). | SME + Engineering + Validation | `MIFID2_Hedge_Report` activation and missed-trade back-reporting |
| D-13 | Hedge transaction-reference parity | **Hard requirement:** must reproduce SQL Server/SSMS values exactly (uniqueness alone is insufficient); baseline comparison mandatory | SME + Validation | Hedge report reconciliation |
| D-14 | Exact CFI / InstrumentClassification gates | **Hard requirement:** Databricks values must match SQL Server exactly; simplified fallback classification is not acceptable | SME + Validation | ETORO report, hedge report, report instrument enrichment |
| D-15 | `Dictionary.Ext_TradeFund` mapping | Confirm Databricks object and columns (`FundAccountID`, `FundName`, `FundType`) | DE + SME | Customer, RegChange customer, report mirror enrichment |
| D-16 | `Reg_Ext_CustomerLatinName` source | Confirm source table and staging population | DE + SME | Customer, RegChange customer, ASIC2 customer profile |
| D-17 | PIN/UserAPI source contract | Finalize objects/columns for PIN enrichment | DE + SME | Customer ext, Failed TRAX |
| D-18 | ReplaceChar parity sign-off | Execute and approve UDF tests vs SQL Server | Validation owner | Customer outputs |
| D-19 | `CDE_Execution_timestamp -> OpenTime` semantics | Validate compatibility view timing fields | SME | ASIC2 compatibility view, ETORO |
| D-20 | Report-scoped exclusion semantics | Row-level `table_name` scope for ETORO/Hedge exclusions | SME | ETORO, Hedge reports |
| D-21 | Required-column certifications (batch) | Close per-source contracts listed in `docs/source_profiling_results.md` | DE + Validation | All staging modules with "confirmed accessible, certification pending" |
| D-22 | `InstrumentMetaData_SpecialChar_Conversion` activation | After `Reg_Ext_Trade_InstrumentMetaData` staging is certified and populated | Engineering | Report, Hedge, ETORO instrument enrichment |
| D-23 | SQL Server baseline dates and scoped extracts | Selected baseline report dates for huge outputs; no full `MIFID2_Report` export unless explicitly approved. See [sql_server_baseline_extract_plan.md](sql_server_baseline_extract_plan.md). | Validation + SQL Server team + SME | Cross-module and per-module baseline comparisons |
| D-24 | Step 12 optional checkpoint materialization | CTE-only vs temporary checkpoint tables for reconciliation reproducibility | Engineering | Report validation evidence (non-blocking for minimal forward run) |
| D-25 | `Reg_DWH_StaticPosition` conditional use | Keep conditional unless OpenPrice impact is proven for MiFID fields | SME | ASIC2 OpenPrice fallback only if proven |

## Resolved decisions (do not re-open without new evidence)

| Topic | Resolution |
| --- | --- |
| Target environment | `main.regtech_ops_stg` with `bi_output_regtechops_` prefix |
| Static reference tables (internal accounts, special-char dictionary, EDNF mapping) | Recreated as external Delta with explicit LOCATION under RegTechOps path |
| NOC / old Databricks attempt | Reference-only; not implementation authority (NOC = monitoring/freshness; old attempt includes delivery/SFTP/TRAX scope outside current table-generation phase) |
| Temporary masked customer tables | Manager-approved workaround for dev/structural testing only; not confirmed final/production/regulatory parity source |
| Active blocker simplification | Only active access blocker category remains `main.pii_data` customer/history access |
| Phase 1 delivery/upload/response | Out of scope |
| Phase 1 production deployment | Out of scope (`main.regtech` not targeted) |

## How to close decisions

1. Record the decision, owner, and date in `docs/open_questions_and_decisions.md` when approved.
2. Update `docs/open_blockers_for_execution.md` and `docs/unresolved_dependencies.md` to remove or downgrade resolved items.
3. Update `docs/dependency_coverage_matrix.md` status/notes if object-level impact changes.
4. Re-run relevant SELECT-only validation SQL after execution environment changes (do not un-gate DML until validations pass).

## Priority order (recommended)

1. D-01 (final PII access/exception) and D-21 (required-column certification)
2. D-05 validation closure (selected split-price source), D-06–D-11 implementation planning and extract-ownership assignment for approved historical seed strategy
3. D-12, D-13, D-14 (hard parity implementation + baseline evidence)
4. D-15–D-20 and D-22 (remaining source contracts and staged dependency gates)
5. D-23–D-25 (baseline evidence enhancements and conditional checks)
