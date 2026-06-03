# DE / Data Platform Action List (Step 18B)

Actions required from Data Engineering and Data Platform teams before Databricks module execution and final parity validation can proceed.

**Status:** Open items remain. Execution is blocked until remediation and access grants are evidenced in profiling and blocker registers.

Related registers:

- `docs/open_blockers_for_execution.md`
- `docs/access_blockers.md`
- `docs/manual_approval_gates.md` (MAG-02, MAG-06, MAG-14)
- `docs/remaining_decisions.md` (D-01, D-05, D-21, seed/support items)

---

## Priority 1 — PII access for final parity (MAG-06)

| # | Action | Object | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 1 | Grant schema/table access for final customer parity | `main.pii_data.bronze_etoro_customer_customer` | D-01 (final) | MAG-06 |
| 2 | Grant schema/table access for final customer history parity | `main.pii_data.bronze_etoro_history_customer` | D-01 (final) | MAG-06 |

**Note:** Manager-approved masked tables in `main.general` are **development-only** and do not satisfy this action list for final parity.

## Priority 2 — Selected source confirmation and certification (MAG-02, MAG-14)

| # | Action | Topic | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 3 | Confirm/certify selected `Reg_CurrencyPrice_Ext` source contract | `main.dealing.bronze_pricelog_history_currencyprice` | D-21 | MAG-02 |
| 4 | Confirm/certify selected `Reg_Ext_CurrencyPriceMaxDateWithSplit` source contract | `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` | D-05, D-21 | MAG-14, MAG-02 |
| 5 | Complete required-column certification for remaining “accessible, certification pending” sources | See `docs/source_profiling_results.md` | D-21 | MAG-02 |

**Confirmed accessible — certification still pending (examples):**

- `main.trading.bronze_etoro_trade_futuresmetadata`
- `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341`
- `main.trading.bronze_etoro_trade_instrumentmetadata`
- `main.general.bronze_etoro_dictionary_currency`
- `main.general.bronze_etoro_dictionary_currencytype`

## Priority 3 — Historical seed support (approved strategy, implementation pending)

| # | Action | Scope |
| --- | --- | --- |
| 6 | Provide extraction/access support for historical seed loads required by approved strategy | NPD, Failed TRAX, Hedge, ASIC2, liquidity SCD, migration/regulation in-out, movement history |
| 7 | Confirm availability windows and partition guidance for selected price/candle sources | Include `etr_y`, `etr_ym`, `etr_ymd` filter guidance |

---

## Priority 4 — Execution infrastructure (later phase)

These items are **not** required to close documentation blockers but will be needed before controlled execution or workflow activation:

| # | Action | Notes |
| --- | --- | --- |
| 8 | Confirm SQL warehouse / cluster policy for RegTech ops staging workloads | Align with platform standards |
| 9 | Confirm service principal or job identity permissions for `main.regtech_ops_stg` writes | After go/no-go for execution enablement |
| 10 | Confirm job/bundle deployment permissions if workflow skeleton is ever activated | Separate from Step 18B; requires MAG closure + deployment approval |

---

## Completion checklist (DE/Data Platform)

- [ ] `main.pii_data` customer tables accessible for final parity (Actions 1–2) **or** formal exception documented by RegTech SME/Compliance
- [ ] Selected price and split-price sources certified (Actions 3–4)
- [ ] Required-column certifications batch closed (Action 5)
- [ ] Historical seed extraction/access support confirmed (Actions 6–7)
- [ ] `docs/source_profiling_results.md` updated after certification/confirmation
- [ ] `docs/open_blockers_for_execution.md` and MAG-02/06/14 evidence updated externally

## Downgraded from active DE blockers

The following are no longer active DE storage/catalog blockers in this phase:

- `main.trading.bronze_etoro_trade_currencyprice` (readable but not preferred; primary source switched to `main.dealing.bronze_pricelog_history_currencyprice`)
- `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` (readable; required columns present)
- `dwh_daily_process` split-price comparison access (fallback/reference-only after primary source selection)

Do not enable module DML or deploy workflow until Validation/QA and Manager go/no-go criteria in `docs/post_blocker_execution_plan.md` are satisfied.
