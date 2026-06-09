# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/06_asic2_subset/01_asic2_source_profiling.sql",
    "databricks/sql/06_asic2_subset/02_asic2_ext_staging.sql",
    "databricks/sql/06_asic2_subset/03_asic2_positions_and_instruments.sql",
    "databricks/sql/06_asic2_subset/04_asic2_transactions.sql",
    "databricks/sql/06_asic2_subset/05_mifid_asic_compatibility_view.sql",
    "databricks/sql/06_asic2_subset/06_asic2_validation.sql",
]

print("ASIC2 wrapper is structural-only and does not claim ETORO final parity.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
