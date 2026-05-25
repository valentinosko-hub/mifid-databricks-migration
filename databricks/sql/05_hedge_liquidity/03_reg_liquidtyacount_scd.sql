-- Step 7: Reg_LiquidtyAcount_SCD templates (gated authoring).
--
-- Persistent history target:
--   main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
--
-- Source procedure parity basis:
--   SP_Reg_LiquidtyAcount_SCD.sql
--
-- IMPORTANT:
-- - Do not use an unconditional CREATE OR REPLACE TABLE runtime pattern here.
-- - Active execution requires a seed/cutover decision:
--   1) optional initial seed/rebuild template
--   2) incremental update template
-- - SQL Server behavior for removed accounts does NOT set IsLast = 0; this
--   template preserves that behavior by default.

WITH scd_gates AS (
  SELECT
    'Reg_LiquidtyAcount_SCD' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting Step 7 seed/cutover decision and source profiling sign-off.' AS gate_reason
)
SELECT *
FROM scd_gates;

-- -----------------------------------------------------------------------------
-- TEMPLATE A (optional): initial seed / controlled rebuild
-- -----------------------------------------------------------------------------
-- Use only if a full SCD reset is explicitly approved.
-- This template does not preserve prior history; it seeds current snapshot rows.
/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
USING DELTA
AS
WITH utc_ctx AS (
  SELECT
    to_utc_timestamp(current_timestamp(), current_timezone()) AS utc_now,
    CAST(to_utc_timestamp(current_timestamp(), current_timezone()) AS DATE) AS run_date
),
current_ext AS (
  SELECT
    la.LiquidityAccountID,
    hs.HedgeServerID,
    la.LiquidityAccountName,
    la.LiquidityProviderID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext hs
    ON la.LiquidityAccountID = hs.LiquidityAccountID
)
SELECT
  ce.LiquidityAccountID,
  ce.HedgeServerID,
  ce.LiquidityAccountName,
  ce.LiquidityProviderID,
  ctx.utc_now AS ValidFrom,
  CAST('9999-12-31 00:00:00' AS TIMESTAMP) AS ValidTo,
  ctx.run_date AS RunDate,
  1 AS IsNew,
  1 AS IsLast
FROM current_ext ce
CROSS JOIN utc_ctx ctx;
*/

-- -----------------------------------------------------------------------------
-- TEMPLATE B (preferred): incremental update template (pending cutover decision)
-- -----------------------------------------------------------------------------
-- Behavior parity goals:
-- - RunDate = CAST(GETUTCDATE() AS DATE)
-- - new rows: ValidFrom = GETUTCDATE(), ValidTo = 9999-12-31, IsNew = 1, IsLast = 1
-- - changed rows: close previous latest row (IsLast = 0), insert replacement
-- - replacement rows: IsNew = 0, IsLast = 1, ValidTo = 9999-12-31
-- - removed rows: close ValidTo and update RunDate; do NOT set IsLast = 0
/*
-- 1) Context and current ext snapshot
WITH utc_ctx AS (
  SELECT
    to_utc_timestamp(current_timestamp(), current_timezone()) AS utc_now,
    CAST(to_utc_timestamp(current_timestamp(), current_timezone()) AS DATE) AS run_date
),
current_ext AS (
  SELECT
    la.LiquidityAccountID,
    hs.HedgeServerID,
    la.LiquidityAccountName,
    la.LiquidityProviderID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext hs
    ON la.LiquidityAccountID = hs.LiquidityAccountID
),
last_rec_found AS (
  SELECT
    LiquidityAccountID,
    MAX(ValidTo) AS m_ValidTo,
    CASE WHEN MAX(ValidTo) <> CAST('9999-12-31 00:00:00' AS TIMESTAMP) THEN 1 ELSE 0 END AS WasClosedInd
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
  GROUP BY LiquidityAccountID
),
last_rows AS (
  SELECT
    s.LiquidityAccountID,
    s.HedgeServerID,
    s.LiquidityAccountName,
    s.LiquidityProviderID,
    s.ValidTo,
    l.WasClosedInd
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd s
  JOIN last_rec_found l
    ON s.LiquidityAccountID = l.LiquidityAccountID
   AND s.ValidTo = l.m_ValidTo
),
changed_accounts AS (
  SELECT ce.LiquidityAccountID
  FROM current_ext ce
  EXCEPT
  SELECT
    lr.LiquidityAccountID
  FROM last_rows lr
  JOIN current_ext ce
    ON ce.LiquidityAccountID = lr.LiquidityAccountID
   AND COALESCE(ce.HedgeServerID, -1) = COALESCE(lr.HedgeServerID, -1)
   AND COALESCE(ce.LiquidityAccountName, '') = COALESCE(lr.LiquidityAccountName, '')
   AND COALESCE(ce.LiquidityProviderID, -1) = COALESCE(lr.LiquidityProviderID, -1)
)
-- 2) Insert brand-new accounts
INSERT INTO main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd (
  LiquidityAccountID,
  HedgeServerID,
  LiquidityAccountName,
  LiquidityProviderID,
  ValidFrom,
  ValidTo,
  RunDate,
  IsNew,
  IsLast
)
SELECT
  ce.LiquidityAccountID,
  ce.HedgeServerID,
  ce.LiquidityAccountName,
  ce.LiquidityProviderID,
  ctx.utc_now AS ValidFrom,
  CAST('9999-12-31 00:00:00' AS TIMESTAMP) AS ValidTo,
  ctx.run_date AS RunDate,
  1 AS IsNew,
  1 AS IsLast
FROM current_ext ce
CROSS JOIN utc_ctx ctx
LEFT JOIN (
  SELECT DISTINCT LiquidityAccountID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
) hist
  ON ce.LiquidityAccountID = hist.LiquidityAccountID
WHERE hist.LiquidityAccountID IS NULL;

-- 3) Close changed latest rows (IsLast = 0)
WITH utc_ctx AS (
  SELECT
    to_utc_timestamp(current_timestamp(), current_timezone()) AS utc_now,
    CAST(to_utc_timestamp(current_timestamp(), current_timezone()) AS DATE) AS run_date
),
last_rec_found AS (
  SELECT
    LiquidityAccountID,
    MAX(ValidTo) AS m_ValidTo,
    CASE WHEN MAX(ValidTo) <> CAST('9999-12-31 00:00:00' AS TIMESTAMP) THEN 1 ELSE 0 END AS WasClosedInd
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
  GROUP BY LiquidityAccountID
),
changed_accounts AS (
  SELECT LiquidityAccountID
  FROM (
    SELECT ce.LiquidityAccountID, ce.HedgeServerID, ce.LiquidityAccountName, ce.LiquidityProviderID
    FROM (
      SELECT
        la.LiquidityAccountID,
        hs.HedgeServerID,
        la.LiquidityAccountName,
        la.LiquidityProviderID
      FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
      LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext hs
        ON la.LiquidityAccountID = hs.LiquidityAccountID
    ) ce
    EXCEPT
    SELECT
      s.LiquidityAccountID,
      s.HedgeServerID,
      s.LiquidityAccountName,
      s.LiquidityProviderID
    FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd s
    JOIN last_rec_found l
      ON s.LiquidityAccountID = l.LiquidityAccountID
     AND s.ValidTo = l.m_ValidTo
  )
)
UPDATE main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd AS tgt
SET
  ValidTo = CASE WHEN l.WasClosedInd = 1 THEN tgt.ValidTo ELSE ctx.utc_now END,
  RunDate = ctx.run_date,
  IsLast = 0
FROM last_rec_found l
CROSS JOIN utc_ctx ctx
WHERE tgt.LiquidityAccountID = l.LiquidityAccountID
  AND tgt.ValidTo = l.m_ValidTo
  AND tgt.LiquidityAccountID IN (SELECT LiquidityAccountID FROM changed_accounts);

-- 4) Insert replacement current rows for changed accounts
WITH utc_ctx AS (
  SELECT
    to_utc_timestamp(current_timestamp(), current_timezone()) AS utc_now,
    CAST(to_utc_timestamp(current_timestamp(), current_timezone()) AS DATE) AS run_date
),
current_ext AS (
  SELECT
    la.LiquidityAccountID,
    hs.HedgeServerID,
    la.LiquidityAccountName,
    la.LiquidityProviderID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext hs
    ON la.LiquidityAccountID = hs.LiquidityAccountID
),
changed_accounts AS (
  SELECT LiquidityAccountID
  FROM (
    SELECT ce.LiquidityAccountID, ce.HedgeServerID, ce.LiquidityAccountName, ce.LiquidityProviderID
    FROM current_ext ce
    EXCEPT
    SELECT
      s.LiquidityAccountID,
      s.HedgeServerID,
      s.LiquidityAccountName,
      s.LiquidityProviderID
    FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd s
    JOIN (
      SELECT LiquidityAccountID, MAX(ValidTo) AS m_ValidTo
      FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
      GROUP BY LiquidityAccountID
    ) l
      ON s.LiquidityAccountID = l.LiquidityAccountID
     AND s.ValidTo = l.m_ValidTo
  )
)
INSERT INTO main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd (
  LiquidityAccountID,
  HedgeServerID,
  LiquidityAccountName,
  LiquidityProviderID,
  ValidFrom,
  ValidTo,
  RunDate,
  IsNew,
  IsLast
)
SELECT
  ce.LiquidityAccountID,
  ce.HedgeServerID,
  ce.LiquidityAccountName,
  ce.LiquidityProviderID,
  ctx.utc_now AS ValidFrom,
  CAST('9999-12-31 00:00:00' AS TIMESTAMP) AS ValidTo,
  ctx.run_date AS RunDate,
  0 AS IsNew,
  1 AS IsLast
FROM current_ext ce
CROSS JOIN utc_ctx ctx
WHERE ce.LiquidityAccountID IN (SELECT LiquidityAccountID FROM changed_accounts);

-- 5) Close removed accounts from ext
-- SQL Server parity note:
-- - Does not set IsLast = 0 in this update.
WITH utc_ctx AS (
  SELECT
    to_utc_timestamp(current_timestamp(), current_timezone()) AS utc_now,
    CAST(to_utc_timestamp(current_timestamp(), current_timezone()) AS DATE) AS run_date
),
last_rec_found AS (
  SELECT LiquidityAccountID, MAX(ValidTo) AS m_ValidTo
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
  GROUP BY LiquidityAccountID
),
current_ext AS (
  SELECT
    la.LiquidityAccountID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext la
)
UPDATE main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd AS tgt
SET
  ValidTo = ctx.utc_now,
  RunDate = ctx.run_date
FROM last_rec_found l
CROSS JOIN utc_ctx ctx
LEFT JOIN current_ext ce
  ON tgt.LiquidityAccountID = ce.LiquidityAccountID
WHERE tgt.LiquidityAccountID = l.LiquidityAccountID
  AND tgt.ValidTo = l.m_ValidTo
  AND ce.LiquidityAccountID IS NULL;
*/
