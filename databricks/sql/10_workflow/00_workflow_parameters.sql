-- Step 17B workflow parameter skeleton (non-executing).
-- This file is SELECT-only and is intended for parameter visibility and gate diagnostics.
-- Do not add DML/DDL activation logic here.

WITH workflow_parameters AS (
  SELECT
    '{{job.parameters.report_date}}' AS report_date,
    '{{job.parameters.catalog}}' AS catalog_name,
    '{{job.parameters.schema}}' AS schema_name,
    '{{job.parameters.object_prefix}}' AS object_prefix,
    '{{job.parameters.run_mode}}' AS run_mode,
    '{{job.parameters.dry_run}}' AS dry_run,
    '{{job.parameters.dev_customer_source_mode}}' AS dev_customer_source_mode,
    '{{job.parameters.customer_source_policy}}' AS customer_source_policy,
    '{{job.parameters.allow_masked_customer_sources}}' AS allow_masked_customer_sources,
    '{{job.parameters.require_unmasked_pii_for_parity}}' AS require_unmasked_pii_for_parity,
    '{{job.parameters.skip_delivery_steps}}' AS skip_delivery_steps,
    '{{job.parameters.enable_validation_only}}' AS enable_validation_only,
    '{{job.parameters.sql_warehouse_id}}' AS sql_warehouse_id,
    '{{job.parameters.git_branch}}' AS git_branch
),
policy_evaluation AS (
  SELECT
    *,
    CASE
      WHEN lower(run_mode) = 'development_structural_test'
           AND lower(dev_customer_source_mode) = 'masked_fallback'
      THEN 'ALLOWED_FOR_STRUCTURAL_TEST_ONLY'
      WHEN lower(run_mode) = 'final_parity_production'
           AND lower(require_unmasked_pii_for_parity) = 'true'
      THEN 'UNMASKED_PII_REQUIRED'
      ELSE 'REVIEW_REQUIRED'
    END AS customer_policy_resolution
  FROM workflow_parameters
)
SELECT
  report_date,
  catalog_name,
  schema_name,
  object_prefix,
  run_mode,
  dry_run,
  dev_customer_source_mode,
  customer_source_policy,
  allow_masked_customer_sources,
  require_unmasked_pii_for_parity,
  skip_delivery_steps,
  enable_validation_only,
  sql_warehouse_id,
  git_branch,
  customer_policy_resolution
FROM policy_evaluation;
