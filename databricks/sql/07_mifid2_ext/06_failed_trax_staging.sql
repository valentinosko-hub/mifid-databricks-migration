-- Step 9: MIFID2_Failed_TRAX staging (gated authoring).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
--
-- IMPORTANT:
-- - Treat Failed TRAX as SSIS-created staging, not as a raw source table.
-- - It depends on historical/current rows from MIFID2_NPD_TRAX.
-- - Do not invent historical rows; keep executable logic gated until seed/cutover decision.

WITH staging_gates AS (
  SELECT
    'MIFID2_Failed_TRAX' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting MIFID2_NPD_TRAX history/current availability and PIN/UserAPI source confirmation.'
      AS gate_reason
)
SELECT *
FROM staging_gates;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATE ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, history-seed decisions, and parity checks must pass.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
latest_trax AS (
  -- SSIS parity intent:
  -- latest row per CID from MIFID2_NPD_TRAX, then keep AcceptedTRAX = 0 OR NULL.
  SELECT
    t.*,
    ROW_NUMBER() OVER (
      PARTITION BY t.CID
      ORDER BY t.ReportDate DESC
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax t
),
failed_cids AS (
  SELECT CID
  FROM latest_trax
  WHERE rn = 1
    AND (AcceptedTRAX = 0 OR AcceptedTRAX IS NULL)
),
customer_current AS (
  SELECT
    c.CID,
    c.GCID,
    c.PlayerLevelID,
    c.PlayerStatusID,
    c.CountryID,
    c.LabelID,
    h.FirstName,
    h.LastName,
    h.BirthDate,
    b.CountryIDByIP,
    h.FirstName AS curFirstName,
    h.LastName AS curLastName,
    h.BirthDate AS curBirthDate,
    c.CitizenshipCountryID
  FROM main.general.bronze_etoro_customer_customer c
  JOIN failed_cids fc
    ON c.CID = fc.CID
  LEFT JOIN main.pii_data.bronze_etoro_history_customer h
    ON c.CID = h.CID
   AND h.ValidTo = CAST('9999-12-31 00:00:00' AS TIMESTAMP)
  LEFT JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON c.CID = b.CID
   AND b.ValidTo = CAST('9999-12-31 00:00:00' AS TIMESTAMP)
)
SELECT
  cc.CID,
  cc.GCID,
  cc.PlayerLevelID,
  cc.PlayerStatusID,
  cc.CountryID,
  cc.LabelID,
  cc.FirstName,
  cc.LastName,
  cc.BirthDate,
  cc.CountryIDByIP,
  cc.curFirstName,
  cc.curLastName,
  cc.curBirthDate,
  cc.CitizenshipCountryID,
  -- DO NOT UNGATE UNTIL PIN/UserAPI source object and column contract are confirmed.
  -- No NULL-default fallback is allowed for production parity.
  CAST(raise_error('TODO: map PIN_ID from profiled PIN/UserAPI source before un-gating.') AS BIGINT) AS PIN_ID,
  CAST(raise_error('TODO: map PIN_Type from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN_Type,
  CAST(raise_error('TODO: map PIN from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN,
  CAST(raise_error('TODO: map UAPI_CountryID from profiled PIN/UserAPI source before un-gating.') AS INT) AS UAPI_CountryID,
  rp.report_date AS ReportDate
FROM customer_current cc
JOIN run_parameters rp
  ON 1 = 1;
*/
