# Databricks notebook source
# MAGIC %run ./99_common_utils

# COMMAND ----------

params = get_job_params()
validate_staging_params(params)

sql_files = [
    "databricks/sql/01_static_references/01_static_reference_compatibility.sql",
    "databricks/sql/validation/01_static_reference_row_counts.sql",
    "databricks/sql/validation/02_static_reference_required_columns.sql",
    "databricks/sql/validation/03_static_reference_null_keys.sql",
    "databricks/sql/validation/04_static_reference_duplicate_keys.sql",
    "databricks/sql/validation/05_ednf_mapping_duplicate_checks.sql",
    "databricks/sql/validation/06_internalaccounts_cid_duplicate_checks.sql",
    "databricks/sql/validation/07_dictionary_ext_specialchar_duplicate_key_checks.sql",
    "databricks/sql/02_udfs/01_fn_replacechar.sql",
    "databricks/sql/02_udfs/02_instrumentmetadata_specialchar_conversion_deferred.sql",
]

print(
    "Static/reference wrapper only. TODO: keep one-to-one task mapping synchronized with "
    "staging job YAML as source mappings are finalized."
)

maybe_run_sql_files(sql_files, params, allow_execution=False)
