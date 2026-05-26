-- Step 9: MIFID2_ext source profiling (non-executable staging).
--
-- Targets (all gated in Step 9):
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax
--
-- Purpose:
-- - Confirm source visibility/access and required-column contracts before un-gating Step 9 staging SQL.
-- - Keep expected/access-pending dependencies explicit:
--   - PIN/UserAPI source shape
--   - reg-change migration population parity from Step 6
--   - MIFID2_NPD_TRAX history/current availability for Failed TRAX flow

-- -----------------------------------------------------------------------------
-- 1) Source inventory and visibility
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'customer_customer' AS source_key, 'main' AS table_catalog, 'general' AS table_schema, 'bronze_etoro_customer_customer' AS table_name, 'confirmed mapping' AS source_status UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer', 'confirmed mapping' UNION ALL
  SELECT 'history_backofficecustomer', 'main', 'general', 'bronze_etoro_history_backofficecustomer', 'confirmed mapping (required-column profiling pending)' UNION ALL
  SELECT 'dictionary_country', 'main', 'general', 'bronze_etoro_dictionary_country', 'confirmed mapping' UNION ALL
  SELECT 'dictionary_label', 'main', 'general', 'bronze_etoro_dictionary_label', 'confirmed mapping' UNION ALL
  SELECT 'customer_extendeduserfield', 'main', 'dwh', 'gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield', 'confirmed mapping (PIN-shape profiling pending)' UNION ALL
  SELECT 'dictionary_extendeduservaluetype', 'main', 'compliance', 'bronze_userapidb_dictionary_extendeduservaluetype', 'confirmed mapping (PIN-shape profiling pending)' UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse', 'confirmed mapping (required-column profiling pending)' UNION ALL
  SELECT 'history_positionforexternaluse', 'main', 'trading', 'bronze_etoro_history_position_datafactory', 'confirmed mapping (required-column profiling pending)' UNION ALL
  SELECT 'history_positionchangelog', 'main', 'trading', 'bronze_etoro_history_positionchangelog', 'confirmed mapping' UNION ALL
  SELECT 'history_mirror', 'main', 'trading', 'bronze_etoro_history_mirror', 'confirmed mapping' UNION ALL
  SELECT 'hedge_executionlog', 'main', 'dealing', 'bronze_etoro_hedge_executionlog', 'confirmed mapping' UNION ALL
  SELECT 'reg_migrationinout_population', 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_migrationinout_population', 'Step 6 gated dependency' UNION ALL
  SELECT 'mifid2_npd_trax', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_npd_trax', 'expected dependency for Failed TRAX seed/cutover'
),
source_columns AS (
  SELECT
    st.source_key,
    st.table_catalog,
    st.table_schema,
    st.table_name,
    st.source_status,
    c.column_name
  FROM source_targets st
  LEFT JOIN system.information_schema.columns c
    ON lower(c.table_catalog) = lower(st.table_catalog)
   AND lower(c.table_schema) = lower(st.table_schema)
   AND lower(c.table_name) = lower(st.table_name)
)
SELECT
  source_key,
  table_catalog,
  table_schema,
  table_name,
  source_status,
  COUNT(column_name) AS visible_column_count
FROM source_columns
GROUP BY source_key, table_catalog, table_schema, table_name, source_status
ORDER BY source_key;

-- -----------------------------------------------------------------------------
-- 2) Required-column checks for key Step 9 source contracts
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'customer_customer' AS source_key, 'main' AS table_catalog, 'general' AS table_schema, 'bronze_etoro_customer_customer' AS table_name UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'history_backofficecustomer', 'main', 'general', 'bronze_etoro_history_backofficecustomer' UNION ALL
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
-- 3) Source row counts and key coverage (where practical)
-- -----------------------------------------------------------------------------
SELECT
  'customer_customer' AS source_key,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CID) AS distinct_business_key_count
FROM main.general.bronze_etoro_customer_customer
UNION ALL
SELECT
  'history_customer',
  COUNT(*),
  COUNT(DISTINCT CID)
FROM main.pii_data.bronze_etoro_history_customer
UNION ALL
SELECT
  'history_backofficecustomer',
  COUNT(*),
  COUNT(DISTINCT CID)
FROM main.general.bronze_etoro_history_backofficecustomer
UNION ALL
SELECT
  'trade_positionforexternaluse',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.bi_db.bronze_etoro_trade_positionforexternaluse
UNION ALL
SELECT
  'history_positionforexternaluse',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.trading.bronze_etoro_history_position_datafactory
UNION ALL
SELECT
  'history_positionchangelog',
  COUNT(*),
  COUNT(DISTINCT PositionID)
FROM main.trading.bronze_etoro_history_positionchangelog
UNION ALL
SELECT
  'history_mirror',
  COUNT(*),
  COUNT(DISTINCT MirrorID)
FROM main.trading.bronze_etoro_history_mirror
UNION ALL
SELECT
  'hedge_executionlog',
  COUNT(*),
  COUNT(DISTINCT OrderID)
FROM main.dealing.bronze_etoro_hedge_executionlog;

-- -----------------------------------------------------------------------------
-- 4) Source freshness support (timestamp-column discovery)
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'customer_customer' AS source_key, 'main' AS table_catalog, 'general' AS table_schema, 'bronze_etoro_customer_customer' AS table_name UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'history_backofficecustomer', 'main', 'general', 'bronze_etoro_history_backofficecustomer' UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse' UNION ALL
  SELECT 'history_positionforexternaluse', 'main', 'trading', 'bronze_etoro_history_position_datafactory' UNION ALL
  SELECT 'history_positionchangelog', 'main', 'trading', 'bronze_etoro_history_positionchangelog' UNION ALL
  SELECT 'history_mirror', 'main', 'trading', 'bronze_etoro_history_mirror' UNION ALL
  SELECT 'hedge_executionlog', 'main', 'dealing', 'bronze_etoro_hedge_executionlog'
)
SELECT
  st.source_key,
  c.column_name,
  c.data_type
FROM source_targets st
JOIN system.information_schema.columns c
  ON lower(c.table_catalog) = lower(st.table_catalog)
 AND lower(c.table_schema) = lower(st.table_schema)
 AND lower(c.table_name) = lower(st.table_name)
WHERE lower(c.data_type) IN ('timestamp', 'timestamp_ntz', 'date')
   OR lower(c.column_name) LIKE '%valid%'
   OR lower(c.column_name) LIKE '%occurred%'
   OR lower(c.column_name) LIKE '%executiontime%'
   OR lower(c.column_name) LIKE '%updated%'
ORDER BY st.source_key, c.column_name;

-- -----------------------------------------------------------------------------
-- 5) PIN/UserAPI discovery gate
-- -----------------------------------------------------------------------------
-- Step 9 expects PIN/UserAPI enrichment for customer/failed-TRAX flows.
-- Use this inventory to confirm exact source objects before un-gating SQL templates.
SELECT
  table_catalog,
  table_schema,
  table_name
FROM system.information_schema.tables
WHERE lower(table_catalog) = 'main'
  AND (
    lower(table_schema) LIKE '%userapi%'
    OR lower(table_name) LIKE '%userapi%'
    OR lower(table_name) LIKE '%pin%'
  )
ORDER BY table_catalog, table_schema, table_name;

-- -----------------------------------------------------------------------------
-- 6) Step 9 dependency gates: migration population and MIFID2_NPD_TRAX
-- -----------------------------------------------------------------------------
SELECT
  table_catalog,
  table_schema,
  table_name
FROM system.information_schema.tables
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) IN (
    'bi_output_regtechops_reg_migrationinout_population',
    'bi_output_regtechops_mifid2_npd_trax'
  )
ORDER BY table_name;

-- Optional manual follow-up after table visibility is confirmed:
-- SELECT ReportDate, COUNT(*) AS row_count
-- FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax
-- GROUP BY ReportDate
-- ORDER BY ReportDate DESC;
