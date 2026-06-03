-- Step 17B cross-module readiness gate wrapper (non-executing).
-- SELECT-only summary for readiness status and manual approval checkpoints.
-- Intended to run after module validation package placeholders.

SELECT
  check_group,
  check_name,
  check_status,
  required_evidence
FROM VALUES
  ('foundation', 'source_access_confirmed', 'OPEN', 'No active no-schema/no-catalog blockers for execution path'),
  ('foundation', 'required_columns_confirmed', 'OPEN', 'Required-column certifications recorded'),
  ('foundation', 'storage_data_scan_resolved', 'OPEN', 'No storage/data scan failures on required sources'),
  ('foundation', 'static_reference_availability', 'PARTIAL', 'Resolved static references + validation evidence'),
  ('policy', 'pii_source_policy_approved', 'OPEN', 'Run mode and customer policy approval recorded'),
  ('history_seed', 'history_seed_policy_approved', 'OPEN', 'Signed policies for NPD/FailedTRAX/ASIC2/SCD'),
  ('materialization', 'migration_materialization_approved', 'OPEN', 'Reg_MigrationInOut / Reg_RegulationInOut decision approved'),
  ('hedge_parity', 'hedge_recordid_strategy_approved', 'OPEN', 'RecordID parity approval evidence'),
  ('hedge_parity', 'hedge_transaction_reference_approved', 'OPEN', 'TransactionReference parity approval evidence'),
  ('validation', 'module_validation_packages_passed', 'OPEN', 'Module-level validation outputs'),
  ('validation', 'cross_module_validation_passed', 'OPEN', '09_validation readiness/manifest/dependency checks'),
  ('baseline', 'sql_server_baseline_comparison_completed', 'PENDING_OPTIONAL', 'Baseline comparison output where required')
AS readiness(check_group, check_name, check_status, required_evidence);

SELECT
  blocker_object,
  blocker_category,
  blocker_state
FROM VALUES
  ('main.trading.bronze_etoro_trade_currencyprice', 'storage_data_scan', 'OPEN'),
  ('main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount', 'storage_data_scan', 'OPEN'),
  ('main.pii_data.bronze_etoro_customer_customer', 'source_access', 'OPEN'),
  ('main.pii_data.bronze_etoro_history_customer', 'source_access', 'OPEN'),
  ('dwh_daily_process catalog', 'catalog_access', 'OPEN'),
  ('MIFID2_NPD_TRAX history/cutover', 'history_seed', 'OPEN'),
  ('ASIC2 history/seed', 'history_seed', 'OPEN'),
  ('liquidity SCD seed/cutover', 'history_seed', 'OPEN'),
  ('Hedge RecordID', 'business_decision', 'OPEN'),
  ('Hedge TransactionReferenceNumber', 'business_decision', 'OPEN')
AS blockers(blocker_object, blocker_category, blocker_state);

SELECT
  '{{job.parameters.run_mode}}' AS run_mode,
  '{{job.parameters.dev_customer_source_mode}}' AS dev_customer_source_mode,
  '{{job.parameters.customer_source_policy}}' AS customer_source_policy,
  '{{job.parameters.allow_masked_customer_sources}}' AS allow_masked_customer_sources,
  '{{job.parameters.require_unmasked_pii_for_parity}}' AS require_unmasked_pii_for_parity,
  CASE
    WHEN lower('{{job.parameters.run_mode}}') = 'development_structural_test'
      THEN 'STRUCTURAL_TEST_ONLY_MASKED_ALLOWED_WITH_APPROVAL'
    WHEN lower('{{job.parameters.run_mode}}') = 'final_parity_production'
      THEN 'UNMASKED_PII_OR_FORMAL_APPROVAL_REQUIRED'
    ELSE 'INVALID_RUN_MODE'
  END AS mode_resolution,
  'NO_DELIVERY_UPLOAD_RESPONSE_IMPLEMENTED' AS delivery_scope_guard,
  'NO_PRODUCTION_DEPLOYMENT_IMPLEMENTED' AS deployment_scope_guard;
