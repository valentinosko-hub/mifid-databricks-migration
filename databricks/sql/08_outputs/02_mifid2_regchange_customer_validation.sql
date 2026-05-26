-- Step 11: MIFID2_RegChange_Customer validation templates.
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
--
-- Execute only after Step 11 output activation is approved.

-- -----------------------------------------------------------------------------
-- 1) Target schema parity check (DDL contract: MIFID2_RegChange_Customer.sql)
-- -----------------------------------------------------------------------------
WITH expected_columns AS (
  -- SQL Server DDL source:
  -- reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_RegChange_Customer.sql
  -- Databricks mapping rules applied:
  -- int -> INT, bit -> BOOLEAN, varchar/nvarchar -> STRING, date -> DATE, datetime -> TIMESTAMP.
  SELECT *
  FROM VALUES
    ('CID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('RegulationID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('PlayerLevelID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('CountryID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('FTD', 'TIMESTAMP', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('AccountTypeID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('Country', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('CopyFund', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('CopyFundName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('FundTypeID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('FundType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('IDType', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('PIN_Type', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('PIN_LEI', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('BirthDate', 'DATE', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('FirstName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('LastName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('IsUKReport', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('IsEUReport', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('NotAllowedCONCAT', 'BOOLEAN', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('ReportDate', 'DATE', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('TraxEntity', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    ('TraxAccount', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT))
  AS t(
    column_name,
    expected_data_type,
    expected_is_nullable,
    expected_numeric_precision,
    expected_numeric_scale
  )
),
actual_columns AS (
  SELECT
    c.column_name,
    upper(c.data_type) AS actual_data_type,
    upper(c.is_nullable) AS actual_is_nullable,
    CAST(c.numeric_precision AS INT) AS actual_numeric_precision,
    CAST(c.numeric_scale AS INT) AS actual_numeric_scale
  FROM system.information_schema.columns c
  WHERE lower(c.table_catalog) = 'main'
    AND lower(c.table_schema) = 'regtech_ops_stg'
    AND lower(c.table_name) = 'bi_output_regtechops_mifid2_regchange_customer'
),
missing_columns AS (
  SELECT
    e.column_name,
    'missing column' AS mismatch_type,
    e.expected_data_type,
    CAST(NULL AS STRING) AS actual_data_type,
    e.expected_is_nullable,
    CAST(NULL AS STRING) AS actual_is_nullable,
    e.expected_numeric_precision,
    CAST(NULL AS INT) AS actual_numeric_precision,
    e.expected_numeric_scale,
    CAST(NULL AS INT) AS actual_numeric_scale
  FROM expected_columns e
  LEFT JOIN actual_columns a
    ON lower(e.column_name) = lower(a.column_name)
  WHERE a.column_name IS NULL
),
datatype_mismatches AS (
  SELECT
    e.column_name,
    'unexpected data type' AS mismatch_type,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.column_name) = lower(a.column_name)
  WHERE lower(a.actual_data_type) <> lower(e.expected_data_type)
),
nullability_mismatches AS (
  SELECT
    e.column_name,
    'unexpected nullability' AS mismatch_type,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.column_name) = lower(a.column_name)
  WHERE upper(a.actual_is_nullable) <> upper(e.expected_is_nullable)
),
precision_scale_mismatches AS (
  SELECT
    e.column_name,
    'unexpected precision/scale' AS mismatch_type,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.column_name) = lower(a.column_name)
  WHERE lower(e.expected_data_type) = 'decimal'
    AND (
      COALESCE(a.actual_numeric_precision, -1) <> COALESCE(e.expected_numeric_precision, -1)
      OR COALESCE(a.actual_numeric_scale, -1) <> COALESCE(e.expected_numeric_scale, -1)
    )
)
SELECT *
FROM missing_columns
UNION ALL
SELECT *
FROM datatype_mismatches
UNION ALL
SELECT *
FROM nullability_mismatches
UNION ALL
SELECT *
FROM precision_scale_mismatches
ORDER BY column_name, mismatch_type;

-- 1b) Column-order parity check (ordinal position vs SQL Server DDL order)
WITH expected_column_order AS (
  SELECT * FROM VALUES
    (1, 'CID'),
    (2, 'RegulationID'),
    (3, 'PlayerLevelID'),
    (4, 'CountryID'),
    (5, 'FTD'),
    (6, 'AccountTypeID'),
    (7, 'Country'),
    (8, 'CopyFund'),
    (9, 'CopyFundName'),
    (10, 'FundTypeID'),
    (11, 'FundType'),
    (12, 'IDType'),
    (13, 'PIN_Type'),
    (14, 'PIN_LEI'),
    (15, 'BirthDate'),
    (16, 'FirstName'),
    (17, 'LastName'),
    (18, 'IsUKReport'),
    (19, 'IsEUReport'),
    (20, 'NotAllowedCONCAT'),
    (21, 'ReportDate'),
    (22, 'TraxEntity'),
    (23, 'TraxAccount')
  AS t(expected_ordinal_position, column_name)
),
actual_column_order AS (
  SELECT
    ordinal_position AS actual_ordinal_position,
    column_name
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_regchange_customer'
)
SELECT
  e.column_name,
  e.expected_ordinal_position,
  a.actual_ordinal_position
FROM expected_column_order e
LEFT JOIN actual_column_order a
  ON lower(e.column_name) = lower(a.column_name)
WHERE a.actual_ordinal_position IS NULL
   OR a.actual_ordinal_position <> e.expected_ordinal_position
ORDER BY e.expected_ordinal_position;

-- -----------------------------------------------------------------------------
-- 2) Source required-column checks
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'mifid2_ext_regchange_customer' AS source_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_regchange_customer' AS table_name UNION ALL
  SELECT 'internal_accounts_view', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_internal_accounts' UNION ALL
  SELECT 'ext_country_view', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ext_country' UNION ALL
  SELECT 'reg_ext_customerlatinname', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_customerlatinname'
),
required_source_columns AS (
  SELECT 'mifid2_ext_regchange_customer' AS source_key, col AS column_name
  FROM VALUES
    ('CID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'), ('RegulationID'),
    ('AccountTypeID'), ('Lei'), ('CountryIDByIP'), ('curFirstName'), ('curLastName'),
    ('curBirthDate'), ('CitizenshipCountryID'), ('PIN_ID'), ('PIN_Type'), ('PIN'),
    ('UAPI_CountryID'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'internal_accounts_view', col FROM VALUES ('CID'), ('LEI') AS t(col)
  UNION ALL
  SELECT 'ext_country_view', col FROM VALUES ('CountryID'), ('Abbreviation') AS t(col)
  UNION ALL
  SELECT 'reg_ext_customerlatinname', col FROM VALUES ('CID'), ('FirstName'), ('LastName') AS t(col)
),
available_source_columns AS (
  SELECT
    st.source_key,
    c.column_name
  FROM source_targets st
  JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(st.table_catalog)
   AND lower(c.table_schema) = lower(st.table_schema)
   AND lower(c.table_name) = lower(st.table_name)
)
SELECT
  rsc.source_key,
  rsc.column_name AS missing_required_source_column
FROM required_source_columns rsc
LEFT JOIN available_source_columns asc
  ON rsc.source_key = asc.source_key
 AND lower(rsc.column_name) = lower(asc.column_name)
WHERE asc.column_name IS NULL
ORDER BY rsc.source_key, rsc.column_name;

-- 2b) Activation gate checklist (status output; no side effects)
SELECT *
FROM VALUES
  ('step9_regchange_staging_ready', 'pending', 'bi_output_regtechops_mifid2_ext_regchange_customer source profiling and contract gates must be cleared.'),
  ('step6_regchange_interval_parity', 'pending', 'Migration population and reg-change interval parity gates must be cleared in Step 6/9 lineage.'),
  ('pin_userapi_contract', 'pending', 'PIN_ID/PIN_Type/PIN/UAPI_CountryID profiling and contracts must be approved.'),
  ('reg_ext_customerlatinname_ready', 'pending', 'bi_output_regtechops_reg_ext_customerlatinname availability/shape must be confirmed.'),
  ('ext_tradefund_mapping', 'pending', 'Dictionary.Ext_TradeFund Databricks mapping must be confirmed (FundAccountID, FundName, FundType).'),
  ('replacechar_parity', 'pending', 'bi_output_regtechops_fn_replacechar parity validation must be approved for Step 11.')
AS t(gate_name, gate_status, gate_reason);

-- Optional TradeFund column-contract check.
-- Dictionary.Ext_TradeFund mapping is not confirmed yet.
-- Replace {{ext_tradefund_source}} and {{ext_tradefund_source_table_name_only}}
-- only after the real Databricks source table is confirmed.
-- Expected logical columns: FundAccountID, FundName, FundType.
-- Keep this validation gated until the mapping is confirmed.
/*
WITH required_tradefund_columns AS (
  SELECT col AS column_name
  FROM VALUES ('FundAccountID'), ('FundName'), ('FundType') AS t(col)
),
available_tradefund_columns AS (
  SELECT c.column_name
  FROM system.information_schema.columns c
  WHERE lower(c.table_catalog) = 'main'
    AND lower(c.table_schema) = 'regtech_ops_stg'
    AND lower(c.table_name) = lower('{{ext_tradefund_source_table_name_only}}')
)
SELECT
  rtc.column_name AS missing_tradefund_column
FROM required_tradefund_columns rtc
LEFT JOIN available_tradefund_columns atc
  ON lower(rtc.column_name) = lower(atc.column_name)
WHERE atc.column_name IS NULL
ORDER BY rtc.column_name;
*/

-- -----------------------------------------------------------------------------
-- 3) Row counts by ReportDate and ReportDate/RegulationID
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
GROUP BY ReportDate
ORDER BY ReportDate;

SELECT
  ReportDate,
  RegulationID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
GROUP BY ReportDate, RegulationID
ORDER BY ReportDate, RegulationID;

-- -----------------------------------------------------------------------------
-- 4) Duplicate checks
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
GROUP BY ReportDate, CID
HAVING COUNT(*) > 1;

SELECT
  ReportDate,
  CID,
  RegulationID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
GROUP BY ReportDate, CID, RegulationID
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 5) Required null checks
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN PlayerLevelID IS NULL THEN 1 ELSE 0 END) AS null_playerlevelid_count,
  SUM(CASE WHEN CountryID IS NULL THEN 1 ELSE 0 END) AS null_countryid_count,
  SUM(CASE WHEN FTD IS NULL THEN 1 ELSE 0 END) AS null_ftd_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer;

-- -----------------------------------------------------------------------------
-- 6) Exclusion checks from SP_MIFID2_RegChange_Customer
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN o.CountryID = 250 THEN 1 ELSE 0 END) AS rows_with_country_250,
  SUM(
    CASE
      WHEN o.PlayerLevelID = 4 AND ia.CID IS NULL THEN 1
      ELSE 0
    END
  ) AS playerlevel4_without_internal_account_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN run_parameters rp
  ON o.ReportDate = rp.report_date
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
  ON o.CID = ia.CID;

-- -----------------------------------------------------------------------------
-- 7) Country-code coverage and country normalization checks
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS rows_with_missing_country_code
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country c
  ON o.CountryID = c.CountryID
WHERE c.CountryID IS NULL
   OR c.Abbreviation IS NULL
   OR length(trim(c.Abbreviation)) = 0;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN o.CountryID = 144 THEN 1 ELSE 0 END) AS output_rows_with_country_144
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN run_parameters rp
  ON o.ReportDate = rp.report_date;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_effective_country AS (
  SELECT
    s.CID,
    CASE WHEN s.RegulationID IN (4, 10) THEN 4 ELSE s.RegulationID END AS normalized_regulation_id,
    CASE
      WHEN COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID)
    END AS expected_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer s
  JOIN run_parameters rp
    ON s.ReportDate = rp.report_date
)
SELECT
  COUNT(*) AS rows_with_country_precedence_mismatch
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN run_parameters rp
  ON o.ReportDate = rp.report_date
JOIN source_effective_country s
  ON o.CID = s.CID
 AND o.RegulationID = s.normalized_regulation_id
WHERE o.CountryID <> s.expected_country_id;

WITH no_concat AS (
  SELECT CountryID
  FROM VALUES (67), (95), (102), (126), (164), (191) AS t(CountryID)
),
output_rows AS (
  SELECT
    o.CountryID,
    o.NotAllowedCONCAT
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
  WHERE o.ReportDate = CAST('{{report_date}}' AS DATE)
)
SELECT
  SUM(
    CASE
      WHEN nc.CountryID IS NOT NULL AND o.NotAllowedCONCAT <> TRUE THEN 1
      ELSE 0
    END
  ) AS no_concat_countries_flagged_false_count,
  SUM(
    CASE
      WHEN nc.CountryID IS NULL AND o.NotAllowedCONCAT <> FALSE THEN 1
      ELSE 0
    END
  ) AS non_no_concat_countries_flagged_true_count
FROM output_rows o
LEFT JOIN no_concat nc
  ON o.CountryID = nc.CountryID;

-- -----------------------------------------------------------------------------
-- 8) Name/birthdate checks
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN BirthDate IS NULL THEN 1 ELSE 0 END) AS null_birthdate_count,
  SUM(CASE WHEN FirstName IS NULL OR length(trim(FirstName)) = 0 THEN 1 ELSE 0 END) AS blank_firstname_count,
  SUM(CASE WHEN LastName IS NULL OR length(trim(LastName)) = 0 THEN 1 ELSE 0 END) AS blank_lastname_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer;

-- -----------------------------------------------------------------------------
-- 9) ReplaceChar sample checks
-- -----------------------------------------------------------------------------
WITH samples AS (
  SELECT raw_input, expected_output
  FROM VALUES
    (' šÉ-12 ', 'sE '),
    ('A_B|9', 'A B'),
    ('Éé_ß', 'Ee s')
  AS t(raw_input, expected_output)
)
SELECT
  raw_input,
  expected_output,
  main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(raw_input) AS actual_output
FROM samples;

-- Uppercase behavior sanity checks
SELECT
  SUM(
    CASE
      WHEN FirstName IS NOT NULL AND FirstName <> upper(FirstName) THEN 1
      ELSE 0
    END
  ) AS non_uppercase_firstname_count,
  SUM(
    CASE
      WHEN LastName IS NOT NULL AND LastName <> upper(LastName) THEN 1
      ELSE 0
    END
  ) AS non_uppercase_lastname_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

-- -----------------------------------------------------------------------------
-- 10) Latin-name coverage for Chinese/Cyrillic source rows
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_rows AS (
  SELECT
    s.CID,
    CASE
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.FirstName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.FirstName), 1, 1)) BETWEEN 65520 AND 65533
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.LastName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.LastName), 1, 1)) BETWEEN 65520 AND 65533
      ) THEN 'Chinese'
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.FirstName), 1, 1)) BETWEEN 1024 AND 1279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(s.LastName), 1, 1)) BETWEEN 1024 AND 1279
      ) THEN 'Cyrillic'
      ELSE NULL
    END AS detected_lang
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer s
  JOIN run_parameters rp
    ON s.ReportDate = rp.report_date
),
lang_rows AS (
  SELECT *
  FROM source_rows
  WHERE detected_lang IN ('Chinese', 'Cyrillic')
),
latin_hits AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname
)
SELECT
  lr.detected_lang,
  COUNT(*) AS lang_row_count,
  SUM(CASE WHEN lh.CID IS NULL THEN 1 ELSE 0 END) AS missing_latinname_count
FROM lang_rows lr
LEFT JOIN latin_hits lh
  ON lr.CID = lh.CID
GROUP BY lr.detected_lang
ORDER BY lr.detected_lang;

-- -----------------------------------------------------------------------------
-- 11) Blank first/last fallback behavior check
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS suspicious_one_side_blank_name_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE (length(COALESCE(trim(FirstName), '')) = 0 AND length(COALESCE(trim(LastName), '')) > 0)
   OR (length(COALESCE(trim(LastName), '')) = 0 AND length(COALESCE(trim(FirstName), '')) > 0);

-- Final Cyrillic replacements should be applied in output names.
SELECT
  SUM(
    CASE
      WHEN coalesce(FirstName, '') LIKE '%І%' OR coalesce(LastName, '') LIKE '%І%' THEN 1
      ELSE 0
    END
  ) AS rows_containing_unreplaced_cyrillic_i,
  SUM(
    CASE
      WHEN coalesce(FirstName, '') LIKE '%Ё%' OR coalesce(LastName, '') LIKE '%Ё%' THEN 1
      ELSE 0
    END
  ) AS rows_containing_unreplaced_cyrillic_yo
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

-- -----------------------------------------------------------------------------
-- 12) PIN/UserAPI completeness checks (if source is available)
-- -----------------------------------------------------------------------------
WITH required_pin_columns AS (
  SELECT col AS column_name
  FROM VALUES ('PIN_ID'), ('PIN_Type'), ('PIN'), ('UAPI_CountryID') AS t(col)
),
available_pin_columns AS (
  SELECT c.column_name
  FROM system.information_schema.columns c
  WHERE lower(c.table_catalog) = 'main'
    AND lower(c.table_schema) = 'regtech_ops_stg'
    AND lower(c.table_name) = 'bi_output_regtechops_mifid2_ext_regchange_customer'
    AND lower(c.column_name) IN ('pin_id', 'pin_type', 'pin', 'uapi_countryid')
)
SELECT
  CASE
    WHEN COUNT(apc.column_name) = 4 THEN 'source_available'
    ELSE 'source_not_available_or_not_profiled'
  END AS pin_userapi_source_status,
  COUNT(apc.column_name) AS available_required_column_count
FROM required_pin_columns rpc
LEFT JOIN available_pin_columns apc
  ON lower(rpc.column_name) = lower(apc.column_name);

-- Execute this query only when previous check returns source_available.
SELECT
  SUM(
    CASE
      WHEN PIN_Type <> 'LEI' AND (PIN_LEI IS NULL OR length(PIN_LEI) = 0)
        THEN 1
      ELSE 0
    END
  ) AS non_lei_rows_without_pin_lei_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer;

-- -----------------------------------------------------------------------------
-- 13) InternalAccounts / LEI checks
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS accounttype2_without_lei_pin_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE AccountTypeID = 2
  AND (PIN_Type <> 'LEI' OR PIN_LEI IS NULL OR length(PIN_LEI) <> 20);

SELECT
  COUNT(*) AS lei_rows_with_invalid_pin_lei_length
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE PIN_Type = 'LEI'
  AND (PIN_LEI IS NULL OR length(PIN_LEI) <> 20);

SELECT
  COUNT(*) AS internal_account_rows_missing_lei_pin_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
  ON o.CID = ia.CID
WHERE (o.PIN_Type = 'LEI' OR o.IDType = 2)
  AND (o.PIN_LEI IS NULL OR length(o.PIN_LEI) <> 20);

SELECT
  COUNT(*) AS lei_rows_not_uppercase_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
WHERE PIN_Type = 'LEI'
  AND PIN_LEI IS NOT NULL
  AND PIN_LEI <> upper(PIN_LEI);

-- Step 11-specific behavior check:
-- No-concat countries still keep country+PIN concatenation in PIN_LEI for non-LEI rows.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
no_concat AS (
  SELECT CountryID
  FROM VALUES (67), (95), (102), (126), (164), (191) AS t(CountryID)
),
source_rows AS (
  SELECT
    s.CID,
    CASE WHEN s.RegulationID IN (4, 10) THEN 4 ELSE s.RegulationID END AS normalized_regulation_id,
    CASE
      WHEN COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID)
    END AS effective_country_id,
    upper(trim(s.PIN)) AS source_pin,
    s.AccountTypeID,
    s.Lei
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer s
  JOIN run_parameters rp
    ON s.ReportDate = rp.report_date
),
expected_non_lei AS (
  SELECT
    s.CID,
    s.normalized_regulation_id,
    concat(c.Abbreviation, s.source_pin) AS expected_pin_lei
  FROM source_rows s
  JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country c
    ON s.effective_country_id = c.CountryID
  JOIN no_concat nc
    ON s.effective_country_id = nc.CountryID
  WHERE NOT (length(coalesce(s.Lei, '')) = 20 OR coalesce(s.AccountTypeID, 0) = 2)
    AND length(coalesce(s.source_pin, '')) > 0
)
SELECT
  COUNT(*) AS no_concat_rows_with_unexpected_pin_lei_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN run_parameters rp
  ON o.ReportDate = rp.report_date
JOIN expected_non_lei e
  ON o.CID = e.CID
 AND o.RegulationID = e.normalized_regulation_id
WHERE o.PIN_LEI <> e.expected_pin_lei;

-- -----------------------------------------------------------------------------
-- 14) Source-to-output row-count checks for report_date
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_rows AS (
  SELECT
    s.CID,
    CASE
      WHEN COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(s.CitizenshipCountryID, 0), s.CountryID)
    END AS effective_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer s
  JOIN run_parameters rp
    ON s.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON s.CID = ia.CID
  WHERE NOT (
    s.CountryID = 250
    OR (s.PlayerLevelID = 4 AND ia.CID IS NULL)
  )
),
source_expected AS (
  SELECT COUNT(*) AS expected_rows
  FROM source_rows s
  JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country c
    ON s.effective_country_id = c.CountryID
),
output_counts AS (
  SELECT COUNT(*) AS actual_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
  JOIN run_parameters rp
    ON o.ReportDate = rp.report_date
)
SELECT
  s.expected_rows,
  o.actual_rows,
  s.expected_rows - o.actual_rows AS row_count_delta
FROM source_expected s
CROSS JOIN output_counts o;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS output_cids_not_present_in_regchange_source
FROM output_cids o
LEFT JOIN source_cids s
  ON o.CID = s.CID
WHERE s.CID IS NULL;

-- Optional check: run when Step 9 failed-trax staging table exists in environment.
-- Confirms Step 11 output does not include failed-trax-only CIDs.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
failed_trax_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
failed_only_cids AS (
  SELECT f.CID
  FROM failed_trax_cids f
  LEFT JOIN source_cids s
    ON f.CID = s.CID
  WHERE s.CID IS NULL
),
output_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS failed_trax_only_cids_present_in_step11_output
FROM output_cids o
JOIN failed_only_cids f
  ON o.CID = f.CID;
*/

-- -----------------------------------------------------------------------------
-- 15) Comparison notes vs MIFID2_Customer
-- -----------------------------------------------------------------------------
-- OPTIONAL - run only after Step 10 MIFID2_Customer has been materialized.
-- The queries below reference:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
-- and should remain gated until that object exists.
/*
-- 15a) Schema contract parity check between regchange and customer outputs.
WITH regchange_schema AS (
  SELECT
    lower(column_name) AS column_name,
    lower(data_type) AS data_type,
    upper(is_nullable) AS is_nullable
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_regchange_customer'
),
customer_schema AS (
  SELECT
    lower(column_name) AS column_name,
    lower(data_type) AS data_type,
    upper(is_nullable) AS is_nullable
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_customer'
)
SELECT
  COALESCE(r.column_name, c.column_name) AS column_name,
  r.data_type AS regchange_data_type,
  c.data_type AS customer_data_type,
  r.is_nullable AS regchange_is_nullable,
  c.is_nullable AS customer_is_nullable
FROM regchange_schema r
FULL OUTER JOIN customer_schema c
  ON r.column_name = c.column_name
WHERE r.column_name IS NULL
   OR c.column_name IS NULL
   OR r.data_type <> c.data_type
   OR r.is_nullable <> c.is_nullable
ORDER BY COALESCE(r.column_name, c.column_name);

-- 15b) Expected row-set differences by report_date.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
regchange_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
customer_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS regchange_only_cid_count
FROM regchange_cids r
LEFT JOIN customer_cids c
  ON r.CID = c.CID
WHERE c.CID IS NULL;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
regchange_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
customer_cids AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS customer_only_cid_count
FROM customer_cids c
LEFT JOIN regchange_cids r
  ON c.CID = r.CID
WHERE r.CID IS NULL;
*/

-- 15c) Step 11 behavior note check:
-- This output should not apply excluded-CID filtering unless SP logic changes.
SELECT
  COUNT(*) AS output_rows_present_in_excluded_cid_reference
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids e
  ON o.CID = e.CID
WHERE o.ReportDate = CAST('{{report_date}}' AS DATE);
