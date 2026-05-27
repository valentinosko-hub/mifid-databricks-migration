-- Step 14B2: MIFID2_Hedge_Report source preparation and branch source CTE templates.
--
-- In scope (Step 14B2):
-- - Gated source-preparation CTE templates only for:
--     EU hedge source rows
--     EU-UK hedge source rows
--     UK hedge source rows
--     EDNF / IB enrichment source
--     instrument / FIRDS / dictionary enrichment source
--     liquidity account / LEI / SCD enrichment source
--     exclusion source preparation
--
-- Out of scope (do not implement here):
-- - Final MIFID2_Hedge_Report projection output rows
-- - Final report-date DELETE / INSERT execution logic
-- - RecordID final strategy implementation
-- - Final TransactionReferenceNumber parity closure
-- - MIFID2_NPD_TRAX
-- - file delivery / export / upload / deployment logic
--
-- SQL Server authorities:
-- - SP_MIFID_HedgeEU_Report.sql
-- - SP_MIFID_HedgeUK_Report.sql
-- - MIFID2_Hedge_Report.sql
--
-- Important:
-- - This file must remain non-executable for final output population.
-- - Do not insert into main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report in Step 14B2.
-- - Keep unresolved logic hard-gated for Step 14B3.

-- -----------------------------------------------------------------------------
-- 0) Run parameters and gate checklist
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
target_object AS (
  SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report' AS target_object
),
source_prep_gates AS (
  SELECT
    'step14b2_eu_source_contract' AS gate_name,
    'pending' AS gate_status,
    'MIFID2_ext_HedgeExecutionLog source profiling must confirm all required columns and filter parity.' AS gate_reason
  UNION ALL
  SELECT
    'step14b2_uk_source_contract',
    'pending',
    'Reg_Ext_HedgeExecutionLog and Reg_Ext_HedgeHBCOrderLog source profiling must confirm required columns and joins.'
  UNION ALL
  SELECT
    'step14b2_liquidity_scd_contract',
    'pending',
    'Reg_Ext_LiquidityAccountID and Reg_LiquidtyAcount_SCD coverage by ExecutionTime window must be accepted.'
  UNION ALL
  SELECT
    'step14b2_instrument_dictionary_contract',
    'pending',
    'Instrument SCD/full-description/special-char and dictionary currency/type sources must be report-date ready.'
  UNION ALL
  SELECT
    'step14b2_ednf_ib_contract',
    'pending',
    'EDNF / IB mapping coverage must be profiled for hedge candidate instruments.'
  UNION ALL
  SELECT
    'step14b2_exclusion_scope_semantics',
    'pending',
    'table_name = [MIFID2_Hedge_Report] must remain row-level report scoping (not full-table suppression).'
  UNION ALL
  SELECT
    'step14b2_transaction_reference_parity',
    'pending',
    'ProviderExecID normalization + RowID + report date + fallback logic remains hard-gated for Step 14B3 final parity.'
  UNION ALL
  SELECT
    'step14b2_recordid_strategy',
    'pending',
    'RecordID strategy remains unresolved and must not be implemented in Step 14B2.'
)
SELECT
  rp.report_date,
  rp.start_ts,
  rp.end_ts,
  t.target_object,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_parameters rp
CROSS JOIN target_object t
CROSS JOIN source_prep_gates g
ORDER BY g.gate_name;

-- -----------------------------------------------------------------------------
-- 1) Branch source-preparation CTE templates (SELECT-only, no final output writes)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
eu_execution_base AS (
  SELECT
    'eu_ext' AS source_origin,
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.HedgeServerID AS INT) AS HedgeServerID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.IsBuy AS INT) AS IsBuy,
    CAST(ext.Units AS DECIMAL(38, 12)) AS Units,
    CAST(ext.ExecutionRate AS DECIMAL(38, 12)) AS ExecutionRate,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID,
    CAST(ext.ProviderExecID AS STRING) AS ProviderExecID_Raw,
    UPPER(
      REPLACE(
        REPLACE(
          REPLACE(CAST(ext.ProviderExecID AS STRING), '-', ''),
          '.',
          ''
        ),
        REGEXP_EXTRACT(CAST(ext.ProviderExecID AS STRING), '[~,@,#,$,%,&,*,\\(,\\),\\.,!\\^\\?:]', 0),
        ''
      )
    ) AS ProviderExecID_Normalized,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime,
    CAST(ext.Success AS INT) AS Success,
    ROW_NUMBER() OVER (ORDER BY CAST(ext.ExecutionTime AS TIMESTAMP), CAST(ext.OrderID AS BIGINT)) AS RowID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
),
uk_execution_base AS (
  SELECT
    'uk_ext' AS source_origin,
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.HedgeServerID AS INT) AS HedgeServerID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.IsBuy AS INT) AS IsBuy,
    CAST(ext.Units AS DECIMAL(38, 12)) AS Units,
    CAST(ext.ExecutionRate AS DECIMAL(38, 12)) AS ExecutionRate,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID,
    CAST(ext.ProviderExecID AS STRING) AS ProviderExecID_Raw,
    UPPER(
      REPLACE(
        REPLACE(
          REPLACE(CAST(ext.ProviderExecID AS STRING), '-', ''),
          '.',
          ''
        ),
        REGEXP_EXTRACT(CAST(ext.ProviderExecID AS STRING), '[~,@,#,$,%,&,*,\\(,\\),\\.,!\\^\\?:]', 0),
        ''
      )
    ) AS ProviderExecID_Normalized,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime,
    CAST(ext.Success AS INT) AS Success,
    ROW_NUMBER() OVER (ORDER BY CAST(ext.ExecutionTime AS TIMESTAMP), CAST(ext.OrderID AS BIGINT)) AS RowID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(38, 12)) > 0
    AND CAST(ext.ExecutionTime AS TIMESTAMP) >= (SELECT start_ts FROM run_parameters)
    AND CAST(ext.ExecutionTime AS TIMESTAMP) < (SELECT end_ts FROM run_parameters)
    AND CAST(ext.Success AS INT) = 1
    AND ext.EMSOrderID IS NULL
),
execution_union AS (
  SELECT * FROM eu_execution_base
  UNION ALL
  SELECT * FROM uk_execution_base
),
liquidity_scd_enriched AS (
  SELECT
    e.source_origin,
    e.ExecutionID,
    e.HedgeServerID,
    e.LiquidityAccountID,
    CAST(lp.LiquidityAccountName AS STRING) AS LiquidityProvider,
    e.InstrumentID,
    e.IsBuy,
    e.Units,
    e.ExecutionRate,
    e.EMSOrderID,
    CAST(lp.LEI AS STRING) AS LEI,
    CAST(lp.LpCountryCode AS STRING) AS LPCountryCode,
    CAST(lp.eToroEntity AS STRING) AS eToroEntity,
    CAST(lp.RealOrCFD AS STRING) AS RealOrCFD,
    CASE
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'REAL' THEN 1
      WHEN UPPER(CAST(lp.RealOrCFD AS STRING)) = 'CFD' THEN 0
      ELSE -1
    END AS IsReal,
    CASE
      WHEN UPPER(CAST(lp.eToroEntity AS STRING)) = '213800GIFQMSV7HROS23' THEN 'EU'
      WHEN UPPER(CAST(lp.eToroEntity AS STRING)) = '213800FLAB1OVA8OHT72' THEN 'UK'
      ELSE 'UNKNOWN'
    END AS ExecutionFlow,
    e.ProviderExecID_Raw,
    e.ProviderExecID_Normalized,
    e.ExecutionTime,
    e.Success,
    e.RowID,
    CAST(scd.ValidFrom AS TIMESTAMP) AS SCD_ValidFrom,
    CAST(scd.ValidTo AS TIMESTAMP) AS SCD_ValidTo
  FROM execution_union e
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd scd
    ON e.LiquidityAccountID = CAST(scd.LiquidityAccountID AS INT)
   AND e.ExecutionTime >= CAST(scd.ValidFrom AS TIMESTAMP)
   AND e.ExecutionTime < CAST(scd.ValidTo AS TIMESTAMP)
),
instrument_full_description_latest AS (
  SELECT
    fd.InstrumentID,
    fd.IndexNameFullDescription,
    ROW_NUMBER() OVER (PARTITION BY fd.InstrumentID ORDER BY fd.ReportDate DESC) AS rn
  FROM main.regtech.gold_regtech_reg_instruments_full_description fd
),
instrument_metadata_enriched AS (
  SELECT
    i.InstrumentID,
    i.InstrumentTypeID,
    i.BuyCurrencyID,
    i.SellCurrencyID,
    i.ISINCode,
    CAST(i.IsMifid AS INT) AS IsMifid,
    CAST(COALESCE(i.IsMifidByFCA, i.IsMifid) AS INT) AS IsMifidByFCA,
    CAST(i.Tradable AS INT) AS Tradable,
    CAST(i.ValidFrom AS TIMESTAMP) AS InstrumentValidFrom,
    CAST(i.ValidTo AS TIMESTAMP) AS InstrumentValidTo,
    fd.IndexNameFullDescription,
    conv.New_InstrumentDisplayName,
    dc_buy.Abbreviation AS BuyAbbreviation,
    dc_sell.Abbreviation AS SellAbbreviation,
    dct.CurrencyTypeID,
    dct.Name AS CurrencyTypeName
  FROM main.regtech.gold_regtech_reg_instruments_scd i
  LEFT JOIN instrument_full_description_latest fd
    ON fd.InstrumentID = i.InstrumentID
   AND fd.rn = 1
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion conv
    ON conv.InstrumentID = i.InstrumentID
   AND conv.ReportDate = (SELECT report_date FROM run_parameters)
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = i.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = i.SellCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype dct
    ON dct.CurrencyTypeID = i.InstrumentTypeID
  WHERE (SELECT start_ts FROM run_parameters) >= CAST(i.ValidFrom AS TIMESTAMP)
    AND (SELECT start_ts FROM run_parameters) < CAST(i.ValidTo AS TIMESTAMP)
    AND CAST(i.Tradable AS INT) = 1
),
hbc_order_source AS (
  SELECT
    CAST(HedgeID AS BIGINT) AS HedgeID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog
),
ednf_mapping_source AS (
  SELECT
    CAST(instrument_id AS INT) AS instrument_id,
    CAST(contract_desc AS STRING) AS contract_desc,
    CAST(contract_long_name AS STRING) AS contract_long_name,
    CAST(ib_underlying_symbol AS STRING) AS ib_underlying_symbol
  FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
),
ednf_ib_enriched AS (
  SELECT
    c.InstrumentID,
    em.contract_desc,
    em.contract_long_name,
    em.ib_underlying_symbol,
    ect.ContractDesc AS ednf_contractdesc_match,
    ect.ContractLongName AS ednf_contractlongname_match,
    ect.IB_UnderlyingSymbol AS ednf_ib_underlyingsymbol_match,
    ib.IB_UnderlyingSymbol AS ib_underlyingsymbol_open_positions_match
  FROM (SELECT DISTINCT InstrumentID FROM liquidity_scd_enriched) c
  LEFT JOIN ednf_mapping_source em
    ON em.instrument_id = c.InstrumentID
  LEFT JOIN main.general.gold_ednf_coretrades ect
    ON ect.ContractDesc = em.contract_desc
  LEFT JOIN main.general.gold_ib_u1059976_open_positions_all ib
    ON ib.IB_UnderlyingSymbol = em.ib_underlying_symbol
),
source_exclusion_candidates AS (
  SELECT
    'instrument_exclusion' AS exclusion_type,
    CAST(e.instrument_id AS STRING) AS exclusion_key,
    CAST(e.table_name AS STRING) AS table_name
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  WHERE e.table_name = '[MIFID2_Hedge_Report]'
  UNION ALL
  SELECT
    'position_or_transaction_reference_exclusion' AS exclusion_type,
    CAST(p.position_id AS STRING) AS exclusion_key,
    CAST(p.table_name AS STRING) AS table_name
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids p
  WHERE p.table_name = '[MIFID2_Hedge_Report]'
),
eu_execution_source AS (
  SELECT
    1 AS RegulationReportID,
    'EU' AS rowSource,
    l.source_origin,
    l.ExecutionID,
    l.HedgeServerID,
    l.LiquidityAccountID,
    l.LiquidityProvider,
    l.InstrumentID,
    l.IsBuy,
    l.Units,
    l.ExecutionRate,
    l.EMSOrderID,
    l.LEI,
    l.LPCountryCode,
    l.eToroEntity,
    l.ExecutionFlow,
    l.IsReal,
    l.ProviderExecID_Raw,
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime
  FROM liquidity_scd_enriched l
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifid = 1
  WHERE l.source_origin = 'eu_ext'
    AND l.ExecutionFlow = 'EU'
),
eu_uk_execution_source AS (
  SELECT
    1 AS RegulationReportID,
    'EU-UK' AS rowSource,
    l.source_origin,
    l.ExecutionID,
    l.HedgeServerID,
    l.LiquidityAccountID,
    l.LiquidityProvider,
    l.InstrumentID,
    l.IsBuy,
    l.Units,
    l.ExecutionRate,
    l.EMSOrderID,
    l.LEI,
    l.LPCountryCode,
    l.eToroEntity,
    l.ExecutionFlow,
    l.IsReal,
    l.ProviderExecID_Raw,
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime
  FROM liquidity_scd_enriched l
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifid = 1
  WHERE l.source_origin = 'eu_ext'
    AND l.ExecutionFlow = 'UK'
    AND l.IsReal = 1
),
uk_execution_source AS (
  SELECT
    2 AS RegulationReportID,
    'UK' AS rowSource,
    l.source_origin,
    l.ExecutionID,
    l.HedgeServerID,
    l.LiquidityAccountID,
    l.LiquidityProvider,
    l.InstrumentID,
    l.IsBuy,
    l.Units,
    l.ExecutionRate,
    l.EMSOrderID,
    l.LEI,
    l.LPCountryCode,
    l.eToroEntity,
    l.ExecutionFlow,
    l.IsReal,
    CASE WHEN h.HedgeID IS NULL THEN 'CBH' ELSE 'HBC' END AS HedgingType,
    l.ProviderExecID_Raw,
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime
  FROM liquidity_scd_enriched l
  LEFT JOIN hbc_order_source h
    ON h.HedgeID = l.ExecutionID
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifidByFCA = 1
  WHERE l.source_origin = 'uk_ext'
    AND l.eToroEntity = '213800FLAB1OVA8OHT72'
    AND l.EMSOrderID IS NULL
),
transaction_reference_fields_prepared AS (
  SELECT
    RegulationReportID,
    rowSource,
    InstrumentID,
    LiquidityProvider,
    ProviderExecID_Normalized,
    RowID,
    CAST((SELECT report_date FROM run_parameters) AS STRING) AS report_date_token,
    -- HARDENING NOTE (Step 14B2):
    -- - This CTE is intentionally non-final and is not transaction-reference parity.
    -- - It prepares source fields for Step 14B3 handoff and parity review only.
    -- - Final TransactionReferenceNumber construction must be implemented in Step 14B3
    --   using the exact SQL Server logic from SP_MIFID_HedgeEU_Report.sql and
    --   SP_MIFID_HedgeUK_Report.sql.
    -- - Do not treat this CTE as final transaction reference parity.
    -- NOTE: Final TransactionReferenceNumber parity is intentionally deferred to Step 14B3.
    -- Keep only source fields required for final construction in this step.
    CASE
      WHEN ProviderExecID_Normalized IS NULL OR length(trim(ProviderExecID_Normalized)) = 0 THEN 'fallback_required'
      ELSE 'providerexecid_available'
    END AS transaction_reference_seed_status
  FROM (
    SELECT RegulationReportID, rowSource, InstrumentID, LiquidityProvider, ProviderExecID_Normalized, RowID
    FROM eu_execution_source
    UNION ALL
    SELECT RegulationReportID, rowSource, InstrumentID, LiquidityProvider, ProviderExecID_Normalized, RowID
    FROM eu_uk_execution_source
    UNION ALL
    SELECT RegulationReportID, rowSource, InstrumentID, LiquidityProvider, ProviderExecID_Normalized, RowID
    FROM uk_execution_source
  ) s
)
SELECT
  branch_name,
  RegulationReportID,
  rowSource,
  prepared_rows
FROM (
  SELECT 'EU source rows' AS branch_name, 1 AS RegulationReportID, 'EU' AS rowSource, COUNT(*) AS prepared_rows
  FROM eu_execution_source
  UNION ALL
  SELECT 'EU-UK source rows', 1, 'EU-UK', COUNT(*)
  FROM eu_uk_execution_source
  UNION ALL
  SELECT 'UK source rows', 2, 'UK', COUNT(*)
  FROM uk_execution_source
) c
ORDER BY RegulationReportID, rowSource;

WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
source_exclusion_candidates AS (
  SELECT
    'instrument_exclusion' AS exclusion_type,
    CAST(e.instrument_id AS STRING) AS exclusion_key,
    CAST(e.table_name AS STRING) AS table_name
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  WHERE e.table_name = '[MIFID2_Hedge_Report]'
  UNION ALL
  SELECT
    'position_or_transaction_reference_exclusion' AS exclusion_type,
    CAST(p.position_id AS STRING) AS exclusion_key,
    CAST(p.table_name AS STRING) AS table_name
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids p
  WHERE p.table_name = '[MIFID2_Hedge_Report]'
)
SELECT
  exclusion_type,
  COUNT(*) AS exclusion_rows
FROM source_exclusion_candidates
GROUP BY exclusion_type
ORDER BY exclusion_type;

-- -----------------------------------------------------------------------------
-- 2) OPTIONAL checkpoint template anchors (gated)
-- -----------------------------------------------------------------------------
-- NOTE:
-- - No active checkpoint materialization is enabled in Step 14B2.
-- - If optional checkpoints are introduced later, they must be prefixed,
--   explicitly typed, and activated only after source gates pass.
--
-- Suggested optional checkpoint names (do not activate here):
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_eu_source_prep
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_eu_uk_source_prep
-- - main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_uk_source_prep

-- -----------------------------------------------------------------------------
-- 3) Step 14B3 handoff checklist (documentation-only)
-- -----------------------------------------------------------------------------
-- - Final branch projection from prepared EU / EU-UK / UK sources.
-- - Final TransactionReferenceNumber parity implementation.
-- - Report-scoped exclusion application by InstrumentID and generated reference key.
-- - RecordID strategy closure and approved implementation.
-- - Final output load templates for main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report.
