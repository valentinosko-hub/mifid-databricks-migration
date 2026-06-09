# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/03_pre_regulation_ext/04_non_price_source_profiling.sql",
    "databricks/sql/03_pre_regulation_ext/05_non_price_staging_gates.sql",
    "databricks/sql/03_pre_regulation_ext/06_non_price_validation.sql",
]

print(
    "Covers structural wrappers for Reg_Ext_Trade_GetInstrument, "
    "Reg_Ext_Trade_InstrumentMetaData, Reg_Ext_DictionaryCurrency, "
    "Reg_Ext_DictionaryCurrencyType, and Reg_Instruments_ext/SCD gates."
)

maybe_run_sql_files(sql_files, params, allow_execution=False)
