-- Step 13B2: MIFID2_ETORO_Report projection template (gated).
--
-- Target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
--
-- Scope in this file:
-- - Author Step 13B2 projection template from ASIC2 compatibility source.
-- - Keep final load statements gated/commented until upstream gates are cleared.
--
-- Out of scope in this file:
-- - Step 13B3 validation/reconciliation package
-- - MIFID2_Hedge_Report and MIFID2_NPD_TRAX
-- - file delivery/export/upload/response/deployment
--
-- Source-of-truth rule:
-- - Do NOT use legacy dbo.ASIC_Transactions as migration source-of-truth.
-- - Use Step 8 ASIC2 compatibility source only:
--     {{asic_compatibility_source}}
--
-- Required placeholders in gated template below:
--   {{report_date}}
--   {{asic_compatibility_source}}
--   {{excluded_cids_source}}
--   {{excluded_instruments_source}}
--   {{excluded_position_ids_source}}
--
-- IMPORTANT:
-- - table_name = '[MIFID2_ETORO_Report]' in exclusion sources scopes exclusion rows
--   to this report. It does NOT mean exclude the entire output table.
-- - Exclude matching instruments/positions for this report based on
--   table_name = '[MIFID2_ETORO_Report]'.

-- -----------------------------------------------------------------------------
-- 0) Gate checklist (read-only status output, no placeholders)
-- -----------------------------------------------------------------------------
WITH dependency_gates AS (
  SELECT 'step8_compatibility_activation' AS gate_name, 'pending' AS gate_status,
         'Step 8 compatibility source must be activated and contract-validated.' AS gate_reason
  UNION ALL
  SELECT 'opentime_parity', 'pending',
         'CDE_Execution_timestamp -> OpenTime parity must be accepted before activation.'
  UNION ALL
  SELECT 'openprice_staticposition_conditional', 'pending',
         'OpenPrice remains gated while Reg_DWH_StaticPosition fallback impact is unresolved.'
  UNION ALL
  SELECT 'instrumentclassification_exact_mapping', 'pending',
         'Exact SP_MIFID2_ETORO_Report InstrumentClassification mapping must be ported, or hard-gated.'
  UNION ALL
  SELECT 'dictionary_currency_dependencies', 'pending',
         'Reg_Ext_DictionaryCurrency and Reg_Ext_DictionaryCurrencyType contracts must be validated.'
  UNION ALL
  SELECT 'instrument_metadata_dependencies', 'pending',
         'Reg_Instruments_SCD / Reg_Instruments_Full_Description / SpecialChar conversion coverage required.'
  UNION ALL
  SELECT 'asic2_history_seed_window', 'pending',
         'ASIC2 history seed coverage must satisfy requested ETORO reconciliation windows.'
  UNION ALL
  SELECT 'upi_non_dependency_rule', 'pending',
         'EMIR Refit UPI remains non-blocking unless proven to affect consumed compatibility fields.'
)
SELECT *
FROM dependency_gates
ORDER BY gate_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- -----------------------------------------------------------------------------
/*
-- COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- Requires Step 8 ASIC2 compatibility activation and ETORO source profiling.
-- Requires OpenTime, OpenPrice, dictionary, instrument, and exclusion-source gates to pass.
DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report (
  RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
  IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
  TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
  BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
  BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
  BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
  SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
  SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
  SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
  TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
  TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
  PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
  ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
  NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
  StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
  InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
  CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
  ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
  ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
  BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
)
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
asic_src AS (
  SELECT
    DateID,
    ReportDate,
    CID,
    PositionID,
    InstrumentID,
    OpenORClose,
    IsBuy,
    OpenTime,
    Volume,
    OpenPrice,
    RegChange
  FROM {{asic_compatibility_source}}
  WHERE ReportDate = CAST('{{report_date}}' AS DATE)
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
instrument_metadata AS (
  SELECT
    scd.InstrumentID,
    scd.InstrumentTypeID,
    scd.BuyCurrencyID,
    scd.SellCurrencyID,
    scd.ISINCode,
    scd.IsMifid,
    scd.Tradable,
    fd.IndexNameFullDescription,
    CASE
      WHEN imsc.InstrumentID IS NOT NULL
        THEN REPLACE(imsc.New_InstrumentDisplayName, ',', ' ')
      ELSE REPLACE(scd.InstrumentDisplayName, ',', ' ')
    END AS InstrumentFullName,
    CASE
      WHEN scd.SellCurrencyID = 666 THEN REPLACE(dc_sell.Abbreviation, 'GBX', 'GBP')
      WHEN scd.SellCurrencyID = 38 THEN REPLACE(dc_sell.Abbreviation, 'CNH', 'CNY')
      ELSE dc_sell.Abbreviation
    END AS SellAbbreviation,
    dc_buy.Abbreviation AS BuyAbbreviation,
    ctp.CurrencyTypeID,
    ctp.Name AS CurrencyTypeName
  FROM main.regtech.gold_regtech_reg_instruments_scd scd
  JOIN run_parameters rp
    ON rp.report_date >= scd.ValidFrom
   AND rp.report_date < scd.ValidTo
  LEFT JOIN full_description_latest fd
    ON fd.InstrumentID = scd.InstrumentID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion imsc
    ON imsc.InstrumentID = scd.InstrumentID
   AND imsc.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = scd.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = scd.SellCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype ctp
    ON ctp.CurrencyTypeID = scd.InstrumentTypeID
  WHERE scd.Tradable = 1
    AND scd.IsMifid = 1
),
eligible_source AS (
  SELECT
    src.*
  FROM asic_src src
  LEFT JOIN {{excluded_cids_source}} ex_cid
    ON ex_cid.cid = src.CID
  WHERE ex_cid.cid IS NULL
    -- Exclude matching instruments for this report based on table_name = '[MIFID2_ETORO_Report]'.
    AND NOT EXISTS (
      SELECT 1
      FROM {{excluded_instruments_source}} ex
      WHERE ex.InstrumentID = src.InstrumentID
        AND ex.table_name = '[MIFID2_ETORO_Report]'
    )
    -- Exclude matching positions for this report based on table_name = '[MIFID2_ETORO_Report]'.
    AND NOT EXISTS (
      SELECT 1
      FROM {{excluded_position_ids_source}} ex
      WHERE CAST(ex.PositionID AS STRING) = CAST(src.PositionID AS STRING)
        AND ex.table_name = '[MIFID2_ETORO_Report]'
    )
),
projected AS (
  SELECT
    1 AS RegulationReportID,                                              -- (1)
    src.DateID AS DateID,                                                 -- (3)
    src.ReportDate AS ReportDate,                                         -- (4)
    src.CID AS CID,                                                       -- (5)
    1 AS RegulationID,                                                    -- (2)
    src.PositionID AS PositionID,                                         -- (6)
    src.InstrumentID AS InstrumentID,                                     -- (7)
    src.OpenORClose AS OpenORClose,                                       -- (8)
    CAST(src.IsBuy AS INT) AS BuyORSell,                                  -- (9)
    CAST(NULL AS INT) AS IDType,
    0 AS IsCopy,
    CAST(NULL AS INT) AS CopyFund,
    CAST(NULL AS INT) AS FundTypeID,
    'NEWT' AS ReportStatus,
    CONCAT(CAST(src.PositionID AS STRING), src.OpenORClose, 'AUS', CAST(src.DateID AS STRING)) AS TransactionReferenceNumber, -- (10)
    '' AS TradingVenueTransactionIdentificationCode,
    '213800GIFQMSV7HROS23' AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    'LEI' AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE WHEN CAST(src.IsBuy AS INT) = 1 THEN '549300OK2V4QF20B0D04' ELSE '213800GIFQMSV7HROS23' END AS BuyerIdentificationCode,
    CASE WHEN CAST(src.IsBuy AS INT) = 1 THEN 'CY' ELSE '' END AS BuyerCountryOfTheBranch,
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
    CASE WHEN CAST(src.IsBuy AS INT) = 1 THEN '213800GIFQMSV7HROS23' ELSE '549300OK2V4QF20B0D04' END AS SellerIdentificationCode,
    CASE WHEN CAST(src.IsBuy AS INT) = 1 THEN '' ELSE 'CY' END AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames,
    '' AS SellerSurnames,
    '' AS SellerDateOfBirth,
    '' AS SellerDecisionMakerCodeType,
    '' AS SellerDecisionMakerNPCode,
    '' AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames,
    '' AS SellerDecisionMakerSurnames,
    '' AS SellerDecisionMakerDateOfBirth,
    'false' AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    date_format(CAST(src.OpenTime AS TIMESTAMP), "yyyy-MM-dd'T'HH:mm:ss'Z'") AS TradingDateTime, -- (11)
    'DEAL' AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(src.Volume AS STRING) AS Quantity,                               -- (12)
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN md.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType, -- (15)
    CAST(src.OpenPrice AS STRING) AS Price,                               -- (13)
    SUBSTRING(md.SellAbbreviation, 1, 3) AS PriceCurrency,                -- (16)
    '' AS NetAmount,
    'XXXX' AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment,
    '' AS UpfrontPaymentCurrency,
    '' AS ComplexTradeComponentId,
    '' AS InstrumentIdentificationCode,
    CONCAT(LEFT(md.InstrumentFullName, 50), ' CFD') AS InstrumentFullName, -- (17)
    CAST(NULL AS STRING) AS InstrumentClassification,                      -- HARD GATE: exact SP_MIFID2_ETORO_Report mapping required.
    SUBSTRING(md.SellAbbreviation, 1, 3) AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    '1' AS PriceMultiplier,
    COALESCE(md.ISINCode, '') AS UnderlyingInstrumentCode,                 -- (18)
    CASE
      WHEN md.InstrumentID IN (312, 313, 314) THEN ''
      WHEN md.InstrumentTypeID = 4 AND md.IndexNameFullDescription IS NOT NULL THEN md.IndexNameFullDescription
      WHEN md.InstrumentTypeID = 4 AND md.IndexNameFullDescription IS NULL THEN COALESCE(LEFT(md.InstrumentFullName, 50), '')
      ELSE ''
    END AS UnderlyingIndexName,
    CASE
      WHEN md.InstrumentID = 26 THEN '1MNTH'
      WHEN md.InstrumentID IN (
        225000, 225001, 225002, 225003, 225004, 225005, 225006, 225007, 225008,
        225009, 225010, 225011, 225012, 225013, 225014, 225015, 225016
      ) THEN '10YEAR'
      ELSE ''
    END AS TermOfTheUnderlyingIndex,
    '' AS OptionType,
    '' AS StrikePriceType,
    '' AS StrikePrice,
    '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle,
    '' AS MaturityDate,
    '' AS ExpiryDate,
    'CASH' AS DeliveryType,
    'ALG' AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    'ETOROBROKERAGE01' AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETOROBROKERAGE01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    '' AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE WHEN md.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
    'false' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation,
    '' AS TransactionType,
    '' AS LifecycleEvent,
    CASE WHEN md.CurrencyTypeID IN (4, 5, 6) THEN 'Equity' ELSE COALESCE(md.CurrencyTypeName, '') END AS AssetClass, -- (19)
    0 AS IsRealStockETF,
    to_utc_timestamp(current_timestamp(), current_timezone()) AS UpdateDate, -- (20) SQL Server parity for GETUTCDATE()
    CAST(0 AS SMALLINT) AS BackReportingIndicator,
    src.RegChange AS RegChange                                              -- (14)
  FROM eligible_source src
  JOIN instrument_metadata md
    ON md.InstrumentID = src.InstrumentID
)
SELECT
  RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
  IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
  TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
  BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
  BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
  BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
  SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
  SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
  SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
  TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
  TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
  PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
  ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
  NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
  StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
  InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
  CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
  ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
  ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
  BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
FROM projected;
*/
