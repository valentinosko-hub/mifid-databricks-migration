-- Step 9: MIFID2_ext position-change-log and mirror staging (gated authoring).
--
-- Targets:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
--
-- IMPORTANT:
-- - Do not execute final CREATE OR REPLACE TABLE logic until source profiling passes.
-- - Mirror CopyFund logic depends on BackOfficeCustomer account-type contract.
-- - These are SSIS truncate/reload staging objects and should be materialized as Delta.

WITH staging_gates AS (
  SELECT
    'MIFID2_ext_PositionChangeLog' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting required-column profiling and date-window parity validation.' AS gate_reason
  UNION ALL
  SELECT
    'MIFID2_ext_Mirror',
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror',
    'pending',
    'Awaiting BackOfficeCustomer profile confirmation for CopyFund derivation.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATES ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
-- -----------------------------------------------------------------------------

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
USING DELTA
AS
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
)
SELECT
  pcl.PositionID,
  pcl.LastOpPriceRate AS ChangeLogLastOpPriceRate,
  pcl.Occurred AS ChangeLogOccurred,
  pcl.ChangeTypeID,
  pcl.IsSettled
FROM main.trading.bronze_etoro_history_positionchangelog pcl
JOIN run_window w
  ON pcl.Occurred >= w.start_ts
 AND pcl.Occurred < w.end_ts
WHERE pcl.ChangeTypeID = 0;
*/

/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
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
backoffice_asof AS (
  -- CopyFund parity rule:
  -- CopyFund = 1 when parent CID has AccountTypeID = 9 in BackOffice source.
  SELECT
    b.CID,
    b.AccountTypeID
  FROM main.general.bronze_etoro_history_backofficecustomer b
  JOIN run_window w
    ON b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
)
SELECT
  m.MirrorID,
  m.ParentCID,
  m.MirrorOperationID,
  m.Occurred,
  CASE WHEN bo.AccountTypeID = 9 THEN 1 ELSE 0 END AS CopyFund
FROM main.trading.bronze_etoro_history_mirror m
JOIN run_window w
  ON m.Occurred >= w.start_ts
 AND m.Occurred < w.end_ts
LEFT JOIN backoffice_asof bo
  ON m.ParentCID = bo.CID
WHERE m.MirrorOperationID = 1;
*/
