# Remaining Decisions (Step 16B2)

This document consolidates open technical and business decisions that must be closed before Databricks execution and module un-gating.

Source registers:

- `docs/open_blockers_for_execution.md`
- `docs/unresolved_dependencies.md`
- `docs/open_questions_and_decisions.md`
- `docs/history_seed_requirements.md`

## Decision register

| ID | Decision | Options / notes | Owner | Blocks |
| --- | --- | --- | --- | --- |
| D-01 | PII source access / temporary masked fallback policy | **Resolved for dev only:** manager-approved masked tables (`main.general.bronze_etoro_customer_customer_masked`, `main.general.bronze_etoro_history_customer_masked`) for temporary development/structural testing. **Still open for final parity:** grant `main.pii_data` access or obtain formal RegTech SME/Compliance approval to treat masked data as regulatory parity source | DE + Governance + Business + RegTech SME/Compliance | Final identity-field parity and final validation of Customer, RegChange Customer, Failed TRAX, NPD TRAX |
| D-02 | CurrencyPrice storage issue / alternative source | Fix `main.trading.bronze_etoro_trade_currencyprice` scan failure vs certify alternative for `History.CurrencyPrice_Active` | DE/Data Platform | `Reg_CurrencyPrice_Ext`, report pricing, movements |
| D-03 | HedgeServerToLiquidityAccount storage issue | Fix `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` vs certified alternative | DE/Data Platform | Hedge liquidity ext, SCD, hedge report |
| D-04 | `dwh_daily_process` access | Grant catalog access for comparison vs retire candidates | DE/Data Platform | Customer-history fallback profiling, split-price candidate comparison |
| D-05 | CurrencyPriceMaxDateWithSplit source selection | `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` vs certify `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` as sole source | DE + SME | Split-price staging, movement enrichment, report split logic |
| D-06 | `MIFID2_NPD_TRAX` seed/cutover | Prior latest rows by `(CID, RegulationID)` for validation windows vs forward-only clean start (non-historical parity) | DE + SME | NPD TRAX, Failed TRAX retry logic |
| D-07 | `MIFID2_Failed_TRAX` shared seed policy | Must align with D-06 NPD history availability | DE + SME | Failed TRAX staging, Customer output |
| D-08 | `ASIC2_Transactions` seed/history window | Define optional seed boundaries for older ETORO parity windows | DE + SME | ASIC2 subset, ETORO report |
| D-09 | Liquidity SCD seed/cutover | Seed/rebuild vs incremental; removed-account `IsLast` parity vs correction | DE + SME | `Reg_LiquidtyAcount_SCD`, hedge report |
| D-10 | Migration population materialization | Prefixed snapshot from `main.regtech` gold vs SSIS-compatible recreation from run-date inputs | DE + SME | Movements, reg-change customer/position, report reg-change branches |
| D-11 | Regulation in/out daily data materialization | Same policy family as D-10 for `Reg_RegulationInOutDailyData` consumers | DE + SME | Downstream reg-in/out consumers |
| D-12 | Hedge `RecordID` strategy | Deterministic generation vs other approved approach (SQL Server: `IDENTITY(100000001,1)`) | SME + Engineering | `MIFID2_Hedge_Report` activation |
| D-13 | Hedge transaction-reference parity | Approve SQL Server-style expression behavior and exclusion-key matching | SME + Validation | Hedge report reconciliation |
| D-14 | Exact CFI / InstrumentClassification gates | Port/hard-gate closure for ETORO/Hedge/report flows where still open | SME | ETORO report, hedge report, report instrument enrichment |
| D-15 | `Dictionary.Ext_TradeFund` mapping | Confirm Databricks object and columns (`FundAccountID`, `FundName`, `FundType`) | DE + SME | Customer, RegChange customer, report mirror enrichment |
| D-16 | `Reg_Ext_CustomerLatinName` source | Confirm source table and staging population | DE + SME | Customer, RegChange customer, ASIC2 customer profile |
| D-17 | PIN/UserAPI source contract | Finalize objects/columns for PIN enrichment | DE + SME | Customer ext, Failed TRAX |
| D-18 | ReplaceChar parity sign-off | Execute and approve UDF tests vs SQL Server | Validation owner | Customer outputs |
| D-19 | `CDE_Execution_timestamp -> OpenTime` semantics | Validate compatibility view timing fields | SME | ASIC2 compatibility view, ETORO |
| D-20 | Report-scoped exclusion semantics | Row-level `table_name` scope for ETORO/Hedge exclusions | SME | ETORO, Hedge reports |
| D-21 | Required-column certifications (batch) | Close per-source contracts listed in `docs/source_profiling_results.md` | DE + Validation | All staging modules with "confirmed accessible, certification pending" |
| D-22 | `InstrumentMetaData_SpecialChar_Conversion` activation | After `Reg_Ext_Trade_InstrumentMetaData` staging is certified and populated | Engineering | Report, Hedge, ETORO instrument enrichment |
| D-23 | Optional SQL Server baseline sources | Provide normalized baseline tables/views per output module | Validation + SQL Server team | Cross-module and per-module baseline comparisons |
| D-24 | Step 12 optional checkpoint materialization | CTE-only vs temporary checkpoint tables for reconciliation reproducibility | Engineering | Report validation evidence (non-blocking for minimal forward run) |
| D-25 | `Reg_DWH_StaticPosition` conditional use | Keep conditional unless OpenPrice impact is proven for MiFID fields | SME | ASIC2 OpenPrice fallback only if proven |

## Resolved decisions (do not re-open without new evidence)

| Topic | Resolution |
| --- | --- |
| Target environment | `main.regtech_ops_stg` with `bi_output_regtechops_` prefix |
| Static reference tables (internal accounts, special-char dictionary, EDNF mapping) | Recreated as external Delta with explicit LOCATION under RegTechOps path |
| NOC / old Databricks attempt | Reference-only; not implementation authority (NOC = monitoring/freshness; old attempt includes delivery/SFTP/TRAX scope outside current table-generation phase) |
| Temporary masked customer tables | Manager-approved workaround for dev/structural testing only; not confirmed final/production/regulatory parity source |
| Phase 1 delivery/upload/response | Out of scope |
| Phase 1 production deployment | Out of scope (`main.regtech` not targeted) |

## How to close decisions

1. Record the decision, owner, and date in `docs/open_questions_and_decisions.md` when approved.
2. Update `docs/open_blockers_for_execution.md` and `docs/unresolved_dependencies.md` to remove or downgrade resolved items.
3. Update `docs/dependency_coverage_matrix.md` status/notes if object-level impact changes.
4. Re-run relevant SELECT-only validation SQL after execution environment changes (do not un-gate DML until validations pass).

## Priority order (recommended)

1. D-01, D-02, D-03, D-04 (access and storage)
2. D-05, D-21 (source selection and column certification)
3. D-06, D-07, D-08, D-09, D-10, D-11 (history/seed and materialization)
4. D-12, D-13, D-14, D-15–D-20 (business parity)
5. D-22–D-25 (conditional / evidence enhancements)
