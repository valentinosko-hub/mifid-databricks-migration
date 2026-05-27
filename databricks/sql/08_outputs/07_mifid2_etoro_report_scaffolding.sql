-- Step 13B1: MIFID2_ETORO_Report scaffolding/output contract/dependency gates only.
--
-- In scope (Step 13B1):
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
--
-- Out of scope (do not implement here):
--   final ETORO projection logic
--   ETORO validation/reconciliation package
--   MIFID2_Hedge_Report and MIFID2_NPD_TRAX
--   file delivery/export/upload/response/deployment
--
-- Source-of-truth rule:
-- - Legacy dbo.ASIC_Transactions is not migration source-of-truth.
-- - Step 8 ASIC2 compatibility objects are required:
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions
--     main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions
--
-- Important behavior notes:
-- - SQL Server ETORO uses GETUTCDATE() for UpdateDate.
-- - Databricks parity should use current UTC timestamp only in final activated Step 13B2 logic.
-- - Step 13B1 remains non-executable for final INSERT behavior.

-- -----------------------------------------------------------------------------
-- 0) Report-date parameter + dependency gate checklist (no side effects)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
target_objects AS (
  SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report' AS target_object
),
required_compatibility_fields AS (
  SELECT 'DateID' AS compatibility_field UNION ALL
  SELECT 'ReportDate' UNION ALL
  SELECT 'CID' UNION ALL
  SELECT 'PositionID' UNION ALL
  SELECT 'InstrumentID' UNION ALL
  SELECT 'OpenORClose' UNION ALL
  SELECT 'IsBuy' UNION ALL
  SELECT 'OpenTime' UNION ALL
  SELECT 'Volume' UNION ALL
  SELECT 'OpenPrice' UNION ALL
  SELECT 'RegChange'
),
dependency_gates AS (
  SELECT
    'step8_asic2_compatibility_activation' AS gate_name,
    'pending' AS gate_status,
    'Step 8 compatibility table/view must be activated and contract-validated.' AS gate_reason
  UNION ALL
  SELECT
    'opentime_parity',
    'pending',
    'CDE_Execution_timestamp -> OpenTime parity must be accepted before ETORO activation.'
  UNION ALL
  SELECT
    'volume_parity',
    'pending',
    'Quantity -> Volume parity must be accepted before ETORO activation.'
  UNION ALL
  SELECT
    'openprice_parity',
    'pending',
    'OpenPrice parity must be accepted before ETORO activation.'
  UNION ALL
  SELECT
    'reg_dwh_staticposition_conditional',
    'pending',
    'Conditional only; blocks activation only if profiling proves fallback impact on consumed fields (for example OpenPrice).'
  UNION ALL
  SELECT
    'instrument_specialchar_conversion',
    'pending',
    'InstrumentMetaData_SpecialChar_Conversion must be available for report-date join coverage.'
  UNION ALL
  SELECT
    'dictionary_currency',
    'pending',
    'Reg_Ext_DictionaryCurrency source contract/coverage must be validated.'
  UNION ALL
  SELECT
    'dictionary_currency_type',
    'pending',
    'Reg_Ext_DictionaryCurrencyType source contract/coverage must be validated.'
  UNION ALL
  SELECT
    'instrument_scd_full_description',
    'pending',
    'Reg_Instruments_SCD and Reg_Instruments_Full_Description report-date coverage must be validated.'
  UNION ALL
  SELECT
    'exclusion_sources_currentness',
    'pending',
    'Excluded CIDs/instruments/position IDs contracts and freshness must be validated for ETORO table_name scope.'
  UNION ALL
  SELECT
    'asic2_history_seed_window',
    'pending',
    'ASIC2 history seed for requested reconciliation window must be confirmed.'
  UNION ALL
  SELECT
    'instrumentclassification_exact_mapping',
    'pending',
    'Exact ETORO InstrumentClassification case mapping must be ported before activation.'
),
non_dependency_notes AS (
  SELECT
    'emir_upi_non_dependency' AS note_name,
    'EMIR Refit UPI is non-blocking unless profiling shows impact on one of the 11 consumed compatibility fields.' AS note_text
  UNION ALL
  SELECT
    'noc_old_attempt_non_authority',
    'NOC and prior Databricks attempts are discovery/reference only and are not implementation authority.'
)
SELECT
  rp.report_date,
  t.target_object,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_parameters rp
CROSS JOIN target_objects t
CROSS JOIN dependency_gates g
ORDER BY g.gate_name;

SELECT
  'main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions' AS compatibility_view,
  compatibility_field
FROM required_compatibility_fields
ORDER BY compatibility_field;

SELECT
  note_name,
  note_text
FROM non_dependency_notes
ORDER BY note_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED DDL TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/MIFID2_ETORO_Report.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report (
  RegulationReportID INT,
  DateID INT,
  ReportDate DATE,
  CID INT,
  RegulationID INT,
  PositionID BIGINT,
  InstrumentID INT,
  OpenORClose STRING,
  BuyORSell INT,
  IDType INT,
  IsCopy INT,
  CopyFund INT,
  FundTypeID INT,
  ReportStatus STRING,
  TransactionReferenceNumber STRING,
  TradingVenueTransactionIdentificationCode STRING,
  ExecutingEntityIdentificationCode STRING,
  InvestmentFirmCoveredBy201465EU STRING,
  BuyerIdentificationCodeType STRING,
  BuyerNPCode STRING,
  BuyerIdentificationCode STRING,
  BuyerCountryOfTheBranch STRING,
  BuyerFirstNames STRING,
  BuyerSurnames STRING,
  BuyerDateOfBirth STRING,
  BuyerDecisionMakerCodeType STRING,
  BuyerDecisionMakerNPCode STRING,
  BuyerDecisionMakerCode STRING,
  BuyerDecisionMakerFirstNames STRING,
  BuyerDecisionMakerSurnames STRING,
  BuyerDecisionMakerDateOfBirth STRING,
  SellerIdentificationCodeType STRING,
  SellerNPCode STRING,
  SellerIdentificationCode STRING,
  SellerCountryOfTheBranch STRING,
  SellerFirstNames STRING,
  SellerSurnames STRING,
  SellerDateOfBirth STRING,
  SellerDecisionMakerCodeType STRING,
  SellerDecisionMakerNPCode STRING,
  SellerDecisionMakerCode STRING,
  SellerDecisionMakerFirstNames STRING,
  SellerDecisionMakerSurnames STRING,
  SellerDecisionMakerDateOfBirth STRING,
  TransmissionOfOrderIndicator STRING,
  TransmittingFirmIdentificationCodeForTheBuyer STRING,
  TransmittingFirmIdentificationCodeForTheSeller STRING,
  TradingDateTime STRING,
  TradingCapacity STRING,
  QuantityType STRING,
  Quantity STRING,
  QuantityCurrency STRING,
  DerivativeNotionalIncreaseDecrease STRING,
  PriceType STRING,
  Price STRING,
  PriceCurrency STRING,
  NetAmount STRING,
  Venue STRING,
  CountryOfTheBranchMembership STRING,
  UpfrontPayment STRING,
  UpfrontPaymentCurrency STRING,
  ComplexTradeComponentId STRING,
  InstrumentIdentificationCode STRING,
  InstrumentFullName STRING,
  InstrumentClassification STRING,
  NotionalCurrency1 STRING,
  NotionalCurrency2 STRING,
  PriceMultiplier STRING,
  UnderlyingInstrumentCode STRING,
  UnderlyingIndexName STRING,
  TermOfTheUnderlyingIndex STRING,
  OptionType STRING,
  StrikePriceType STRING,
  StrikePrice STRING,
  StrikePriceCurrency STRING,
  OptionExerciseStyle STRING,
  MaturityDate STRING,
  ExpiryDate STRING,
  DeliveryType STRING,
  InvestmentDecisionWithinFirmType STRING,
  InvestmentDecisionWithinFirmNPCode STRING,
  InvestmentDecisionWithinFirm STRING,
  CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision STRING,
  ExecutionWithinFirmType STRING,
  ExecutionWithinFirmNPCode STRING,
  ExecutionWithinFirm STRING,
  CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution STRING,
  WaiverIndicator STRING,
  ShortSellingIndicator STRING,
  OTCPostTradeIndicator STRING,
  CommodityDerivativeIndicator STRING,
  SecuritiesFinancingTransactionIndicator STRING,
  BranchLocation STRING,
  TransactionType STRING,
  LifecycleEvent STRING,
  AssetClass STRING,
  IsRealStockETF INT,
  UpdateDate TIMESTAMP,
  BackReportingIndicator SMALLINT,
  RegChange INT
)
USING DELTA;
*/

-- SQL Server uniqueness intent from AK_UniqueTransactionMIFID_ETORO:
--   (ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator)
-- Enforce as validation checks in Step 13B3 (do not translate SQL Server indexes directly).

-- -----------------------------------------------------------------------------
-- 2) Step 13B2 TODO anchors (projection implementation only, still gated)
-- -----------------------------------------------------------------------------
-- TODO (Step 13B2 only):
-- - Build ETORO projection from Step 8 compatibility source (not legacy ASIC table).
-- - Port exact InstrumentClassification CASE logic from SP_MIFID2_ETORO_Report.
-- - Port ETORO constants, identifiers, and branch-specific field derivations.
-- - Apply exclusion sources with ETORO table_name parity.
-- - Activate UpdateDate with current UTC timestamp equivalent only after gates pass.

-- -----------------------------------------------------------------------------
-- 3) Step 13B3 TODO anchors (validation/reconciliation package only)
-- -----------------------------------------------------------------------------
-- TODO (Step 13B3 only):
-- - Add schema/row-count/duplicate/null checks for ETORO output.
-- - Add compatibility-field parity checks (OpenTime, Volume, OpenPrice).
-- - Add exclusion-parity and instrument coverage checks.

-- -----------------------------------------------------------------------------
-- 4) COMMENTED EXECUTION TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- -----------------------------------------------------------------------------
/*
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
SELECT
  -- TODO Step 13B2 final ETORO projection
  *
FROM (
  SELECT CAST(NULL AS INT) AS RegulationReportID
) x
WHERE 1 = 0;
*/
