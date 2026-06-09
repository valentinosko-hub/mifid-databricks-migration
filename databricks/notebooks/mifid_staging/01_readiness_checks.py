# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/12_staging_readiness/04_target_schema_safety_checks.sql",
    "databricks/sql/10_workflow/gates/gate_global_scope.sql",
    "databricks/sql/12_staging_readiness/01_source_table_existence_checks.sql",
    "databricks/sql/12_staging_readiness/02_required_column_checks.sql",
    "databricks/sql/12_staging_readiness/03_row_count_date_range_checks.sql",
]

print(
    "Readiness notes: system.information_schema may be blocked; use catalog-scoped "
    "main.information_schema (or parameterized catalog) and manual evidence where needed."
)
print("Operational rule: stop on FAIL/BLOCK. TODO/SKIP/RUN_MANUAL rows require evidence review.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
