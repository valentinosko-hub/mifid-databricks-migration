# MiFID Source Access Blockers

This register tracks active access blockers after the latest source-resolution update.

Documentation-only update:

- No SQL execution
- No Databricks object creation/modification
- No workflow deployment

## Active blockers (current)

### No schema access (active)

| Object | Status | Impacted areas | Keep gated until |
| --- | --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access | Final customer parity, identity-change logic, NPD identity fields, final `MIFID2_Customer` / `MIFID2_Failed_TRAX` / `MIFID2_NPD_TRAX` validation | `main.pii_data` access is granted or formal regulatory exception is approved |
| `main.pii_data.bronze_etoro_history_customer` | No schema access | Final customer history/as-of parity, reg-change customer parity, NPD identity continuity | `main.pii_data` access is granted or formal regulatory exception is approved |

## Temporary masked customer workaround (not a blocker closure)

Manager-approved for development/structural testing only:

| Object | Allowed use |
| --- | --- |
| `main.general.bronze_etoro_customer_customer_masked` | schema profiling, row-count checks, join-path testing, gated template development, non-production structural validation |
| `main.general.bronze_etoro_history_customer_masked` | same as above for history/as-of paths |

Not approved as final regulatory parity source.

Final parity remains gated for:

- `FirstName`, `LastName`, `BirthDate`, `PIN`, `PIN_Type`
- customer identity-change comparison
- `NonLatinOrEmptyName` detection
- final validation for `MIFID2_Customer`, `MIFID2_RegChange_Customer`, `MIFID2_Failed_TRAX`, `MIFID2_NPD_TRAX`

## Downgraded / removed as active blockers

These items are no longer tracked as active access/storage blockers:

| Object / topic | New classification | Notes |
| --- | --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | Readable but not preferred | Not selected as primary `Reg_CurrencyPrice_Ext` source |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Confirmed accessible | Required columns present; keep normal duplicate/coverage validation |
| `dwh_daily_process` for split-price comparison | Fallback/reference only | Primary split-price source selected from `main.dealing` candles table |

## Source selections linked to blocker downgrade

- `History.CurrencyPrice` / `History.CurrencyPrice_Active` / `Reg_CurrencyPrice_Ext` primary source:
  - `main.dealing.bronze_pricelog_history_currencyprice`
- `Candles.CurrencyPriceMaxDateWithSplit` / `Reg_Ext_CurrencyPriceMaxDateWithSplit` primary source:
  - `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit`

## Resolved former blockers (static references)

| Object | LOCATION | Status |
| --- | --- | --- |
| `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dbo_internal_accounts` | Resolved |
| `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dictionary_ext_specialchar` | Resolved |
| `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/ed_f_to_istrument_id_e_toro` | Resolved |

## Remaining DE/Security asks in blocker context

1. Grant `main.pii_data` customer/history access for final parity mode.
2. Support historical seed extraction/access for approved seed strategy.
3. Support later execution principal / warehouse permissions when execution enablement is approved.

## Reference-only / out-of-scope reminders

- NOC and old Databricks attempt materials remain reference-only.
- Delivery/upload/response and production deployment remain out of scope for this phase.
