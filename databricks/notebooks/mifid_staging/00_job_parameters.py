# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

print("MiFID staging notebook parameter snapshot:")
for key in sorted(params):
    print(f"- {key}={params[key]}")

exit_status("PASS", "Parameter guard and defaults loaded for staging wrappers.")
