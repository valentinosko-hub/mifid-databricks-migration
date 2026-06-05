-- Step 11: Manual CSV seed testing — external CSV + seed test table DDL (GATED/COMMENTED).
--
-- Scope:
-- - Staging-only seed test tables in main.regtech_ops_stg.
-- - CSV files live in approved secure ADLS/Volume locations — NOT in Git.
-- - No writes to main.regtech. No production tables. No delivery/upload/response logic.
--
-- Prerequisites:
-- - Replace {{approved_*}} placeholders with approved secure paths before uncommenting.
-- - NPD CSV exports may contain PII — use restricted ACLs only.
-- - Record SQL Server export row counts in external manifest before load validation.
--
-- DO NOT UNCOMMENT UNTIL: secure path approved, PII handling reviewed, staging write access confirmed.

-- -----------------------------------------------------------------------------
-- 0) Path placeholders (replace at run time; do not commit real paths to Git)
-- -----------------------------------------------------------------------------
-- NPD CSV:
--   {{npd_csv_location}} = abfss://{{approved_container}}@{{storage_account}}.dfs.core.windows.net/{{approved_seed_path}}/mifid2_npd_trax/
-- Hedge CSV:
--   {{hedge_csv_location}} = abfss://{{approved_container}}@{{storage_account}}.dfs.core.windows.net/{{approved_seed_path}}/mifid2_hedge_report/
-- Delta storage for seed test tables:
--   {{seed_delta_location_npd}} = abfss://{{approved_container}}@{{storage_account}}.dfs.core.windows.net/{{approved_seed_path}}/delta/seed_test_mifid2_npd_trax/
--   {{seed_delta_location_hedge}} = abfss://{{approved_container}}@{{storage_account}}.dfs.core.windows.net/{{approved_seed_path}}/delta/seed_test_mifid2_hedge_report/

-- -----------------------------------------------------------------------------
-- 1) External CSV source tables (read-only staging inputs)
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_seed_test_ext_mifid2_npd_trax_csv
USING CSV
OPTIONS (
  path '{{npd_csv_location}}',
  header 'true',
  inferSchema 'false',
  mode 'PERMISSIVE'
);

CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_seed_test_ext_mifid2_hedge_report_csv
USING CSV
OPTIONS (
  path '{{hedge_csv_location}}',
  header 'true',
  inferSchema 'false',
  mode 'PERMISSIVE'
);
*/

-- -----------------------------------------------------------------------------
-- 2) Seed test Delta tables (temporary staging test assets)
-- DDL contracts align with module scaffolding:
--   databricks/sql/08_outputs/09_mifid2_npd_trax_scaffolding.sql
--   databricks/sql/08_outputs/08_mifid2_hedge_report_scaffolding.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_npd_trax (
  ReportDate DATE NOT NULL,
  CID INT NOT NULL,
  ReportTypeID INT NOT NULL,
  Entity STRING NOT NULL,
  RegulationID INT,
  AccountTypeID INT,
  IDType INT,
  OrigPINType STRING,
  PIN STRING,
  NotAllowedCONCAT BOOLEAN,
  MessageID STRING,
  Action STRING,
  InternalCode STRING,
  ExpiryDate STRING,
  EffectiveFromDate STRING,
  ExecutingEntity STRING,
  CountryofBranch STRING,
  LEI STRING,
  LEIType STRING,
  NaturalPersonType STRING,
  BusinessUnit STRING,
  ContactEmail STRING,
  ParentOfCollectiveInvestmentSchemeStatus STRING,
  CountryofNationality STRING,
  PassportNumber STRING,
  NationalID STRING,
  CONCAT STRING,
  FirstNames STRING,
  Surnames STRING,
  DateofBirth STRING,
  AcceptedTRAX BOOLEAN,
  ErrorColumn STRING,
  ErrorDescription STRING,
  FailedSinceDate DATE,
  DateFixedTRAX TIMESTAMP,
  RowNum INT,
  TraxAccount STRING,
  NonLatinOrEmptyName BOOLEAN,
  UpdateDate TIMESTAMP
)
USING DELTA
LOCATION '{{seed_delta_location_npd}}';

CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report (
  DateID INT,
  ReportDate DATE,
  HedgeServerID INT,
  LiquidityProvider STRING,
  ExecutionID INT,
  InstrumentID INT,
  BuyORSell INT,
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
  RecordID INT,
  RegulationReportID INT,
  AssetClass STRING,
  LiquidityAccountID INT,
  rowSource STRING,
  BackReportingIndicator SMALLINT,
  EMSOrderID STRING
)
USING DELTA
LOCATION '{{seed_delta_location_hedge}}';
*/

-- -----------------------------------------------------------------------------
-- 3) Post-create checklist (documentation only)
-- -----------------------------------------------------------------------------
SELECT
  'seed_testing_ddl_gate' AS gate_name,
  'pending' AS gate_status,
  'Uncomment DDL only after approved secure CSV/Delta LOCATION paths and PII review.' AS gate_reason
UNION ALL
SELECT
  'seed_testing_no_main_regtech_writes',
  'required',
  'All seed test objects must remain in main.regtech_ops_stg only.'
UNION ALL
SELECT
  'seed_testing_no_git_csv',
  'required',
  'CSV seed files must not be committed to Git.';
