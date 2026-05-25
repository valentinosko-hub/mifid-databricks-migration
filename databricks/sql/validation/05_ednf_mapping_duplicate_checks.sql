-- Validation: EDNF-specific duplicate checks.
-- Returns rows only when duplicates exist.

-- Duplicate InstrumentID mappings.
SELECT
  'duplicate_instrumentid' AS check_name,
  InstrumentID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
GROUP BY InstrumentID
HAVING COUNT(*) > 1;

-- Duplicate logical mapping key (InstrumentID + IB_UnderlyingSymbol).
SELECT
  'duplicate_instrumentid_underlyingsymbol' AS check_name,
  InstrumentID,
  IB_UnderlyingSymbol,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
GROUP BY InstrumentID, IB_UnderlyingSymbol
HAVING COUNT(*) > 1;

