-- Step 14B2: MIFID2_Hedge_Report source-preparation validation templates (SELECT-only).
--
-- Scope:
-- - Validate source-preparation logic for EU / EU-UK / UK branch candidate sets.
-- - Validate source contracts, filters, enrichment coverage, and exclusion-source semantics.
--
-- Rules:
-- - SELECT-only validation SQL.
-- - No CREATE / INSERT / UPDATE / DELETE / MERGE / DROP statements.
-- - No assumptions that optional checkpoint tables exist.
-- - Mark checkpoint-dependent checks as OPTIONAL / gated.

-- -----------------------------------------------------------------------------
-- 0) Run parameters and validation gates
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
validation_gates AS (
  SELECT *
  FROM VALUES
    ('step14b2_source_activation', 'pending', 'Source profiling/access gates for Step 7/Step 9 hedge staging must pass.'),
    ('step14b2_transaction_reference_parity', 'pending', 'Final TransactionReferenceNumber parity remains deferred to Step 14B3.'),
    ('step14b2_recordid_strategy', 'pending', 'RecordID strategy remains unresolved and out of scope in Step 14B2.'),
    ('step14b2_optional_checkpoints', 'pending', 'Checkpoint-dependent validations are optional/gated unless materialized explicitly.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  rp.start_ts,
  rp.end_ts,
  vg.gate_name,
  vg.gate_status,
  vg.gate_reason
FROM run_parameters rp
CROSS JOIN validation_gates vg
ORDER BY vg.gate_name;

-- -----------------------------------------------------------------------------
-- 1) Source row counts: EU / EU-UK / UK
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
eu_base AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.Units AS DECIMAL(38, 12)) AS Units,
    CAST(ext.Success AS INT) AS Success,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
),
eu_with_lp AS (
  SELECT
    e.*,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity,
    CASE
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'REAL' THEN 1
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'CFD' THEN 0
      ELSE -1
    END AS IsReal
  FROM eu_base e
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
),
instrument_flags AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsMifid AS INT) AS IsMifid,
    CAST(COALESCE(IsMifidByFCA, IsMifid) AS INT) AS IsMifidByFCA,
    CAST(Tradable AS INT) AS Tradable,
    CAST(ValidFrom AS TIMESTAMP) AS ValidFrom,
    CAST(ValidTo AS TIMESTAMP) AS ValidTo
  FROM main.regtech.gold_regtech_reg_instruments_scd
),
eu_source_rows AS (
  SELECT COUNT(*) AS row_count
  FROM eu_with_lp e
  JOIN instrument_flags m
    ON m.InstrumentID = e.InstrumentID
   AND m.IsMifid = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE UPPER(e.eToroEntity) = '213800GIFQMSV7HROS23'
),
eu_uk_source_rows AS (
  SELECT COUNT(*) AS row_count
  FROM eu_with_lp e
  JOIN instrument_flags m
    ON m.InstrumentID = e.InstrumentID
   AND m.IsMifid = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE UPPER(e.eToroEntity) = '213800FLAB1OVA8OHT72'
    AND e.IsReal = 1
),
uk_source_rows AS (
  SELECT COUNT(*) AS row_count
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog ext
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON CAST(ext.LiquidityAccountID AS INT) = CAST(lp.LiquidityAccountID AS INT)
  JOIN instrument_flags m
    ON CAST(ext.InstrumentID AS INT) = m.InstrumentID
   AND m.IsMifidByFCA = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
    AND ext.EMSOrderID IS NULL
    AND UPPER(CAST(lp.eToroEntity AS STRING)) = '213800FLAB1OVA8OHT72'
)
SELECT 'EU source rows' AS source_name, row_count FROM eu_source_rows
UNION ALL
SELECT 'EU-UK source rows', row_count FROM eu_uk_source_rows
UNION ALL
SELECT 'UK source rows', row_count FROM uk_source_rows;

-- -----------------------------------------------------------------------------
-- 2) Source date-window validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
)
SELECT
  'EU_EXT' AS source_name,
  COUNT(*) AS checked_rows,
  SUM(CASE WHEN CAST(ExecutionTime AS TIMESTAMP) < (SELECT start_ts FROM run_parameters) THEN 1 ELSE 0 END) AS rows_before_window,
  SUM(CASE WHEN CAST(ExecutionTime AS TIMESTAMP) >= (SELECT end_ts FROM run_parameters) THEN 1 ELSE 0 END) AS rows_after_window
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
WHERE CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters) - INTERVAL 1 DAY
  AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters) + INTERVAL 1 DAY
UNION ALL
SELECT
  'UK_EXT',
  COUNT(*),
  SUM(CASE WHEN CAST(ExecutionTime AS TIMESTAMP) < (SELECT start_ts FROM run_parameters) THEN 1 ELSE 0 END),
  SUM(CASE WHEN CAST(ExecutionTime AS TIMESTAMP) >= (SELECT end_ts FROM run_parameters) THEN 1 ELSE 0 END)
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
WHERE CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters) - INTERVAL 1 DAY
  AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters) + INTERVAL 1 DAY;

-- -----------------------------------------------------------------------------
-- 3) Source filter validation
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
)
SELECT
  'EU_EXT_FILTERS' AS filter_group,
  COUNT(*) AS candidate_rows,
  SUM(CASE WHEN CAST(Units AS DECIMAL(38, 12)) <= 0 THEN 1 ELSE 0 END) AS fail_units_gt_zero,
  SUM(CASE WHEN CAST(Success AS INT) <> 1 THEN 1 ELSE 0 END) AS fail_success_eq_one
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
WHERE CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
  AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
UNION ALL
SELECT
  'UK_EXT_FILTERS',
  COUNT(*),
  SUM(CASE WHEN CAST(Units AS DECIMAL(38, 12)) <= 0 THEN 1 ELSE 0 END),
  SUM(CASE WHEN CAST(Success AS INT) <> 1 THEN 1 ELSE 0 END)
FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
WHERE CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
  AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters);

WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
uk_candidates AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity,
    CAST(COALESCE(m.IsMifidByFCA, m.IsMifid) AS INT) AS IsMifidByFCA
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog ext
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON CAST(ext.LiquidityAccountID AS INT) = CAST(lp.LiquidityAccountID AS INT)
  JOIN main.regtech.gold_regtech_reg_instruments_scd m
    ON CAST(ext.InstrumentID AS INT) = CAST(m.InstrumentID AS INT)
   AND CAST(m.Tradable AS INT) = 1
   AND (SELECT start_ts FROM run_parameters) >= CAST(m.ValidFrom AS TIMESTAMP)
   AND (SELECT start_ts FROM run_parameters) < CAST(m.ValidTo AS TIMESTAMP)
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
)
SELECT
  COUNT(*) AS uk_candidate_rows,
  SUM(CASE WHEN EMSOrderID IS NOT NULL THEN 1 ELSE 0 END) AS fail_uk_emsorderid_is_null,
  SUM(CASE WHEN UPPER(eToroEntity) <> '213800FLAB1OVA8OHT72' THEN 1 ELSE 0 END) AS fail_uk_entity_filter,
  SUM(CASE WHEN IsMifidByFCA <> 1 THEN 1 ELSE 0 END) AS fail_uk_ismifidbyfca_filter
FROM uk_candidates;

WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
eu_candidates AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity,
    CASE
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'REAL' THEN 1
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'CFD' THEN 0
      ELSE -1
    END AS IsReal
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog ext
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON CAST(ext.LiquidityAccountID AS INT) = CAST(lp.LiquidityAccountID AS INT)
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
)
SELECT
  COUNT(*) AS eu_candidate_rows,
  SUM(CASE WHEN UPPER(eToroEntity) = '213800GIFQMSV7HROS23' THEN 1 ELSE 0 END) AS eu_executionflow_rows,
  SUM(CASE WHEN UPPER(eToroEntity) = '213800FLAB1OVA8OHT72' AND IsReal = 1 THEN 1 ELSE 0 END) AS eu_uk_executionflow_isreal_rows
FROM eu_candidates;

-- -----------------------------------------------------------------------------
-- 4) Required-column checks for source contracts
-- -----------------------------------------------------------------------------
WITH expected_required_columns AS (
  SELECT *
  FROM VALUES
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'OrderID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'HedgeServerID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'LiquidityAccountID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'InstrumentID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'IsBuy'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'Units'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'ExecutionRate'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'ProviderExecID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'ExecutionTime'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'Success'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_hedgeexecutionlog', 'EMSOrderID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'OrderID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'HedgeServerID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'LiquidityAccountID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'InstrumentID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'IsBuy'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'Units'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'ExecutionRate'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'ProviderExecID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'ExecutionTime'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'Success'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgeexecutionlog', 'EMSOrderID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'LiquidityAccountID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'LiquidityAccountName'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'LEI'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'LpCountryCode'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'eToroEntity'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_liquidityaccountid', 'RealOrCFD'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_scd', 'LiquidityAccountID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_scd', 'ValidFrom'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_scd', 'ValidTo'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_hedgehbcorderlog', 'HedgeID'),
    ('main', 'general', 'gold_ednf_coretrades', 'ContractDesc'),
    ('main', 'general', 'gold_ednf_coretrades', 'ContractLongName'),
    ('main', 'general', 'gold_ednf_coretrades', 'IB_UnderlyingSymbol'),
    ('main', 'general', 'gold_ib_u1059976_open_positions_all', 'IB_UnderlyingSymbol'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ednf_to_instrumentid', 'instrument_id'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ednf_to_instrumentid', 'contract_desc'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ednf_to_instrumentid', 'contract_long_name'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_vw_ednf_to_instrumentid', 'ib_underlying_symbol'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'InstrumentID'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'InstrumentTypeID'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'BuyCurrencyID'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'SellCurrencyID'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'ISINCode'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'IsMifid'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'IsMifidByFCA'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'Tradable'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'ValidFrom'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_scd', 'ValidTo'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_full_description', 'InstrumentID'),
    ('main', 'regtech', 'gold_regtech_reg_instruments_full_description', 'IndexNameFullDescription'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_instrumentmetadata_specialchar_conversion', 'InstrumentID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_instrumentmetadata_specialchar_conversion', 'ReportDate'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrency', 'CurrencyID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrency', 'Abbreviation'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrencytype', 'CurrencyTypeID'),
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_reg_ext_dictionarycurrencytype', 'Name')
  AS t(table_catalog, table_schema, table_name, column_name)
),
actual_columns AS (
  SELECT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name,
    lower(column_name) AS column_name
  FROM system.information_schema.columns
)
SELECT
  e.table_catalog,
  e.table_schema,
  e.table_name,
  e.column_name,
  CASE
    WHEN a.column_name IS NULL THEN 'missing_required_column'
    ELSE 'ok'
  END AS required_column_status
FROM expected_required_columns e
LEFT JOIN actual_columns a
  ON a.table_catalog = lower(e.table_catalog)
 AND a.table_schema = lower(e.table_schema)
 AND a.table_name = lower(e.table_name)
 AND a.column_name = lower(e.column_name)
ORDER BY e.table_catalog, e.table_schema, e.table_name, e.column_name;

-- Raw EDNF mapping static source exists check (column contract remains gated to compatibility view).
WITH expected_objects AS (
  SELECT *
  FROM VALUES
    ('main', 'regtech_ops_stg', 'bi_output_regtechops_ed_f_to_istrument_id_e_toro')
  AS t(table_catalog, table_schema, table_name)
),
actual_objects AS (
  SELECT DISTINCT
    lower(table_catalog) AS table_catalog,
    lower(table_schema) AS table_schema,
    lower(table_name) AS table_name
  FROM system.information_schema.columns
)
SELECT
  e.table_catalog,
  e.table_schema,
  e.table_name,
  CASE
    WHEN a.table_name IS NULL THEN 'missing_object'
    ELSE 'ok'
  END AS object_status
FROM expected_objects e
LEFT JOIN actual_objects a
  ON a.table_catalog = lower(e.table_catalog)
 AND a.table_schema = lower(e.table_schema)
 AND a.table_name = lower(e.table_name);

-- -----------------------------------------------------------------------------
-- 5) Liquidity / LEI / SCD coverage checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
execution_union AS (
  SELECT CAST(LiquidityAccountID AS INT) AS LiquidityAccountID, CAST(ExecutionTime AS TIMESTAMP) AS ExecutionTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
  UNION ALL
  SELECT CAST(LiquidityAccountID AS INT), CAST(ExecutionTime AS TIMESTAMP)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
),
liquidity_joined AS (
  SELECT
    e.LiquidityAccountID,
    e.ExecutionTime,
    lp.LiquidityAccountID AS lp_liquidityaccountid,
    lp.LEI,
    scd.LiquidityAccountID AS scd_liquidityaccountid
  FROM execution_union e
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd scd
    ON e.LiquidityAccountID = CAST(scd.LiquidityAccountID AS INT)
   AND e.ExecutionTime >= CAST(scd.ValidFrom AS TIMESTAMP)
   AND e.ExecutionTime < CAST(scd.ValidTo AS TIMESTAMP)
)
SELECT
  COUNT(*) AS source_rows,
  SUM(CASE WHEN lp_liquidityaccountid IS NULL THEN 1 ELSE 0 END) AS missing_liquidityaccountid_mapping_count,
  SUM(CASE WHEN lp_liquidityaccountid IS NOT NULL AND (LEI IS NULL OR length(trim(CAST(LEI AS STRING))) = 0) THEN 1 ELSE 0 END) AS missing_lei_count,
  SUM(CASE WHEN scd_liquidityaccountid IS NULL THEN 1 ELSE 0 END) AS missing_scd_validity_window_count
FROM liquidity_joined;

-- -----------------------------------------------------------------------------
-- 6) EDNF / IB join coverage checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
candidate_instruments AS (
  SELECT DISTINCT CAST(InstrumentID AS INT) AS InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
  UNION
  SELECT DISTINCT CAST(InstrumentID AS INT)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
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
    c.InstrumentID,
    m.contract_desc,
    m.contract_long_name,
    m.ib_underlying_symbol,
    ect.ContractDesc AS ednf_contractdesc_match,
    ect.ContractLongName AS ednf_contractlongname_match,
    ect.IB_UnderlyingSymbol AS ednf_ib_underlyingsymbol_match,
    ib.IB_UnderlyingSymbol AS ib_underlyingsymbol_match
  FROM candidate_instruments c
  LEFT JOIN ednf_mapping m
    ON m.instrument_id = c.InstrumentID
  LEFT JOIN main.general.gold_ednf_coretrades ect
    ON ect.ContractDesc = m.contract_desc
  LEFT JOIN main.general.gold_ib_u1059976_open_positions_all ib
    ON ib.IB_UnderlyingSymbol = m.ib_underlying_symbol
)
SELECT
  COUNT(*) AS candidate_instrument_count,
  SUM(CASE WHEN contract_desc IS NULL THEN 1 ELSE 0 END) AS missing_contractdesc_mapping_count,
  SUM(CASE WHEN contract_long_name IS NULL THEN 1 ELSE 0 END) AS missing_contractlongname_mapping_count,
  SUM(CASE WHEN ib_underlying_symbol IS NULL THEN 1 ELSE 0 END) AS missing_ib_underlyingsymbol_mapping_count,
  SUM(CASE WHEN contract_desc IS NOT NULL AND ednf_contractdesc_match IS NULL THEN 1 ELSE 0 END) AS missing_ednf_contractdesc_join_count,
  SUM(CASE WHEN contract_long_name IS NOT NULL AND ednf_contractlongname_match IS NULL THEN 1 ELSE 0 END) AS missing_ednf_contractlongname_join_count,
  SUM(CASE WHEN ib_underlying_symbol IS NOT NULL AND ib_underlyingsymbol_match IS NULL THEN 1 ELSE 0 END) AS missing_ib_open_positions_join_count
FROM coverage;

WITH ednf_mapping AS (
  SELECT
    CAST(instrument_id AS INT) AS instrument_id,
    CAST(contract_desc AS STRING) AS contract_desc,
    COUNT(*) AS mapping_rows
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
  GROUP BY CAST(instrument_id AS INT), CAST(contract_desc AS STRING)
)
SELECT
  instrument_id,
  contract_desc,
  mapping_rows
FROM ednf_mapping
WHERE mapping_rows > 1
ORDER BY mapping_rows DESC, instrument_id, contract_desc;

-- -----------------------------------------------------------------------------
-- 7) Instrument / dictionary enrichment coverage checks
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
candidate_instruments AS (
  SELECT DISTINCT CAST(InstrumentID AS INT) AS InstrumentID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
  UNION
  SELECT DISTINCT CAST(InstrumentID AS INT)
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog
  WHERE CAST(Units AS DECIMAL(38, 12)) > 0
    AND CAST(ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(Success AS INT) = 1
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
    c.InstrumentID,
    scd.InstrumentID AS scd_match,
    fd.InstrumentID AS full_description_match,
    conv.InstrumentID AS specialchar_match,
    dc_buy.CurrencyID AS buy_currency_match,
    dc_sell.CurrencyID AS sell_currency_match,
    dct.CurrencyTypeID AS currency_type_match
  FROM candidate_instruments c
  LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
    ON scd.InstrumentID = c.InstrumentID
   AND CAST(scd.Tradable AS INT) = 1
   AND (SELECT start_ts FROM run_parameters) >= CAST(scd.ValidFrom AS TIMESTAMP)
   AND (SELECT start_ts FROM run_parameters) < CAST(scd.ValidTo AS TIMESTAMP)
  LEFT JOIN full_description_latest fd
    ON fd.InstrumentID = c.InstrumentID
   AND fd.rn = 1
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion conv
    ON conv.InstrumentID = c.InstrumentID
   AND conv.ReportDate = CAST('{{report_date}}' AS DATE)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = scd.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = scd.SellCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype dct
    ON dct.CurrencyTypeID = scd.InstrumentTypeID
)
SELECT
  COUNT(*) AS candidate_instruments,
  SUM(CASE WHEN scd_match IS NULL THEN 1 ELSE 0 END) AS missing_instruments_scd_coverage_count,
  SUM(CASE WHEN full_description_match IS NULL THEN 1 ELSE 0 END) AS missing_full_description_coverage_count,
  SUM(CASE WHEN specialchar_match IS NULL THEN 1 ELSE 0 END) AS missing_specialchar_conversion_coverage_count,
  SUM(CASE WHEN scd_match IS NOT NULL AND buy_currency_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_buycurrency_count,
  SUM(CASE WHEN scd_match IS NOT NULL AND sell_currency_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_sellcurrency_count,
  SUM(CASE WHEN scd_match IS NOT NULL AND currency_type_match IS NULL THEN 1 ELSE 0 END) AS missing_dictionary_currencytype_count
FROM coverage;

-- -----------------------------------------------------------------------------
-- 8) Exclusion-source validation and semantics checks
-- -----------------------------------------------------------------------------
SELECT
  'instrument_exclusion_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
WHERE table_name = '[MIFID2_Hedge_Report]'
UNION ALL
SELECT
  'position_or_transaction_reference_exclusion_rows',
  COUNT(*)
FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids
WHERE table_name = '[MIFID2_Hedge_Report]';

SELECT
  'row_level_report_scope_semantics' AS semantic_rule,
  'Apply exclusions only to matching rows for table_name = [MIFID2_Hedge_Report]; do not suppress the whole report.' AS semantic_description;

-- -----------------------------------------------------------------------------
-- 9) Source-to-branch-preparation count checks (CTE-prep level)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
eu_base AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.Units AS DECIMAL(38, 12)) AS Units,
    CAST(ext.Success AS INT) AS Success,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
),
uk_base AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.Units AS DECIMAL(38, 12)) AS Units,
    CAST(ext.Success AS INT) AS Success,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
),
instrument_flags AS (
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(IsMifid AS INT) AS IsMifid,
    CAST(COALESCE(IsMifidByFCA, IsMifid) AS INT) AS IsMifidByFCA,
    CAST(Tradable AS INT) AS Tradable,
    CAST(ValidFrom AS TIMESTAMP) AS ValidFrom,
    CAST(ValidTo AS TIMESTAMP) AS ValidTo
  FROM main.regtech.gold_regtech_reg_instruments_scd
),
eu_with_lp AS (
  SELECT
    e.*,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity,
    CASE
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'REAL' THEN 1
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'CFD' THEN 0
      ELSE -1
    END AS IsReal
  FROM eu_base e
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
),
uk_with_lp AS (
  SELECT
    u.*,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity
  FROM uk_base u
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON u.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
),
prepared_eu AS (
  SELECT COUNT(*) AS cnt
  FROM eu_with_lp e
  JOIN instrument_flags m
    ON m.InstrumentID = e.InstrumentID
   AND m.IsMifid = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE UPPER(e.eToroEntity) = '213800GIFQMSV7HROS23'
),
prepared_eu_uk AS (
  SELECT COUNT(*) AS cnt
  FROM eu_with_lp e
  JOIN instrument_flags m
    ON m.InstrumentID = e.InstrumentID
   AND m.IsMifid = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE UPPER(e.eToroEntity) = '213800FLAB1OVA8OHT72'
    AND e.IsReal = 1
),
prepared_uk AS (
  SELECT COUNT(*) AS cnt
  FROM uk_with_lp u
  JOIN instrument_flags m
    ON m.InstrumentID = u.InstrumentID
   AND m.IsMifidByFCA = 1
   AND m.Tradable = 1
   AND (SELECT start_ts FROM run_parameters) >= m.ValidFrom
   AND (SELECT start_ts FROM run_parameters) < m.ValidTo
  WHERE u.EMSOrderID IS NULL
    AND UPPER(u.eToroEntity) = '213800FLAB1OVA8OHT72'
),
expected_eu AS (
  SELECT COUNT(*) AS cnt
  FROM eu_with_lp
  WHERE UPPER(eToroEntity) = '213800GIFQMSV7HROS23'
),
expected_eu_uk AS (
  SELECT COUNT(*) AS cnt
  FROM eu_with_lp
  WHERE UPPER(eToroEntity) = '213800FLAB1OVA8OHT72'
    AND IsReal = 1
),
expected_uk AS (
  SELECT COUNT(*) AS cnt
  FROM uk_with_lp
  WHERE EMSOrderID IS NULL
    AND UPPER(eToroEntity) = '213800FLAB1OVA8OHT72'
)
SELECT
  'EU expected_vs_prepared' AS metric_name,
  e.cnt AS expected_rows,
  p.cnt AS prepared_rows,
  p.cnt - e.cnt AS delta_rows
FROM expected_eu e
CROSS JOIN prepared_eu p
UNION ALL
SELECT
  'EU-UK expected_vs_prepared',
  e.cnt,
  p.cnt,
  p.cnt - e.cnt
FROM expected_eu_uk e
CROSS JOIN prepared_eu_uk p
UNION ALL
SELECT
  'UK expected_vs_prepared',
  e.cnt,
  p.cnt,
  p.cnt - e.cnt
FROM expected_uk e
CROSS JOIN prepared_uk p;

-- -----------------------------------------------------------------------------
-- 10) OPTIONAL / gated validation for optional materialized checkpoints
-- -----------------------------------------------------------------------------
/*
-- OPTIONAL - run only if optional checkpoint tables were explicitly materialized.
-- Required optional checkpoint objects (if created):
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_eu_source_prep
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_eu_uk_source_prep
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_uk_source_prep
--
-- Example checkpoint parity template:
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT
  'OPTIONAL_CHECKPOINT_EU' AS metric_name,
  COUNT(*) AS checkpoint_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_eu_source_prep
WHERE ReportDate = (SELECT report_date FROM run_parameters);
*/
