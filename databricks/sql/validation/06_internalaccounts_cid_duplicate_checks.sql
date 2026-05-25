-- Validation: InternalAccounts CID duplicate checks.
-- Returns rows only when duplicates exist.

SELECT
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts
GROUP BY CID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, CID;

