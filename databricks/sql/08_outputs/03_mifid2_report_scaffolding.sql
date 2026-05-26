-- Step 12B1: MIFID2_Report / MIFID2_ME_Report / MIFID2_Removed_OP_Partials
-- scaffolding, schema contracts, dependency gates, and TODO anchors only.
--
-- In scope (Step 12B1):
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_report
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
--
-- Out of scope (do not implement here):
--   full SP_MIFID_Report business logic
--   position/trade population CTEs
--   final branch projections (EU/UK/FCA-flow/Seychelles/ME)
--   MIFID2_ETORO_Report, MIFID2_Hedge_Report, MIFID2_NPD_TRAX
--   file delivery/export/upload/response/deployment
--
-- IMPORTANT:
-- - Keep runtime load logic gated/commented until all upstream gates pass.
-- - Do not invent UpdateDate defaults (nullable in SQL Server DDL and not populated in insert lists).
-- - Removed partials inserts must use explicit column lists (no implicit ordinal insert).

-- -----------------------------------------------------------------------------
-- 0) Report-date parameter scaffold (no side effects)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
target_objects AS (
  SELECT *
  FROM VALUES
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_report'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials')
  AS t(target_object)
),
output_gates AS (
  SELECT
    'step12_price_split_sources' AS gate_name,
    'pending' AS gate_status,
    'Step 5B1 gates unresolved: Reg_CurrencyPrice_Ext / Reg_Ext_DailyMaxPrices / Reg_Ext_CurrencyPriceMaxDateWithSplit / Reg_Ext_T_PriceCandle60Min profiling and source selection must pass.' AS gate_reason
  UNION ALL
  SELECT
    'step12_non_price_pre_regulation',
    'pending',
    'Step 5B2 gates unresolved for non-price Pre_Regulation staging objects (dictionary/instrument/migration inputs).'
  UNION ALL
  SELECT
    'step12_regulation_movements',
    'pending',
    'Step 6 gates unresolved for Reg_Regulation_Movments_Positions and migration/reg-change interval parity.'
  UNION ALL
  SELECT
    'step12_mifid2_ext_position_family',
    'pending',
    'Step 9 gates unresolved for MIFID2_ext_Position / MIFID2_ext_RegChange_Position / PositionChangeLog / Mirror contracts.'
  UNION ALL
  SELECT
    'step12_customer_outputs',
    'pending',
    'Step 10/11 customer outputs must be available and parity-validated before report population.'
  UNION ALL
  SELECT
    'step12_specialchar_conversion',
    'pending',
    'InstrumentMetaData_SpecialChar_Conversion dependency is gated on Reg_Ext_Trade_InstrumentMetaData source profiling.'
  UNION ALL
  SELECT
    'step12_futuresmetadata_profile',
    'pending',
    'Expected FuturesMetaData mapping is main.trading.bronze_etoro_trade_futuresmetadata; required columns InstrumentID, CFICode, ExpirationDateTime, Multiplier still need profiling.'
  UNION ALL
  SELECT
    'step12_exclusion_refs',
    'pending',
    'Excluded instruments/position IDs and MIFID2_Instruments_To_Exclude mapping parity must be validated before activation.'
  UNION ALL
  SELECT
    'step12_removed_partials_explicit_columns',
    'pending',
    'MIFID2_Removed_OP_Partials load must be rewritten with explicit target column lists for Databricks parity safety.'
)
SELECT
  rp.report_date,
  t.target_object,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_parameters rp
CROSS JOIN target_objects t
CROSS JOIN output_gates g
ORDER BY t.target_object, g.gate_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/MIFID2_Report.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_report (
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

-- SQL Server uniqueness intent from AK_UniqueTransactionMIFID_New2:
--   (ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator)
-- Enforce as validation checks (not SQL Server index translation).

-- -----------------------------------------------------------------------------
-- 2) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/MIFID2_ME_Report.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report (
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

-- -----------------------------------------------------------------------------
-- 3) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/MIFID2_Removed_OP_Partials.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials (
  ReportDate DATE,
  PositionID BIGINT,
  ParentPositionID BIGINT,
  CID INT,
  OpenOccurred TIMESTAMP,
  CloseOccurred TIMESTAMP,
  InitForexRate DECIMAL(16,8),
  EndForexRate DECIMAL(16,8),
  AmountInUnitsDecimal DECIMAL(16,6),
  InstrumentID INT,
  IsBuy TINYINT,
  Leverage INT,
  OpenORClose STRING NOT NULL,
  MirrorID INT,
  HedgeServerID INT,
  IsSettled TINYINT,
  ChangeLogLastOpPriceRate DECIMAL(16,8),
  ChangeLogOccurred TIMESTAMP,
  ChangeTypeID TINYINT,
  InitForexPriceRateID BIGINT,
  EndForexPriceRateID BIGINT,
  LastOpPriceRate DECIMAL(16,8),
  OriginalPositionID BIGINT,
  ChangeLogIsSettled TINYINT,
  InitialUnits DECIMAL(16,8),
  RegulationID INT
)
USING DELTA;
*/

-- -----------------------------------------------------------------------------
-- 4) STEP 12B2 TODO - position/trade population CTE scaffolding
-- -----------------------------------------------------------------------------
-- TODO (Step 12B2 only):
-- - Build run-parameterized candidate population CTEs from:
--     bi_output_regtechops_mifid2_ext_position
--     bi_output_regtechops_mifid2_ext_regchange_position
--     bi_output_regtechops_mifid2_ext_positionchangelog
--     bi_output_regtechops_mifid2_ext_mirror
--     bi_output_regtechops_reg_migrationinout_population
--     bi_output_regtechops_reg_regulation_movments_positions
-- - Add same-day open+close synthetic-open handling.
-- - Add partial-close removal staging flow for removed partials side-table contract.
-- - Add split-adjustment and GBX divide-by-100 prep stages (still gate-controlled).

-- -----------------------------------------------------------------------------
-- 5) STEP 12B3 TODO - final branch projection scaffolding
-- -----------------------------------------------------------------------------
-- TODO (Step 12B3 only):
-- - Add branch projections for:
--     EU / CySEC
--     UK / FCA
--     FCA-flow-in-EU
--     Seychelles
--     ME
-- - Add branch-specific RegulationReportID and transaction-reference derivations.
-- - Project RegChange/BackReportingIndicator fields.
-- - Keep UpdateDate nullable and unpopulated unless source logic explicitly sets it.

-- -----------------------------------------------------------------------------
-- 6) STEP 12B4 TODO - reconciliation and activation
-- -----------------------------------------------------------------------------
-- TODO (Step 12B4 only):
-- - Convert gate statuses to executable criteria.
-- - Implement report-date scoped delete/insert orchestration patterns:
--     * SQL Server parity uses batched delete loops (DELETE TOP 4000).
--     * Databricks can use report-date scoped delete before insert once parity approved.
-- - Wire validation foundation checks and approve activation gates.

-- -----------------------------------------------------------------------------
-- 7) COMMENTED EXECUTION TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- -----------------------------------------------------------------------------
/*
-- Report-date scoped load skeleton (placeholder only; no Step 12B1 business logic):
DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_report (
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
  -- TODO Step 12B3 final branch projection
  *
FROM (
  -- TODO Step 12B2 position/trade candidate population
  SELECT
    CAST(NULL AS INT) AS RegulationReportID
) x
WHERE 1 = 0;

DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
SELECT *
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE 1 = 0; -- TODO Step 12B3 ME branch logic

DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials (
  ReportDate, PositionID, ParentPositionID, CID, OpenOccurred, CloseOccurred, InitForexRate, EndForexRate,
  AmountInUnitsDecimal, InstrumentID, IsBuy, Leverage, OpenORClose, MirrorID, HedgeServerID, IsSettled,
  ChangeLogLastOpPriceRate, ChangeLogOccurred, ChangeTypeID, InitForexPriceRateID, EndForexPriceRateID,
  LastOpPriceRate, OriginalPositionID, ChangeLogIsSettled, InitialUnits, RegulationID
)
SELECT
  -- TODO Step 12B2 removed partials staging output with explicit columns
  *
FROM (
  SELECT CAST(NULL AS DATE) AS ReportDate
) rp
WHERE 1 = 0;
*/
