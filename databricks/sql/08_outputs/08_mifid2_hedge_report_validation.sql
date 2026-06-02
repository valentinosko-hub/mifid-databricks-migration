-- Step 14B4: MIFID2_Hedge_Report validation and reconciliation package (read-only).
--
-- Scope:
-- - Validate output and source-to-output reconciliation readiness for:
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
--
-- Rules:
-- - SELECT-only validation SQL.
-- - No CREATE / INSERT / UPDATE / DELETE / MERGE / DROP.
-- - Keep placeholder-dependent checks explicitly gated/commented.
-- - Do not add new hedge business logic in this file.

-- -----------------------------------------------------------------------------
-- 0) Run parameters, target summary, and gate checklist
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report' AS target_table
),
validation_gates AS (
  SELECT *
  FROM VALUES
    ('step7_liquidity_scd_source_profiling', 'pending', 'Step 7 liquidity/SCD source profiling remains required.'),
    ('step7_liquidity_scd_seed_cutover', 'pending', 'Liquidity SCD seed/cutover policy remains required.'),
    ('step7_lei_coverage', 'pending', 'LEI coverage completeness for report-relevant liquidity accounts remains required.'),
    ('step9_mifid2_ext_hedgeexecutionlog_activation', 'pending', 'Step 9 MIFID2_ext_HedgeExecutionLog activation remains required.'),
    ('step5b2_reg_ext_hedgeexecutionlog_activation', 'pending', 'Step 5B2 Reg_Ext_HedgeExecutionLog activation remains required.'),
    ('step5b2_reg_ext_hedgehbcorderlog_activation', 'pending', 'Step 5B2 Reg_Ext_HedgeHBCOrderLog activation remains required.'),
    ('step14_ednf_ib_mapping_coverage', 'pending', 'EDNF / IB mapping coverage remains required.'),
    ('step14_instrument_specialchar_conversion', 'pending', 'InstrumentMetaData_SpecialChar_Conversion readiness remains required.'),
    ('step14_dictionary_currency_contracts', 'pending', 'Dictionary currency/currency-type readiness remains required.'),
    ('step14_recordid_deterministic_strategy', 'pending', 'RecordID deterministic strategy approval remains required.'),
    ('step14_transaction_reference_exact_parity', 'pending', 'TransactionReferenceNumber exact parity validation remains required.'),
    ('step14_exclusion_mapping_parity', 'pending', 'Exclusion mapping parity remains required.'),
    ('step14_optional_branch_sources', 'pending', 'Optional branch-source placeholders/checkpoints remain gated until materialized.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  rp.target_table,
  vg.gate_name,
  vg.gate_status,
  vg.gate_reason
FROM run_parameters rp
CROSS JOIN validation_gates vg
ORDER BY vg.gate_name;

SELECT
  'Validation notes' AS section_name,
  'Run this package as read-only checks only. Placeholder-dependent checks are optional/gated until sources are available.' AS execution_note;

-- -----------------------------------------------------------------------------
-- 1) Schema parity checks
-- - column count
-- - schema snapshot (name/order/type/nullability/precision/scale)
-- - required-column contract checks
-- -----------------------------------------------------------------------------
WITH expected_table AS (
  SELECT
    'main' AS expected_catalog,
    'regtech_ops_stg' AS expected_schema,
    'bi_output_regtechops_mifid2_hedge_report' AS expected_table_name
),
actual_table_columns AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name,
    COUNT(*) AS actual_column_count
  FROM system.information_schema.columns
  WHERE lower(table_catalog) = 'main'
    AND lower(table_schema) = 'regtech_ops_stg'
    AND lower(table_name) = 'bi_output_regtechops_mifid2_hedge_report'
  GROUP BY lower(table_catalog), lower(table_schema), lower(table_name)
)
SELECT
  e.expected_catalog,
  e.expected_schema,
  e.expected_table_name,
  a.actual_column_count,
  CASE WHEN a.table_name IS NULL THEN 'missing_table' ELSE 'present' END AS table_presence_status
FROM expected_table e
LEFT JOIN actual_table_columns a
  ON a.table_catalog = lower(e.expected_catalog)
 AND a.table_schema = lower(e.expected_schema)
 AND a.table_name = lower(e.expected_table_name);

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
  AND lower(table_name) = 'bi_output_regtechops_mifid2_hedge_report'
ORDER BY ordinal_position;

WITH expected_required_columns AS (
  SELECT *
  FROM VALUES
    (1,  'DateID',                      'int',      'YES'),
    (2,  'ReportDate',                  'date',     'YES'),
    (3,  'HedgeServerID',               'int',      'YES'),
    (4,  'LiquidityProvider',           'string',   'YES'),
    (5,  'ExecutionID',                 'int',      'YES'),
    (6,  'InstrumentID',                'int',      'YES'),
    (7,  'BuyORSell',                   'int',      'YES'),
    (8,  'ReportStatus',                'string',   'YES'),
    (9,  'TransactionReferenceNumber',  'string',   'YES'),
    (42, 'TradingDateTime',             'string',   'YES'),
    (45, 'Quantity',                    'string',   'YES'),
    (49, 'Price',                       'string',   'YES'),
    (50, 'PriceCurrency',               'string',   'YES'),
    (90, 'RecordID',                    'int',      'YES'),
    (91, 'RegulationReportID',          'int',      'YES'),
    (92, 'AssetClass',                  'string',   'YES'),
    (93, 'LiquidityAccountID',          'int',      'YES'),
    (94, 'rowSource',                   'string',   'YES'),
    (95, 'BackReportingIndicator',      'smallint', 'YES'),
    (96, 'EMSOrderID',                  'string',   'YES')
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
    AND lower(table_name) = 'bi_output_regtechops_mifid2_hedge_report'
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
-- - by ReportDate / RegulationReportID / rowSource / LiquidityAccountID / InstrumentID
-- - branch counts (EU / EU-UK / UK)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'BY_REPORTDATE' AS metric_name,
  CAST(ReportDate AS STRING) AS metric_key_1,
  CAST(NULL AS STRING) AS metric_key_2,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate
UNION ALL
SELECT
  'BY_REGULATIONREPORTID',
  CAST(RegulationReportID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY RegulationReportID
UNION ALL
SELECT
  'BY_ROWSOURCE',
  CAST(rowSource AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY rowSource
UNION ALL
SELECT
  'BY_LIQUIDITYACCOUNTID',
  CAST(LiquidityAccountID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY LiquidityAccountID
UNION ALL
SELECT
  'BY_INSTRUMENTID',
  CAST(InstrumentID AS STRING),
  CAST(NULL AS STRING),
  COUNT(*)
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY InstrumentID
ORDER BY metric_name, metric_key_1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  rowSource,
  RegulationReportID,
  COUNT(*) AS branch_row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND rowSource IN ('EU', 'EU-UK', 'UK')
GROUP BY rowSource, RegulationReportID
ORDER BY RegulationReportID, rowSource;

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
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  RecordID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND RecordID IS NOT NULL
GROUP BY RecordID
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  ExecutionID,
  EMSOrderID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, ExecutionID, EMSOrderID
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 4) Required-null checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transactionreference_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS null_liquidityaccountid_count,
  SUM(CASE WHEN ExecutingEntityIdentificationCode IS NULL OR length(trim(ExecutingEntityIdentificationCode)) = 0 THEN 1 ELSE 0 END) AS null_executingentity_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count,
  SUM(CASE WHEN PriceCurrency IS NULL OR length(trim(PriceCurrency)) = 0 THEN 1 ELSE 0 END) AS null_pricecurrency_count,
  SUM(CASE WHEN rowSource IS NULL OR length(trim(rowSource)) = 0 THEN 1 ELSE 0 END) AS null_rowsource_count,
  SUM(CASE WHEN BackReportingIndicator IS NULL THEN 1 ELSE 0 END) AS null_backreportingindicator_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 5) Source-to-output reconciliation (gated placeholders for branch sources)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_branch_counts AS (
  SELECT
    rowSource,
    RegulationReportID,
    COUNT(*) AS output_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND rowSource IN ('EU', 'EU-UK', 'UK')
  GROUP BY rowSource, RegulationReportID
)
SELECT
  rowSource,
  RegulationReportID,
  output_rows
FROM output_branch_counts
ORDER BY RegulationReportID, rowSource;

SELECT
  'OPTIONAL_GATED_BRANCH_RECONCILIATION' AS reconciliation_status,
  'Enable only when {{hedge_eu_source}}, {{hedge_eu_uk_source}}, {{hedge_uk_source}} are materialized/validated.' AS note;

/*
-- OPTIONAL / GATED: run only when branch sources are available/materialized.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
expected_eu AS (
  SELECT COUNT(*) AS expected_rows
  FROM {{hedge_eu_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
expected_eu_uk AS (
  SELECT COUNT(*) AS expected_rows
  FROM {{hedge_eu_uk_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
expected_uk AS (
  SELECT COUNT(*) AS expected_rows
  FROM {{hedge_uk_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_eu AS (
  SELECT COUNT(*) AS output_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND RegulationReportID = 1
    AND rowSource = 'EU'
),
output_eu_uk AS (
  SELECT COUNT(*) AS output_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND RegulationReportID = 1
    AND rowSource = 'EU-UK'
),
output_uk AS (
  SELECT COUNT(*) AS output_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND RegulationReportID = 2
    AND rowSource = 'UK'
)
SELECT
  'EU' AS branch_name,
  e.expected_rows,
  o.output_rows,
  o.output_rows - e.expected_rows AS delta_rows
FROM expected_eu e CROSS JOIN output_eu o
UNION ALL
SELECT
  'EU-UK',
  e.expected_rows,
  o.output_rows,
  o.output_rows - e.expected_rows
FROM expected_eu_uk e CROSS JOIN output_eu_uk o
UNION ALL
SELECT
  'UK',
  e.expected_rows,
  o.output_rows,
  o.output_rows - e.expected_rows
FROM expected_uk e CROSS JOIN output_uk o;
*/

-- -----------------------------------------------------------------------------
-- 6) EDNF / IB join coverage checks (gated by source readiness)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_instruments AS (
  SELECT DISTINCT CAST(InstrumentID AS INT) AS InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
ednf_mapping AS (
  SELECT
    CAST(instrument_id AS INT) AS instrument_id,
    CAST(contract_desc AS STRING) AS contract_desc,
    CAST(contract_long_name AS STRING) AS contract_long_name,
    CAST(ib_underlying_symbol AS STRING) AS ib_underlying_symbol
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
),
coverage AS (
  SELECT
    oi.InstrumentID,
    m.contract_desc,
    m.contract_long_name,
    m.ib_underlying_symbol,
    ect.ContractDesc AS ednf_contractdesc_match,
    ect.ContractLongName AS ednf_contractlongname_match,
    ib.IB_UnderlyingSymbol AS ib_underlyingsymbol_match
  FROM output_instruments oi
  LEFT JOIN ednf_mapping m
    ON m.instrument_id = oi.InstrumentID
  LEFT JOIN main.general.gold_ednf_coretrades ect
    ON ect.ContractDesc = m.contract_desc
  LEFT JOIN main.general.gold_ib_u1059976_open_positions_all ib
    ON ib.IB_UnderlyingSymbol = m.ib_underlying_symbol
)
SELECT
  COUNT(*) AS output_instrument_count,
  SUM(CASE WHEN contract_desc IS NULL THEN 1 ELSE 0 END) AS missing_contractdesc_count,
  SUM(CASE WHEN contract_long_name IS NULL THEN 1 ELSE 0 END) AS missing_contractlongname_count,
  SUM(CASE WHEN ib_underlying_symbol IS NULL THEN 1 ELSE 0 END) AS missing_ib_underlyingsymbol_count,
  SUM(CASE WHEN contract_desc IS NOT NULL AND ednf_contractdesc_match IS NULL THEN 1 ELSE 0 END) AS unmatched_ednf_contractdesc_count,
  SUM(CASE WHEN contract_long_name IS NOT NULL AND ednf_contractlongname_match IS NULL THEN 1 ELSE 0 END) AS unmatched_ednf_contractlongname_count,
  SUM(CASE WHEN ib_underlying_symbol IS NOT NULL AND ib_underlyingsymbol_match IS NULL THEN 1 ELSE 0 END) AS unmatched_ib_underlyingsymbol_count
FROM coverage;

WITH ednf_mapping_dupes AS (
  SELECT
    CAST(instrument_id AS INT) AS instrument_id,
    CAST(contract_desc AS STRING) AS contract_desc,
    COUNT(*) AS duplicate_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
  GROUP BY CAST(instrument_id AS INT), CAST(contract_desc AS STRING)
)
SELECT
  instrument_id,
  contract_desc,
  duplicate_rows
FROM ednf_mapping_dupes
WHERE duplicate_rows > 1
ORDER BY duplicate_rows DESC, instrument_id;

WITH ednf_mapping AS (
  SELECT DISTINCT CAST(contract_desc AS STRING) AS contract_desc
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
)
SELECT
  COUNT(*) AS unmatched_lp_ednf_trades_count
FROM main.general.gold_ednf_coretrades ect
LEFT JOIN ednf_mapping m
  ON m.contract_desc = CAST(ect.ContractDesc AS STRING)
WHERE m.contract_desc IS NULL;

WITH ib_mapping AS (
  SELECT DISTINCT CAST(ib_underlying_symbol AS STRING) AS ib_underlying_symbol
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
)
SELECT
  COUNT(*) AS unmatched_ib_open_positions_count
FROM main.general.gold_ib_u1059976_open_positions_all ib
LEFT JOIN ib_mapping m
  ON m.ib_underlying_symbol = CAST(ib.IB_UnderlyingSymbol AS STRING)
WHERE m.ib_underlying_symbol IS NULL;

SELECT
  'OPTIONAL_GATED_EDNF_IB_DEEP_PARITY' AS parity_status,
  'Deep EDNF/IB parity checks remain gated until source profiling/access gates pass.' AS note;

-- -----------------------------------------------------------------------------
-- 7) Liquidity account / LEI / SCD validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_rows AS (
  SELECT *
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
liq_joined AS (
  SELECT
    o.RegulationReportID,
    o.rowSource,
    o.LiquidityAccountID,
    o.TradingDateTime,
    o.TransactionReferenceNumber,
    lp.LiquidityAccountID AS lp_liquidityaccountid,
    lp.LEI,
    lp.eToroEntity,
    scd.LiquidityAccountID AS scd_liquidityaccountid
  FROM output_rows o
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON o.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd scd
    ON o.LiquidityAccountID = CAST(scd.LiquidityAccountID AS INT)
   AND TRY_CAST(o.TradingDateTime AS TIMESTAMP) >= CAST(scd.ValidFrom AS TIMESTAMP)
   AND TRY_CAST(o.TradingDateTime AS TIMESTAMP) < CAST(scd.ValidTo AS TIMESTAMP)
)
SELECT
  COUNT(*) AS output_rows_checked,
  SUM(CASE WHEN LiquidityAccountID IS NULL THEN 1 ELSE 0 END) AS missing_liquidityaccountid_in_output_count,
  SUM(CASE WHEN lp_liquidityaccountid IS NULL THEN 1 ELSE 0 END) AS output_liquidityaccountid_not_covered_count,
  SUM(CASE WHEN lp_liquidityaccountid IS NOT NULL AND LEI IS NULL THEN 1 ELSE 0 END) AS missing_lei_count,
  SUM(CASE WHEN lp_liquidityaccountid IS NOT NULL AND LEI IS NOT NULL AND length(trim(CAST(LEI AS STRING))) = 0 THEN 1 ELSE 0 END) AS blank_lei_count,
  SUM(CASE WHEN scd_liquidityaccountid IS NULL THEN 1 ELSE 0 END) AS no_valid_scd_window_at_tradingtime_count,
  SUM(CASE WHEN rowSource = 'UK' AND upper(COALESCE(CAST(eToroEntity AS STRING), '')) <> '213800FLAB1OVA8OHT72' THEN 1 ELSE 0 END) AS uk_entity_coverage_fail_count
FROM liq_joined;

SELECT
  CAST(LiquidityAccountID AS INT) AS LiquidityAccountID,
  COUNT(*) AS current_rows_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
WHERE CURRENT_TIMESTAMP() >= CAST(ValidFrom AS TIMESTAMP)
  AND CURRENT_TIMESTAMP() < CAST(ValidTo AS TIMESTAMP)
GROUP BY CAST(LiquidityAccountID AS INT)
HAVING COUNT(*) > 1
ORDER BY current_rows_count DESC, LiquidityAccountID;

SELECT
  COUNT(*) AS invalid_scd_range_count
FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
WHERE CAST(ValidFrom AS TIMESTAMP) > CAST(ValidTo AS TIMESTAMP);

WITH scd_rows AS (
  SELECT
    CAST(LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ValidFrom AS TIMESTAMP) AS ValidFrom,
    CAST(ValidTo AS TIMESTAMP) AS ValidTo
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd
)
SELECT
  a.LiquidityAccountID,
  a.ValidFrom AS overlap_a_validfrom,
  a.ValidTo AS overlap_a_validto,
  b.ValidFrom AS overlap_b_validfrom,
  b.ValidTo AS overlap_b_validto
FROM scd_rows a
JOIN scd_rows b
  ON a.LiquidityAccountID = b.LiquidityAccountID
 AND a.ValidFrom < b.ValidTo
 AND b.ValidFrom < a.ValidTo
 AND (a.ValidFrom <> b.ValidFrom OR a.ValidTo <> b.ValidTo)
ORDER BY a.LiquidityAccountID, overlap_a_validfrom, overlap_b_validfrom;

-- -----------------------------------------------------------------------------
-- 8) RecordID validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_rows AS (
  SELECT *
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
recordid_stats AS (
  SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN RecordID IS NULL THEN 1 ELSE 0 END) AS null_recordid_count,
    SUM(CASE WHEN RecordID IS NOT NULL AND RecordID < 100000001 THEN 1 ELSE 0 END) AS recordid_below_floor_count
  FROM output_rows
)
SELECT *
FROM recordid_stats;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  RecordID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND RecordID IS NOT NULL
GROUP BY RecordID
HAVING COUNT(*) > 1;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
recordid_rows AS (
  SELECT
    ReportDate,
    RegulationReportID,
    rowSource,
    TransactionReferenceNumber,
    ExecutionID,
    LiquidityAccountID,
    InstrumentID,
    RecordID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
    AND RecordID IS NOT NULL
),
deterministic_expected AS (
  SELECT
    *,
    100000000 + ROW_NUMBER() OVER (
      ORDER BY
        ReportDate,
        RegulationReportID,
        rowSource,
        TransactionReferenceNumber,
        ExecutionID,
        LiquidityAccountID,
        InstrumentID
    ) AS expected_recordid
  FROM recordid_rows
)
SELECT
  COUNT(*) AS compared_rows,
  SUM(CASE WHEN RecordID <> expected_recordid THEN 1 ELSE 0 END) AS deterministic_recordid_mismatch_count
FROM deterministic_expected;

SELECT
  'RecordID gate note' AS gate_name,
  'If deterministic strategy is not approved, nullable/placeholder RecordID remains acceptable in gated templates.' AS gate_note;

-- -----------------------------------------------------------------------------
-- 9) TransactionReferenceNumber validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_or_blank_transactionreference_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber
HAVING COUNT(*) > 1;

SELECT
  'OPTIONAL_GATED_TRN_DEEP_PARITY' AS parity_status,
  'Deep TransactionReferenceNumber parity checks require materialized branch-source placeholders and exact source fields.' AS note;

/*
-- OPTIONAL / GATED: run when branch sources are available/materialized.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_union AS (
  SELECT
    CAST(ReportDate AS DATE) AS ReportDate,
    CAST(RegulationReportID AS INT) AS RegulationReportID,
    CAST(ProviderExecID_Normalized AS STRING) AS ProviderExecID_Normalized,
    CAST(RowID AS INT) AS RowID,
    CAST(LiquidityProvider AS STRING) AS LiquidityProvider,
    CAST(GeneratedTransactionReferenceNumber AS STRING) AS ExpectedTransactionReferenceNumber
  FROM {{hedge_eu_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    CAST(ReportDate AS DATE),
    CAST(RegulationReportID AS INT),
    CAST(ProviderExecID_Normalized AS STRING),
    CAST(RowID AS INT),
    CAST(LiquidityProvider AS STRING),
    CAST(GeneratedTransactionReferenceNumber AS STRING)
  FROM {{hedge_eu_uk_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
  UNION ALL
  SELECT
    CAST(ReportDate AS DATE),
    CAST(RegulationReportID AS INT),
    CAST(ProviderExecID_Normalized AS STRING),
    CAST(RowID AS INT),
    CAST(LiquidityProvider AS STRING),
    CAST(GeneratedTransactionReferenceNumber AS STRING)
  FROM {{hedge_uk_source}}
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
output_rows AS (
  SELECT
    ReportDate,
    RegulationReportID,
    TransactionReferenceNumber
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
)
SELECT
  COUNT(*) AS compared_rows,
  SUM(CASE WHEN o.TransactionReferenceNumber <> s.ExpectedTransactionReferenceNumber THEN 1 ELSE 0 END) AS transactionreference_mismatch_count,
  SUM(CASE WHEN s.ProviderExecID_Normalized IS NULL OR length(trim(s.ProviderExecID_Normalized)) = 0 THEN 1 ELSE 0 END) AS providerexecid_normalization_missing_count,
  SUM(
    CASE
      WHEN (s.ProviderExecID_Normalized IS NULL OR length(trim(s.ProviderExecID_Normalized)) = 0)
       AND (s.LiquidityProvider IS NULL OR length(trim(s.LiquidityProvider)) = 0 OR s.RowID IS NULL)
      THEN 1
      ELSE 0
    END
  ) AS fallback_source_coverage_missing_count
FROM source_union s
JOIN output_rows o
  ON o.ReportDate = s.ReportDate
 AND o.RegulationReportID = s.RegulationReportID;
*/

-- -----------------------------------------------------------------------------
-- 10) Exclusion checks (report-scoped row-level semantics)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_instrument_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  ON CAST(o.InstrumentID AS STRING) = CAST(e.instrument_id AS STRING)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_Hedge_Report]';

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS excluded_position_or_transactionreference_rows_present
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report o
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids e
  ON CAST(o.TransactionReferenceNumber AS STRING) = CAST(e.position_id AS STRING)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
  AND e.table_name = '[MIFID2_Hedge_Report]';

SELECT
  'row_level_report_scope_semantics' AS semantic_rule,
  'table_name = [MIFID2_Hedge_Report] means row-level report exclusion scope, not full-table suppression.' AS semantic_note;

-- -----------------------------------------------------------------------------
-- 11) Instrument / dictionary coverage checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
output_instruments AS (
  SELECT DISTINCT CAST(InstrumentID AS INT) AS InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
  WHERE ReportDate = (SELECT report_date FROM run_parameters)
),
full_description_latest AS (
  SELECT
    fd.InstrumentID,
    fd.IndexNameFullDescription,
    ROW_NUMBER() OVER (PARTITION BY fd.InstrumentID ORDER BY fd.ReportDate DESC) AS rn
  FROM main.regtech.gold_regtech_reg_instruments_full_description fd
),
coverage AS (
  SELECT
    oi.InstrumentID,
    scd.InstrumentID AS scd_match,
    fd.InstrumentID AS full_description_match,
    conv.InstrumentID AS specialchar_match,
    dct.CurrencyTypeID AS currency_type_match,
    dc_buy.CurrencyID AS buy_currency_match,
    dc_sell.CurrencyID AS sell_currency_match,
    CAST(COALESCE(scd.IsMifidByFCA, scd.IsMifid) AS INT) AS IsMifidByFCA,
    CAST(scd.IsMifid AS INT) AS IsMifid
  FROM output_instruments oi
  LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
    ON scd.InstrumentID = oi.InstrumentID
   AND CAST(scd.Tradable AS INT) = 1
   AND (SELECT report_date FROM run_parameters) >= CAST(scd.ValidFrom AS DATE)
   AND (SELECT report_date FROM run_parameters) < CAST(scd.ValidTo AS DATE)
  LEFT JOIN full_description_latest fd
    ON fd.InstrumentID = oi.InstrumentID
   AND fd.rn = 1
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion conv
    ON conv.InstrumentID = oi.InstrumentID
   AND conv.ReportDate = (SELECT report_date FROM run_parameters)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = scd.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = scd.SellCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype dct
    ON dct.CurrencyTypeID = scd.InstrumentTypeID
)
SELECT
  COUNT(*) AS output_distinct_instruments,
  SUM(CASE WHEN scd_match IS NULL THEN 1 ELSE 0 END) AS missing_instruments_scd_coverage_count,
  SUM(CASE WHEN full_description_match IS NULL THEN 1 ELSE 0 END) AS missing_full_description_coverage_count,
  SUM(CASE WHEN specialchar_match IS NULL THEN 1 ELSE 0 END) AS missing_specialchar_conversion_coverage_count,
  SUM(CASE WHEN currency_type_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_currencytype_coverage_count,
  SUM(CASE WHEN buy_currency_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_buycurrency_coverage_count,
  SUM(CASE WHEN sell_currency_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_sellcurrency_coverage_count
FROM coverage;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS output_rows,
  SUM(CASE WHEN AssetClass IS NULL OR length(trim(AssetClass)) = 0 THEN 1 ELSE 0 END) AS missing_assetclass_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN o.rowSource IN ('EU', 'EU-UK') AND CAST(scd.IsMifid AS INT) <> 1 THEN 1 ELSE 0 END) AS eu_branch_ismifid_coverage_fail_count,
  SUM(CASE WHEN o.rowSource = 'UK' AND CAST(COALESCE(scd.IsMifidByFCA, scd.IsMifid) AS INT) <> 1 THEN 1 ELSE 0 END) AS uk_branch_ismifidbyfca_coverage_fail_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report o
LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
  ON scd.InstrumentID = o.InstrumentID
 AND CAST(scd.Tradable AS INT) = 1
 AND o.ReportDate >= CAST(scd.ValidFrom AS DATE)
 AND o.ReportDate < CAST(scd.ValidTo AS DATE)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters);

-- -----------------------------------------------------------------------------
-- 12) Branch behavior checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  rowSource,
  RegulationReportID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY rowSource, RegulationReportID
ORDER BY RegulationReportID, rowSource;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  SUM(CASE WHEN rowSource IN ('EU', 'EU-UK') AND RegulationReportID <> 1 THEN 1 ELSE 0 END) AS eu_or_eu_uk_regulationreportid_mismatch_count,
  SUM(CASE WHEN rowSource = 'UK' AND RegulationReportID <> 2 THEN 1 ELSE 0 END) AS uk_regulationreportid_mismatch_count,
  SUM(CASE WHEN rowSource NOT IN ('EU', 'EU-UK', 'UK') THEN 1 ELSE 0 END) AS unexpected_rowsource_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters);

SELECT
  'OPTIONAL_GATED_BRANCH_SOURCE_PARITY' AS parity_status,
  'ExecutionFlow / IsReal / Success / Units source-parity checks require Step 14B2 branch-source placeholders.' AS note;

/*
-- OPTIONAL / GATED: run only when branch source placeholders are available.
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'EU' AS branch_name,
  COUNT(*) AS fail_rows
FROM {{hedge_eu_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND (ExecutionFlow <> 'EU' OR Units <= 0 OR Success <> 1)
UNION ALL
SELECT
  'EU-UK',
  COUNT(*)
FROM {{hedge_eu_uk_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND (ExecutionFlow <> 'UK' OR IsReal <> 1 OR Units <= 0 OR Success <> 1)
UNION ALL
SELECT
  'UK',
  COUNT(*)
FROM {{hedge_uk_source}}
WHERE ReportDate = (SELECT report_date FROM run_parameters)
  AND (EMSOrderID IS NOT NULL OR upper(eToroEntity) <> '213800FLAB1OVA8OHT72' OR IsMifidByFCA <> 1 OR Units <= 0 OR Success <> 1);
*/

-- -----------------------------------------------------------------------------
-- 13) Quantity / price aggregate checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  rowSource,
  COUNT(*) AS row_count,
  SUM(TRY_CAST(Quantity AS DOUBLE)) AS sum_quantity,
  AVG(TRY_CAST(Price AS DOUBLE)) AS avg_price,
  MIN(TRY_CAST(Price AS DOUBLE)) AS min_price,
  MAX(TRY_CAST(Price AS DOUBLE)) AS max_price
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, rowSource
ORDER BY RegulationReportID, rowSource;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  ReportDate,
  RegulationReportID,
  rowSource,
  InstrumentID,
  LiquidityAccountID,
  COUNT(*) AS row_count,
  SUM(TRY_CAST(Quantity AS DOUBLE)) AS sum_quantity,
  AVG(TRY_CAST(Price AS DOUBLE)) AS avg_price,
  MIN(TRY_CAST(Price AS DOUBLE)) AS min_price,
  MAX(TRY_CAST(Price AS DOUBLE)) AS max_price
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = (SELECT report_date FROM run_parameters)
GROUP BY ReportDate, RegulationReportID, rowSource, InstrumentID, LiquidityAccountID
ORDER BY RegulationReportID, rowSource, InstrumentID, LiquidityAccountID;

-- -----------------------------------------------------------------------------
-- 14) GBX validation (gated when no audit fields are materialized)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  COUNT(*) AS gbx_candidate_rows_in_output
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report o
JOIN main.regtech.gold_regtech_reg_instruments_scd scd
  ON scd.InstrumentID = o.InstrumentID
 AND CAST(scd.Tradable AS INT) = 1
 AND o.ReportDate >= CAST(scd.ValidFrom AS DATE)
 AND o.ReportDate < CAST(scd.ValidTo AS DATE)
WHERE o.ReportDate = (SELECT report_date FROM run_parameters)
  AND scd.SellCurrencyID = 666;

SELECT
  'OPTIONAL_GATED_GBX_AUDIT_PARITY' AS parity_status,
  'GBX pre/post division parity requires audit fields (e.g., RawExecutionRate, IsGBX, AdjustedExecutionRate); keep gated if audit fields are not materialized.' AS note;

