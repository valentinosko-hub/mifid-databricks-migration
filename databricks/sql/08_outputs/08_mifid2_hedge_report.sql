-- Step 14B3: MIFID2_Hedge_Report final branch projection template (gated).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
--
-- Scope in this file:
-- - Author gated final projection templates for EU / EU-UK / UK branches.
-- - Keep final report-date DELETE / INSERT statements commented/gated.
--
-- Explicitly out of scope in this file:
-- - MIFID2_NPD_TRAX
-- - file delivery / CSV / SFTP / 7z / upload / response handling / deployment
--
-- Authorities:
-- - SP_MIFID_HedgeEU_Report.sql
-- - SP_MIFID_HedgeUK_Report.sql
-- - MIFID2_Hedge_Report.sql
--
-- Important:
-- - Do not activate final DML until all Step 14 dependency gates are approved.
-- - Do not introduce non-deterministic identity behavior for RecordID.
-- - table_name = '[MIFID2_Hedge_Report]' exclusion rows are row-level report scope,
--   not full-table suppression.

-- -----------------------------------------------------------------------------
-- 0) Step 14B3 gate checklist (read-only, safe to run)
-- -----------------------------------------------------------------------------
WITH step14b3_dependency_gates AS (
  SELECT *
  FROM VALUES
    ('step7_liquidity_scd_activation', 'pending', 'Liquidity/SCD source profiling and cutover decisions must be approved.'),
    ('step9_mifid2_ext_hedgeexecutionlog_activation', 'pending', 'MIFID2_ext_HedgeExecutionLog source profiling must pass.'),
    ('step5b2_reg_ext_hedge_sources_activation', 'pending', 'Reg_Ext_HedgeExecutionLog and Reg_Ext_HedgeHBCOrderLog profiling must pass.'),
    ('step14b3_ednf_ib_coverage', 'pending', 'EDNF/IB mapping coverage and joins must be validated.'),
    ('step14b3_instrument_specialchar_dependency', 'pending', 'InstrumentMetaData_SpecialChar_Conversion must be report-date ready.'),
    ('step14b3_dictionary_contracts', 'pending', 'Dictionary currency/type contracts must be report-date ready.'),
    ('step14b3_lei_coverage', 'pending', 'LEI coverage for report-relevant liquidity accounts must be complete.'),
    ('step14b3_exclusion_parity', 'pending', 'Report-scoped row-level exclusion semantics must be validated.'),
    ('step14b3_transaction_reference_exact_port', 'pending', 'TransactionReferenceNumber exact SQL Server parity expression must be validated.'),
    ('step14b3_recordid_deterministic_strategy', 'pending', 'Deterministic RecordID strategy requires explicit approval before activation.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT *
FROM step14b3_dependency_gates
ORDER BY gate_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- - Includes full source-preparation + branch projection stack in one statement.
-- - Keeps DELETE/INSERT non-executable until dependencies are approved.
-- -----------------------------------------------------------------------------
/*
DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report (
  DateID,
  ReportDate,
  HedgeServerID,
  LiquidityProvider,
  ExecutionID,
  InstrumentID,
  BuyORSell,
  ReportStatus,
  TransactionReferenceNumber,
  TradingVenueTransactionIdentificationCode,
  ExecutingEntityIdentificationCode,
  InvestmentFirmCoveredBy201465EU,
  BuyerIdentificationCodeType,
  BuyerNPCode,
  BuyerIdentificationCode,
  BuyerCountryOfTheBranch,
  BuyerFirstNames,
  BuyerSurnames,
  BuyerDateOfBirth,
  BuyerDecisionMakerCodeType,
  BuyerDecisionMakerNPCode,
  BuyerDecisionMakerCode,
  BuyerDecisionMakerFirstNames,
  BuyerDecisionMakerSurnames,
  BuyerDecisionMakerDateOfBirth,
  SellerIdentificationCodeType,
  SellerNPCode,
  SellerIdentificationCode,
  SellerCountryOfTheBranch,
  SellerFirstNames,
  SellerSurnames,
  SellerDateOfBirth,
  SellerDecisionMakerCodeType,
  SellerDecisionMakerNPCode,
  SellerDecisionMakerCode,
  SellerDecisionMakerFirstNames,
  SellerDecisionMakerSurnames,
  SellerDecisionMakerDateOfBirth,
  TransmissionOfOrderIndicator,
  TransmittingFirmIdentificationCodeForTheBuyer,
  TransmittingFirmIdentificationCodeForTheSeller,
  TradingDateTime,
  TradingCapacity,
  QuantityType,
  Quantity,
  QuantityCurrency,
  DerivativeNotionalIncreaseDecrease,
  PriceType,
  Price,
  PriceCurrency,
  NetAmount,
  Venue,
  CountryOfTheBranchMembership,
  UpfrontPayment,
  UpfrontPaymentCurrency,
  ComplexTradeComponentId,
  InstrumentIdentificationCode,
  InstrumentFullName,
  InstrumentClassification,
  NotionalCurrency1,
  NotionalCurrency2,
  PriceMultiplier,
  UnderlyingInstrumentCode,
  UnderlyingIndexName,
  TermOfTheUnderlyingIndex,
  OptionType,
  StrikePriceType,
  StrikePrice,
  StrikePriceCurrency,
  OptionExerciseStyle,
  MaturityDate,
  ExpiryDate,
  DeliveryType,
  InvestmentDecisionWithinFirmType,
  InvestmentDecisionWithinFirmNPCode,
  InvestmentDecisionWithinFirm,
  CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
  ExecutionWithinFirmType,
  ExecutionWithinFirmNPCode,
  ExecutionWithinFirm,
  CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
  WaiverIndicator,
  ShortSellingIndicator,
  OTCPostTradeIndicator,
  CommodityDerivativeIndicator,
  SecuritiesFinancingTransactionIndicator,
  BranchLocation,
  TransactionType,
  LifecycleEvent,
  RecordID,
  RegulationReportID,
  AssetClass,
  LiquidityAccountID,
  rowSource,
  BackReportingIndicator,
  EMSOrderID
)
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    CAST(CAST('{{report_date}}' AS DATE) AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{{report_date}}' AS DATE), 1) AS TIMESTAMP) AS end_ts
),
eu_execution_base AS (
  SELECT
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
liquidity_scd_enriched AS (
  SELECT
    src_type,
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
    e.RowID
  FROM (
    SELECT 'eu_ext' AS src_type, * FROM eu_execution_base
    UNION ALL
    SELECT 'uk_ext' AS src_type, * FROM uk_execution_base
  ) e
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
    CASE WHEN i.SellCurrencyID = 666 THEN 1 ELSE 0 END AS IsGBX,
    CASE
      WHEN i.SellCurrencyID = 666 THEN REPLACE(dc_sell.Abbreviation, 'GBX', 'GBP')
      WHEN i.SellCurrencyID = 38 THEN REPLACE(dc_sell.Abbreviation, 'CNH', 'CNY')
      ELSE dc_sell.Abbreviation
    END AS SellAbbreviation,
    dc_buy.Abbreviation AS BuyAbbreviation,
    dct.CurrencyTypeID,
    dct.Name AS CurrencyTypeName,
    fd.IndexNameFullDescription,
    CASE
      WHEN conv.InstrumentID IS NOT NULL THEN REPLACE(conv.New_InstrumentDisplayName, ',', ' ')
      ELSE REPLACE(i.InstrumentDisplayName, ',', ' ')
    END AS InstrumentFullName
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
  WHERE CAST(i.Tradable AS INT) = 1
    AND (SELECT report_date FROM run_parameters) >= CAST(i.ValidFrom AS DATE)
    AND (SELECT report_date FROM run_parameters) < CAST(i.ValidTo AS DATE)
),
hbc_order_source AS (
  SELECT CAST(HedgeID AS BIGINT) AS HedgeID
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
    ib.IB_UnderlyingSymbol AS ib_underlyingsymbol_match
  FROM (SELECT DISTINCT InstrumentID FROM liquidity_scd_enriched) c
  LEFT JOIN ednf_mapping_source em
    ON em.instrument_id = c.InstrumentID
  LEFT JOIN main.general.gold_ednf_coretrades ect
    ON ect.ContractDesc = em.contract_desc
  LEFT JOIN main.general.gold_ib_u1059976_open_positions_all ib
    ON ib.IB_UnderlyingSymbol = em.ib_underlying_symbol
),
eu_branch AS (
  SELECT
    1 AS RegulationReportID,
    'EU' AS rowSource,
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
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime,
    m.InstrumentTypeID,
    m.IsGBX,
    m.SellAbbreviation,
    m.ISINCode,
    m.InstrumentFullName,
    m.IndexNameFullDescription,
    m.CurrencyTypeID,
    m.CurrencyTypeName,
    '213800GIFQMSV7HROS23' AS ExecutingEntityCode,
    l.LEI AS BuyerSellerCode,
    'DEAL' AS TradingCapacityCode,
    CASE WHEN e.ContractDesc IS NOT NULL THEN 1 ELSE 0 END AS HasEDNFContractCoverage
  FROM liquidity_scd_enriched l
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifid = 1
  LEFT JOIN ednf_ib_enriched e
    ON e.InstrumentID = l.InstrumentID
  WHERE l.src_type = 'eu_ext'
    AND l.ExecutionFlow = 'EU'
),
eu_uk_branch AS (
  SELECT
    1 AS RegulationReportID,
    'EU-UK' AS rowSource,
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
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime,
    m.InstrumentTypeID,
    m.IsGBX,
    m.SellAbbreviation,
    m.ISINCode,
    m.InstrumentFullName,
    m.IndexNameFullDescription,
    m.CurrencyTypeID,
    m.CurrencyTypeName,
    '213800GIFQMSV7HROS23' AS ExecutingEntityCode,
    '213800FLAB1OVA8OHT72' AS BuyerSellerCode,
    'DEAL' AS TradingCapacityCode,
    CASE WHEN e.ContractDesc IS NOT NULL THEN 1 ELSE 0 END AS HasEDNFContractCoverage
  FROM liquidity_scd_enriched l
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifid = 1
  LEFT JOIN ednf_ib_enriched e
    ON e.InstrumentID = l.InstrumentID
  WHERE l.src_type = 'eu_ext'
    AND l.ExecutionFlow = 'UK'
    AND l.IsReal = 1
),
uk_branch AS (
  SELECT
    2 AS RegulationReportID,
    'UK' AS rowSource,
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
    l.ProviderExecID_Normalized,
    l.RowID,
    l.ExecutionTime,
    m.InstrumentTypeID,
    m.IsGBX,
    m.SellAbbreviation,
    m.ISINCode,
    m.InstrumentFullName,
    m.IndexNameFullDescription,
    m.CurrencyTypeID,
    m.CurrencyTypeName,
    '213800FLAB1OVA8OHT72' AS ExecutingEntityCode,
    l.LEI AS BuyerSellerCode,
    'MTCH' AS TradingCapacityCode,
    CASE WHEN h.HedgeID IS NULL THEN 'CBH' ELSE 'HBC' END AS HedgingType,
    CASE WHEN e.ContractDesc IS NOT NULL THEN 1 ELSE 0 END AS HasEDNFContractCoverage
  FROM liquidity_scd_enriched l
  LEFT JOIN hbc_order_source h
    ON h.HedgeID = l.ExecutionID
  JOIN instrument_metadata_enriched m
    ON m.InstrumentID = l.InstrumentID
   AND m.IsMifidByFCA = 1
  LEFT JOIN ednf_ib_enriched e
    ON e.InstrumentID = l.InstrumentID
  WHERE l.src_type = 'uk_ext'
    AND l.EMSOrderID IS NULL
    AND l.eToroEntity = '213800FLAB1OVA8OHT72'
),
branch_union AS (
  SELECT
    RegulationReportID, rowSource, ExecutionID, HedgeServerID, LiquidityAccountID, LiquidityProvider, InstrumentID, IsBuy,
    Units, ExecutionRate, EMSOrderID, LEI, LPCountryCode, eToroEntity, ExecutionFlow, IsReal, ProviderExecID_Normalized,
    RowID, ExecutionTime, InstrumentTypeID, IsGBX, SellAbbreviation, ISINCode, InstrumentFullName, IndexNameFullDescription,
    CurrencyTypeID, CurrencyTypeName, ExecutingEntityCode, BuyerSellerCode, TradingCapacityCode
  FROM eu_branch
  UNION ALL
  SELECT
    RegulationReportID, rowSource, ExecutionID, HedgeServerID, LiquidityAccountID, LiquidityProvider, InstrumentID, IsBuy,
    Units, ExecutionRate, EMSOrderID, LEI, LPCountryCode, eToroEntity, ExecutionFlow, IsReal, ProviderExecID_Normalized,
    RowID, ExecutionTime, InstrumentTypeID, IsGBX, SellAbbreviation, ISINCode, InstrumentFullName, IndexNameFullDescription,
    CurrencyTypeID, CurrencyTypeName, ExecutingEntityCode, BuyerSellerCode, TradingCapacityCode
  FROM eu_uk_branch
  UNION ALL
  SELECT
    RegulationReportID, rowSource, ExecutionID, HedgeServerID, LiquidityAccountID, LiquidityProvider, InstrumentID, IsBuy,
    Units, ExecutionRate, EMSOrderID, LEI, LPCountryCode, eToroEntity, ExecutionFlow, IsReal, ProviderExecID_Normalized,
    RowID, ExecutionTime, InstrumentTypeID, IsGBX, SellAbbreviation, ISINCode, InstrumentFullName, IndexNameFullDescription,
    CurrencyTypeID, CurrencyTypeName, ExecutingEntityCode, BuyerSellerCode, TradingCapacityCode
  FROM uk_branch
),
transaction_reference_exact AS (
  SELECT
    b.*,
    -- Exact SQL Server parity intent:
    -- ISNULL(CONCAT(UPPER(CAST(ProviderExecID AS VARCHAR(50))), CAST(RowID AS VARCHAR), CONVERT(varchar(8), @StartDate, 112)),
    --        CONCAT(UPPER(LiquidityProvider), CONVERT(varchar(8), @StartDate, 112), CAST(RowID AS VARCHAR)))
    COALESCE(
      CONCAT(
        UPPER(COALESCE(CAST(b.ProviderExecID_Normalized AS STRING), '')),
        COALESCE(CAST(b.RowID AS STRING), ''),
        date_format((SELECT report_date FROM run_parameters), 'yyyyMMdd')
      ),
      CONCAT(
        UPPER(COALESCE(CAST(b.LiquidityProvider AS STRING), '')),
        date_format((SELECT report_date FROM run_parameters), 'yyyyMMdd'),
        COALESCE(CAST(b.RowID AS STRING), '')
      )
    ) AS TransactionReferenceNumber
  FROM branch_union b
),
instrument_exclusion_scope AS (
  SELECT DISTINCT CAST(instrument_id AS STRING) AS instrument_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
  WHERE table_name = '[MIFID2_Hedge_Report]'
),
position_exclusion_scope AS (
  SELECT DISTINCT CAST(position_id AS STRING) AS position_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids
  WHERE table_name = '[MIFID2_Hedge_Report]'
),
branch_projection_filtered AS (
  SELECT *
  FROM transaction_reference_exact p
  WHERE CAST(p.InstrumentID AS STRING) NOT IN (SELECT instrument_id FROM instrument_exclusion_scope)
    AND NOT EXISTS (
      SELECT 1
      FROM position_exclusion_scope x
      WHERE x.position_id = p.TransactionReferenceNumber
    )
),
final_projection AS (
  SELECT
    CAST(date_format((SELECT report_date FROM run_parameters), 'yyyyMMdd') AS INT) AS DateID,
    (SELECT report_date FROM run_parameters) AS ReportDate,
    p.HedgeServerID,
    p.LiquidityProvider,
    p.ExecutionID,
    p.InstrumentID,
    CAST(p.IsBuy AS INT) AS BuyORSell,
    'NEWT' AS ReportStatus,
    p.TransactionReferenceNumber,
    '' AS TradingVenueTransactionIdentificationCode,
    p.ExecutingEntityCode AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    'LEI' AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE WHEN p.IsBuy = 1 THEN p.ExecutingEntityCode ELSE COALESCE(p.BuyerSellerCode, p.LEI) END AS BuyerIdentificationCode,
    '' AS BuyerCountryOfTheBranch,
    '' AS BuyerFirstNames,
    '' AS BuyerSurnames,
    '' AS BuyerDateOfBirth,
    '' AS BuyerDecisionMakerCodeType,
    '' AS BuyerDecisionMakerNPCode,
    '' AS BuyerDecisionMakerCode,
    '' AS BuyerDecisionMakerFirstNames,
    '' AS BuyerDecisionMakerSurnames,
    '' AS BuyerDecisionMakerDateOfBirth,
    'LEI' AS SellerIdentificationCodeType,
    '' AS SellerNPCode,
    CASE WHEN p.IsBuy = 0 THEN p.ExecutingEntityCode ELSE COALESCE(p.BuyerSellerCode, p.LEI) END AS SellerIdentificationCode,
    '' AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames,
    '' AS SellerSurnames,
    '' AS SellerDateOfBirth,
    '' AS SellerDecisionMakerCodeType,
    '' AS SellerDecisionMakerNPCode,
    '' AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames,
    '' AS SellerDecisionMakerSurnames,
    '' AS SellerDecisionMakerDateOfBirth,
    'FALSE' AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    CONCAT(
      date_format(p.ExecutionTime, 'yyyy-MM-dd'),
      'T',
      date_format(CASE WHEN second(p.ExecutionTime) = 0 THEN p.ExecutionTime + INTERVAL 1 SECOND ELSE p.ExecutionTime END, 'HH:mm:ss'),
      'Z'
    ) AS TradingDateTime,
    p.TradingCapacityCode AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(p.Units AS STRING) AS Quantity,
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN p.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
    CAST(CASE WHEN p.IsGBX = 1 THEN p.ExecutionRate / 100.00 ELSE p.ExecutionRate END AS STRING) AS Price,
    SUBSTRING(p.SellAbbreviation, 1, 3) AS PriceCurrency,
    '' AS NetAmount,
    CASE WHEN p.rowSource = 'EU' AND p.IsReal = 0 THEN 'XXXX' ELSE 'XOFF' END AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment,
    '' AS UpfrontPaymentCurrency,
    '' AS ComplexTradeComponentId,
    CASE
      WHEN p.rowSource = 'UK' THEN COALESCE(p.ISINCode, '')
      WHEN p.IsReal = 1 AND p.ISINCode IS NOT NULL THEN p.ISINCode
      ELSE ''
    END AS InstrumentIdentificationCode,
    CASE
      WHEN p.rowSource = 'EU' AND p.IsReal = 0 THEN CONCAT(LEFT(COALESCE(p.InstrumentFullName, ''), 50), ' CFD')
      ELSE ''
    END AS InstrumentFullName,
    -- HARD GATE (Step 14B3):
    -- Exact branch-specific InstrumentClassification logic from SQL Server procedures
    -- remains unresolved and must be validated/approved before activation.
    CAST(NULL AS STRING) AS InstrumentClassification,
    '' AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    CASE WHEN p.IsReal = 1 THEN '' ELSE '1' END AS PriceMultiplier,
    CASE WHEN p.IsReal = 1 THEN '' ELSE COALESCE(p.ISINCode, '') END AS UnderlyingInstrumentCode,
    '' AS UnderlyingIndexName,
    '' AS TermOfTheUnderlyingIndex,
    '' AS OptionType,
    '' AS StrikePriceType,
    '' AS StrikePrice,
    '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle,
    '' AS MaturityDate,
    '' AS ExpiryDate,
    CASE WHEN p.IsReal = 1 THEN '' ELSE 'CASH' END AS DeliveryType,
    '' AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    '' AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETORODEALING01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    CASE
      WHEN p.rowSource = 'EU'
       AND p.IsReal = 1
       AND p.IsBuy = 0
       AND p.CurrencyTypeID IN (5, 6) THEN 'SELL'
      ELSE ''
    END AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE WHEN p.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
    'FALSE' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation,
    '' AS TransactionType,
    '' AS LifecycleEvent,
    p.RegulationReportID,
    CASE WHEN p.CurrencyTypeID IN (4, 5, 6) THEN 'Equity' ELSE COALESCE(p.CurrencyTypeName, '') END AS AssetClass,
    p.LiquidityAccountID,
    p.rowSource,
    CAST(0 AS SMALLINT) AS BackReportingIndicator,
    p.EMSOrderID
  FROM branch_projection_filtered p
),
recordid_deterministic AS (
  SELECT
    fp.*,
    -- Step 14B3 preferred deterministic strategy (approval-gated):
    -- RecordID = 100000000 + row_number() over stable branch ordering key.
    100000000 + ROW_NUMBER() OVER (
      ORDER BY
        fp.ReportDate,
        fp.RegulationReportID,
        fp.rowSource,
        fp.TransactionReferenceNumber,
        fp.ExecutionID,
        fp.LiquidityAccountID,
        fp.InstrumentID
    ) AS RecordID
  FROM final_projection fp
)
SELECT
  DateID,
  ReportDate,
  HedgeServerID,
  LiquidityProvider,
  ExecutionID,
  InstrumentID,
  BuyORSell,
  ReportStatus,
  TransactionReferenceNumber,
  TradingVenueTransactionIdentificationCode,
  ExecutingEntityIdentificationCode,
  InvestmentFirmCoveredBy201465EU,
  BuyerIdentificationCodeType,
  BuyerNPCode,
  BuyerIdentificationCode,
  BuyerCountryOfTheBranch,
  BuyerFirstNames,
  BuyerSurnames,
  BuyerDateOfBirth,
  BuyerDecisionMakerCodeType,
  BuyerDecisionMakerNPCode,
  BuyerDecisionMakerCode,
  BuyerDecisionMakerFirstNames,
  BuyerDecisionMakerSurnames,
  BuyerDecisionMakerDateOfBirth,
  SellerIdentificationCodeType,
  SellerNPCode,
  SellerIdentificationCode,
  SellerCountryOfTheBranch,
  SellerFirstNames,
  SellerSurnames,
  SellerDateOfBirth,
  SellerDecisionMakerCodeType,
  SellerDecisionMakerNPCode,
  SellerDecisionMakerCode,
  SellerDecisionMakerFirstNames,
  SellerDecisionMakerSurnames,
  SellerDecisionMakerDateOfBirth,
  TransmissionOfOrderIndicator,
  TransmittingFirmIdentificationCodeForTheBuyer,
  TransmittingFirmIdentificationCodeForTheSeller,
  TradingDateTime,
  TradingCapacity,
  QuantityType,
  Quantity,
  QuantityCurrency,
  DerivativeNotionalIncreaseDecrease,
  PriceType,
  Price,
  PriceCurrency,
  NetAmount,
  Venue,
  CountryOfTheBranchMembership,
  UpfrontPayment,
  UpfrontPaymentCurrency,
  ComplexTradeComponentId,
  InstrumentIdentificationCode,
  InstrumentFullName,
  InstrumentClassification,
  NotionalCurrency1,
  NotionalCurrency2,
  PriceMultiplier,
  UnderlyingInstrumentCode,
  UnderlyingIndexName,
  TermOfTheUnderlyingIndex,
  OptionType,
  StrikePriceType,
  StrikePrice,
  StrikePriceCurrency,
  OptionExerciseStyle,
  MaturityDate,
  ExpiryDate,
  DeliveryType,
  InvestmentDecisionWithinFirmType,
  InvestmentDecisionWithinFirmNPCode,
  InvestmentDecisionWithinFirm,
  CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
  ExecutionWithinFirmType,
  ExecutionWithinFirmNPCode,
  ExecutionWithinFirm,
  CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
  WaiverIndicator,
  ShortSellingIndicator,
  OTCPostTradeIndicator,
  CommodityDerivativeIndicator,
  SecuritiesFinancingTransactionIndicator,
  BranchLocation,
  TransactionType,
  LifecycleEvent,
  RecordID,
  RegulationReportID,
  AssetClass,
  LiquidityAccountID,
  rowSource,
  BackReportingIndicator,
  EMSOrderID
FROM recordid_deterministic;
*/

