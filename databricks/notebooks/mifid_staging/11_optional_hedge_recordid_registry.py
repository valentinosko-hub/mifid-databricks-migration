# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

if params["enable_manual_seed_testing_checks"] != "true":
    exit_status(
        "SKIP",
        "Optional RecordID registry path skipped by default. Enable optional seed/testing controls first.",
    )

sql_files = [
    "databricks/sql/08_outputs/10_hedge_recordid_registry/01_hedge_recordid_registry_scaffold.sql",
    "databricks/sql/08_outputs/10_hedge_recordid_registry/02_hedge_recordid_seed_from_sql_server.sql",
    "databricks/sql/08_outputs/10_hedge_recordid_registry/03_hedge_recordid_allocation_template.sql",
    "databricks/sql/08_outputs/10_hedge_recordid_registry/04_hedge_recordid_validation.sql",
]

print("This optional wrapper does not activate final MIFID2_Hedge_Report.")
print("Requires historical seed availability, natural-key SME signoff, and registry validation evidence.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
