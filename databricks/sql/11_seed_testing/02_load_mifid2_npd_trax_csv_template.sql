-- Step 11: MIFID2_NPD_TRAX manual CSV seed load template (GATED/COMMENTED).
--
-- Target (temporary staging test asset):
--   main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
--
-- Source:
--   Approved secure CSV with header at {{npd_csv_location}}
--   External table: bi_output_regtechops_seed_test_ext_mifid2_npd_trax_csv (from 01_*)
--
-- Rules:
-- - Staging-only. No writes to main.regtech.
-- - PII-sensitive NPD exports must not be placed in broad/shared unsecured locations.
-- - CSV files must not be committed to Git.
-- - Final Step 15 bi_output_regtechops_mifid2_npd_trax activation remains GATED.
--
-- Validation after load: 04_manual_seed_validation.sql (SELECT-only)
--
-- DO NOT UNCOMMENT UNTIL: 01_* DDL executed, export manifest row count recorded, schema mapping approved.

-- -----------------------------------------------------------------------------
-- 0) Run parameters (replace before load)
-- -----------------------------------------------------------------------------
-- {{sql_server_npd_export_row_count}} = integer from SQL Server export manifest (external evidence)
-- Example reference: MCP count 4,576,382 — validate against actual export manifest

-- -----------------------------------------------------------------------------
-- 1) Schema validation gate (run SELECT-only before load — optional pre-check)
-- -----------------------------------------------------------------------------
/*
-- Compare external CSV column list to expected seed test table contract.
SELECT column_name, data_type
FROM system.information_schema.columns
WHERE table_catalog = 'main'
  AND table_schema = 'regtech_ops_stg'
  AND table_name = 'bi_output_regtechops_seed_test_ext_mifid2_npd_trax_csv'
ORDER BY ordinal_position;
*/

-- -----------------------------------------------------------------------------
-- 2) COPY INTO seed test table (preferred for large CSV)
-- -----------------------------------------------------------------------------
/*
COPY INTO main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
FROM '{{npd_csv_location}}'
FILEFORMAT = CSV
FORMAT_OPTIONS (
  'header' = 'true',
  'inferSchema' = 'false'
)
COPY_OPTIONS (
  'mergeSchema' = 'false'
);
*/

-- -----------------------------------------------------------------------------
-- 3) Alternative: INSERT from external CSV table (if explicit cast mapping required)
-- -----------------------------------------------------------------------------
/*
INSERT OVERWRITE main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax
SELECT
  CAST(ReportDate AS DATE) AS ReportDate,
  CAST(CID AS INT) AS CID,
  CAST(ReportTypeID AS INT) AS ReportTypeID,
  CAST(Entity AS STRING) AS Entity,
  CAST(RegulationID AS INT) AS RegulationID,
  CAST(AccountTypeID AS INT) AS AccountTypeID,
  CAST(IDType AS INT) AS IDType,
  CAST(OrigPINType AS STRING) AS OrigPINType,
  CAST(PIN AS STRING) AS PIN,
  CAST(NotAllowedCONCAT AS BOOLEAN) AS NotAllowedCONCAT,
  CAST(MessageID AS STRING) AS MessageID,
  CAST(Action AS STRING) AS Action,
  CAST(InternalCode AS STRING) AS InternalCode,
  CAST(ExpiryDate AS STRING) AS ExpiryDate,
  CAST(EffectiveFromDate AS STRING) AS EffectiveFromDate,
  CAST(ExecutingEntity AS STRING) AS ExecutingEntity,
  CAST(CountryofBranch AS STRING) AS CountryofBranch,
  CAST(LEI AS STRING) AS LEI,
  CAST(LEIType AS STRING) AS LEIType,
  CAST(NaturalPersonType AS STRING) AS NaturalPersonType,
  CAST(BusinessUnit AS STRING) AS BusinessUnit,
  CAST(ContactEmail AS STRING) AS ContactEmail,
  CAST(ParentOfCollectiveInvestmentSchemeStatus AS STRING) AS ParentOfCollectiveInvestmentSchemeStatus,
  CAST(CountryofNationality AS STRING) AS CountryofNationality,
  CAST(PassportNumber AS STRING) AS PassportNumber,
  CAST(NationalID AS STRING) AS NationalID,
  CAST(CONCAT AS STRING) AS CONCAT,
  CAST(FirstNames AS STRING) AS FirstNames,
  CAST(Surnames AS STRING) AS Surnames,
  CAST(DateofBirth AS STRING) AS DateofBirth,
  CAST(AcceptedTRAX AS BOOLEAN) AS AcceptedTRAX,
  CAST(ErrorColumn AS STRING) AS ErrorColumn,
  CAST(ErrorDescription AS STRING) AS ErrorDescription,
  CAST(FailedSinceDate AS DATE) AS FailedSinceDate,
  CAST(DateFixedTRAX AS TIMESTAMP) AS DateFixedTRAX,
  CAST(RowNum AS INT) AS RowNum,
  CAST(TraxAccount AS STRING) AS TraxAccount,
  CAST(NonLatinOrEmptyName AS BOOLEAN) AS NonLatinOrEmptyName,
  CAST(UpdateDate AS TIMESTAMP) AS UpdateDate
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_ext_mifid2_npd_trax_csv;
*/

-- -----------------------------------------------------------------------------
-- 4) Post-load validation requirements (run 04_manual_seed_validation.sql)
-- -----------------------------------------------------------------------------
-- Required checks:
-- - Row count vs {{sql_server_npd_export_row_count}}
-- - Duplicate check on (ReportDate, Entity, CID) — expect 0 duplicate groups
-- - AcceptedTRAX / ErrorDescription / FailedSinceDate field presence (column exists + null rates documented)
-- - Min/max ReportDate vs export manifest
--
-- Final NPD_TRAX module activation (bi_output_regtechops_mifid2_npd_trax) remains gated:
-- - main.pii_data access or formal exception
-- - MAG-10 / D-06 history parity
-- - Step 15 validation and SME sign-off

SELECT
  'npd_seed_load_gate' AS gate_name,
  'pending' AS gate_status,
  'Uncomment load SQL only after secure CSV path approval and DDL from 01_* is in place.' AS gate_reason
UNION ALL
SELECT
  'npd_final_activation_gate',
  'pending',
  'Seed test load does not close final MIFID2_NPD_TRAX activation gates.'
UNION ALL
SELECT
  'npd_pii_handling_gate',
  'required',
  'PII-sensitive NPD CSV must remain in approved secure restricted storage only.';
