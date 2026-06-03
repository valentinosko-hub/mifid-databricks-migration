-- Step 17B run-control skeleton (non-executing).
-- SELECT-only manifest for future workflow-control behavior.
-- No CREATE/INSERT/UPDATE/DELETE/MERGE/DROP statements are allowed in this step.

SELECT
  'step17b_run_control_manifest' AS manifest_name,
  '{{job.parameters.report_date}}' AS report_date,
  '{{job.parameters.run_mode}}' AS run_mode,
  '{{job.parameters.dry_run}}' AS dry_run,
  '{{job.parameters.enable_validation_only}}' AS enable_validation_only,
  '{{job.parameters.customer_source_policy}}' AS customer_source_policy,
  '{{job.parameters.dev_customer_source_mode}}' AS dev_customer_source_mode,
  '{{job.parameters.git_branch}}' AS git_branch,
  current_timestamp() AS manifest_generated_at_utc,
  'TEMPLATE_ONLY_DO_NOT_EXECUTE_FOR_PRODUCTION' AS status;

SELECT
  gate_id,
  gate_name,
  gate_owner,
  gate_status,
  gate_evidence_required
FROM VALUES
  ('RC-01', 'source_access_confirmed', 'DE/Data Platform', 'OPEN', 'No schema/catalog blockers for active path'),
  ('RC-02', 'required_columns_confirmed', 'DE + Validation', 'OPEN', 'Required-column certifications'),
  ('RC-03', 'storage_blockers_resolved', 'DE/Data Platform', 'OPEN', 'No storage/data scan failures'),
  ('RC-04', 'masked_policy_approved', 'Governance + Compliance', 'OPEN', 'Explicit mode/policy approval'),
  ('RC-05', 'history_seed_approved', 'SME + Governance', 'OPEN', 'Signed history/cutover policies'),
  ('RC-06', 'business_parity_approved', 'SME + Validation', 'OPEN', 'RecordID/reference/classification approvals'),
  ('RC-07', 'final_validation_passed', 'Validation Owner', 'OPEN', 'Module + cross-module validation evidence')
AS run_control(gate_id, gate_name, gate_owner, gate_status, gate_evidence_required);

-- Future (commented) template only:
-- CREATE TABLE main.regtech_ops_stg.bi_output_regtechops_workflow_control (...);
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_workflow_control (...);
