# MiFID Source Access Blockers

This document tracks runtime access blockers identified by the latest MiFID source profiling run (`MiFID_Source_Profiling (1).csv`) and the actions required from DE/Data Platform, governance, or business owners before gated migration modules can activate.

This is a documentation-only artifact. No SQL was executed and no Databricks objects were created or modified by this step.

## Blocker taxonomy

- No schema access
- No catalog access
- Storage/data scan failure
- Table not found (resolved separately for RegTech static reference tables)
- Candidate source still needs certification
- Temporary development fallback / manager-approved workaround

## Temporary masked customer workaround (manager-approved; not a blocker closure)

The following masked general tables are approved for **temporary development and structural testing only** while `main.pii_data` access remains pending:

| Object | Status | Allowed use |
| --- | --- | --- |
| `main.general.bronze_etoro_customer_customer_masked` | Temporary development fallback / manager-approved workaround | Schema/column profiling, row counts, join-path tests, gated template dev, non-production structural validation, workflow dry-run planning without identity parity certification |
| `main.general.bronze_etoro_history_customer_masked` | Temporary development fallback / manager-approved workaround | Same as above for history/as-of paths |

Not approved as: Confirmed final source, Production source, Regulatory parity source.

Final expected sources remain:

- `main.pii_data.bronze_etoro_customer_customer`
- `main.pii_data.bronze_etoro_history_customer`

Final field-level parity remains gated for identity-sensitive fields and final validation of `MIFID2_Customer`, `MIFID2_RegChange_Customer`, `MIFID2_Failed_TRAX`, and `MIFID2_NPD_TRAX`.

Future workflow/orchestration must distinguish development/structural test mode (masked) from final parity/production mode (unmasked PII or formal approval).

## Active blockers

### 1. Storage/data scan failures

| Object | Status | Impacted migration areas | Keep gated until |
| --- | --- | --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | Storage/data scan failure | Step 5B1 `Reg_CurrencyPrice_Ext`, Step 12 price derivation, movement enrichment that depends on currency-price staging | DE/Data Platform resolves underlying storage issue or certifies an alternative source for `History.CurrencyPrice_Active` |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Storage/data scan failure | Step 7 `Reg_HedgeServerToLiquidityAccount_Ext`, Step 7 SCD, Step 14 hedge liquidity mapping | DE/Data Platform resolves underlying storage issue |

### 2. No schema access

| Object | Status | Impacted migration areas | Keep gated until |
| --- | --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access | Final customer parity, identity-change logic, NPD_TRAX identity fields, final `MIFID2_Customer` / `MIFID2_Failed_TRAX` / `MIFID2_NPD_TRAX` validation | Grant `main.pii_data` schema access (masked general tables do not close this blocker) |
| `main.pii_data.bronze_etoro_history_customer` | No schema access | Final customer as-of/history parity and final reg-change/NPD validation | Grant `main.pii_data` schema access (masked general tables do not close this blocker) |

### 3. No catalog access

| Object | Status | Impacted migration areas | Keep gated until |
| --- | --- | --- | --- |
| `dwh_daily_process.daily_snapshot.etoro_history_customer` | No catalog access | fallback customer-history candidate profiling | `USE CATALOG dwh_daily_process` is granted or fallback is explicitly retired |
| `dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit` | No catalog access | `Reg_Ext_CurrencyPriceMaxDateWithSplit` candidate comparison | `USE CATALOG dwh_daily_process` is granted or `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` is formally certified as the sole source |

## Resolved former blockers (static reference tables)

The following `main.regtech_ops_stg` static/reference tables were previously blocked by table-not-found/missing source status and are now resolved as external Delta tables with explicit LOCATION:

| Object | LOCATION | New status |
| --- | --- | --- |
| `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dbo_internal_accounts` | Static reference resolved with explicit external LOCATION |
| `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/dictionary_ext_specialchar` | Static reference resolved with explicit external LOCATION |
| `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/ed_f_to_istrument_id_e_toro` | Static reference resolved with explicit external LOCATION |

These are RegTech static/reference tables, not raw DE source tables.

## DE/Data Platform action list

1. Resolve storage/data scan failure on `main.trading.bronze_etoro_trade_currencyprice` or provide a certified alternative for `Reg_CurrencyPrice_Ext`.
2. Resolve storage/data scan failure on `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` for hedge liquidity mapping.
3. Grant schema access to `main.pii_data` customer tables for final regulatory parity (masked general tables are already approved for temporary development/structural testing only).
4. Grant `USE CATALOG dwh_daily_process` so fallback customer-history and split-price candidate objects can be profiled, or formally retire those candidates in favor of accessible alternatives.
5. Confirm whether `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` should be promoted from accessible candidate to certified source for `Reg_Ext_CurrencyPriceMaxDateWithSplit`.

## Business/governance actions still required

- Confirm `Dictionary.Ext_TradeFund` Databricks mapping.
- Confirm `Reg_Ext_CustomerLatinName` source mapping.
- Confirm PIN/UserAPI source contract for Step 9 customer enrichment.
- Approve RecordID, transaction-reference parity, and module activation gates that are independent of source visibility.

## Out of scope / reference-only

The following are not implementation authority for current MiFID table-generation logic in `main.regtech_ops_stg`:

- NOC monitoring documents (reference-only; monitoring/freshness scope; not MiFID report-generation authority)
- Old Databricks attempt / deployment guide (reference-only; includes delivery/SFTP/TRAX-style scope outside current table-generation phase)

Also out of current phase scope:

- File delivery: CSV, 7z, SFTP
- TRAX/Cappitech upload and response handling
- Production deployment to `main.regtech`
