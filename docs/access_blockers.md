# MiFID Source Access Blockers

This document tracks runtime access blockers identified by the latest MiFID source profiling run (`MiFID_Source_Profiling (1).csv`) and the actions required from DE/Data Platform, governance, or business owners before gated migration modules can activate.

This is a documentation-only artifact. No SQL was executed and no Databricks objects were created or modified by this step.

## Blocker taxonomy

- No schema access
- No catalog access
- Storage/data scan failure
- Table not found (resolved separately for RegTech static reference tables)
- Candidate source still needs certification

## Active blockers

### 1. Storage/data scan failures

| Object | Status | Impacted migration areas | Keep gated until |
| --- | --- | --- | --- |
| `main.trading.bronze_etoro_trade_currencyprice` | Storage/data scan failure | Step 5B1 `Reg_CurrencyPrice_Ext`, Step 12 price derivation, movement enrichment that depends on currency-price staging | DE/Data Platform resolves underlying storage issue or certifies an alternative source for `History.CurrencyPrice_Active` |
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Storage/data scan failure | Step 7 `Reg_HedgeServerToLiquidityAccount_Ext`, Step 7 SCD, Step 14 hedge liquidity mapping | DE/Data Platform resolves underlying storage issue |

### 2. No schema access

| Object | Status | Impacted migration areas | Keep gated until |
| --- | --- | --- | --- |
| `main.pii_data.bronze_etoro_customer_customer` | No schema access | Step 8/9/10/11 customer staging, failed-TRAX supplementation, NPD_TRAX customer-dependent logic | Schema access is granted or a business-approved masked/alternative customer source is confirmed |
| `main.pii_data.bronze_etoro_history_customer` | No schema access | Step 8/9 customer as-of/history enrichment, NPD_TRAX customer-dependent logic | Schema access is granted or a business-approved masked/alternative history source is confirmed |

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
3. Grant schema access to `main.pii_data` customer tables or approve a masked/alternative customer source for MiFID customer modules.
4. Grant `USE CATALOG dwh_daily_process` so fallback customer-history and split-price candidate objects can be profiled, or formally retire those candidates in favor of accessible alternatives.
5. Confirm whether `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` should be promoted from accessible candidate to certified source for `Reg_Ext_CurrencyPriceMaxDateWithSplit`.

## Business/governance actions still required

- Confirm `Dictionary.Ext_TradeFund` Databricks mapping.
- Confirm `Reg_Ext_CustomerLatinName` source mapping.
- Confirm PIN/UserAPI source contract for Step 9 customer enrichment.
- Approve RecordID, transaction-reference parity, and module activation gates that are independent of source visibility.

## Out of scope / reference-only

The following are not implementation authority for current MiFID table-generation logic in `main.regtech_ops_stg`:

- NOC monitoring documents (reference-only)
- Old Databricks attempt / deployment guide (reference-only)

Also out of current phase scope:

- File delivery: CSV, 7z, SFTP
- TRAX/Cappitech upload and response handling
- Production deployment to `main.regtech`
