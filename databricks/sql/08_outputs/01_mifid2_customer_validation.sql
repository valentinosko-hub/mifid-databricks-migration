-- Step 10: MIFID2_Customer validation templates.
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
--
-- Execute only after Step 10 output activation is approved.

-- -----------------------------------------------------------------------------
-- 1) Target schema parity check (DDL contract: MIFID2_Customer.sql)
-- -----------------------------------------------------------------------------
WITH expected_columns AS (
  -- SQL Server DDL source:
  -- reference/mifid_databricks_migration_context/02_sql_server_ddls/target_output_tables/MIFID2_Customer.sql
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
    AND lower(c.table_name) = 'bi_output_regtechops_mifid2_customer'
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

-- -----------------------------------------------------------------------------
-- 2) Source required-column checks
-- -----------------------------------------------------------------------------

WITH source_targets AS (
  SELECT 'mifid2_ext_customer' AS source_key, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_customer' AS table_name UNION ALL
  SELECT 'mifid2_failed_trax', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_failed_trax' UNION ALL
  SELECT 'internal_accounts_view', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_internal_accounts' UNION ALL
  SELECT 'ext_country_view', 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ext_country' UNION ALL
  SELECT 'reg_ext_customerlatinname', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_customerlatinname'
),
required_source_columns AS (
  SELECT 'mifid2_ext_customer' AS source_key, col AS column_name
  FROM VALUES
    ('CID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'), ('RegulationID'),
    ('AccountTypeID'), ('Lei'), ('CountryIDByIP'), ('curFirstName'), ('curLastName'),
    ('curBirthDate'), ('CitizenshipCountryID'), ('PIN_ID'), ('PIN_Type'), ('PIN'),
    ('UAPI_CountryID'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'mifid2_failed_trax', col
  FROM VALUES
    ('CID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'),
    ('CountryIDByIP'), ('curFirstName'), ('curLastName'), ('curBirthDate'),
    ('CitizenshipCountryID'), ('PIN_ID'), ('PIN_Type'), ('PIN'),
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

-- -----------------------------------------------------------------------------
-- 2) Row counts by ReportDate and RegulationID
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
-- 3) Duplicate checks
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
-- 4) Required null checks
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN CountryID IS NULL THEN 1 ELSE 0 END) AS null_countryid_count,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country_code_count,
  SUM(CASE WHEN BirthDate IS NULL THEN 1 ELSE 0 END) AS null_birthdate_count,
  SUM(CASE WHEN FirstName IS NULL OR length(trim(FirstName)) = 0 THEN 1 ELSE 0 END) AS blank_firstname_count,
  SUM(CASE WHEN LastName IS NULL OR length(trim(LastName)) = 0 THEN 1 ELSE 0 END) AS blank_lastname_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer;

-- -----------------------------------------------------------------------------
-- 5) ReplaceChar parity sample checks
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

-- -----------------------------------------------------------------------------
-- 6) InternalAccounts / LEI coverage checks
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS accounttype2_without_lei_pin_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
WHERE AccountTypeID = 2
  AND (PIN_Type <> 'LEI' OR PIN_LEI IS NULL OR length(PIN_LEI) <> 20);

SELECT
  COUNT(*) AS internal_account_rows_missing_lei_pin_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
  ON o.CID = ia.CID
WHERE (o.PIN_Type = 'LEI' OR o.IDType = 2)
  AND (o.PIN_LEI IS NULL OR length(o.PIN_LEI) <> 20);

-- -----------------------------------------------------------------------------
-- 7) PIN/UserAPI source availability + completeness checks
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
    AND lower(c.table_name) = 'bi_output_regtechops_mifid2_ext_customer'
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
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer;

-- -----------------------------------------------------------------------------
-- 8) Source-to-output row-count check for report_date
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
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
),
candidate_union AS (
  SELECT * FROM main_customers
  UNION ALL
  SELECT * FROM failed_only
),
source_expected AS (
  SELECT COUNT(*) AS expected_rows
  FROM candidate_union cu
  JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country country
    ON cu.effective_country_id = country.CountryID
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids excluded
    ON excluded.cid = cu.CID
  WHERE excluded.cid IS NULL
),
output_counts AS (
  SELECT COUNT(*) AS actual_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer o
  JOIN run_parameters rp
    ON o.ReportDate = rp.report_date
)
SELECT
  s.expected_rows,
  o.actual_rows,
  s.expected_rows - o.actual_rows AS row_count_delta
FROM source_expected s
CROSS JOIN output_counts o;
