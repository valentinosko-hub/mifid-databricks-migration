-- Step 8: ASIC2-compatible MiFID subset validation templates.
--
-- Intended targets:
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
--   main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog
--   main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport
--   main.regtech_ops_stg.bi_output_regtechops_asic2_positions
--   main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata
--   main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials
--   main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
--   main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
--
-- Execute only after Step 8 staging/view activation gates are approved.

-- -----------------------------------------------------------------------------
-- 1) Source required-column checks
-- -----------------------------------------------------------------------------
WITH source_targets AS (
  SELECT 'history_positionchangelog' AS source_key, 'main' AS table_catalog, 'trading' AS table_schema, 'bronze_etoro_history_positionchangelog' AS table_name UNION ALL
  SELECT 'trade_positionforexternaluse', 'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse' UNION ALL
  SELECT 'customer_customer', 'main', 'general', 'bronze_etoro_customer_customer' UNION ALL
  SELECT 'history_customer', 'main', 'pii_data', 'bronze_etoro_history_customer' UNION ALL
  SELECT 'dictionary_country', 'main', 'general', 'bronze_etoro_dictionary_country' UNION ALL
  SELECT 'dictionary_label', 'main', 'general', 'bronze_etoro_dictionary_label' UNION ALL
  SELECT 'reg_instruments_scd', 'main', 'regtech', 'gold_regtech_reg_instruments_scd' UNION ALL
  SELECT 'excluded_instruments', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_instruments' UNION ALL
  SELECT 'excluded_position_ids', 'main', 'regtech_stg', 'silver_sharepoint_transactionreporting_regtech_excluded_position_ids'
),
required_columns AS (
  SELECT 'history_positionchangelog' AS source_key, col AS column_name FROM VALUES
    ('PositionID'), ('Occurred'), ('ChangeTypeID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'trade_positionforexternaluse', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('CloseOccurred'),
    ('AmountInUnitsDecimal'), ('InitForexRate'), ('Amount'), ('IsBuy'), ('IsSettled'),
    ('UpdateDate'), ('EndForexRate'), ('NetProfit'), ('LastOpPriceRate'),
    ('OriginalPositionID'), ('RegulationID'), ('InitForexPriceRateID'),
    ('EndForexPriceRateID'), ('InitConversionRate'), ('InitialUnits'),
    ('PartialCloseRatio'), ('SettlementTypeID')
  AS t(col)
  UNION ALL
  SELECT 'customer_customer', col FROM VALUES
    ('CID'), ('LabelID'), ('PlayerLevelID'), ('PlayerStatusID'), ('ExternalID')
  AS t(col)
  UNION ALL
  SELECT 'history_customer', col FROM VALUES
    ('CID'), ('FirstName'), ('LastName')
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
  SELECT 'reg_instruments_scd', col FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('BuyCurrencyID'), ('SellCurrencyID')
  AS t(col)
  UNION ALL
  SELECT 'excluded_instruments', col FROM VALUES
    ('InstrumentID')
  AS t(col)
  UNION ALL
  SELECT 'excluded_position_ids', col FROM VALUES
    ('PositionID')
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
  SELECT 'ASIC2_ext_PositionChangeLog' AS staging_object, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_asic2_ext_positionchangelog' AS table_name UNION ALL
  SELECT 'ASIC2_ext_OpenPositions_PositionsReport', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_ext_openpositions_positionsreport' UNION ALL
  SELECT 'ASIC2_Customer_PositionReport', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_customer_positionreport' UNION ALL
  SELECT 'ASIC2_InstrumentMetaData', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_instrumentmetadata' UNION ALL
  SELECT 'ASIC2_Positions', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_positions' UNION ALL
  SELECT 'ASIC2_Removed_OP_Partials', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_removed_op_partials' UNION ALL
  SELECT 'ASIC2_Transactions', 'main', 'regtech_ops_stg', 'bi_output_regtechops_asic2_transactions' UNION ALL
  SELECT 'MIFID2_ASIC2_Transactions', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_asic2_transactions'
),
required_columns AS (
  SELECT 'ASIC2_ext_PositionChangeLog' AS staging_object, col AS column_name FROM VALUES
    ('PositionID'), ('ChangeLogLastOpPriceRate'), ('ChangeLogOccurred'), ('ChangeTypeID'), ('IsSettled')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_ext_OpenPositions_PositionsReport', col FROM VALUES
    ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'), ('CloseOccurred'),
    ('AmountInUnitsDecimal'), ('InitForexRate'), ('Amount'), ('IsBuy'), ('IsSettled'),
    ('UpdateDate'), ('EndForexRate'), ('NetProfit'), ('LastOpPriceRate'),
    ('OriginalPositionID'), ('RegulationID'), ('InitForexPriceRateID'),
    ('EndForexPriceRateID'), ('InitConversionRate'), ('InitialUnits'),
    ('PartialCloseRatio'), ('SettlementTypeID')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_Customer_PositionReport', col FROM VALUES
    ('CID'), ('RegulationID'), ('LabelID'), ('PlayerLevelID'), ('PlayerStatusID'),
    ('ExternalID'), ('PrevRegulationID'), ('PrevLabelID'), ('PrevPlayerLevelID'),
    ('PrevPlayerStatusID'), ('PrevLabel'), ('CountryID'), ('Country'), ('UpdateDate'),
    ('CurLabel'), ('FirstName'), ('LastName'), ('LEI'), ('AccountTypeID')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_InstrumentMetaData', col FROM VALUES
    ('InstrumentID'), ('InstrumentTypeID'), ('Exchange'), ('BuyCurrencyID'), ('SellCurrencyID'),
    ('ISINCode'), ('BuyAbbreviation'), ('SellAbbreviation'), ('InstrumentName'), ('IsGBX'),
    ('ISINCountryCode'), ('InstrumentOfficialName'), ('DollarRatio'), ('Precision')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_Positions', col FROM VALUES
    ('ReportDate'), ('DateID'), ('CID'), ('PositionID'), ('InstrumentID'), ('Deal'),
    ('Login'), ('Transaction Time'), ('Type'), ('Symbol'), ('Volume'), ('Open Price'),
    ('Close Price'), ('Profit'), ('Login Name'), ('UpdateDate'), ('LEI'),
    ('ValuationDateTime'), ('RegulationID')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_Removed_OP_Partials', col FROM VALUES
    ('ReportDate'), ('PositionID'), ('CID'), ('InstrumentID'), ('OpenOccurred'),
    ('CloseOccurred'), ('AmountInUnitsDecimal'), ('InitForexRate'), ('Amount'),
    ('IsBuy'), ('IsSettled'), ('UpdateDate'), ('EndForexRate'), ('NetProfit'),
    ('LastOpPriceRate'), ('OriginalPositionID'), ('RegulationID'), ('InitForexPriceRateID'),
    ('EndForexPriceRateID'), ('InitConversionRate'), ('InitialUnits'), ('PartialCloseRatio'),
    ('SettlementTypeID'), ('OpenORClose')
  AS t(col)
  UNION ALL
  SELECT 'ASIC2_Transactions', col FROM VALUES
    ('DateID'), ('ReportDate'), ('CID'), ('RegulationID'), ('RegChange'), ('InstrumentID'),
    ('PositionID'), ('OpenORClose'), ('IsBuy'), ('OpenPrice'), ('Quantity'),
    ('Unique_product_identifier_UPI'), ('CDE_Execution_timestamp')
  AS t(col)
  UNION ALL
  SELECT 'MIFID2_ASIC2_Transactions', col FROM VALUES
    ('DateID'), ('ReportDate'), ('CID'), ('PositionID'), ('InstrumentID'),
    ('OpenORClose'), ('IsBuy'), ('OpenTime'), ('Volume'), ('OpenPrice'), ('RegChange')
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
-- 3) Row counts by ReportDate
-- -----------------------------------------------------------------------------
SELECT
  'ASIC2_Positions' AS target_object,
  CAST(ReportDate AS DATE) AS report_date,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_positions
GROUP BY CAST(ReportDate AS DATE)
UNION ALL
SELECT
  'ASIC2_Removed_OP_Partials',
  CAST(ReportDate AS DATE),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials
GROUP BY CAST(ReportDate AS DATE)
UNION ALL
SELECT
  'ASIC2_Transactions',
  CAST(ReportDate AS DATE),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
GROUP BY CAST(ReportDate AS DATE)
UNION ALL
SELECT
  'MIFID2_ASIC2_Transactions',
  CAST(ReportDate AS DATE),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
GROUP BY CAST(ReportDate AS DATE)
UNION ALL
SELECT
  'vw_mifid2_asic_transactions',
  CAST(ReportDate AS DATE),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
GROUP BY CAST(ReportDate AS DATE)
ORDER BY target_object, report_date;

-- -----------------------------------------------------------------------------
-- 4) Row counts by RegulationID where present
-- -----------------------------------------------------------------------------
SELECT
  'ASIC2_ext_OpenPositions_PositionsReport' AS target_object,
  RegulationID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
GROUP BY RegulationID
UNION ALL
SELECT
  'ASIC2_Customer_PositionReport',
  RegulationID,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport
GROUP BY RegulationID
UNION ALL
SELECT
  'ASIC2_Positions',
  RegulationID,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_positions
GROUP BY RegulationID
UNION ALL
SELECT
  'ASIC2_Transactions',
  RegulationID,
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
GROUP BY RegulationID
ORDER BY target_object, RegulationID;

-- -----------------------------------------------------------------------------
-- 5) Duplicate checks by ReportDate, PositionID, OpenORClose
-- -----------------------------------------------------------------------------
SELECT
  'ASIC2_Transactions duplicates' AS check_name,
  ReportDate,
  PositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
GROUP BY ReportDate, PositionID, OpenORClose
HAVING COUNT(*) > 1;

SELECT
  'MIFID2_ASIC2_Transactions duplicates' AS check_name,
  ReportDate,
  PositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
GROUP BY ReportDate, PositionID, OpenORClose
HAVING COUNT(*) > 1;

SELECT
  'vw_mifid2_asic_transactions duplicates' AS check_name,
  ReportDate,
  PositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
GROUP BY ReportDate, PositionID, OpenORClose
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 6) Null checks for MiFID compatibility fields
-- -----------------------------------------------------------------------------
SELECT
  'MIFID2_ASIC2_Transactions null checks' AS check_name,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR TRIM(CAST(OpenORClose AS STRING)) = '' THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN IsBuy IS NULL OR TRIM(CAST(IsBuy AS STRING)) = '' THEN 1 ELSE 0 END) AS null_isbuy_count,
  SUM(CASE WHEN OpenTime IS NULL THEN 1 ELSE 0 END) AS null_opentime_count,
  SUM(CASE WHEN Volume IS NULL OR TRIM(CAST(Volume AS STRING)) = '' THEN 1 ELSE 0 END) AS null_volume_count,
  SUM(CASE WHEN OpenPrice IS NULL OR TRIM(CAST(OpenPrice AS STRING)) = '' THEN 1 ELSE 0 END) AS null_openprice_count,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_regchange_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions;

SELECT
  'vw_mifid2_asic_transactions null checks' AS check_name,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR TRIM(CAST(OpenORClose AS STRING)) = '' THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN IsBuy IS NULL OR TRIM(CAST(IsBuy AS STRING)) = '' THEN 1 ELSE 0 END) AS null_isbuy_count,
  SUM(CASE WHEN OpenTime IS NULL THEN 1 ELSE 0 END) AS null_opentime_count,
  SUM(CASE WHEN Volume IS NULL OR TRIM(CAST(Volume AS STRING)) = '' THEN 1 ELSE 0 END) AS null_volume_count,
  SUM(CASE WHEN OpenPrice IS NULL OR TRIM(CAST(OpenPrice AS STRING)) = '' THEN 1 ELSE 0 END) AS null_openprice_count,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_regchange_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions;

-- -----------------------------------------------------------------------------
-- 7) Compatibility view schema check (exactly 11 required columns)
-- -----------------------------------------------------------------------------
WITH required_columns AS (
  SELECT col AS column_name FROM VALUES
    ('DateID'),
    ('ReportDate'),
    ('CID'),
    ('PositionID'),
    ('InstrumentID'),
    ('OpenORClose'),
    ('IsBuy'),
    ('OpenTime'),
    ('Volume'),
    ('OpenPrice'),
    ('RegChange')
  AS t(col)
),
view_columns AS (
  SELECT column_name
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_vw_mifid2_asic_transactions'
)
SELECT
  'missing_required_column' AS issue_type,
  rc.column_name
FROM required_columns rc
LEFT JOIN view_columns vc
  ON lower(rc.column_name) = lower(vc.column_name)
WHERE vc.column_name IS NULL
UNION ALL
SELECT
  'unexpected_extra_column' AS issue_type,
  vc.column_name
FROM view_columns vc
LEFT JOIN required_columns rc
  ON lower(vc.column_name) = lower(rc.column_name)
WHERE rc.column_name IS NULL
ORDER BY issue_type, column_name;

-- Column count must equal 11.
SELECT
  COUNT(*) AS actual_view_column_count
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_vw_mifid2_asic_transactions';

-- -----------------------------------------------------------------------------
-- 8) OpenTime parsing / CDE_Execution_timestamp validation
-- -----------------------------------------------------------------------------
WITH parsed_cde AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    CDE_Execution_timestamp,
    COALESCE(
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss.SSSX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ssX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss'Z'")
    ) AS parsed_execution_ts
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
)
SELECT
  CAST(ReportDate AS DATE) AS report_date,
  COUNT(*) AS row_count,
  SUM(CASE WHEN CDE_Execution_timestamp IS NULL OR TRIM(CDE_Execution_timestamp) = '' THEN 1 ELSE 0 END) AS blank_cde_execution_timestamp_count,
  SUM(CASE WHEN CDE_Execution_timestamp IS NOT NULL AND parsed_execution_ts IS NULL THEN 1 ELSE 0 END) AS unparseable_cde_execution_timestamp_count
FROM parsed_cde
GROUP BY CAST(ReportDate AS DATE)
ORDER BY report_date;

-- Compare parsed CDE timestamp to projected OpenTime.
WITH parsed_cde AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    COALESCE(
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss.SSSX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ssX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss'Z'")
    ) AS parsed_execution_ts
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
),
projected AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    OpenTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
)
SELECT
  CAST(p.ReportDate AS DATE) AS report_date,
  COUNT(*) AS compared_rows,
  SUM(
    CASE
      WHEN p.parsed_execution_ts IS NULL AND pr.OpenTime IS NULL THEN 0
      WHEN p.parsed_execution_ts = pr.OpenTime THEN 0
      ELSE 1
    END
  ) AS parsed_opentime_mismatch_count
FROM parsed_cde p
JOIN projected pr
  ON p.ReportDate = pr.ReportDate
 AND p.PositionID = pr.PositionID
 AND p.OpenORClose = pr.OpenORClose
GROUP BY CAST(p.ReportDate AS DATE)
ORDER BY report_date;

-- -----------------------------------------------------------------------------
-- 9) OpenTime round-trip format checks
-- -----------------------------------------------------------------------------
-- Parse CDE execution timestamp, format it back to expected ETORO-style string,
-- and compare against source CDE plus projected OpenTime formatting.
WITH parsed_cde AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    CDE_Execution_timestamp,
    COALESCE(
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss.SSSX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ssX"),
      to_timestamp(CDE_Execution_timestamp, "yyyy-MM-dd'T'HH:mm:ss'Z'")
    ) AS parsed_execution_ts
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
),
projected AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    OpenTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
)
SELECT
  CAST(p.ReportDate AS DATE) AS report_date,
  COUNT(*) AS compared_rows,
  SUM(
    CASE
      WHEN p.CDE_Execution_timestamp IS NULL OR p.parsed_execution_ts IS NULL THEN 0
      WHEN date_format(p.parsed_execution_ts, "yyyy-MM-dd'T'HH:mm:ss'Z'") = p.CDE_Execution_timestamp THEN 0
      ELSE 1
    END
  ) AS cde_round_trip_mismatch_count,
  SUM(
    CASE
      WHEN p.parsed_execution_ts IS NULL OR pr.OpenTime IS NULL THEN 0
      WHEN date_format(p.parsed_execution_ts, "yyyy-MM-dd'T'HH:mm:ss'Z'")
         = date_format(pr.OpenTime, "yyyy-MM-dd'T'HH:mm:ss'Z'") THEN 0
      ELSE 1
    END
  ) AS opentime_round_trip_mismatch_count
FROM parsed_cde p
JOIN projected pr
  ON p.ReportDate = pr.ReportDate
 AND p.PositionID = pr.PositionID
 AND p.OpenORClose = pr.OpenORClose
GROUP BY CAST(p.ReportDate AS DATE)
ORDER BY report_date;

-- -----------------------------------------------------------------------------
-- 10) Quantity -> Volume parity aggregate checks
-- -----------------------------------------------------------------------------
WITH source_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS report_date,
    SUM(try_cast(Quantity AS DECIMAL(38, 10))) AS quantity_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
  GROUP BY CAST(ReportDate AS DATE)
),
target_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS report_date,
    SUM(try_cast(Volume AS DECIMAL(38, 10))) AS volume_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
  GROUP BY CAST(ReportDate AS DATE)
)
SELECT
  s.report_date,
  s.quantity_sum,
  t.volume_sum,
  (s.quantity_sum - t.volume_sum) AS quantity_volume_delta
FROM source_agg s
JOIN target_agg t
  ON s.report_date = t.report_date
ORDER BY s.report_date;

-- -----------------------------------------------------------------------------
-- 11) Source-to-stage count checks where practical
-- -----------------------------------------------------------------------------
WITH source_counts AS (
  SELECT
    'ASIC2_ext_PositionChangeLog' AS staging_object,
    COUNT(*) AS source_count
  FROM main.trading.bronze_etoro_history_positionchangelog
  UNION ALL
  SELECT
    'ASIC2_ext_OpenPositions_PositionsReport',
    COUNT(*)
  FROM main.bi_db.bronze_etoro_trade_positionforexternaluse
),
stage_counts AS (
  SELECT
    'ASIC2_ext_PositionChangeLog' AS staging_object,
    COUNT(*) AS stage_count
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog
  UNION ALL
  SELECT
    'ASIC2_ext_OpenPositions_PositionsReport',
    COUNT(*)
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport
)
SELECT
  src.staging_object,
  src.source_count,
  stg.stage_count,
  src.source_count - stg.stage_count AS count_delta
FROM source_counts src
JOIN stage_counts stg
  ON src.staging_object = stg.staging_object
ORDER BY src.staging_object;

-- -----------------------------------------------------------------------------
-- 12) Explicit UPI non-dependency checks for MiFID-consumed fields
-- -----------------------------------------------------------------------------
-- Groups with multiple UPI values but unchanged MiFID-consumed field tuple.
WITH grouped AS (
  SELECT
    ReportDate,
    PositionID,
    OpenORClose,
    COUNT(DISTINCT Unique_product_identifier_UPI) AS upi_variant_count,
    COUNT(
      DISTINCT CONCAT_WS(
        '||',
        CAST(DateID AS STRING),
        CAST(ReportDate AS STRING),
        CAST(CID AS STRING),
        CAST(PositionID AS STRING),
        CAST(InstrumentID AS STRING),
        CAST(OpenORClose AS STRING),
        CAST(IsBuy AS STRING),
        CAST(CDE_Execution_timestamp AS STRING),
        CAST(Quantity AS STRING),
        CAST(OpenPrice AS STRING),
        CAST(RegChange AS STRING)
      )
    ) AS mifid_tuple_variant_count
  FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions
  GROUP BY ReportDate, PositionID, OpenORClose
)
SELECT
  ReportDate,
  PositionID,
  OpenORClose,
  upi_variant_count,
  mifid_tuple_variant_count
FROM grouped
WHERE upi_variant_count > 1
ORDER BY ReportDate, PositionID, OpenORClose;

-- -----------------------------------------------------------------------------
-- 13) Reg_DWH_StaticPosition fallback impact checks (conditional)
-- -----------------------------------------------------------------------------
-- Primary impact indicator: OpenPrice null/blank in MiFID projection by ReportDate.
SELECT
  CAST(ReportDate AS DATE) AS report_date,
  COUNT(*) AS row_count,
  SUM(CASE WHEN OpenPrice IS NULL OR TRIM(CAST(OpenPrice AS STRING)) = '' THEN 1 ELSE 0 END) AS null_or_blank_openprice_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
GROUP BY CAST(ReportDate AS DATE)
ORDER BY report_date;

-- Discover whether StaticPosition-like source objects are available for fallback analysis.
SELECT
  table_catalog,
  table_schema,
  table_name
FROM system.information_schema.tables
WHERE lower(table_name) LIKE '%staticposition%'
ORDER BY table_catalog, table_schema, table_name;

-- Optional fallback comparison template (activate only after source mapping is confirmed):
/*
SELECT
  t.ReportDate,
  COUNT(*) AS potential_openprice_fallback_rows
FROM main.regtech_ops_stg.bi_output_regtechops_asic2_transactions t
LEFT JOIN <resolved_staticposition_source> s
  ON t.PositionID = s.PositionID
WHERE (t.OpenPrice IS NULL OR TRIM(CAST(t.OpenPrice AS STRING)) = '')
  AND s.PositionID IS NOT NULL
GROUP BY t.ReportDate
ORDER BY t.ReportDate;
*/

