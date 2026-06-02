-- Step 15B1: MIFID2_NPD_TRAX scaffolding/output contract/dependency gates only.
--
-- In scope (Step 15B1):
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
--
-- Out of scope (do not implement here):
--   full Step 15B2 table-generation logic
--   response file import/status update logic
--   SP_MIFID2_NPD_TRAX_Response_Update
--   TRAX file generation/export/upload flow
--   SFTP / 7z / Cappitech logic
--   production deployment
--
-- SQL Server authorities:
--   reference/.../core_mifid/SP_MIFID2_NPD_TRAX.sql
--   reference/.../target_output_tables/dbo.MIFID2_NPD_TRAX.sql
--   reference/.../selected_packages/MIFID2 TRAX.dtsx
--
-- Important Step 15 boundary:
-- - SP_MIFID2_NPD_TRAX(@StartDate) is table-generation logic.
-- - MIFID2 TRAX.dtsx executes SP_MIFID2_NPD_TRAX before file/upload/response tasks.
-- - SP_MIFID2_NPD_TRAX_Response_Update and TRAX response handling are out of scope.

-- -----------------------------------------------------------------------------
-- 0) Report-date parameter + dependency map + gate checklist (no side effects)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
target_object AS (
  SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax' AS target_object
),
direct_inputs AS (
  SELECT *
  FROM VALUES
    ('history input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax'),
    ('final output input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer'),
    ('final output input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer'),
    ('final output input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_report'),
    ('staging input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer'),
    ('staging input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer'),
    ('reference input', 'main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts'),
    ('exclusion input', 'main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids')
  AS t(input_group, input_object)
),
not_direct_inputs AS (
  SELECT *
  FROM VALUES
    ('not direct input (unless later evidence proves otherwise)', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report'),
    ('not direct input (unless later evidence proves otherwise)', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report'),
    ('not direct input (unless later evidence proves otherwise)', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report')
  AS t(input_group, input_object)
),
gate_status AS (
  SELECT
    'step15_upstream_customer_outputs' AS gate_name,
    'pending' AS gate_status,
    'MIFID2_Customer and MIFID2_RegChange_Customer remain gated due to PII source access blockers and upstream Step 9/10/11 dependencies.' AS gate_reason
  UNION ALL
  SELECT
    'step15_upstream_report_output',
    'pending',
    'MIFID2_Report dependency remains gated until upstream Step 12 dependencies and parity gates pass.'
  UNION ALL
  SELECT
    'step15_pii_customer_access',
    'pending',
    'main.pii_data.bronze_etoro_customer_customer and main.pii_data.bronze_etoro_history_customer have no schema access in latest profiling.'
  UNION ALL
  SELECT
    'step15_history_cutover_policy',
    'pending',
    'Exact new-vs-existing/retry/REPL behavior requires prior NPD history; forward-only start is possible but not historical parity equivalent.'
  UNION ALL
  SELECT
    'step15_failed_trax_history_loop',
    'pending',
    'MIFID2_Failed_TRAX depends on latest NPD history; Step 9 and Step 15 must share explicit seed/cutover policy.'
  UNION ALL
  SELECT
    'step15_response_boundary',
    'pending',
    'TRAX response import/status updates and SP_MIFID2_NPD_TRAX_Response_Update are out of scope for Step 15B1/B2.'
  UNION ALL
  SELECT
    'step15_delivery_boundary',
    'pending',
    'CSV/export/upload/SFTP/7z/Cappitech logic remains out of scope for table-generation implementation.'
)
SELECT
  rp.report_date,
  o.target_object,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_parameters rp
CROSS JOIN target_object o
CROSS JOIN gate_status g
ORDER BY g.gate_name;

SELECT
  input_group,
  input_object
FROM direct_inputs
ORDER BY input_group, input_object;

SELECT
  input_group,
  input_object
FROM not_direct_inputs
ORDER BY input_group, input_object;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/dbo.MIFID2_NPD_TRAX.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax (
  ReportDate DATE NOT NULL,
  CID INT NOT NULL,
  ReportTypeID INT NOT NULL,
  Entity STRING NOT NULL,
  RegulationID INT,
  AccountTypeID INT,
  IDType INT,
  OrigPINType STRING,
  PIN STRING,
  NotAllowedCONCAT BOOLEAN,
  MessageID STRING,
  Action STRING,
  InternalCode STRING,
  ExpiryDate STRING,
  EffectiveFromDate STRING,
  ExecutingEntity STRING,
  CountryofBranch STRING,
  LEI STRING,
  LEIType STRING,
  NaturalPersonType STRING,
  BusinessUnit STRING,
  ContactEmail STRING,
  ParentOfCollectiveInvestmentSchemeStatus STRING,
  CountryofNationality STRING,
  PassportNumber STRING,
  NationalID STRING,
  CONCAT STRING,
  FirstNames STRING,
  Surnames STRING,
  DateofBirth STRING,
  AcceptedTRAX BOOLEAN,
  ErrorColumn STRING,
  ErrorDescription STRING,
  FailedSinceDate DATE,
  DateFixedTRAX TIMESTAMP,
  RowNum INT,
  TraxAccount STRING,
  NonLatinOrEmptyName BOOLEAN,
  UpdateDate TIMESTAMP
)
USING DELTA;
*/

-- SQL Server uniqueness intent from PK:
--   (ReportDate, Entity, CID)
-- Validate through Step 15B3 duplicate checks (do not translate SQL Server indexing/storage directly).

-- -----------------------------------------------------------------------------
-- 2) AcceptedTRAX behavior checklist (Step 15B1 gate documentation only)
-- -----------------------------------------------------------------------------
-- Expected table-generation posture to preserve in Step 15B2:
-- - sendable rows: AcceptedTRAX IS NULL
-- - invalid non-Latin/empty-name rows: AcceptedTRAX = 0
-- - invalid-name error text: 'Not Sent. Invalid Name detected'
-- - prior rejected/null rows may be retried
-- - prior accepted rows may emit REPL when identity fields changed
-- Response-driven status updates are not implemented in Step 15B1.

-- -----------------------------------------------------------------------------
-- 3) History/cutover checklist (Step 15B1 gate documentation only)
-- -----------------------------------------------------------------------------
-- - Previous NPD rows are required for exact new-vs-existing/retry/REPL parity.
-- - Forward-only cutover may start clean for current validation windows, but behavior differs from seeded historical parity.
-- - Historical parity windows require seeded prior latest rows by CID/RegulationID.
-- - Step 9 MIFID2_Failed_TRAX and Step 15 NPD generation share this history dependency loop.

-- -----------------------------------------------------------------------------
-- 4) TODO anchors for next split steps
-- -----------------------------------------------------------------------------
-- TODO (Step 15B2 only):
-- - Port SQL Server SP_MIFID2_NPD_TRAX flow as gated/commented template:
--   * #ids latest history extraction
--   * #failed retry subset
--   * RegChange customer merge from MIFID2_Report + customer outputs
--   * #new / #exist delta detection
--   * #final assembly with AcceptedTRAX/RowNum handling
--   * report-date scoped delete/insert template
-- - Keep DML commented/non-active until all Step 15 gates pass.
--
-- TODO (Step 15B3 only):
-- - Author SELECT-only validation/reconciliation package:
--   * schema parity
--   * row counts by ReportDate/Entity/Action/AcceptedTRAX
--   * duplicate and required-null checks
--   * source-to-output checks (new/exist/failed/exclusion paths)
--   * history seed/cutover coverage checks
--   * optional SQL Server baseline comparison when baseline is provided

-- -----------------------------------------------------------------------------
-- 5) COMMENTED EXECUTION TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- -----------------------------------------------------------------------------
/*
-- Final report-date scoped load logic is intentionally deferred to Step 15B2.
-- DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
-- WHERE ReportDate = CAST('{{report_date}}' AS DATE);
--
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax (...)
-- SELECT ...
-- FROM ...
-- WHERE 1 = 0;
*/

