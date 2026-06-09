# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

if params["enable_manual_seed_testing_checks"] != "true":
    exit_status(
        "SKIP",
        "Optional manual seed path disabled. Requires enable_manual_seed_testing_checks=true.",
    )

sql_files = [
    "databricks/sql/11_seed_testing/01_create_manual_seed_external_tables.sql",
    "databricks/sql/11_seed_testing/02_load_mifid2_npd_trax_csv_template.sql",
    "databricks/sql/11_seed_testing/03_load_mifid2_hedge_report_csv_template.sql",
    "databricks/sql/11_seed_testing/04_manual_seed_validation.sql",
]

print("Manual seed is staging-only. No CSV/extract files may be committed to Git.")
print("Use approved secure storage only for CSVs/manifests.")
print("Current NPD CSV is for load-mechanics testing only.")
print("Final NPD CSV must be regenerated later when the NPD step is reached.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
