# DE / Data Platform Action List (Step 18B)

Actions required from Data Engineering and Data Platform teams before Databricks module execution and final parity validation can proceed.

**Status:** Open items remain. Execution is blocked until remediation and access grants are evidenced in profiling and blocker registers.

Related registers:

- `docs/open_blockers_for_execution.md`
- `docs/access_blockers.md`
- `docs/manual_approval_gates.md` (MAG-01, MAG-02, MAG-03, MAG-06, MAG-14)
- `docs/remaining_decisions.md` (D-02 through D-05, D-21)

---

## Priority 1 — Storage / data scan failures (MAG-03)

| # | Action | Object | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 1 | Fix storage/data scan failure so table is readable and profiled | `main.trading.bronze_etoro_trade_currencyprice` | D-02 | MAG-03 |
| 2 | Fix storage/data scan failure so table is readable and profiled | `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | D-03 | MAG-03 |

**Evidence when done:** Successful `DESCRIBE` / sample read / re-profile entry in `docs/source_profiling_results.md`; update `docs/open_blockers_for_execution.md`.

---

## Priority 2 — PII access for final parity (MAG-06)

| # | Action | Object | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 3 | Grant schema/table access for final customer parity | `main.pii_data.bronze_etoro_customer_customer` | D-01 (final) | MAG-06 |
| 4 | Grant schema/table access for final customer history parity | `main.pii_data.bronze_etoro_history_customer` | D-01 (final) | MAG-06 |

**Note:** Manager-approved masked tables in `main.general` are **development-only** and do not satisfy this action list for final parity.

---

## Priority 3 — Catalog access (MAG-01)

| # | Action | Scope | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 5 | Grant catalog access if still required for profiling and split-price comparison | `dwh_daily_process` | D-04 | MAG-01 |
| 6 | Confirm readable access to daily snapshot history (if catalog granted) | `dwh_daily_process.daily_snapshot.etoro_history_customer` | D-04 | MAG-01 |
| 7 | Confirm readable access to migration split-price table (if catalog granted) | `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` | D-05 | MAG-01, MAG-14 |

---

## Priority 4 — Source selection and certification (MAG-02, MAG-14)

| # | Action | Topic | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 8 | Confirm or certify final source for `CurrencyPriceMaxDateWithSplit` | `dwh_daily_process` candidate vs `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | D-05 | MAG-14 |
| 9 | Complete required-column certification for all “accessible, certification pending” sources | See `docs/source_profiling_results.md` | D-21 | MAG-02 |

**Confirmed accessible — certification still pending (examples):**

- `main.trading.bronze_etoro_trade_futuresmetadata`
- `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341`
- `main.trading.bronze_etoro_trade_instrumentmetadata`
- `main.general.bronze_etoro_dictionary_currency`
- `main.general.bronze_etoro_dictionary_currencytype`

---

## Priority 5 — Execution infrastructure (later phase)

These items are **not** required to close documentation blockers but will be needed before controlled execution or workflow activation:

| # | Action | Notes |
| --- | --- | --- |
| 10 | Confirm SQL warehouse / cluster policy for RegTech ops staging workloads | Align with platform standards |
| 11 | Confirm service principal or job identity permissions for `main.regtech_ops_stg` writes | After go/no-go for execution enablement |
| 12 | Confirm job/bundle deployment permissions if workflow skeleton is ever activated | Separate from Step 18B; requires MAG closure + deployment approval |

---

## Completion checklist (DE/Data Platform)

- [ ] Currency price storage scan resolved (Action 1)
- [ ] Hedge-server-to-liquidity storage scan resolved (Action 2)
- [ ] `main.pii_data` customer tables accessible for final parity (Actions 3–4) **or** formal exception documented by RegTech SME/Compliance (not a DE-only closure)
- [ ] `dwh_daily_process` access granted or candidates retired with SME sign-off (Actions 5–7)
- [ ] Split-price source certified (Action 8)
- [ ] Required-column certifications batch closed (Action 9)
- [ ] `docs/source_profiling_results.md` updated after remediation
- [ ] `docs/open_blockers_for_execution.md` and MAG-01/02/03/06/14 evidence updated externally

Do not enable module DML or deploy workflow until Validation/QA and Manager go/no-go criteria in `docs/post_blocker_execution_plan.md` are satisfied.
