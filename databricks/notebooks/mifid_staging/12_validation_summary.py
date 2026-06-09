# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/10_workflow/gates/gate_module_validation_chain.sql",
    "databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql",
    "databricks/sql/09_validation/07_phase1_readiness_summary.sql",
    "databricks/sql/09_validation/08_cross_module_validation_manifest.sql",
    "databricks/sql/09_validation/09_cross_module_dependency_gate_checks.sql",
    "databricks/sql/10_workflow/02_audit_logging.sql",
]

print("Validation summary wrapper is staging evidence guidance only.")
print("Do not claim final regulatory parity from this notebook output.")
print("Store evidence links and manifests outside Git per staging_execution_evidence_log template.")

maybe_run_sql_files(sql_files, params, allow_execution=False)
