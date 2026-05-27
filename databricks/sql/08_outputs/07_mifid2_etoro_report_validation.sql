-- Step 13B3: MIFID2_ETORO_Report validation and reconciliation package (read-only).
--
-- Scope in this file:
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
-- - main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
--
-- Rules:
-- - SELECT-only validation SQL.
-- - Do not add CREATE / INSERT / UPDATE / DELETE / MERGE / DROP statements.
-- - Keep placeholder-dependent checks gated/commented.
--
-- Dependencies:
-- - Step 13A analysis:
--     docs/mifid2_etoro_report_output_analysis.md
-- - Step 13B2 gated projection template:
--     databricks/sql/08_outputs/07_mifid2_etoro_report.sql

-- -----------------------------------------------------------------------------
-- 0) Run parameters and validation gates
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
validation_gates AS (
  SELECT *
  FROM VALUES
    ('step13b2_projection_activation', 'pending', 'Step 13B2 ETORO projection template must be activated for the run date.'),
    ('step8_compatibility_source_activation', 'pending', 'ASIC2 compatibility view must be active and contract-validated.'),
    ('opentime_parity', 'pending', 'CDE_Execution_timestamp -> OpenTime parity must be approved.'),
    ('openprice_parity', 'pending', 'OpenPrice parity must be approved for requested windows.'),
    ('staticposition_fallback_conditional', 'pending', 'Reg_DWH_StaticPosition fallback impact remains conditional unless proven.'),
    ('instrumentclassification_exact_mapping', 'pending', 'Exact ETORO InstrumentClassification mapping remains hard-gated unless fully ported.'),
    ('dictionary_and_instrument_sources', 'pending', 'Dictionary and instrument metadata dependencies must be report-date ready.'),
    ('asic2_history_seed_window', 'pending', 'ASIC2 history seed coverage must satisfy requested validation windows.'),
    ('sqlserver_baseline_optional', 'pending', 'SQL Server baseline comparison is optional and placeholder-gated until provided.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  vg.gate_name,
  vg.gate_status,
  vg.gate_reason
FROM run_parameters rp
CROSS JOIN validation_gates vg
ORDER BY vg.gate_name;

-- -----------------------------------------------------------------------------
-- 1) Schema parity checks
-- - column names
-- - ordinal positions
-- - data types / precision / scale (where available in information_schema)
-- - nullability expectations for required ETORO fields
-- -----------------------------------------------------------------------------
WITH expected_table AS (
  SELECT 'bi_output_regtechops_mifid2_etoro_report' AS table_name, 100 AS expected_column_count
),
actual_table AS (
  SELECT
    lower(table_name) AS table_name,
    COUNT(*) AS actual_column_count
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_etoro_report'
  GROUP BY lower(table_name)
)
SELECT
  e.table_name,
  e.expected_column_count,
  a.actual_column_count,
  CASE
    WHEN a.table_name IS NULL THEN 'missing_table'
    WHEN e.expected_column_count <> a.actual_column_count THEN 'column_count_mismatch'
    ELSE 'ok'
  END AS schema_width_status
FROM expected_table e
LEFT JOIN actual_table a
  ON lower(e.table_name) = a.table_name;

-- Full column-order/type/nullability snapshot for manual parity review.
SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  numeric_precision,
  numeric_scale
FROM system.information_schema.columns
WHERE lower(table_catalog) = 'main'
  AND lower(table_schema) = 'regtech_ops_stg'
  AND lower(table_name) = 'bi_output_regtechops_mifid2_etoro_report'
ORDER BY ordinal_position;

-- Required-column contract checks (name/order/type/nullability expectations).
WITH expected_required_columns AS (
  SELECT *
  FROM VALUES
    (1,  'RegulationReportID',        'int',      'NO'),
    (2,  'DateID',                    'int',      'NO'),
    (3,  'ReportDate',                'date',     'NO'),
    (4,  'CID',                       'int',      'NO'),
    (5,  'RegulationID',              'int',      'NO'),
    (6,  'PositionID',                'bigint',   'NO'),
    (7,  'InstrumentID',              'int',      'NO'),
    (8,  'OpenORClose',               'string',   'NO'),
    (9,  'BuyORSell',                 'int',      'NO'),
    (15, 'TransactionReferenceNumber','string',   'NO'),
    (48, 'TradingDateTime',           'string',   'NO'),
    (51, 'Quantity',                  'string',   'NO'),
    (55, 'Price',                     'string',   'NO'),
    (56, 'PriceCurrency',             'string',   'NO'),
    (100,'RegChange',                 'int',      'NO')
  AS t(expected_ordinal, column_name, expected_data_type, expected_is_nullable)
),
actual_columns AS (
  SELECT
    ordinal_position,
    column_name,
    lower(data_type) AS data_type,
    upper(is_nullable) AS is_nullable
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_etoro_report'
)
SELECT
  e.expected_ordinal,
  e.column_name AS expected_column_name,
  a.ordinal_position AS actual_ordinal,
  a.column_name AS actual_column_name,
  e.expected_data_type,
  a.data_type AS actual_data_type,
  e.expected_is_nullable,
  a.is_nullable AS actual_is_nullable,
  CASE
    WHEN a.column_name IS NULL THEN 'missing_required_column'
    WHEN a.ordinal_position <> e.expected_ordinal THEN 'ordinal_mismatch'
    WHEN a.data_type <> e.expected_data_type THEN 'datatype_mismatch'
    WHEN a.is_nullable <> e.expected_is_nullable THEN 'nullability_mismatch'
    ELSE 'ok'
  END AS required_column_status
FROM expected_required_columns e
LEFT JOIN actual_columns a
  ON lower(a.column_name) = lower(e.column_name)
ORDER BY e.expected_ordinal;

-- -----------------------------------------------------------------------------
-- 2) Row-count checks
-- - by ReportDate
-- - by RegulationReportID
-- - by RegulationID
-- - by OpenORClose
-- - by RegChange
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'BY_REPORTDATE' AS metric_name,
  CAST(ReportDate AS STRING) AS metric_key_1,
  CAST(NULL AS STRING) AS metric_key_2,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate
UNION ALL
SELECT
  'BY_REGULATIONREPORTID',
  CAST(RegulationReportID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY RegulationReportID
UNION ALL
SELECT
  'BY_REGULATIONID',
  CAST(RegulationID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY RegulationID
UNION ALL
SELECT
  'BY_OPENORCLOSE',
  CAST(OpenORClose AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY OpenORClose
UNION ALL
SELECT
  'BY_REGCHANGE',
  CAST(RegChange AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY RegChange
ORDER BY metric_name, metric_key_1;

-- -----------------------------------------------------------------------------
-- 3) Duplicate checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

-- Optional duplicate lens aligned to position lifecycle.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  PositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, PositionID, OpenORClose
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 4) Required-null checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenORClose IS NULL OR length(trim(OpenORClose)) = 0 THEN 1 ELSE 0 END) AS null_openorclose_count,
  SUM(CASE WHEN BuyORSell IS NULL THEN 1 ELSE 0 END) AS null_buyorsell_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transactionreference_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count,
  SUM(CASE WHEN PriceCurrency IS NULL OR length(trim(PriceCurrency)) = 0 THEN 1 ELSE 0 END) AS null_pricecurrency_count,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_regchange_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 5) ASIC2 source-to-output reconciliation
-- - source/output counts by ReportDate
-- - anti-join checks
-- - key reconciliation by PositionID/OpenORClose/DateID/ReportDate
-- - RegChange count comparison
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_rows AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_rows AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
source_key_counts AS (
  SELECT
    DateID, ReportDate, PositionID, OpenORClose,
    COUNT(*) AS source_key_count
  FROM source_rows
  GROUP BY DateID, ReportDate, PositionID, OpenORClose
),
output_key_counts AS (
  SELECT
    DateID, ReportDate, PositionID, OpenORClose,
    COUNT(*) AS output_key_count
  FROM output_rows
  GROUP BY DateID, ReportDate, PositionID, OpenORClose
),
source_missing_in_output AS (
  SELECT s.*
  FROM source_key_counts s
  LEFT JOIN output_key_counts o
    ON o.DateID = s.DateID
   AND o.ReportDate = s.ReportDate
   AND o.PositionID = s.PositionID
   AND o.OpenORClose = s.OpenORClose
  WHERE o.PositionID IS NULL
),
output_missing_in_source AS (
  SELECT o.*
  FROM output_key_counts o
  LEFT JOIN source_key_counts s
    ON s.DateID = o.DateID
   AND s.ReportDate = o.ReportDate
   AND s.PositionID = o.PositionID
   AND s.OpenORClose = o.OpenORClose
  WHERE s.PositionID IS NULL
)
SELECT 'source_rows' AS metric_name, COUNT(*) AS metric_value
FROM source_rows
UNION ALL
SELECT 'output_rows', COUNT(*)
FROM output_rows
UNION ALL
SELECT 'source_distinct_keys', COUNT(*)
FROM source_key_counts
UNION ALL
SELECT 'output_distinct_keys', COUNT(*)
FROM output_key_counts
UNION ALL
SELECT 'source_keys_missing_in_output', COUNT(*)
FROM source_missing_in_output
UNION ALL
SELECT 'output_keys_missing_in_source', COUNT(*)
FROM output_missing_in_source;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_regchange AS (
  SELECT CAST(RegChange AS INT) AS RegChange, COUNT(*) AS source_count
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(RegChange AS INT)
),
output_regchange AS (
  SELECT CAST(RegChange AS INT) AS RegChange, COUNT(*) AS output_count
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(RegChange AS INT)
)
SELECT
  COALESCE(CAST(s.RegChange AS STRING), CAST(o.RegChange AS STRING)) AS RegChange,
  COALESCE(s.source_count, 0) AS source_count,
  COALESCE(o.output_count, 0) AS output_count,
  COALESCE(o.output_count, 0) - COALESCE(s.source_count, 0) AS count_delta
FROM source_regchange s
FULL OUTER JOIN output_regchange o
  ON s.RegChange = o.RegChange
ORDER BY RegChange;

-- -----------------------------------------------------------------------------
-- 6) OpenTime / TradingDateTime validation
-- - source OpenTime parseability
-- - TradingDateTime format
-- - formatted source-vs-output comparison
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS source_rows,
  SUM(CASE WHEN OpenTime IS NULL THEN 1 ELSE 0 END) AS source_null_opentime_count,
  SUM(CASE WHEN OpenTime IS NOT NULL AND TRY_CAST(OpenTime AS TIMESTAMP) IS NULL THEN 1 ELSE 0 END) AS source_unparseable_opentime_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS output_rows,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_or_blank_tradingdatetime_count,
  SUM(CASE WHEN TradingDateTime IS NOT NULL AND NOT (TradingDateTime RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$') THEN 1 ELSE 0 END) AS invalid_tradingdatetime_format_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    date_format(TRY_CAST(OpenTime AS TIMESTAMP), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS expected_tradingdatetime,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(CID AS INT) AS CID,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(TradingDateTime AS STRING) AS actual_tradingdatetime,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS compared_rows,
  SUM(CASE WHEN s.expected_tradingdatetime IS NULL THEN 1 ELSE 0 END) AS source_expected_tradingdatetime_null_count,
  SUM(CASE WHEN o.actual_tradingdatetime IS NULL OR length(trim(o.actual_tradingdatetime)) = 0 THEN 1 ELSE 0 END) AS output_tradingdatetime_null_count,
  SUM(
    CASE
      WHEN s.expected_tradingdatetime IS NOT NULL
       AND o.actual_tradingdatetime IS NOT NULL
       AND s.expected_tradingdatetime <> o.actual_tradingdatetime
      THEN 1 ELSE 0
    END
  ) AS source_output_tradingdatetime_mismatch_count
FROM source_ranked s
JOIN output_ranked o
  ON o.DateID = s.DateID
 AND o.ReportDate = s.ReportDate
 AND o.PositionID = s.PositionID
 AND o.OpenORClose = s.OpenORClose
 AND o.rn = s.rn;

-- OPTIONAL - semantic timezone checks remain gated unless timezone semantics
-- are explicitly approved for ETORO source windows.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'GATED_TIMEZONE_VALIDATION' AS status,
  'Run only after timezone semantic contract is approved for CDE_Execution_timestamp/OpenTime.' AS note;
*/

-- -----------------------------------------------------------------------------
-- 7) Quantity / Volume parity
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    COUNT(*) AS source_rows,
    SUM(TRY_CAST(Volume AS DOUBLE)) AS source_volume_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(ReportDate AS DATE), CAST(OpenORClose AS STRING), CAST(RegChange AS INT)
),
output_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    COUNT(*) AS output_rows,
    SUM(TRY_CAST(Quantity AS DOUBLE)) AS output_quantity_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(ReportDate AS DATE), CAST(OpenORClose AS STRING), CAST(RegChange AS INT)
)
SELECT
  COALESCE(s.ReportDate, o.ReportDate) AS ReportDate,
  COALESCE(s.OpenORClose, o.OpenORClose) AS OpenORClose,
  COALESCE(s.RegChange, o.RegChange) AS RegChange,
  COALESCE(s.source_rows, 0) AS source_rows,
  COALESCE(o.output_rows, 0) AS output_rows,
  COALESCE(s.source_volume_sum, 0.0) AS source_volume_sum,
  COALESCE(o.output_quantity_sum, 0.0) AS output_quantity_sum,
  COALESCE(o.output_quantity_sum, 0.0) - COALESCE(s.source_volume_sum, 0.0) AS quantity_delta
FROM source_agg s
FULL OUTER JOIN output_agg o
  ON s.ReportDate = o.ReportDate
 AND s.OpenORClose = o.OpenORClose
 AND s.RegChange = o.RegChange
ORDER BY ReportDate, OpenORClose, RegChange;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    TRY_CAST(Volume AS DOUBLE) AS source_volume,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    TRY_CAST(Quantity AS DOUBLE) AS output_quantity,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
row_mismatches AS (
  SELECT
    s.DateID,
    s.ReportDate,
    s.PositionID,
    s.OpenORClose,
    s.source_volume,
    o.output_quantity
  FROM source_ranked s
  JOIN output_ranked o
    ON o.DateID = s.DateID
   AND o.ReportDate = s.ReportDate
   AND o.PositionID = s.PositionID
   AND o.OpenORClose = s.OpenORClose
   AND o.rn = s.rn
  WHERE
    (s.source_volume IS NULL AND o.output_quantity IS NOT NULL)
    OR (s.source_volume IS NOT NULL AND o.output_quantity IS NULL)
    OR (s.source_volume IS NOT NULL AND o.output_quantity IS NOT NULL AND ABS(s.source_volume - o.output_quantity) > 0.00000001)
)
SELECT COUNT(*) AS row_level_quantity_mismatch_count
FROM row_mismatches;

-- -----------------------------------------------------------------------------
-- 8) OpenPrice / Price parity
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    COUNT(*) AS source_rows,
    SUM(TRY_CAST(OpenPrice AS DOUBLE)) AS source_openprice_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(ReportDate AS DATE), CAST(OpenORClose AS STRING), CAST(RegChange AS INT)
),
output_agg AS (
  SELECT
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    COUNT(*) AS output_rows,
    SUM(TRY_CAST(Price AS DOUBLE)) AS output_price_sum
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  GROUP BY CAST(ReportDate AS DATE), CAST(OpenORClose AS STRING), CAST(RegChange AS INT)
)
SELECT
  COALESCE(s.ReportDate, o.ReportDate) AS ReportDate,
  COALESCE(s.OpenORClose, o.OpenORClose) AS OpenORClose,
  COALESCE(s.RegChange, o.RegChange) AS RegChange,
  COALESCE(s.source_rows, 0) AS source_rows,
  COALESCE(o.output_rows, 0) AS output_rows,
  COALESCE(s.source_openprice_sum, 0.0) AS source_openprice_sum,
  COALESCE(o.output_price_sum, 0.0) AS output_price_sum,
  COALESCE(o.output_price_sum, 0.0) - COALESCE(s.source_openprice_sum, 0.0) AS price_delta
FROM source_agg s
FULL OUTER JOIN output_agg o
  ON s.ReportDate = o.ReportDate
 AND s.OpenORClose = o.OpenORClose
 AND s.RegChange = o.RegChange
ORDER BY ReportDate, OpenORClose, RegChange;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    TRY_CAST(OpenPrice AS DOUBLE) AS source_openprice,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_ranked AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    TRY_CAST(Price AS DOUBLE) AS output_price,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(DateID AS INT), CAST(ReportDate AS DATE), CAST(PositionID AS BIGINT), CAST(OpenORClose AS STRING)
      ORDER BY CAST(CID AS INT), CAST(InstrumentID AS INT), CAST(RegChange AS INT)
    ) AS rn
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
row_mismatches AS (
  SELECT
    s.DateID,
    s.ReportDate,
    s.PositionID,
    s.OpenORClose,
    s.source_openprice,
    o.output_price
  FROM source_ranked s
  JOIN output_ranked o
    ON o.DateID = s.DateID
   AND o.ReportDate = s.ReportDate
   AND o.PositionID = s.PositionID
   AND o.OpenORClose = s.OpenORClose
   AND o.rn = s.rn
  WHERE
    (s.source_openprice IS NULL AND o.output_price IS NOT NULL)
    OR (s.source_openprice IS NOT NULL AND o.output_price IS NULL)
    OR (s.source_openprice IS NOT NULL AND o.output_price IS NOT NULL AND ABS(s.source_openprice - o.output_price) > 0.00000001)
)
SELECT COUNT(*) AS row_level_price_mismatch_count
FROM row_mismatches;

-- OPTIONAL - conditional StaticPosition fallback impact checks.
-- Run only if profiling proves fallback logic changes OpenPrice in ETORO windows.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'GATED_STATICPOSITION_FALLBACK_CHECK' AS status,
  'Run only after fallback-impact source {{staticposition_fallback_source}} is confirmed.' AS note;
*/

-- -----------------------------------------------------------------------------
-- 9) Instrument / dictionary / classification / AssetClass coverage
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_instruments AS (
  SELECT DISTINCT CAST(InstrumentID AS INT) AS InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
full_description_latest AS (
  SELECT
    fd.InstrumentID,
    fd.IndexNameFullDescription
  FROM main.regtech.gold_regtech_reg_instruments_full_description fd
  JOIN (
    SELECT MAX(ReportDate) AS max_report_date
    FROM main.regtech.gold_regtech_reg_instruments_full_description
  ) mx
    ON fd.ReportDate = mx.max_report_date
),
instrument_dim AS (
  SELECT
    oi.InstrumentID,
    scd.InstrumentID AS scd_instrumentid,
    fd.InstrumentID AS fd_instrumentid,
    conv.InstrumentID AS conv_instrumentid,
    dc_sell.CurrencyID AS sell_currency_found,
    dc_buy.CurrencyID AS buy_currency_found,
    ctp.CurrencyTypeID AS currency_type_found
  FROM output_instruments oi
  LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
    ON scd.InstrumentID = oi.InstrumentID
   AND (SELECT report_date FROM run_parameters) >= scd.ValidFrom
   AND (SELECT report_date FROM run_parameters) < scd.ValidTo
  LEFT JOIN full_description_latest fd
    ON fd.InstrumentID = oi.InstrumentID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion conv
    ON conv.InstrumentID = oi.InstrumentID
   AND conv.ReportDate = (SELECT report_date FROM run_parameters)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON scd.BuyCurrencyID = dc_buy.CurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON scd.SellCurrencyID = dc_sell.CurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype ctp
    ON scd.InstrumentTypeID = ctp.CurrencyTypeID
)
SELECT
  COUNT(*) AS output_distinct_instruments,
  SUM(CASE WHEN scd_instrumentid IS NULL THEN 1 ELSE 0 END) AS missing_scd_count,
  SUM(CASE WHEN fd_instrumentid IS NULL THEN 1 ELSE 0 END) AS missing_full_description_count,
  SUM(CASE WHEN conv_instrumentid IS NULL THEN 1 ELSE 0 END) AS missing_specialchar_conversion_count,
  SUM(CASE WHEN scd_instrumentid IS NOT NULL AND sell_currency_found IS NULL THEN 1 ELSE 0 END) AS missing_sell_dictionary_currency_count,
  SUM(CASE WHEN scd_instrumentid IS NOT NULL AND buy_currency_found IS NULL THEN 1 ELSE 0 END) AS missing_buy_dictionary_currency_count,
  SUM(CASE WHEN scd_instrumentid IS NOT NULL AND currency_type_found IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_currency_type_count
FROM instrument_dim;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS output_rows,
  SUM(CASE WHEN AssetClass IS NULL OR length(trim(AssetClass)) = 0 THEN 1 ELSE 0 END) AS missing_assetclass_count,
  SUM(CASE WHEN PriceCurrency IS NULL OR length(trim(PriceCurrency)) = 0 THEN 1 ELSE 0 END) AS missing_pricecurrency_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- InstrumentClassification remains hard-gated unless exact mapping is ported.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS output_rows,
  SUM(CASE WHEN InstrumentClassification IS NULL OR length(trim(InstrumentClassification)) = 0 THEN 1 ELSE 0 END) AS null_or_blank_instrumentclassification_count,
  SUM(CASE WHEN InstrumentClassification IS NOT NULL AND length(trim(InstrumentClassification)) > 0 THEN 1 ELSE 0 END) AS populated_instrumentclassification_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- OPTIONAL - exact InstrumentClassification parity source check.
-- Run only after expected source is confirmed/materialized.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
expected_classification AS (
  -- Required logical columns: DateID, ReportDate, PositionID, OpenORClose, ExpectedInstrumentClassification
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(ExpectedInstrumentClassification AS STRING) AS ExpectedInstrumentClassification
  FROM {{instrumentclassification_expected_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_rows AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(InstrumentClassification AS STRING) AS InstrumentClassification
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS compared_rows,
  SUM(
    CASE
      WHEN COALESCE(o.InstrumentClassification, '') <> COALESCE(e.ExpectedInstrumentClassification, '')
      THEN 1 ELSE 0
    END
  ) AS instrumentclassification_mismatch_count
FROM output_rows o
JOIN expected_classification e
  ON o.DateID = e.DateID
 AND o.ReportDate = e.ReportDate
 AND o.PositionID = e.PositionID
 AND o.OpenORClose = e.OpenORClose;
*/

-- -----------------------------------------------------------------------------
-- 10) Exclusion checks
-- Important semantics:
-- table_name = '[MIFID2_ETORO_Report]' is report-scoped row exclusion.
-- It is not an instruction to empty the whole ETORO output table.
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_cid_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids e
  ON CAST(o.CID AS STRING) = CAST(e.cid AS STRING)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_instrument_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  ON CAST(o.InstrumentID AS STRING) = CAST(e.instrument_id AS STRING)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_ETORO_Report]';

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_position_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids e
  ON CAST(o.PositionID AS STRING) = CAST(e.position_id AS STRING)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_ETORO_Report]';

-- -----------------------------------------------------------------------------
-- 11) History / seed checks
-- -----------------------------------------------------------------------------
-- Source and output coverage window summary for ETORO parity requests.
SELECT
  MIN(ReportDate) AS source_min_reportdate,
  MAX(ReportDate) AS source_max_reportdate,
  COUNT(DISTINCT ReportDate) AS source_distinct_reportdates
FROM main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions;

SELECT
  MIN(ReportDate) AS output_min_reportdate,
  MAX(ReportDate) AS output_max_reportdate,
  COUNT(DISTINCT ReportDate) AS output_distinct_reportdates
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report;

-- Optional SQL Server baseline reconciliation (placeholder-gated).
-- Do not invent baseline history; run only when a normalized baseline source is provided.
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
sqlserver_baseline AS (
  -- Required logical columns:
  -- DateID, ReportDate, PositionID, OpenORClose, RegChange, Quantity, Price, TradingDateTime
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    TRY_CAST(Quantity AS DOUBLE) AS QuantityAsDouble,
    TRY_CAST(Price AS DOUBLE) AS PriceAsDouble,
    CAST(TradingDateTime AS STRING) AS TradingDateTime
  FROM {{sqlserver_mifid2_etoro_baseline_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
databricks_output AS (
  SELECT
    CAST(DateID AS INT) AS DateID,
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(PositionID AS BIGINT) AS PositionID,
    CAST(OpenORClose AS STRING) AS OpenORClose,
    CAST(RegChange AS INT) AS RegChange,
    TRY_CAST(Quantity AS DOUBLE) AS QuantityAsDouble,
    TRY_CAST(Price AS DOUBLE) AS PriceAsDouble,
    CAST(TradingDateTime AS STRING) AS TradingDateTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
baseline_missing_in_output AS (
  SELECT b.*
  FROM sqlserver_baseline b
  LEFT JOIN databricks_output d
    ON d.DateID = b.DateID
   AND d.ReportDate = b.ReportDate
   AND d.PositionID = b.PositionID
   AND d.OpenORClose = b.OpenORClose
   AND d.RegChange = b.RegChange
  WHERE d.PositionID IS NULL
),
output_missing_in_baseline AS (
  SELECT d.*
  FROM databricks_output d
  LEFT JOIN sqlserver_baseline b
    ON b.DateID = d.DateID
   AND b.ReportDate = d.ReportDate
   AND b.PositionID = d.PositionID
   AND b.OpenORClose = d.OpenORClose
   AND b.RegChange = d.RegChange
  WHERE b.PositionID IS NULL
)
SELECT 'baseline_missing_in_output' AS reconciliation_type, COUNT(*) AS mismatch_rows
FROM baseline_missing_in_output
UNION ALL
SELECT 'output_missing_in_baseline', COUNT(*)
FROM output_missing_in_baseline;
*/
