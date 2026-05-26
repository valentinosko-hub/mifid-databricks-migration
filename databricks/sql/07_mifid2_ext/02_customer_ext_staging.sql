-- Step 9: MIFID2_ext customer staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until:
--   1) Step 9 source profiling confirms required columns/access.
--   2) PIN/UserAPI source contracts are confirmed.
--   3) Step 6 migration-population dependency parity is confirmed for reg-change flow.
-- - These are SSIS truncate/reload staging objects and should be materialized as Delta.

WITH staging_gates AS (
  SELECT
    'MIFID2_ext_Customer' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting BackOfficeCustomer required-column profiling and PIN/UserAPI source confirmation.' AS gate_reason
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Customer',
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer',
    'pending',
    'Awaiting migration-population parity and PIN/UserAPI source confirmation.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
position_cids AS (
  -- SSIS parity: customer flow is constrained by report-day qualifying positions.
  SELECT DISTINCT p.CID
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  UNION
  SELECT DISTINCT p.CID
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND p.CloseOccurred >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
),
customer_asof AS (
  SELECT
    c.CID,
    c.GCID,
    c.PlayerLevelID,
    c.PlayerStatusID,
    c.CountryID,
    h.LabelID,
    h.FirstName,
    h.LastName,
    h.BirthDate,
    b.RegulationID,
    b.AccountTypeID,
    b.Lei,
    b.CountryIDByIP,
    h.FirstName AS curFirstName,
    h.LastName AS curLastName,
    h.BirthDate AS curBirthDate,
    c.CitizenshipCountryID,
    -- DO NOT UNGATE UNTIL PIN/UserAPI source object and column contract are confirmed.
    -- No NULL-default fallback is allowed for production parity.
    CAST(raise_error('TODO: map PIN_ID from profiled PIN/UserAPI source before un-gating.') AS BIGINT) AS PIN_ID,
    CAST(raise_error('TODO: map PIN_Type from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN_Type,
    CAST(raise_error('TODO: map PIN from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN,
    CAST(raise_error('TODO: map UAPI_CountryID from profiled PIN/UserAPI source before un-gating.') AS INT) AS UAPI_CountryID
  FROM main.general.bronze_etoro_customer_customer c
  JOIN position_cids pc
    ON c.CID = pc.CID
  JOIN run_window w
    ON 1 = 1
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON c.CID = h.CID
   AND h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON c.CID = b.CID
   AND b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID IN (1, 2, 9, 11)
    AND b.AccountTypeID NOT IN (7, 9)
    AND h.LabelID NOT IN (26, 30)
)
SELECT
  ca.CID,
  ca.GCID,
  ca.PlayerLevelID,
  ca.PlayerStatusID,
  ca.CountryID,
  ca.LabelID,
  ca.FirstName,
  ca.LastName,
  ca.BirthDate,
  ca.RegulationID,
  ca.AccountTypeID,
  ca.Lei,
  ca.CountryIDByIP,
  ca.curFirstName,
  ca.curLastName,
  ca.curBirthDate,
  ca.CitizenshipCountryID,
  ca.PIN_ID,
  ca.PIN_Type,
  ca.PIN,
  ca.UAPI_CountryID,
  rp.report_date AS ReportDate
FROM customer_asof ca
JOIN run_parameters rp
  ON 1 = 1;
*/

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
reg_population AS (
  -- Step 6 dependency: must represent SQL Server support-copy parity for run date.
  SELECT
    p.CID,
    p.PrevRegulationID,
    p.RegulationID AS NewRegulationID,
    p.RegValidFrom,
    p.RegValidTo,
    p.RegChangeRank
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population p
  JOIN run_parameters rp
    ON p.RunDate = rp.report_date
  WHERE p.PrevRegulationID IN (1, 2, 9, 11)
),
regchange_position_cids AS (
  SELECT DISTINCT p.CID
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  JOIN reg_population reg
    ON p.CID = reg.CID
  UNION
  SELECT DISTINCT p.CID
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND p.CloseOccurred >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
  JOIN reg_population reg
    ON p.CID = reg.CID
),
customer_asof AS (
  SELECT
    c.CID,
    c.GCID,
    c.PlayerLevelID,
    c.PlayerStatusID,
    c.CountryID,
    h.LabelID,
    h.FirstName,
    h.LastName,
    h.BirthDate,
    b.RegulationID,
    b.AccountTypeID,
    b.Lei,
    b.CountryIDByIP,
    h.FirstName AS curFirstName,
    h.LastName AS curLastName,
    h.BirthDate AS curBirthDate,
    c.CitizenshipCountryID,
    -- DO NOT UNGATE UNTIL PIN/UserAPI source object and column contract are confirmed.
    -- No NULL-default fallback is allowed for production parity.
    CAST(raise_error('TODO: map PIN_ID from profiled PIN/UserAPI source before un-gating.') AS BIGINT) AS PIN_ID,
    CAST(raise_error('TODO: map PIN_Type from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN_Type,
    CAST(raise_error('TODO: map PIN from profiled PIN/UserAPI source before un-gating.') AS STRING) AS PIN,
    CAST(raise_error('TODO: map UAPI_CountryID from profiled PIN/UserAPI source before un-gating.') AS INT) AS UAPI_CountryID
  FROM main.general.bronze_etoro_customer_customer c
  JOIN regchange_position_cids pc
    ON c.CID = pc.CID
  JOIN run_window w
    ON 1 = 1
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON c.CID = h.CID
   AND h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON c.CID = b.CID
   AND b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID NOT IN (1, 2, 9, 11)
    AND b.AccountTypeID NOT IN (7, 9)
    AND h.LabelID NOT IN (26, 30)
)
SELECT
  ca.CID,
  ca.GCID,
  ca.PlayerLevelID,
  ca.PlayerStatusID,
  ca.CountryID,
  ca.LabelID,
  ca.FirstName,
  ca.LastName,
  ca.BirthDate,
  ca.RegulationID,
  ca.AccountTypeID,
  ca.Lei,
  ca.CountryIDByIP,
  ca.curFirstName,
  ca.curLastName,
  ca.curBirthDate,
  ca.CitizenshipCountryID,
  ca.PIN_ID,
  ca.PIN_Type,
  ca.PIN,
  ca.UAPI_CountryID,
  rp.report_date AS ReportDate
FROM customer_asof ca
JOIN run_parameters rp
  ON 1 = 1;
*/
