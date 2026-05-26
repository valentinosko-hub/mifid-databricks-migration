-- Step 10: MIFID2_Customer validation templates.
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
--
-- Execute only after Step 10 output activation is approved.

-- -----------------------------------------------------------------------------
-- 1) Target schema parity (column names/order, data types, nullability, precision/scale)
-- -----------------------------------------------------------------------------
WITH expected_columns AS (
  -- SQL Server DDL source:
  -- reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_Customer.sql
  -- Databricks mapping:
  -- int -> INT, bit -> BOOLEAN, varchar/nvarchar -> STRING, date -> DATE, datetime -> TIMESTAMP.
  SELECT *
  FROM VALUES
    (1, 'CID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (2, 'RegulationID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (3, 'PlayerLevelID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (4, 'CountryID', 'INT', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (5, 'FTD', 'TIMESTAMP', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (6, 'AccountTypeID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (7, 'Country', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (8, 'CopyFund', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (9, 'CopyFundName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (10, 'FundTypeID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (11, 'FundType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (12, 'IDType', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (13, 'PIN_Type', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (14, 'PIN_LEI', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (15, 'BirthDate', 'DATE', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (16, 'FirstName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (17, 'LastName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (18, 'IsUKReport', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (19, 'IsEUReport', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (20, 'NotAllowedCONCAT', 'BOOLEAN', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (21, 'ReportDate', 'DATE', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (22, 'TraxEntity', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (23, 'TraxAccount', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT))
  AS t(
    expected_ordinal_position,
    column_name,
    expected_data_type,
    expected_is_nullable,
    expected_numeric_precision,
    expected_numeric_scale
  )
),
actual_columns AS (
  SELECT
    c.ordinal_position AS actual_ordinal_position,
    c.column_name,
    upper(c.data_type) AS actual_data_type,
    upper(c.is_nullable) AS actual_is_nullable,
    CAST(c.numeric_precision AS INT) AS actual_numeric_precision,
    CAST(c.numeric_scale AS INT) AS actual_numeric_scale
  FROM system.information_schema.columns c
  WHERE lower(c.table_catalog) = 'main'
    AND lower(c.table_schema) = 'regtech_ops_stg'
    AND lower(c.table_name) = 'bi_output_regtechops_mifid2_customer'
),
missing_columns AS (
  SELECT
    e.column_name,
    'missing column' AS mismatch_type,
    e.expected_ordinal_position,
    CAST(NULL AS INT) AS actual_ordinal_position,
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
extra_columns AS (
  SELECT
    a.column_name,
    'extra column' AS mismatch_type,
    CAST(NULL AS INT) AS expected_ordinal_position,
    a.actual_ordinal_position,
    CAST(NULL AS STRING) AS expected_data_type,
    a.actual_data_type,
    CAST(NULL AS STRING) AS expected_is_nullable,
    a.actual_is_nullable,
    CAST(NULL AS INT) AS expected_numeric_precision,
    a.actual_numeric_precision,
    CAST(NULL AS INT) AS expected_numeric_scale,
    a.actual_numeric_scale
  FROM actual_columns a
  LEFT JOIN expected_columns e
    ON lower(a.column_name) = lower(e.column_name)
  WHERE e.column_name IS NULL
),
datatype_mismatches AS (
  SELECT
    e.column_name,
    'unexpected data type' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
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
    e.expected_ordinal_position,
    a.actual_ordinal_position,
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
order_mismatches AS (
  SELECT
    e.column_name,
    'unexpected ordinal position' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
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
  WHERE e.expected_ordinal_position <> a.actual_ordinal_position
),
precision_scale_mismatches AS (
  SELECT
    e.column_name,
    'unexpected precision/scale' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
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
      COALESCE(e.expected_numeric_precision, -1) <> COALESCE(a.actual_numeric_precision, -1)
      OR COALESCE(e.expected_numeric_scale, -1) <> COALESCE(a.actual_numeric_scale, -1)
    )
)
SELECT *
FROM missing_columns
UNION ALL
SELECT *
FROM extra_columns
UNION ALL
SELECT *
FROM datatype_mismatches
UNION ALL
SELECT *
FROM nullability_mismatches
UNION ALL
SELECT *
FROM order_mismatches
UNION ALL
SELECT *
FROM precision_scale_mismatches
ORDER BY mismatch_type, column_name;

-- -----------------------------------------------------------------------------
-- 2) Source and dependency gate checks for Step 10
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'mifid2_ext_customer' AS source_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_customer' AS table_name UNION ALL
  SELECT 'mifid2_failed_trax', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_failed_trax' UNION ALL
  SELECT 'vw_internal_accounts', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_internal_accounts' UNION ALL
  SELECT 'vw_ext_country', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ext_country' UNION ALL
  SELECT 'reg_ext_customerlatinname', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_customerlatinname' UNION ALL
  SELECT 'mifid2_npd_trax', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_npd_trax'
),
visible_tables AS (
  SELECT
    st.source_key,
    CASE WHEN t.table_name IS NOT NULL THEN 'visible' ELSE 'missing_or_no_access' END AS visibility_status
  FROM source_targets st
  LEFT JOIN system.information_schema.tables t
    ON lower(t.table_catalog) = lower(st.table_catalog)
   AND lower(t.table_schema) = lower(st.table_schema)
   AND lower(t.table_name) = lower(st.table_name)
)
SELECT *
FROM visible_tables
ORDER BY source_key;

-- ReplaceChar UDF visibility.
SELECT
  CASE
    WHEN COUNT(*) > 0 THEN 'visible'
    ELSE 'missing_or_no_access'
  END AS replacechar_udf_status
FROM system.information_schema.routines
WHERE lower(routine_catalog) = 'main'
  AND lower(routine_schema) = 'regtech_ops_stg'
  AND lower(routine_name) = 'bi_output_regtechops_fn_replacechar';

-- -----------------------------------------------------------------------------
-- 3) Row counts by ReportDate / ReportDate + RegulationID
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
GROUP BY ReportDate
ORDER BY ReportDate;

SELECT
  ReportDate,
  RegulationID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
GROUP BY ReportDate, RegulationID
ORDER BY ReportDate, RegulationID;

-- -----------------------------------------------------------------------------
-- 4) Duplicate checks
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
GROUP BY ReportDate, CID
HAVING COUNT(*) > 1;

SELECT
  ReportDate,
  CID,
  RegulationID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
GROUP BY ReportDate, CID, RegulationID
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 5) Required null checks
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN PlayerLevelID IS NULL THEN 1 ELSE 0 END) AS null_playerlevelid_count,
  SUM(CASE WHEN CountryID IS NULL THEN 1 ELSE 0 END) AS null_countryid_count,
  SUM(CASE WHEN FTD IS NULL THEN 1 ELSE 0 END) AS null_ftd_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer;

-- -----------------------------------------------------------------------------
-- 6) Exclusion checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids excluded
     ON o.CID = excluded.cid) AS excluded_cids_present_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.CountryID = 250) AS output_country250_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
     ON o.CID = ia.CID
   WHERE o.PlayerLevelID = 4
     AND ia.CID IS NULL) AS playerlevel4_without_internal_account_count;

-- -----------------------------------------------------------------------------
-- 7) Country normalization checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_union AS (
  SELECT
    e.CID,
    CASE
      WHEN COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID)
    END AS expected_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
  JOIN run_parameters rp
    ON e.ReportDate = rp.report_date
  UNION ALL
  SELECT
    f.CID,
    CASE
      WHEN COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID)
    END AS expected_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  JOIN run_parameters rp
    ON f.ReportDate = rp.report_date
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
)
SELECT
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.CountryID = 144) AS output_rows_with_country_144_count,
  (SELECT COUNT(*)
   FROM source_union s
   JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
     ON o.CID = s.CID
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.CountryID <> s.expected_country_id) AS country_precedence_mismatch_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country c
     ON o.CountryID = c.CountryID
   WHERE c.CountryID IS NULL OR c.Abbreviation IS NULL OR length(trim(c.Abbreviation)) = 0)
    AS rows_without_country_abbreviation_count;

-- -----------------------------------------------------------------------------
-- 8) ReplaceChar and name normalization checks
-- -----------------------------------------------------------------------------
WITH sample_cases AS (
  SELECT raw_input, expected_replacechar_output
  FROM VALUES
    (' šÉ-12 ', 'sE '),
    ('A_B|9', 'A B'),
    ('Éé_ß', 'Ee s')
  AS t(raw_input, expected_replacechar_output)
)
SELECT
  raw_input,
  expected_replacechar_output,
  main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(raw_input) AS actual_replacechar_output,
  UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(raw_input)) AS actual_upper_output
FROM sample_cases;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_union AS (
  SELECT
    e.CID,
    e.RegulationID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName)) AS src_first_name,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName)) AS src_last_name,
    CASE
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 65520 AND 65533
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 65520 AND 65533
      ) THEN 'Chinese'
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 1024 AND 1279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 1024 AND 1279
      ) THEN 'Cyrillic'
      ELSE NULL
    END AS lang
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
  JOIN run_parameters rp
    ON e.ReportDate = rp.report_date
  UNION ALL
  SELECT
    f.CID,
    CAST(NULL AS INT) AS RegulationID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName)) AS src_first_name,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName)) AS src_last_name,
    CASE
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 65520 AND 65533
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 65520 AND 65533
      ) THEN 'Chinese'
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 1024 AND 1279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 1024 AND 1279
      ) THEN 'Cyrillic'
      ELSE NULL
    END AS lang
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  JOIN run_parameters rp
    ON f.ReportDate = rp.report_date
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
),
latin_names AS (
  SELECT
    l.CID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(l.FirstName)) AS latin_first_name,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(l.LastName)) AS latin_last_name
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname l
)
SELECT
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.FirstName IS NOT NULL
     AND o.FirstName <> UPPER(o.FirstName)) AS non_uppercase_firstname_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.LastName IS NOT NULL
     AND o.LastName <> UPPER(o.LastName)) AS non_uppercase_lastname_count,
  (SELECT COUNT(*)
   FROM source_union s
   LEFT JOIN latin_names l
     ON s.CID = l.CID
   WHERE s.lang IN ('Chinese', 'Cyrillic')
     AND l.CID IS NULL
     AND COALESCE(s.RegulationID, 0) <> 4) AS non_latin_rows_without_latin_source_count,
  (SELECT COUNT(*)
   FROM source_union s
   JOIN latin_names l
     ON s.CID = l.CID
   JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
     ON o.CID = s.CID
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE s.lang = 'Chinese'
     AND COALESCE(s.RegulationID, 0) <> 4
     AND (o.FirstName <> REPLACE(REPLACE(l.latin_first_name, 'І', 'I'), 'Ё', 'Е')
       OR o.LastName <> REPLACE(REPLACE(l.latin_last_name, 'І', 'I'), 'Ё', 'Е')))
    AS chinese_rows_not_following_latin_translation_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE (length(COALESCE(trim(o.FirstName), '')) = 0 AND length(COALESCE(trim(o.LastName), '')) > 0)
      OR (length(COALESCE(trim(o.LastName), '')) = 0 AND length(COALESCE(trim(o.FirstName), '')) > 0))
    AS blank_first_last_fallback_not_applied_count,
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE instr(COALESCE(o.FirstName, ''), 'І') > 0
      OR instr(COALESCE(o.FirstName, ''), 'Ё') > 0
      OR instr(COALESCE(o.LastName, ''), 'І') > 0
      OR instr(COALESCE(o.LastName, ''), 'Ё') > 0)
    AS rows_with_unreplaced_cyrillic_chars_count;

-- -----------------------------------------------------------------------------
-- 9) PIN / LEI checks (including no-concat countries)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
no_concat AS (
  SELECT CountryID
  FROM VALUES (67), (95), (102), (126), (164), (191) AS t(CountryID)
),
source_union AS (
  SELECT
    e.CID,
    CASE
      WHEN COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID)
    END AS normalized_country_id,
    UPPER(TRIM(e.PIN)) AS normalized_pin,
    e.AccountTypeID,
    COALESCE(e.Lei, ia.LEI) AS lei
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
  JOIN run_parameters rp
    ON e.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON e.CID = ia.CID
  UNION ALL
  SELECT
    f.CID,
    CASE
      WHEN COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID)
    END AS normalized_country_id,
    UPPER(TRIM(f.PIN)) AS normalized_pin,
    CAST(NULL AS INT) AS AccountTypeID,
    CAST(NULL AS STRING) AS lei
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  JOIN run_parameters rp
    ON f.ReportDate = rp.report_date
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
),
source_with_country AS (
  SELECT
    s.CID,
    s.AccountTypeID,
    s.lei,
    s.normalized_pin,
    s.normalized_country_id,
    c.Abbreviation AS country_abbreviation,
    nc.CountryID AS no_concat_country_id
  FROM source_union s
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country c
    ON s.normalized_country_id = c.CountryID
  LEFT JOIN no_concat nc
    ON s.normalized_country_id = nc.CountryID
)
SELECT
  (SELECT COUNT(*)
   FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE o.AccountTypeID = 2
     AND o.PIN_Type <> 'LEI') AS accounttype2_not_marked_as_lei_count,
  (SELECT COUNT(*)
   FROM source_with_country s
   JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
     ON o.CID = s.CID
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE s.lei IS NOT NULL
     AND length(s.lei) = 20
     AND (o.PIN_LEI IS NULL OR o.PIN_LEI <> UPPER(s.lei))) AS valid_lei_rows_without_upper_lei_pin_lei_count,
  (SELECT COUNT(*)
   FROM source_with_country s
   JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
     ON o.CID = s.CID
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE NOT ((s.lei IS NOT NULL AND length(s.lei) = 20) OR COALESCE(s.AccountTypeID, 0) = 2)
     AND length(COALESCE(s.normalized_pin, '')) > 0
     AND s.no_concat_country_id IS NULL
     AND o.PIN_LEI <> CONCAT(COALESCE(s.country_abbreviation, ''), s.normalized_pin))
    AS non_lei_concat_country_pin_lei_mismatch_count,
  (SELECT COUNT(*)
   FROM source_with_country s
   JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
     ON o.CID = s.CID
   JOIN run_parameters rp
     ON o.ReportDate = rp.report_date
   WHERE NOT ((s.lei IS NOT NULL AND length(s.lei) = 20) OR COALESCE(s.AccountTypeID, 0) = 2)
     AND length(COALESCE(s.normalized_pin, '')) > 0
     AND s.no_concat_country_id IS NOT NULL
     AND o.PIN_LEI <> s.normalized_pin)
    AS non_lei_no_concat_pin_lei_mismatch_count;

-- -----------------------------------------------------------------------------
-- 10) Source-to-output contribution checks for report date
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
main_customers AS (
  SELECT
    e.CID,
    CASE
      WHEN COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID)
    END AS effective_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
  JOIN run_parameters rp
    ON e.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON e.CID = ia.CID
  WHERE NOT (
    e.CountryID = 250
    OR (e.PlayerLevelID = 4 AND ia.CID IS NULL)
  )
),
failed_only AS (
  SELECT
    f.CID,
    CASE
      WHEN COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID)
    END AS effective_country_id
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  JOIN run_parameters rp
    ON f.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON f.CID = ia.CID
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
    AND NOT (
      f.CountryID = 250
      OR (f.PlayerLevelID = 4 AND ia.CID IS NULL)
    )
),
candidate_union AS (
  SELECT 'ext_customer' AS contribution_source, CID, effective_country_id FROM main_customers
  UNION ALL
  SELECT 'failed_trax_only' AS contribution_source, CID, effective_country_id FROM failed_only
),
candidate_after_country_exclusion AS (
  SELECT
    cu.contribution_source,
    cu.CID
  FROM candidate_union cu
  JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country country
    ON cu.effective_country_id = country.CountryID
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids excluded
    ON cu.CID = excluded.cid
  WHERE excluded.cid IS NULL
),
contribution_counts AS (
  SELECT
    contribution_source,
    COUNT(*) AS contribution_row_count
  FROM candidate_after_country_exclusion
  GROUP BY contribution_source
),
final_output_count AS (
  SELECT COUNT(*) AS output_row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
  JOIN run_parameters rp
    ON o.ReportDate = rp.report_date
),
expected_total_count AS (
  SELECT COUNT(*) AS expected_row_count
  FROM candidate_after_country_exclusion
)
SELECT
  (SELECT contribution_row_count FROM contribution_counts WHERE contribution_source = 'ext_customer') AS ext_customer_contribution_count,
  (SELECT contribution_row_count FROM contribution_counts WHERE contribution_source = 'failed_trax_only') AS failed_trax_contribution_count,
  e.expected_row_count AS expected_total_after_filters,
  o.output_row_count AS actual_output_row_count,
  e.expected_row_count - o.output_row_count AS final_count_delta
FROM expected_total_count e
CROSS JOIN final_output_count o;
