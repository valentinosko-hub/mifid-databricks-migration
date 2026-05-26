-- Step 9: MIFID2_ext validation templates.
--
-- Intended targets:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
--
-- Execute only after Step 9 staging materialization is activated.

-- -----------------------------------------------------------------------------
-- 1) Source required-column checks
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'customer_customer' AS source_key, 'main' AS table_catalog, 'general' AS table_schema, 'bronze_etoro_customer_customer' AS table_name UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'history_backofficecustomer', 'main', 'general', 'bronze_etoro_history_backofficecustomer' UNION ALL
  SELECT 'dictionary_country', 'main', 'general', 'bronze_etoro_dictionary_country' UNION ALL
  SELECT 'dictionary_label', 'main', 'general', 'bronze_etoro_dictionary_label' UNION ALL
  SELECT 'customer_extendeduserfield', 'main', 'dwh', 'gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield' UNION ALL
  SELECT 'dictionary_extendeduservaluetype', 'main', 'compliance', 'bronze_userapidb_dictionary_extendeduservaluetype' UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse' UNION ALL
  SELECT 'history_positionforexternaluse', 'main', 'trading', 'bronze_etoro_history_position_datafactory' UNION ALL
  SELECT 'history_positionchangelog', 'main', 'trading', 'bronze_etoro_history_positionchangelog' UNION ALL
  SELECT 'history_mirror', 'main', 'trading', 'bronze_etoro_history_mirror' UNION ALL
  SELECT 'hedge_executionlog', 'main', 'dealing', 'bronze_etoro_hedge_executionlog' UNION ALL
  SELECT 'reg_migrationinout_population', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_migrationinout_population' UNION ALL
  SELECT 'mifid2_npd_trax', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_npd_trax'
),
required_columns AS (
  SELECT 'customer_customer' AS source_key, col AS column_name FROM VALUES
    ('CID'), ('GCID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('BirthDate'), ('CitizenshipCountryID')
  AS t(col)
  UNION ALL
  SELECT 'history_customer', col FROM VALUES
    ('CID'), ('FirstName'), ('LastName'), ('BirthDate'), ('LabelID'), ('ValidFrom'), ('ValidTo')
  AS t(col)
  UNION ALL
  SELECT 'history_backofficecustomer', col FROM VALUES
    ('CID'), ('RegulationID'), ('AccountTypeID'), ('Lei'), ('CountryIDByIP'), ('ValidFrom'), ('ValidTo')
  AS t(col)
  UNION ALL
  SELECT 'dictionary_country', col FROM VALUES
    ('CountryID')
  AS t(col)
  UNION ALL
  SELECT 'dictionary_label', col FROM VALUES
    ('LabelID')
  AS t(col)
  UNION ALL
  SELECT 'customer_extendeduserfield', col FROM VALUES
    ('GCID'), ('ValueTypeID'), ('Value'), ('CountryID')
  AS t(col)
  UNION ALL
  SELECT 'dictionary_extendeduservaluetype', col FROM VALUES
    ('ValueTypeID'), ('Code')
  AS t(col)
  UNION ALL
  SELECT 'trade_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('ParentPositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'),
    ('InitForexRate'), ('EndForexRate'), ('AmountInUnitsDecimal'), ('InstrumentID'), ('IsBuy'),
    ('Leverage'), ('LastOpConversionRate'), ('MirrorID'), ('InitExecutionID'), ('EndExecutionID'),
    ('HedgeServerID'), ('IsSettled'), ('InitForexPriceRateID'), ('EndForexPriceRateID'),
    ('LastOpPriceRate'), ('OriginalPositionID'), ('InitialUnits'), ('Occurred')
  AS t(col)
  UNION ALL
  SELECT 'history_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('ParentPositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'),
    ('InitForexRate'), ('EndForexRate'), ('AmountInUnitsDecimal'), ('InstrumentID'), ('IsBuy'),
    ('Leverage'), ('LastOpConversionRate'), ('MirrorID'), ('InitExecutionID'), ('EndExecutionID'),
    ('HedgeServerID'), ('IsSettled'), ('InitForexPriceRateID'), ('EndForexPriceRateID'),
    ('LastOpPriceRate'), ('OriginalPositionID'), ('InitialUnits')
  AS t(col)
  UNION ALL
  SELECT 'history_positionchangelog', col FROM VALUES
    ('PositionID'), ('Occurred'), ('ChangeTypeID'), ('LastOpPriceRate'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'history_mirror', col FROM VALUES
    ('MirrorID'), ('ParentCID'), ('MirrorOperationID'), ('Occurred')
  AS t(col)
  UNION ALL
  SELECT 'hedge_executionlog', col FROM VALUES
    ('OrderID'), ('HedgeServerID'), ('InstrumentID'), ('IsBuy'), ('Units'), ('ExecutionRate'),
    ('ProviderExecID'), ('ExecutionTime'), ('Success'), ('LogTime'), ('LiquidityAccountID'),
    ('EMSOrderID'), ('OrderState')
  AS t(col)
  UNION ALL
  SELECT 'reg_migrationinout_population', col FROM VALUES
    ('CID'), ('PrevRegulationID'), ('RegulationID'), ('Migration_Occurred'),
    ('RegValidFrom'), ('RegValidTo'), ('RegChangeRank'), ('RunDate')
  AS t(col)
  UNION ALL
  SELECT 'mifid2_npd_trax', col FROM VALUES
    ('CID'), ('ReportDate'), ('AcceptedTRAX')
  AS t(col)
),
available_columns AS (
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
  rc.source_key,
  rc.column_name AS missing_required_column
FROM required_columns rc
LEFT JOIN available_columns ac
  ON rc.source_key = ac.source_key
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.source_key, rc.column_name;

-- -----------------------------------------------------------------------------
-- 2) Target required-column checks
-- -----------------------------------------------------------------------------
WITH target_objects AS (
  SELECT 'MIFID2_ext_Customer' AS staging_object, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_customer' AS table_name UNION ALL
  SELECT 'MIFID2_ext_RegChange_Customer', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_regchange_customer' UNION ALL
  SELECT 'MIFID2_ext_Position', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_position' UNION ALL
  SELECT 'MIFID2_ext_RegChange_Position', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_regchange_position' UNION ALL
  SELECT 'MIFID2_ext_PositionChangeLog', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_positionchangelog' UNION ALL
  SELECT 'MIFID2_ext_Mirror', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_mirror' UNION ALL
  SELECT 'MIFID2_ext_HedgeExecutionLog', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog' UNION ALL
  SELECT 'MIFID2_Failed_TRAX', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_failed_trax'
),
required_columns AS (
  SELECT 'MIFID2_ext_Customer' AS staging_object, col AS column_name FROM VALUES
    ('CID'), ('GCID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'), ('RegulationID'), ('AccountTypeID'),
    ('Lei'), ('CountryIDByIP'), ('curFirstName'), ('curLastName'), ('curBirthDate'),
    ('CitizenshipCountryID'), ('PIN_ID'), ('PIN_Type'), ('PIN'), ('UAPI_CountryID'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_RegChange_Customer', col FROM VALUES
    ('CID'), ('GCID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'), ('RegulationID'), ('AccountTypeID'),
    ('Lei'), ('CountryIDByIP'), ('curFirstName'), ('curLastName'), ('curBirthDate'),
    ('CitizenshipCountryID'), ('PIN_ID'), ('PIN_Type'), ('PIN'), ('UAPI_CountryID'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_Position', col FROM VALUES
    ('PositionID'), ('ParentPositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'),
    ('InitForexRate'), ('EndForexRate'), ('AmountInUnitsDecimal'), ('InstrumentID'), ('IsBuy'),
    ('Leverage'), ('LastOpConversionRate'), ('MirrorID'), ('InitExecutionID'), ('EndExecutionID'),
    ('HedgeServerID'), ('IsSettled'), ('InitForexPriceRateID'), ('EndForexPriceRateID'),
    ('LastOpPriceRate'), ('OriginalPositionID'), ('InitialUnits'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_RegChange_Position', col FROM VALUES
    ('PositionID'), ('ParentPositionID'), ('CID'), ('OpenOccurred'), ('CloseOccurred'),
    ('InitForexRate'), ('EndForexRate'), ('AmountInUnitsDecimal'), ('InstrumentID'), ('IsBuy'),
    ('Leverage'), ('LastOpConversionRate'), ('MirrorID'), ('InitExecutionID'), ('EndExecutionID'),
    ('HedgeServerID'), ('IsSettled'), ('InitForexPriceRateID'), ('EndForexPriceRateID'),
    ('LastOpPriceRate'), ('OriginalPositionID'), ('InitialUnits'), ('ReportDate')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_PositionChangeLog', col FROM VALUES
    ('PositionID'), ('ChangeLogLastOpPriceRate'), ('ChangeLogOccurred'), ('ChangeTypeID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_Mirror', col FROM VALUES
    ('MirrorID'), ('ParentCID'), ('MirrorOperationID'), ('Occurred'), ('CopyFund')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ext_HedgeExecutionLog', col FROM VALUES
    ('OrderID'), ('HedgeServerID'), ('InstrumentID'), ('IsBuy'), ('Units'), ('ExecutionRate'),
    ('ProviderExecID'), ('ExecutionTime'), ('Success'), ('LogTime'), ('LiquidityAccountID'), ('EMSOrderID')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_Failed_TRAX', col FROM VALUES
    ('CID'), ('GCID'), ('PlayerLevelID'), ('PlayerStatusID'), ('CountryID'), ('LabelID'),
    ('FirstName'), ('LastName'), ('BirthDate'), ('CountryIDByIP'),
    ('curFirstName'), ('curLastName'), ('curBirthDate'), ('CitizenshipCountryID'),
    ('PIN_ID'), ('PIN_Type'), ('PIN'), ('UAPI_CountryID'), ('ReportDate')
  AS t(col)
),
available_columns AS (
  SELECT
    t.staging_object,
    c.column_name
  FROM target_objects t
  JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(t.table_catalog)
   AND lower(c.table_schema) = lower(t.table_schema)
   AND lower(c.table_name) = lower(t.table_name)
)
SELECT
  rc.staging_object,
  rc.column_name AS missing_required_column
FROM required_columns rc
LEFT JOIN available_columns ac
  ON rc.staging_object = ac.staging_object
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.staging_object, rc.column_name;

-- -----------------------------------------------------------------------------
-- 3) Row counts by ReportDate / day-window
-- -----------------------------------------------------------------------------
SELECT
  'MIFID2_ext_Customer' AS staging_object,
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
GROUP BY ReportDate
UNION ALL
SELECT
  'MIFID2_ext_RegChange_Customer',
  ReportDate,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
GROUP BY ReportDate
UNION ALL
SELECT
  'MIFID2_ext_Position',
  ReportDate,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
GROUP BY ReportDate
UNION ALL
SELECT
  'MIFID2_ext_RegChange_Position',
  ReportDate,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
GROUP BY ReportDate
UNION ALL
SELECT
  'MIFID2_Failed_TRAX',
  ReportDate,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
GROUP BY ReportDate
ORDER BY staging_object, ReportDate;

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
  'MIFID2_ext_PositionChangeLog' AS staging_object,
  rp.report_date AS report_date,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog s
JOIN run_window w
  ON s.ChangeLogOccurred >= w.start_ts
 AND s.ChangeLogOccurred < w.end_ts
JOIN run_parameters rp
  ON 1 = 1
UNION ALL
SELECT
  'MIFID2_ext_Mirror',
  rp.report_date,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror s
JOIN run_window w
  ON s.Occurred >= w.start_ts
 AND s.Occurred < w.end_ts
JOIN run_parameters rp
  ON 1 = 1
UNION ALL
SELECT
  'MIFID2_ext_HedgeExecutionLog',
  rp.report_date,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog s
JOIN run_window w
  ON s.ExecutionTime >= w.start_ts
 AND s.ExecutionTime < w.end_ts
JOIN run_parameters rp
  ON 1 = 1
ORDER BY staging_object, report_date;

-- -----------------------------------------------------------------------------
-- 4) Row counts by RegulationID where applicable
-- -----------------------------------------------------------------------------
SELECT
  'MIFID2_ext_Customer' AS staging_object,
  RegulationID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
GROUP BY RegulationID
UNION ALL
SELECT
  'MIFID2_ext_RegChange_Customer',
  RegulationID,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
GROUP BY RegulationID
ORDER BY staging_object, RegulationID;

-- -----------------------------------------------------------------------------
-- 5) Duplicate checks
-- -----------------------------------------------------------------------------
SELECT
  'customer duplicate ReportDate/CID' AS check_name,
  ReportDate,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
GROUP BY ReportDate, CID
HAVING COUNT(*) > 1;

SELECT
  'regchange customer duplicate ReportDate/CID' AS check_name,
  ReportDate,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
GROUP BY ReportDate, CID
HAVING COUNT(*) > 1;

SELECT
  'position duplicate ReportDate/PositionID' AS check_name,
  ReportDate,
  PositionID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
GROUP BY ReportDate, PositionID
HAVING COUNT(*) > 1;

SELECT
  'regchange position duplicate ReportDate/PositionID' AS check_name,
  ReportDate,
  PositionID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
GROUP BY ReportDate, PositionID
HAVING COUNT(*) > 1;

SELECT
  'changelog duplicate PositionID/ChangeLogOccurred/ChangeTypeID' AS check_name,
  PositionID,
  ChangeLogOccurred,
  ChangeTypeID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
GROUP BY PositionID, ChangeLogOccurred, ChangeTypeID
HAVING COUNT(*) > 1;

SELECT
  'mirror duplicate MirrorID' AS check_name,
  MirrorID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
GROUP BY MirrorID
HAVING COUNT(*) > 1;

SELECT
  'hedge duplicate OrderID/ExecutionTime/ProviderExecID' AS check_name,
  OrderID,
  ExecutionTime,
  ProviderExecID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
GROUP BY OrderID, ExecutionTime, ProviderExecID
HAVING COUNT(*) > 1;

SELECT
  'failed trax duplicate ReportDate/CID' AS check_name,
  ReportDate,
  CID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
GROUP BY ReportDate, CID
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 6) Null checks for required keys/fields
-- -----------------------------------------------------------------------------
SELECT
  'MIFID2_ext_Customer null key checks' AS check_name,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer;

SELECT
  'MIFID2_ext_RegChange_Customer null key checks' AS check_name,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer;

SELECT
  'MIFID2_ext_Position null key checks' AS check_name,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenOccurred IS NULL THEN 1 ELSE 0 END) AS null_openoccurred_count,
  SUM(CASE WHEN CloseOccurred IS NULL THEN 1 ELSE 0 END) AS null_closeoccurred_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position;

SELECT
  'MIFID2_ext_RegChange_Position null key checks' AS check_name,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenOccurred IS NULL THEN 1 ELSE 0 END) AS null_openoccurred_count,
  SUM(CASE WHEN CloseOccurred IS NULL THEN 1 ELSE 0 END) AS null_closeoccurred_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position;

SELECT
  'MIFID2_ext_HedgeExecutionLog null key checks' AS check_name,
  SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS null_orderid_count,
  SUM(CASE WHEN ExecutionTime IS NULL THEN 1 ELSE 0 END) AS null_executiontime_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog;

SELECT
  'MIFID2_Failed_TRAX null key checks' AS check_name,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax;

-- -----------------------------------------------------------------------------
-- 7) Customer as-of validation (History.Customer + BackOfficeCustomer)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
customer_rows AS (
  SELECT *
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
history_hits AS (
  SELECT DISTINCT s.CID
  FROM customer_rows s
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON s.CID = h.CID
  JOIN run_window w
    ON h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
),
backoffice_hits AS (
  SELECT DISTINCT s.CID
  FROM customer_rows s
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON s.CID = b.CID
  JOIN run_window w
    ON b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
)
SELECT
  (
    SELECT COUNT(*)
    FROM customer_rows s
    LEFT JOIN history_hits h
      ON s.CID = h.CID
    WHERE h.CID IS NULL
  ) AS staged_rows_without_history_asof_match,
  (
    SELECT COUNT(*)
    FROM customer_rows s
    LEFT JOIN backoffice_hits b
      ON s.CID = b.CID
    WHERE b.CID IS NULL
  ) AS staged_rows_without_backoffice_asof_match;

-- -----------------------------------------------------------------------------
-- 7b) RegChange customer as-of and migration-gate validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
regchange_rows AS (
  SELECT *
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
history_hits AS (
  SELECT DISTINCT s.CID
  FROM regchange_rows s
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON s.CID = h.CID
  JOIN run_window w
    ON h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
),
backoffice_non_mifid_hits AS (
  SELECT DISTINCT s.CID
  FROM regchange_rows s
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON s.CID = b.CID
  JOIN run_window w
    ON b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID NOT IN (1, 2, 9, 11)
),
backoffice_mifid_hits AS (
  SELECT DISTINCT s.CID
  FROM regchange_rows s
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON s.CID = b.CID
  JOIN run_window w
    ON b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID IN (1, 2, 9, 11)
),
migration_prevreg_hits AS (
  SELECT DISTINCT s.CID
  FROM regchange_rows s
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population p
    ON s.CID = p.CID
  JOIN run_parameters rp
    ON p.RunDate = rp.report_date
  WHERE p.PrevRegulationID IN (1, 2, 9, 11)
)
SELECT
  (
    SELECT COUNT(*)
    FROM regchange_rows s
    LEFT JOIN history_hits h
      ON s.CID = h.CID
    WHERE h.CID IS NULL
  ) AS regchange_rows_without_history_asof_match,
  (
    SELECT COUNT(*)
    FROM regchange_rows s
    LEFT JOIN backoffice_non_mifid_hits b
      ON s.CID = b.CID
    WHERE b.CID IS NULL
  ) AS regchange_rows_without_nonmifid_backoffice_asof_match,
  (
    SELECT COUNT(*)
    FROM regchange_rows s
    JOIN backoffice_mifid_hits b
      ON s.CID = b.CID
  ) AS regchange_rows_with_mifid_backoffice_asof_match,
  (
    SELECT COUNT(*)
    FROM regchange_rows s
    LEFT JOIN migration_prevreg_hits m
      ON s.CID = m.CID
    WHERE m.CID IS NULL
  ) AS regchange_rows_without_prevreg_gate_match,
  (
    SELECT COUNT(*)
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
    WHERE ReportDate <> (SELECT report_date FROM run_parameters)
       OR ReportDate IS NULL
  ) AS regchange_rows_with_reportdate_mismatch;

-- -----------------------------------------------------------------------------
-- 8) Position date-window validation
-- -----------------------------------------------------------------------------
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
  (
    SELECT COUNT(*)
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position p
    JOIN run_window w
      ON 1 = 1
    WHERE p.OpenOccurred < CAST('2015-04-26' AS TIMESTAMP)
       OR (
            NOT (
              (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
              OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts)
            )
          )
  ) AS invalid_position_window_count,
  (
    SELECT COUNT(*)
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position p
    JOIN run_window w
      ON 1 = 1
    WHERE p.OpenOccurred < CAST('2015-04-26' AS TIMESTAMP)
       OR (
            NOT (
              (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
              OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts)
            )
          )
  ) AS invalid_regchange_position_window_count;

-- Suspicious null-close checks:
-- CloseOccurred is acceptable as NULL only for open positions that opened within the report-day window.
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
  COUNT(*) AS suspicious_null_closeoccurred_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position p
JOIN run_window w
  ON 1 = 1
WHERE p.CloseOccurred IS NULL
  AND NOT (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts);

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
  COUNT(*) AS suspicious_regchange_null_closeoccurred_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position p
JOIN run_window w
  ON 1 = 1
WHERE p.CloseOccurred IS NULL
  AND NOT (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts);

-- -----------------------------------------------------------------------------
-- 9) PositionChangeLog ChangeTypeID = 0 validation
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS invalid_changelog_changetype_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
WHERE ChangeTypeID <> 0 OR ChangeTypeID IS NULL;

-- -----------------------------------------------------------------------------
-- 10) Mirror CopyFund validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
backoffice_asof AS (
  SELECT
    b.CID,
    b.AccountTypeID
  FROM main.general.bronze_etoro_history_backofficecustomer b
  JOIN run_window w
    ON b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
)
SELECT
  COUNT(*) AS mirror_copyfund_mismatch_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror m
LEFT JOIN backoffice_asof b
  ON m.ParentCID = b.CID
WHERE COALESCE(m.CopyFund, 0) <> CASE WHEN b.AccountTypeID = 9 THEN 1 ELSE 0 END;

-- -----------------------------------------------------------------------------
-- 11) Hedge execution filter parity validation
-- -----------------------------------------------------------------------------
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
  COUNT(*) AS invalid_providerexecid_orderstate_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog s
JOIN main.dealing.bronze_etoro_hedge_executionlog src
  ON s.OrderID = src.OrderID
 AND s.ExecutionTime = src.ExecutionTime
JOIN run_window w
  ON src.ExecutionTime >= w.start_ts
 AND src.ExecutionTime < w.end_ts
WHERE src.ProviderExecID IS NULL
  AND src.OrderState = 4;

-- -----------------------------------------------------------------------------
-- 12) Failed TRAX latest-row + accepted-status validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
latest_npd AS (
  SELECT
    t.CID,
    t.AcceptedTRAX,
    ROW_NUMBER() OVER (
      PARTITION BY t.CID
      ORDER BY t.ReportDate DESC
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax t
),
expected_failed AS (
  SELECT CID
  FROM latest_npd
  WHERE rn = 1
    AND (AcceptedTRAX = 0 OR AcceptedTRAX IS NULL)
),
staged_failed AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  (
    SELECT COUNT(*)
    FROM expected_failed ef
    LEFT JOIN staged_failed sf
      ON ef.CID = sf.CID
    WHERE sf.CID IS NULL
  ) AS expected_failed_cids_missing_from_stage,
  (
    SELECT COUNT(*)
    FROM staged_failed sf
    LEFT JOIN expected_failed ef
      ON sf.CID = ef.CID
    WHERE ef.CID IS NULL
  ) AS staged_failed_cids_not_in_expected_latest_set;

-- -----------------------------------------------------------------------------
-- 13) Source-to-stage count checks where practical
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    CAST(report_date AS TIMESTAMP) AS start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS end_ts
  FROM run_parameters
),
reg_population AS (
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
main_position_cids AS (
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
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND COALESCE(p.CloseOccurred, w.end_ts) >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
),
regchange_position_union AS (
  SELECT
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  UNION ALL
  SELECT
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND COALESCE(p.CloseOccurred, w.end_ts) >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
),
regchange_interval_cids AS (
  SELECT DISTINCT pu.CID
  FROM regchange_position_union pu
  JOIN reg_population reg
    ON pu.CID = reg.CID
   AND pu.OpenOccurred < COALESCE(reg.RegValidTo, CAST('9999-12-31 00:00:00' AS TIMESTAMP))
   AND COALESCE(pu.CloseOccurred, CAST('9999-12-31 00:00:00' AS TIMESTAMP)) >= reg.RegValidFrom
),
main_customer_scope AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
regchange_customer_scope AS (
  SELECT DISTINCT CID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
position_union AS (
  SELECT
    p.PositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse p
  JOIN run_window w
    ON p.Occurred >= w.start_ts
   AND p.Occurred < w.end_ts
  UNION ALL
  SELECT
    p.PositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred
  FROM main.trading.bronze_etoro_history_position_datafactory p
  JOIN run_window w
    ON (
         (p.CloseOccurred >= w.start_ts AND p.CloseOccurred < w.end_ts)
         OR (p.OpenOccurred >= w.start_ts AND p.OpenOccurred < w.end_ts AND COALESCE(p.CloseOccurred, w.end_ts) >= w.end_ts)
       )
   AND p.OpenOccurred >= CAST('2015-04-26' AS TIMESTAMP)
),
latest_npd AS (
  SELECT
    t.CID,
    t.AcceptedTRAX,
    ROW_NUMBER() OVER (
      PARTITION BY t.CID
      ORDER BY t.ReportDate DESC
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax t
),
source_counts AS (
  SELECT
    'MIFID2_ext_Customer' AS staging_object,
    COUNT(*) AS source_count
  FROM main.general.bronze_etoro_customer_customer c
  JOIN main_position_cids pc
    ON c.CID = pc.CID
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON c.CID = h.CID
  JOIN run_window w
    ON h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON c.CID = b.CID
   AND b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID IN (1, 2, 9, 11)
    AND b.AccountTypeID NOT IN (7, 9)
    AND h.LabelID NOT IN (26, 30)
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Customer',
    COUNT(*)
  FROM main.general.bronze_etoro_customer_customer c
  JOIN regchange_interval_cids pc
    ON c.CID = pc.CID
  JOIN main.pii_data.bronze_etoro_history_customer h
    ON c.CID = h.CID
  JOIN run_window w
    ON h.ValidFrom < w.end_ts
   AND h.ValidTo >= w.end_ts
  JOIN main.general.bronze_etoro_history_backofficecustomer b
    ON c.CID = b.CID
   AND b.ValidFrom < w.end_ts
   AND b.ValidTo >= w.end_ts
  WHERE b.RegulationID NOT IN (1, 2, 9, 11)
    AND b.AccountTypeID NOT IN (7, 9)
    AND h.LabelID NOT IN (26, 30)
  UNION ALL
  SELECT
    'MIFID2_ext_Position',
    COUNT(*)
  FROM position_union p
  JOIN main_customer_scope c
    ON p.CID = c.CID
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Position',
    COUNT(*)
  FROM position_union p
  JOIN regchange_customer_scope c
    ON p.CID = c.CID
  JOIN reg_population reg
    ON p.CID = reg.CID
   AND p.OpenOccurred < COALESCE(reg.RegValidTo, CAST('9999-12-31 00:00:00' AS TIMESTAMP))
   AND COALESCE(p.CloseOccurred, CAST('9999-12-31 00:00:00' AS TIMESTAMP)) >= reg.RegValidFrom
  UNION ALL
  SELECT
    'MIFID2_ext_PositionChangeLog' AS staging_object,
    COUNT(*) AS source_count
  FROM main.trading.bronze_etoro_history_positionchangelog src
  JOIN run_window w
    ON src.Occurred >= w.start_ts
   AND src.Occurred < w.end_ts
  WHERE src.ChangeTypeID = 0
  UNION ALL
  SELECT
    'MIFID2_ext_Mirror',
    COUNT(*)
  FROM main.trading.bronze_etoro_history_mirror src
  JOIN run_window w
    ON src.Occurred >= w.start_ts
   AND src.Occurred < w.end_ts
  WHERE src.MirrorOperationID = 1
  UNION ALL
  SELECT
    'MIFID2_ext_HedgeExecutionLog',
    COUNT(*)
  FROM main.dealing.bronze_etoro_hedge_executionlog src
  JOIN run_window w
    ON src.ExecutionTime >= w.start_ts
   AND src.ExecutionTime < w.end_ts
  WHERE NOT (src.ProviderExecID IS NULL AND src.OrderState = 4)
  UNION ALL
  -- Gated check:
  -- Expected Failed TRAX rows come from latest MIFID2_NPD_TRAX rows per CID.
  -- Keep this check gated until MIFID2_NPD_TRAX history/current availability is confirmed.
  SELECT
    'MIFID2_Failed_TRAX',
    COUNT(*)
  FROM latest_npd n
  WHERE n.rn = 1
    AND (n.AcceptedTRAX = 0 OR n.AcceptedTRAX IS NULL)
),
stage_counts AS (
  SELECT
    'MIFID2_ext_Customer' AS staging_object,
    COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Customer',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'MIFID2_ext_Position',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'MIFID2_ext_RegChange_Position',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    'MIFID2_ext_PositionChangeLog' AS staging_object,
    COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
  JOIN run_window w
    ON ChangeLogOccurred >= w.start_ts
   AND ChangeLogOccurred < w.end_ts
  UNION ALL
  SELECT
    'MIFID2_ext_Mirror',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
  JOIN run_window w
    ON Occurred >= w.start_ts
   AND Occurred < w.end_ts
  UNION ALL
  SELECT
    'MIFID2_ext_HedgeExecutionLog',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
  JOIN run_window w
    ON ExecutionTime >= w.start_ts
   AND ExecutionTime < w.end_ts
  UNION ALL
  SELECT
    'MIFID2_Failed_TRAX',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  src.staging_object,
  src.source_count,
  stg.stage_count,
  src.source_count - stg.stage_count AS count_delta,
  CASE
    WHEN src.staging_object = 'MIFID2_Failed_TRAX'
      THEN 'gated_pending_mifid2_npd_trax_history_current_availability'
    ELSE 'active_check'
  END AS check_status
FROM source_counts src
JOIN stage_counts stg
  ON src.staging_object = stg.staging_object
ORDER BY src.staging_object;
