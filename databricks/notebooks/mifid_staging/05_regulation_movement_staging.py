# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/04_regulation_movements/01_regulation_movments_source_profiling.sql",
    "databricks/sql/04_regulation_movements/02_regulation_movments_staging.sql",
    "databricks/sql/04_regulation_movements/03_regulation_movments_validation.sql",
]

print(
    "Wrapper scope: Reg_MigrationInOut_Population snapshot, "
    "Reg_RegulationInOutDailyData snapshot, Reg_Regulation_Movments_Positions."
)
print("Final movement parity remains gated pending approvals and baseline evidence.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
