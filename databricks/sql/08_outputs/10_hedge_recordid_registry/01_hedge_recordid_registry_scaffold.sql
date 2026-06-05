-- Step 10: Hedge RecordID registry/control scaffold (GATED/COMMENTED).
--
-- Scope:
-- - Persistent registry/control table design for MIFID2_Hedge_Report RecordID continuity.
-- - Staging target only: main.regtech_ops_stg.
-- - No writes to main.regtech.
--
-- Rules:
-- - Keep CREATE fully commented until approvals and prerequisites are closed.
-- - Use a fixed external LOCATION path (stable across reruns); do not use ad-hoc temp paths.
-- - Do not store raw CSV/PII in Git.
--
-- Required placeholder:
--   {{hedge_recordid_registry_location}}
-- Example:
--   abfss://{{approved_container}}@{{storage_account}}.dfs.core.windows.net/{{approved_path}}/hedge_recordid_registry/
--
-- DO NOT UNCOMMENT UNTIL:
-- - Historical source is available and validated.
-- - Natural-key signoff is approved.
-- - Registry creation is approved by DE/SME/Validation.

/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry (
  RecordID BIGINT NOT NULL,
  RecordBusinessKey STRING NOT NULL,
  ReportDate DATE NOT NULL,
  RegulationReportID INT NOT NULL,
  rowSource STRING,
  TransactionReferenceNumber STRING NOT NULL,
  ExecutionID BIGINT,
  OrderID STRING,
  EMSOrderID STRING,
  LiquidityAccountID INT,
  InstrumentID INT,
  SourceRecordOrigin STRING,
  FirstAllocatedRunID STRING,
  FirstAllocatedTimestamp TIMESTAMP,
  LastSeenRunID STRING,
  LastSeenTimestamp TIMESTAMP,
  MigratedFromSQLServerFlag BOOLEAN NOT NULL,
  IsActive BOOLEAN NOT NULL
)
USING DELTA
LOCATION '{{hedge_recordid_registry_location}}';
*/

-- Documentation gate checklist (SELECT-only note block)
SELECT
  'registry_scaffold_gate' AS gate_name,
  'pending' AS gate_status,
  'CREATE TABLE remains commented until fixed LOCATION approval and natural-key signoff.' AS gate_reason
UNION ALL
SELECT
  'registry_fixed_location_gate',
  'required',
  'Registry storage path must be fixed and reusable across reruns to preserve deterministic allocation state.'
UNION ALL
SELECT
  'registry_target_boundary',
  'required',
  'Registry objects must remain in main.regtech_ops_stg; no main.regtech writes.';
