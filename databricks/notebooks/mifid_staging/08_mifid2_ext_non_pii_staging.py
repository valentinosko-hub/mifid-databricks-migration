# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/07_mifid2_ext/01_mifid2_ext_source_profiling.sql",
    "databricks/sql/07_mifid2_ext/03_position_ext_staging.sql",
    "databricks/sql/07_mifid2_ext/04_positionchangelog_mirror_ext_staging.sql",
    "databricks/sql/07_mifid2_ext/05_hedge_ext_staging.sql",
    "databricks/sql/07_mifid2_ext/07_mifid2_ext_validation.sql",
]

print(
    "Wrapper scope: MIFID2_ext_Position, MIFID2_ext_RegChange_Position, "
    "MIFID2_ext_PositionChangeLog, MIFID2_ext_Mirror, MIFID2_ext_HedgeExecutionLog."
)
print(
    "PII customer paths remain gated and excluded from this non-PII wrapper. "
    "Failed_TRAX remains gated unless NPD history readiness/approvals are closed."
)

maybe_run_sql_files(sql_files, params, allow_execution=False)
