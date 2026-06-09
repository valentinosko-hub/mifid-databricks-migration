# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/05_hedge_liquidity/01_hedge_liquidity_source_profiling.sql",
    "databricks/sql/05_hedge_liquidity/02_liquidity_ext_staging.sql",
    "databricks/sql/05_hedge_liquidity/03_reg_liquidtyacount_scd.sql",
    "databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql",
]

print(
    "Wrapper scope: HedgeServerToLiquidityAccount, LiquidityAccounts, "
    "LiquidityAccountID, LiquidityProviders, and Liquidity SCD structural checks."
)
print("Final Hedge report activation remains gated on RecordID registry validation.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
