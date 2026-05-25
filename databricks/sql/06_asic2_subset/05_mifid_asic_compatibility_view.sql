-- Step 8: MiFID compatibility view for ASIC2-backed transactions (gated).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
--
-- Required output contract (exactly 11 columns):
--   DateID, ReportDate, CID, PositionID, InstrumentID, OpenORClose,
--   IsBuy, OpenTime, Volume, OpenPrice, RegChange
--
-- Mapping from ASIC2_Transactions:
--   DateID -> DateID
--   ReportDate -> ReportDate
--   CID -> CID
--   PositionID -> PositionID
--   InstrumentID -> InstrumentID
--   OpenORClose -> OpenORClose
--   IsBuy -> IsBuy
--   Quantity -> Volume
--   OpenPrice -> OpenPrice
--   RegChange -> RegChange
--   CDE_Execution_timestamp -> OpenTime (unproven; validation required)

WITH gate_status AS (
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions' AS target_object,
    'pending' AS executable_view_status,
    'Awaiting projected subset activation and OpenTime semantic validation.' AS gate_reason
),
mapping_contract AS (
  SELECT 'DateID' AS target_column, 'DateID' AS asic2_transactions_source UNION ALL
  SELECT 'ReportDate', 'ReportDate' UNION ALL
  SELECT 'CID', 'CID' UNION ALL
  SELECT 'PositionID', 'PositionID' UNION ALL
  SELECT 'InstrumentID', 'InstrumentID' UNION ALL
  SELECT 'OpenORClose', 'OpenORClose' UNION ALL
  SELECT 'IsBuy', 'IsBuy' UNION ALL
  SELECT 'OpenTime', 'CDE_Execution_timestamp' UNION ALL
  SELECT 'Volume', 'Quantity' UNION ALL
  SELECT 'OpenPrice', 'OpenPrice' UNION ALL
  SELECT 'RegChange', 'RegChange'
)
SELECT *
FROM gate_status;

SELECT *
FROM mapping_contract
ORDER BY target_column;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATE ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE VIEW main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
AS
SELECT
  DateID,
  ReportDate,
  CID,
  PositionID,
  InstrumentID,
  OpenORClose,
  IsBuy,
  OpenTime,
  Volume,
  OpenPrice,
  RegChange
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions;
*/

