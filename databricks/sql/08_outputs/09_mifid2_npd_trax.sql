-- Step 15B2: MIFID2_NPD_TRAX table-generation template (gated/commented).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
--
-- Scope in this file:
-- - Author Step 15A-equivalent CTE flow as a gated template for table generation only.
-- - Keep all final DELETE / INSERT / CREATE statements commented/non-active.
--
-- Explicitly out of scope:
-- - SP_MIFID2_NPD_TRAX_Response_Update
-- - TRAX file generation / CSV export / upload / SFTP / 7z / Cappitech
-- - response import/update handling
-- - production deployment
--
-- Authorities:
-- - reference/.../core_mifid/SP_MIFID2_NPD_TRAX.sql
-- - reference/.../target_output_tables/dbo.MIFID2_NPD_TRAX.sql
-- - reference/.../selected_packages/MIFID2 TRAX.dtsx
--
-- Important:
-- - Do not activate this template until all Step 15 gates are approved.
-- - Do not fabricate missing prior NPD history.
-- - Do not synthesize missing source/output columns.
-- - Keep this table-generation template independent of response/delivery flows.

-- -----------------------------------------------------------------------------
-- 0) Step 15B2 gate checklist (read-only, safe to run)
-- -----------------------------------------------------------------------------
WITH step15b2_dependency_gates AS (
  SELECT *
  FROM VALUES
    ('step15_history_cutover_policy', 'pending', 'Exact new/existing/retry/REPL parity needs prior latest NPD rows by CID/RegulationID.'),
    ('step15_step9_failed_trax_loop', 'pending', 'MIFID2_Failed_TRAX depends on latest NPD history; shared seed policy is required.'),
    ('step15_upstream_customer_outputs', 'pending', 'MIFID2_Customer and MIFID2_RegChange_Customer remain gated by PII and upstream Step 9/10/11 gates.'),
    ('step15_upstream_report_output', 'pending', 'MIFID2_Report dependency remains gated until Step 12 gates pass.'),
    ('step15_pii_customer_access', 'pending', 'main.pii_data.bronze_etoro_customer_customer and main.pii_data.bronze_etoro_history_customer have no schema access.'),
    ('step15_identity_change_parity', 'pending', 'Existing-row identity-change comparison set must match SQL Server exactly or remain hard-gated.'),
    ('step15_invalid_name_parity', 'pending', 'Invalid non-Latin/empty-name detection must match SQL Server behavior before activation.'),
    ('step15_rownum_parity', 'pending', 'RowNum partition/order for sendable rows must match SQL Server behavior before activation.'),
    ('step15_response_boundary', 'pending', 'Response status update/SP_MIFID2_NPD_TRAX_Response_Update is out of scope for Step 15B2.'),
    ('step15_delivery_boundary', 'pending', 'CSV/upload/SFTP/7z/Cappitech handling is out of scope for Step 15B2.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT *
FROM step15b2_dependency_gates
ORDER BY gate_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- CTE scope rule preserved:
-- - DELETE first
-- - CTE stack directly attached to INSERT
-- -----------------------------------------------------------------------------
/*
DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax (
  ReportDate,
  CID,
  ReportTypeID,
  Entity,
  RegulationID,
  AccountTypeID,
  IDType,
  OrigPINType,
  PIN,
  NotAllowedCONCAT,
  MessageID,
  Action,
  InternalCode,
  ExpiryDate,
  EffectiveFromDate,
  ExecutingEntity,
  CountryofBranch,
  LEI,
  LEIType,
  NaturalPersonType,
  BusinessUnit,
  ContactEmail,
  ParentOfCollectiveInvestmentSchemeStatus,
  CountryofNationality,
  PassportNumber,
  NationalID,
  CONCAT,
  FirstNames,
  Surnames,
  DateofBirth,
  AcceptedTRAX,
  ErrorColumn,
  ErrorDescription,
  FailedSinceDate,
  DateFixedTRAX,
  RowNum,
  TraxAccount,
  NonLatinOrEmptyName,
  UpdateDate
)
WITH
run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),

-- Equivalent of #ids (latest existing NPD row per CID/RegulationID).
-- HARD GATE: parity requires seeded prior/current NPD history.
prior_latest_ids AS (
  SELECT
    h.CID,
    h.RegulationID,
    MAX(h.ReportDate) AS latest_report_date
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax h
  GROUP BY h.CID, h.RegulationID
),

prior_latest_rows AS (
  SELECT
    h.*
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax h
  INNER JOIN prior_latest_ids i
    ON h.CID = i.CID
   AND COALESCE(h.RegulationID, -1) = COALESCE(i.RegulationID, -1)
   AND h.ReportDate = i.latest_report_date
),

-- Equivalent of failed/retry dependency from prior NPD state.
failed_retry_candidates AS (
  SELECT
    r.CID,
    r.RegulationID,
    r.Action AS prior_action,
    r.AcceptedTRAX AS prior_accepted_trax,
    r.ReportDate AS prior_report_date
  FROM prior_latest_rows r
  WHERE r.AcceptedTRAX = 0
     OR r.AcceptedTRAX IS NULL
),

-- Equivalent of #RegChangeCusts from report output.
reg_change_customers AS (
  SELECT DISTINCT
    rep.CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report rep
  INNER JOIN run_parameters p
    ON rep.ReportDate = p.report_date
  WHERE rep.RegChange IN (1, 2)
),

-- Equivalent of #MIFID2_Customer_All (base + reg-change additions).
customer_all_candidates AS (
  SELECT
    c.ReportDate,
    c.CID,
    c.RegulationID,
    c.ReportTypeID,
    c.Entity,
    c.AccountTypeID,
    c.IDType,
    c.OrigPINType,
    c.PIN,
    c.NotAllowedCONCAT,
    c.MessageID,
    c.Action,
    c.InternalCode,
    c.ExpiryDate,
    c.EffectiveFromDate,
    c.ExecutingEntity,
    c.CountryofBranch,
    c.LEI,
    c.LEIType,
    c.NaturalPersonType,
    c.BusinessUnit,
    c.ContactEmail,
    c.ParentOfCollectiveInvestmentSchemeStatus,
    c.CountryofNationality,
    c.PassportNumber,
    c.NationalID,
    c.CONCAT,
    c.FirstNames,
    c.Surnames,
    c.DateofBirth,
    c.TraxAccount,
    COALESCE(c.NonLatinOrEmptyName, 0) AS candidate_nonlatin_or_emptyname
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
  INNER JOIN run_parameters p
    ON c.ReportDate = p.report_date
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids ex
    ON c.CID = ex.CID
  WHERE ex.CID IS NULL

  UNION ALL

  SELECT
    rc.ReportDate,
    rc.CID,
    rc.RegulationID,
    rc.ReportTypeID,
    rc.Entity,
    rc.AccountTypeID,
    rc.IDType,
    rc.OrigPINType,
    rc.PIN,
    rc.NotAllowedCONCAT,
    rc.MessageID,
    rc.Action,
    rc.InternalCode,
    rc.ExpiryDate,
    rc.EffectiveFromDate,
    rc.ExecutingEntity,
    rc.CountryofBranch,
    rc.LEI,
    rc.LEIType,
    rc.NaturalPersonType,
    rc.BusinessUnit,
    rc.ContactEmail,
    rc.ParentOfCollectiveInvestmentSchemeStatus,
    rc.CountryofNationality,
    rc.PassportNumber,
    rc.NationalID,
    rc.CONCAT,
    rc.FirstNames,
    rc.Surnames,
    rc.DateofBirth,
    rc.TraxAccount,
    COALESCE(rc.NonLatinOrEmptyName, 0) AS candidate_nonlatin_or_emptyname
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer rc
  INNER JOIN run_parameters p
    ON rc.ReportDate = p.report_date
  INNER JOIN reg_change_customers rg
    ON rc.CID = rg.CID
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids ex
    ON rc.CID = ex.CID
  WHERE ex.CID IS NULL
),

-- Equivalent of #new.
new_candidates AS (
  SELECT
    c.*,
    'NEWM' AS candidate_action,
    CAST('new_candidate' AS STRING) AS candidate_reason
  FROM customer_all_candidates c
  LEFT JOIN prior_latest_ids i
    ON c.CID = i.CID
   AND COALESCE(c.RegulationID, -1) = COALESCE(i.RegulationID, -1)
  WHERE i.CID IS NULL
),

-- Equivalent of #exist with identity-change checks.
-- HARD GATE: keep change set exact to SQL Server before activation.
existing_changed_candidates AS (
  SELECT
    c.*,
    CASE
      WHEN COALESCE(p.AcceptedTRAX, 0) = 1 THEN 'REPL'
      ELSE p.Action
    END AS candidate_action,
    CAST('existing_changed_candidate' AS STRING) AS candidate_reason
  FROM customer_all_candidates c
  INNER JOIN prior_latest_rows p
    ON c.CID = p.CID
   AND COALESCE(c.RegulationID, -1) = COALESCE(p.RegulationID, -1)
  WHERE
    (
      COALESCE(c.PIN, '') <> COALESCE(p.PIN, '')
      OR COALESCE(c.FirstNames, '') <> COALESCE(p.FirstNames, '')
      OR COALESCE(c.Surnames, '') <> COALESCE(p.Surnames, '')
      OR COALESCE(c.PassportNumber, '') <> COALESCE(p.PassportNumber, '')
      OR COALESCE(c.NationalID, '') <> COALESCE(p.NationalID, '')
      OR COALESCE(c.CountryofNationality, '') <> COALESCE(p.CountryofNationality, '')
      OR COALESCE(c.DateofBirth, '') <> COALESCE(p.DateofBirth, '')
    )
),

-- Retry branch sourced from prior failed/not-yet-accepted rows.
retry_candidates AS (
  SELECT
    c.*,
    COALESCE(r.prior_action, c.Action) AS candidate_action,
    CAST('retry_candidate' AS STRING) AS candidate_reason
  FROM customer_all_candidates c
  INNER JOIN failed_retry_candidates r
    ON c.CID = r.CID
   AND COALESCE(c.RegulationID, -1) = COALESCE(r.RegulationID, -1)
),

candidate_union AS (
  SELECT * FROM new_candidates
  UNION ALL
  SELECT * FROM existing_changed_candidates
  UNION ALL
  SELECT * FROM retry_candidates
),

-- Equivalent of #final with invalid-name and AcceptedTRAX behavior.
final_candidates AS (
  SELECT
    c.ReportDate,
    c.CID,
    c.ReportTypeID,
    c.Entity,
    c.RegulationID,
    c.AccountTypeID,
    c.IDType,
    c.OrigPINType,
    c.PIN,
    c.NotAllowedCONCAT,
    c.MessageID,
    c.candidate_action AS Action,
    c.InternalCode,
    c.ExpiryDate,
    c.EffectiveFromDate,
    c.ExecutingEntity,
    c.CountryofBranch,
    c.LEI,
    c.LEIType,
    c.NaturalPersonType,
    c.BusinessUnit,
    c.ContactEmail,
    c.ParentOfCollectiveInvestmentSchemeStatus,
    c.CountryofNationality,
    c.PassportNumber,
    c.NationalID,
    c.CONCAT,
    c.FirstNames,
    c.Surnames,
    c.DateofBirth,
    CASE
      WHEN c.candidate_nonlatin_or_emptyname = 1
        OR TRIM(COALESCE(c.FirstNames, '')) = ''
        OR TRIM(COALESCE(c.Surnames, '')) = ''
      THEN 0
      ELSE NULL
    END AS AcceptedTRAX,
    CAST(NULL AS STRING) AS ErrorColumn,
    CASE
      WHEN c.candidate_nonlatin_or_emptyname = 1
        OR TRIM(COALESCE(c.FirstNames, '')) = ''
        OR TRIM(COALESCE(c.Surnames, '')) = ''
      THEN 'Not Sent. Invalid Name detected'
      ELSE NULL
    END AS ErrorDescription,
    CAST(NULL AS DATE) AS FailedSinceDate,
    CAST(NULL AS TIMESTAMP) AS DateFixedTRAX,
    c.TraxAccount,
    CASE
      WHEN c.candidate_nonlatin_or_emptyname = 1
        OR TRIM(COALESCE(c.FirstNames, '')) = ''
        OR TRIM(COALESCE(c.Surnames, '')) = ''
      THEN 1
      ELSE 0
    END AS NonLatinOrEmptyName,
    CURRENT_TIMESTAMP() AS UpdateDate
  FROM candidate_union c
),

-- HARD GATE: row numbering order must match SQL Server exactly.
final_candidates_with_rownum AS (
  SELECT
    f.*,
    CASE
      WHEN f.AcceptedTRAX IS NULL THEN
        ROW_NUMBER() OVER (
          PARTITION BY f.ReportDate, f.Entity
          ORDER BY f.CID, COALESCE(f.RegulationID, -1), f.Action
        )
      ELSE NULL
    END AS RowNum
  FROM final_candidates f
)

SELECT
  ReportDate,
  CID,
  ReportTypeID,
  Entity,
  RegulationID,
  AccountTypeID,
  IDType,
  OrigPINType,
  PIN,
  NotAllowedCONCAT,
  MessageID,
  Action,
  InternalCode,
  ExpiryDate,
  EffectiveFromDate,
  ExecutingEntity,
  CountryofBranch,
  LEI,
  LEIType,
  NaturalPersonType,
  BusinessUnit,
  ContactEmail,
  ParentOfCollectiveInvestmentSchemeStatus,
  CountryofNationality,
  PassportNumber,
  NationalID,
  CONCAT,
  FirstNames,
  Surnames,
  DateofBirth,
  AcceptedTRAX,
  ErrorColumn,
  ErrorDescription,
  FailedSinceDate,
  DateFixedTRAX,
  RowNum,
  TraxAccount,
  NonLatinOrEmptyName,
  UpdateDate
FROM final_candidates_with_rownum;
*/

-- -----------------------------------------------------------------------------
-- 2) Step 15B3 handoff notes (validation package only)
-- -----------------------------------------------------------------------------
-- - Validate schema parity to dbo.MIFID2_NPD_TRAX.sql.
-- - Validate counts by ReportDate/Entity/Action/AcceptedTRAX.
-- - Validate duplicate/required-null checks and exclusion coverage.
-- - Validate history seed coverage and forward-only-window caveats.
-- - Keep SQL Server baseline comparison optional/gated until baseline source is provided.

