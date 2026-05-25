-- Compatibility view: InternalAccounts

CREATE OR REPLACE VIEW main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts AS
SELECT
  CID,
  LEI,
  Description,
  CID AS cid,
  LEI AS lei,
  Description AS description
FROM main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts;

