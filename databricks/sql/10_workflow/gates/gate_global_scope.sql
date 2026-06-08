-- Step 17B / staging smoke-test global gate wrapper (non-executing).
-- SELECT-only gate summary for scope, source/target policy, and blocker-awareness checks.
-- No DDL/DML.

WITH param_eval AS (
  SELECT
    '{{job.parameters.source_catalog}}' AS source_catalog_name,
    '{{job.parameters.source_schema}}' AS source_schema_name,
    '{{job.parameters.target_catalog}}' AS target_catalog_name,
    '{{job.parameters.target_schema}}' AS target_schema_name,
    '{{job.parameters.catalog}}' AS catalog_name,
    '{{job.parameters.schema}}' AS schema_name,
    '{{job.parameters.object_prefix}}' AS object_prefix,
    '{{job.parameters.run_mode}}' AS run_mode,
    '{{job.parameters.dry_run}}' AS dry_run,
    '{{job.parameters.staging_execution_approved}}' AS staging_execution_approved,
    '{{job.parameters.dev_customer_source_mode}}' AS dev_customer_source_mode,
    '{{job.parameters.customer_source_policy}}' AS customer_source_policy,
    '{{job.parameters.allow_masked_customer_sources}}' AS allow_masked_customer_sources,
    '{{job.parameters.require_unmasked_pii_for_parity}}' AS require_unmasked_pii_for_parity,
    '{{job.parameters.skip_delivery_steps}}' AS skip_delivery_steps,
    '{{job.parameters.enable_validation_only}}' AS enable_validation_only
),
resolved_targets AS (
  SELECT
    *,
    lower(coalesce(nullif(trim(target_catalog_name), ''), catalog_name)) AS effective_target_catalog,
    lower(coalesce(nullif(trim(target_schema_name), ''), schema_name)) AS effective_target_schema,
    lower(coalesce(nullif(trim(source_catalog_name), ''), 'main')) AS effective_source_catalog,
    lower(coalesce(nullif(trim(source_schema_name), ''), 'regtech')) AS effective_source_schema
  FROM param_eval
),
gate_checks AS (
  SELECT
    'GATE-01' AS gate_id,
    'scope_gate' AS gate_name,
    CASE
      WHEN lower(skip_delivery_steps) = 'true' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Delivery/upload/response tasks must remain excluded' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-02' AS gate_id,
    'target_write_schema_gate' AS gate_name,
    CASE
      WHEN effective_target_catalog = 'main'
       AND effective_target_schema = 'regtech_ops_stg'
      THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Write target must be main.regtech_ops_stg' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-03' AS gate_id,
    'dry_run_gate' AS gate_name,
    CASE
      WHEN lower(dry_run) = 'true' THEN 'PASS'
      WHEN lower(dry_run) = 'false'
           AND lower(staging_execution_approved) = 'true'
           AND lower(run_mode) = 'development_structural_test'
      THEN 'PASS_WITH_LIMITS'
      ELSE 'BLOCK'
    END AS gate_status,
    'dry_run=true is default safe mode; dry_run=false requires staging_execution_approved=true and development_structural_test (MAG-18)' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-04' AS gate_id,
    'masked_customer_policy_gate' AS gate_name,
    CASE
      WHEN lower(run_mode) = 'development_structural_test'
           AND lower(dev_customer_source_mode) = 'masked_fallback'
      THEN 'PASS_WITH_LIMITS'
      WHEN lower(run_mode) = 'final_parity_production'
           AND lower(require_unmasked_pii_for_parity) = 'true'
           AND lower(allow_masked_customer_sources) = 'false'
      THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Masked sources are structural-test only; final parity requires unmasked PII or formal approval' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-05' AS gate_id,
    'validation_only_gate' AS gate_name,
    CASE
      WHEN lower(enable_validation_only) = 'true' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Workflow should remain readiness/validation-oriented until explicitly approved' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-06' AS gate_id,
    'source_read_policy_gate' AS gate_name,
    CASE
      WHEN effective_source_catalog = 'main'
       AND effective_source_schema = 'regtech'
      THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Primary read source policy: main.regtech (DE-migrated sources)' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-07' AS gate_id,
    'forbid_main_regtech_write_gate' AS gate_name,
    CASE
      WHEN effective_target_schema <> 'regtech' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'main.regtech must never be a write target from RegTech staging jobs' AS gate_rule
  FROM resolved_targets
  UNION ALL
  SELECT
    'GATE-08' AS gate_id,
    'object_prefix_gate' AS gate_name,
    CASE
      WHEN lower(object_prefix) LIKE 'bi_output_regtechops_%' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Generated persistent objects must use bi_output_regtechops_ prefix' AS gate_rule
  FROM resolved_targets
)
SELECT
  gate_id,
  gate_name,
  gate_status,
  gate_rule
FROM gate_checks
ORDER BY gate_id;

SELECT
  effective_source_catalog AS source_catalog,
  effective_source_schema AS source_schema,
  effective_target_catalog AS target_catalog,
  effective_target_schema AS target_schema,
  object_prefix,
  dry_run,
  staging_execution_approved,
  run_mode
FROM resolved_targets;

SELECT
  blocker_id,
  blocker_object,
  blocker_status,
  blocker_reason
FROM VALUES
  ('B-01', 'main.trading.bronze_etoro_trade_currencyprice', 'OPEN', 'Storage/data scan failure'),
  ('B-02', 'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount', 'OPEN', 'Storage/data scan failure'),
  ('B-03', 'main.pii_data.bronze_etoro_customer_customer', 'OPEN', 'No schema access for final parity'),
  ('B-04', 'main.pii_data.bronze_etoro_history_customer', 'OPEN', 'No schema access for final parity'),
  ('B-05', 'dwh_daily_process catalog', 'OPEN', 'No catalog access'),
  ('B-06', 'MIFID2_NPD_TRAX history/cutover', 'OPEN', 'History/seed decision pending'),
  ('B-07', 'ASIC2_Transactions seed/history', 'OPEN', 'History/seed decision pending'),
  ('B-08', 'Reg_LiquidtyAcount_SCD seed/cutover', 'OPEN', 'History/seed decision pending'),
  ('B-09', 'Hedge RecordID strategy', 'OPEN', 'Business parity decision pending'),
  ('B-10', 'Hedge TransactionReferenceNumber parity', 'OPEN', 'Business parity decision pending')
AS blockers(blocker_id, blocker_object, blocker_status, blocker_reason);
