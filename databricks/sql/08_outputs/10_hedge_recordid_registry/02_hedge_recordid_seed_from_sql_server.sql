-- Step 10: Hedge RecordID registry seed from SQL Server history (GATED/COMMENTED).
--
-- Purpose:
-- - Seed registry with historical SQL Server MIFID2_Hedge_Report rows.
-- - Preserve historical RecordID values exactly (no regeneration).
-- - Build RecordBusinessKey from:
--     ReportDate + RegulationReportID + TransactionReferenceNumber
--
-- Source options (choose one before uncommenting):
-- - {{de_migrated_mifid2_hedge_report_source}}  (preferred DE-migrated history source)
-- - main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report (staging/manual seed tests)
--
-- DO NOT UNCOMMENT UNTIL:
-- - Source selection is approved.
-- - Historical seed validation has passed.
-- - RecordBusinessKey signoff status is documented.

-- -----------------------------------------------------------------------------
-- 0) Source selection placeholders (documentation only)
-- -----------------------------------------------------------------------------
-- {{hedge_registry_seed_source}} should resolve to one of:
--   {{de_migrated_mifid2_hedge_report_source}}
--   main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
-- {{registry_seed_run_id}} = unique run identifier string

-- -----------------------------------------------------------------------------
-- 1) Seed template (commented)
-- -----------------------------------------------------------------------------
/*
MERGE INTO main.regtech_ops_stg.bi_output_regtechops_hedge_recordid_registry AS tgt
USING (
  SELECT
    CAST(src.RecordID AS BIGINT) AS RecordID,
    concat_ws(
      '|',
      CAST(src.ReportDate AS STRING),
      CAST(src.RegulationReportID AS STRING),
      coalesce(trim(src.TransactionReferenceNumber), '')
    ) AS RecordBusinessKey,
    CAST(src.ReportDate AS DATE) AS ReportDate,
    CAST(src.RegulationReportID AS INT) AS RegulationReportID,
    CAST(src.rowSource AS STRING) AS rowSource,
    CAST(src.TransactionReferenceNumber AS STRING) AS TransactionReferenceNumber,
    CAST(src.ExecutionID AS BIGINT) AS ExecutionID,
    CAST(src.OrderID AS STRING) AS OrderID,
    CAST(src.EMSOrderID AS STRING) AS EMSOrderID,
    CAST(src.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(src.InstrumentID AS INT) AS InstrumentID,
    'SQL_SERVER_HISTORICAL_SEED' AS SourceRecordOrigin,
    '{{registry_seed_run_id}}' AS FirstAllocatedRunID,
    current_timestamp() AS FirstAllocatedTimestamp,
    '{{registry_seed_run_id}}' AS LastSeenRunID,
    current_timestamp() AS LastSeenTimestamp,
    TRUE AS MigratedFromSQLServerFlag,
    TRUE AS IsActive
  FROM {{hedge_registry_seed_source}} src
  WHERE src.RecordID IS NOT NULL
    AND src.ReportDate IS NOT NULL
    AND src.RegulationReportID IS NOT NULL
    AND src.TransactionReferenceNumber IS NOT NULL
) s
ON tgt.RecordBusinessKey = s.RecordBusinessKey
WHEN MATCHED THEN UPDATE SET
  tgt.RecordID = s.RecordID,
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
  tgt.LastSeenRunID = s.LastSeenRunID,
  tgt.LastSeenTimestamp = s.LastSeenTimestamp,
  tgt.MigratedFromSQLServerFlag = TRUE,
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
  s.FirstAllocatedRunID,
  s.FirstAllocatedTimestamp,
  s.LastSeenRunID,
  s.LastSeenTimestamp,
  s.MigratedFromSQLServerFlag,
  s.IsActive
);
*/

-- -----------------------------------------------------------------------------
-- 2) Seed gate notes (SELECT-only)
-- -----------------------------------------------------------------------------
SELECT
  'registry_seed_gate' AS gate_name,
  'pending' AS gate_status,
  'Seed MERGE remains commented until source availability and seed validation are approved.' AS gate_reason
UNION ALL
SELECT
  'registry_seed_preserve_recordid',
  'required',
  'Historical SQL Server RecordID values must be copied exactly.'
UNION ALL
SELECT
  'registry_seed_business_key_gate',
  'pending',
  'RecordBusinessKey starts with ReportDate+RegulationReportID+TransactionReferenceNumber; SME final key signoff pending.';
