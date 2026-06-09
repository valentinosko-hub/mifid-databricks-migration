# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/03_pre_regulation_ext/00_pre_regulation_parameters.sql",
    "databricks/sql/03_pre_regulation_ext/01_price_currency_source_profiling.sql",
    "databricks/sql/03_pre_regulation_ext/02_price_currency_staging.sql",
    "databricks/sql/03_pre_regulation_ext/03_price_currency_validation.sql",
]

print("Preferred CurrencyPrice source: main.dealing.bronze_pricelog_history_currencyprice")
print(
    "Preferred CurrencyPriceMaxDateWithSplit source: "
    "main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit"
)
print(
    "Do not use full-table COUNT on massive CurrencyPrice history. Prefer report-date "
    "and/or one-hour lookback checks for readiness evidence."
)

maybe_run_sql_files(sql_files, params, allow_execution=False)
