# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

if not (
    params["enable_masked_customer_structural_tests"] == "true"
    and params["allow_masked_customer_sources"] == "true"
):
    exit_status(
        "SKIP",
        "Optional masked-customer structural path disabled. "
        "Requires enable_masked_customer_structural_tests=true and allow_masked_customer_sources=true.",
    )

sql_files = [
    "databricks/sql/10_workflow/gates/gate_module_validation_chain.sql",
]

print("Masked customer fallback is development-only and cannot be used for final parity claims.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
