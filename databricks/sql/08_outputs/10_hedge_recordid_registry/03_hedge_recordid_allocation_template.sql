-- Step 10: Hedge RecordID future allocation template (GATED/COMMENTED).
--
-- Purpose:
-- - Reuse existing RecordID for already-known RecordBusinessKey rows.
-- - Allocate new RecordID only for unseen rows (genuinely new or missed-trade back-reporting).
-- - Allocate from MAX(existing RecordID) + deterministic row_number for unseen rows only.
--
-- IMPORTANT:
-- - This is design-template SQL only; keep fully commented until approvals close.
-- - Do not use non-deterministic identity behavior.
-- - Do not use per-run row_number over all rows that could reassign existing IDs.
--
-- Inputs placeholder:
-- - {{prepared_hedge_candidates_source}}
--   (candidate rows prepared for Hedge report projection, not final output activation)
-- - {{allocation_run_id}}

/*
WITH candidates AS (
  SELECT
    CAST(c.ReportDate AS DATE) AS ReportDate,
    CAST(c.RegulationReportID AS INT) AS RegulationReportID,
    CAST(c.rowSource AS STRING) AS rowSource,
    CAST(c.TransactionReferenceNumber AS STRING) AS TransactionReferenceNumber,
    CAST(c.ExecutionID AS BIGINT) AS ExecutionID,
    CAST(c.OrderID AS STRING) AS OrderID,
    CAST(c.EMSOrderID AS STRING) AS EMSOrderID,
    CAST(c.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(c.InstrumentID AS INT) AS InstrumentID,
    concat_ws(
      '|',
      CAST(c.ReportDate AS STRING),
      CAST(c.RegulationReportID AS STRING),
      coalesce(trim(c.TransactionReferenceNumber), '')
    ) AS RecordBusinessKey
  FROM {{prepared_hedge_candidates_source}} c
  WHERE c.ReportDate IS NOT NULL
    AND c.RegulationReportID IS NOT NULL
    AND c.TransactionReferenceNumber IS NOT NULL
),
existing AS (
  SELECT
    RecordBusinessKey,
    RecordID
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
  WHERE IsActive = TRUE
),
unseen AS (
  SELECT c.*
  FROM candidates c
  LEFT JOIN existing e
    ON c.RecordBusinessKey = e.RecordBusinessKey
  WHERE e.RecordBusinessKey IS NULL
),
base_max AS (
  SELECT COALESCE(MAX(RecordID), 136314953) AS current_max_recordid
  FROM main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry
),
new_allocations AS (
  SELECT
    u.*,
    b.current_max_recordid
      + ROW_NUMBER() OVER (
          ORDER BY
            u.ReportDate,
            u.RegulationReportID,
            u.TransactionReferenceNumber,
            coalesce(u.ExecutionID, -1),
            coalesce(u.OrderID, ''),
            coalesce(u.EMSOrderID, '')
        ) AS AllocatedRecordID
  FROM unseen u
  CROSS JOIN base_max b
),
resolved_ids AS (
  SELECT
    c.RecordBusinessKey,
    c.ReportDate,
    c.RegulationReportID,
    c.rowSource,
    c.TransactionReferenceNumber,
    c.ExecutionID,
    c.OrderID,
    c.EMSOrderID,
    c.LiquidityAccountID,
    c.InstrumentID,
    COALESCE(e.RecordID, n.AllocatedRecordID) AS RecordID,
    CASE
      WHEN e.RecordID IS NOT NULL THEN 'REGISTRY_REUSED'
      ELSE 'DATABRICKS_NEW_ALLOCATION'
    END AS SourceRecordOrigin
  FROM candidates c
  LEFT JOIN existing e
    ON c.RecordBusinessKey = e.RecordBusinessKey
  LEFT JOIN new_allocations n
    ON c.RecordBusinessKey = n.RecordBusinessKey
)
MERGE INTO main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry AS tgt
USING resolved_ids s
ON tgt.RecordBusinessKey = s.RecordBusinessKey
WHEN MATCHED THEN UPDATE SET
  tgt.ReportDate = s.ReportDate,
  tgt.RegulationReportID = s.RegulationReportID,
  tgt.rowSource = s.rowSource,
  tgt.TransactionReferenceNumber = s.TransactionReferenceNumber,
  tgt.ExecutionID = s.ExecutionID,
  tgt.OrderID = s.OrderID,
  tgt.EMSOrderID = s.EMSOrderID,
  tgt.LiquidityAccountID = s.LiquidityAccountID,
  tgt.InstrumentID = s.InstrumentID,
  tgt.SourceRecordOrigin = s.SourceRecordOrigin,
  tgt.LastSeenRunID = '{{allocation_run_id}}',
  tgt.LastSeenTimestamp = current_timestamp(),
  tgt.IsActive = TRUE
WHEN NOT MATCHED THEN INSERT (
  RecordID,
  RecordBusinessKey,
  ReportDate,
  RegulationReportID,
  rowSource,
  TransactionReferenceNumber,
  ExecutionID,
  OrderID,
  EMSOrderID,
  LiquidityAccountID,
  InstrumentID,
  SourceRecordOrigin,
  FirstAllocatedRunID,
  FirstAllocatedTimestamp,
  LastSeenRunID,
  LastSeenTimestamp,
  MigratedFromSQLServerFlag,
  IsActive
) VALUES (
  s.RecordID,
  s.RecordBusinessKey,
  s.ReportDate,
  s.RegulationReportID,
  s.rowSource,
  s.TransactionReferenceNumber,
  s.ExecutionID,
  s.OrderID,
  s.EMSOrderID,
  s.LiquidityAccountID,
  s.InstrumentID,
  s.SourceRecordOrigin,
  '{{allocation_run_id}}',
  current_timestamp(),
  '{{allocation_run_id}}',
  current_timestamp(),
  FALSE,
  TRUE
);
*/

-- Gate notes (SELECT-only)
SELECT
  'registry_allocation_gate' AS gate_name,
  'pending' AS gate_status,
  'Allocation template remains commented until seed is validated and RecordBusinessKey signoff is complete.' AS gate_reason
UNION ALL
SELECT
  'registry_allocation_reuse_required',
  'required',
  'Existing RecordBusinessKey rows must reuse existing RecordID; no reassignment on reruns.'
UNION ALL
SELECT
  'registry_allocation_max_plus_one_required',
  'required',
  'Unseen rows allocate from current MAX(RecordID)+1 using deterministic ordering only.';
