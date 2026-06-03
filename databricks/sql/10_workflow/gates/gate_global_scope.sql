-- Step 17B global gate wrapper (non-executing).
-- This is a SELECT-only gate summary for scope, policy, and blocker-awareness checks.

WITH param_eval AS (
  SELECT
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
    '{{job.parameters.enable_validation_only}}' AS enable_validation_only
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
  FROM param_eval
  UNION ALL
  SELECT
    'GATE-02' AS gate_id,
    'environment_naming_gate' AS gate_name,
    CASE
      WHEN lower(catalog_name) = 'main'
       AND lower(schema_name) = 'regtech_ops_stg'
       AND lower(object_prefix) = 'bi_output_regtechops_'
      THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Targets must remain under main.regtech_ops_stg with bi_output_regtechops_ prefix' AS gate_rule
  FROM param_eval
  UNION ALL
  SELECT
    'GATE-03' AS gate_id,
    'dry_run_gate' AS gate_name,
    CASE
      WHEN lower(dry_run) = 'true' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Step 17B skeleton must remain dry-run template until approvals close' AS gate_rule
  FROM param_eval
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
  FROM param_eval
  UNION ALL
  SELECT
    'GATE-05' AS gate_id,
    'validation_only_gate' AS gate_name,
    CASE
      WHEN lower(enable_validation_only) = 'true' THEN 'PASS'
      ELSE 'BLOCK'
    END AS gate_status,
    'Step 17B should remain non-executing readiness/validation-oriented' AS gate_rule
  FROM param_eval
)
SELECT
  gate_id,
  gate_name,
  gate_status,
  gate_rule
FROM gate_checks
ORDER BY gate_id;

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
