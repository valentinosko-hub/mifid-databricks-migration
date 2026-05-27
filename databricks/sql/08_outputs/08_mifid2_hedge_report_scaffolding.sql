-- Step 14B1: MIFID2_Hedge_Report scaffolding/output contract/dependency gates only.
--
-- In scope (Step 14B1):
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
--
-- Out of scope (do not implement here):
--   actual EU branch projection
--   actual EU-UK branch projection
--   actual UK branch projection
--   final DELETE/INSERT load logic
--   final RecordID generation implementation
--   MIFID2_NPD_TRAX
--   file delivery/export/upload/response/deployment
--
-- SQL Server authorities:
--   reference/.../core_mifid/SP_MIFID_HedgeEU_Report.sql
--   reference/.../core_mifid/SP_MIFID_HedgeUK_Report.sql
--   reference/.../target_output_tables/MIFID2_Hedge_Report.sql
--
-- Important behavior notes:
-- - SQL Server target includes RecordID INT IDENTITY(100000001,1).
-- - Do not introduce non-deterministic identity behavior for Step 14B1.
-- - Exclusion rows with table_name='[MIFID2_Hedge_Report]' are row-level report-scoped filters.
--   They do not mean "suppress all Hedge rows".

-- -----------------------------------------------------------------------------
-- 0) Report-date parameter + source map + gate checklist (no side effects)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
target_object AS (
  SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report' AS target_object
),
branch_contract AS (
  SELECT *
  FROM VALUES
    ('EU',    'SP_MIFID_HedgeEU_Report', 'ExecutionFlow = ''EU''',               1, 'EU'),
    ('EU-UK', 'SP_MIFID_HedgeEU_Report', 'ExecutionFlow = ''UK'' AND IsReal = 1', 1, 'EU-UK'),
    ('UK',    'SP_MIFID_HedgeUK_Report', 'UK hedge rows from Reg_Ext_HedgeExecutionLog', 2, 'UK')
  AS t(branch_name, sql_server_procedure, branch_filter_summary, regulationreportid, rowsource_value)
),
direct_dependencies AS (
  SELECT *
  FROM VALUES
    ('EU direct input', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog'),
    ('EU direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid'),
    ('EU direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd'),
    ('UK direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog'),
    ('UK direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog'),
    ('UK direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid'),
    ('UK direct input', 'main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd'),
    ('shared instrument/dictionary', 'main.regtech.gold_regtech_reg_instruments_scd'),
    ('shared instrument/dictionary', 'main.regtech.gold_regtech_reg_instruments_full_description'),
    ('shared instrument/dictionary', 'main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion'),
    ('shared instrument/dictionary', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency'),
    ('shared instrument/dictionary', 'main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype'),
    ('EDNF/IB/LP enrichment', 'main.general.gold_ednf_coretrades'),
    ('EDNF/IB/LP enrichment', 'main.general.gold_ib_u1059976_open_positions_all'),
    ('EDNF/IB/LP enrichment', 'main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro'),
    ('EDNF/IB/LP enrichment', 'main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid'),
    ('exclusion input', 'main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments'),
    ('exclusion input', 'main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids')
  AS t(dependency_group, dependency_object)
),
gate_status AS (
  SELECT
    'step14_eu_source_activation' AS gate_name,
    'pending' AS gate_status,
    'MIFID2_ext_HedgeExecutionLog + liquidity-account/SCD joins must be profile-validated for EU path.' AS gate_reason
  UNION ALL
  SELECT
    'step14_uk_source_activation',
    'pending',
    'Reg_Ext_HedgeExecutionLog + Reg_Ext_HedgeHBCOrderLog + liquidity-account/SCD joins must be profile-validated for UK path.'
  UNION ALL
  SELECT
    'step14_branch_filters_eu',
    'pending',
    'EU path must preserve Units>0, Success=1, ExecutionTime day-window, ExecutionFlow branching, and MiFID eligibility joins.'
  UNION ALL
  SELECT
    'step14_branch_filters_uk',
    'pending',
    'UK path must preserve Units>0, EMSOrderID IS NULL, Success=1, ExecutionTime day-window, LP.eToroEntity UK, and IsMifidByFCA=1.'
  UNION ALL
  SELECT
    'step14_transaction_reference_parity',
    'pending',
    'TransactionReferenceNumber logic (normalized ProviderExecID + RowID + StartDate with LP/date/RowID fallback) must be ported exactly.'
  UNION ALL
  SELECT
    'step14_exclusion_scope_semantics',
    'pending',
    'Exclusion rows with table_name=[MIFID2_Hedge_Report] must be treated as row-level report-scoped filters only.'
  UNION ALL
  SELECT
    'step14_recordid_strategy',
    'pending',
    'RecordID INT IDENTITY(100000001,1) requires explicit deterministic strategy or approved placeholder behavior before activation.'
  UNION ALL
  SELECT
    'step14_instrument_dictionary_coverage',
    'pending',
    'Reg instrument and dictionary dependencies must be report-date complete for both branches.'
  UNION ALL
  SELECT
    'step14_ednf_ib_mapping_coverage',
    'pending',
    'EDNF/IB joins and mapping tables must prove coverage for hedge instruments and LP-driven metadata.'
  UNION ALL
  SELECT
    'step14_lei_liquidity_coverage',
    'pending',
    'LiquidityAccountID-to-LEI coverage and SCD validity windows must be complete for report-date execution.'
)
SELECT
  rp.report_date,
  o.target_object,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_parameters rp
CROSS JOIN target_object o
CROSS JOIN gate_status g
ORDER BY g.gate_name;

SELECT
  dependency_group,
  dependency_object
FROM direct_dependencies
ORDER BY dependency_group, dependency_object;

SELECT
  branch_name,
  sql_server_procedure,
  branch_filter_summary,
  regulationreportid,
  rowsource_value
FROM branch_contract
ORDER BY branch_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- DDL contract source:
--   reference/.../target_output_tables/MIFID2_Hedge_Report.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report (
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
USING DELTA;
*/

-- SQL Server uniqueness intent from AK_UniqueTransaction:
--   (ReportDate, RegulationReportID, TransactionReferenceNumber)
-- Validate through Step 14B4 duplicate checks (do not translate SQL Server indexes directly).

-- -----------------------------------------------------------------------------
-- 2) RecordID strategy checklist (Step 14B1 documentation gate only)
-- -----------------------------------------------------------------------------
-- Approved strategy options to carry into Step 14B2/14B3:
-- - deterministic row_number() over a stable branch/order key + 100000000
-- - nullable/placeholder RecordID in gated template outputs
-- - explicitly accepted non-parity identity behavior (only with later approval)
-- Step 14B1 keeps RecordID unresolved and non-executable.

-- -----------------------------------------------------------------------------
-- 3) Step 14B2 TODO anchors (source preparation / branch source CTEs only)
-- -----------------------------------------------------------------------------
-- TODO (Step 14B2 only):
-- - Build source CTEs for:
--   * EU direct branch candidates (ExecutionFlow='EU')
--   * EU-reportable real-stock rows via UK flow (ExecutionFlow='UK' and IsReal=1)
--   * UK branch candidates from Reg_Ext_HedgeExecutionLog with HBC order enrichment
-- - Port day-window and quality filters:
--   * Units > 0
--   * Success = 1
--   * ExecutionTime >= {{report_date}} and < {{report_date}} + 1 day
--   * UK-only EMSOrderID IS NULL and LP.eToroEntity filter
-- - Prepare normalized ProviderExecID and RowID scaffolding for transaction-reference parity.

-- -----------------------------------------------------------------------------
-- 4) Step 14B3 TODO anchors (final EU/UK projection only)
-- -----------------------------------------------------------------------------
-- TODO (Step 14B3 only):
-- - Implement final projection for rowSource values:
--   * EU (RegulationReportID=1)
--   * EU-UK (RegulationReportID=1)
--   * UK (RegulationReportID=2)
-- - Implement final TransactionReferenceNumber parity logic.
-- - Implement exclusion filters scoped by table_name='[MIFID2_Hedge_Report]'.
-- - Implement approved RecordID strategy.
-- - Keep final DELETE/INSERT activation gated until dependencies are approved.

-- -----------------------------------------------------------------------------
-- 5) Step 14B4 TODO anchors (validation/reconciliation only)
-- -----------------------------------------------------------------------------
-- TODO (Step 14B4 only):
-- - Schema parity checks (including RecordID behavior acceptance).
-- - Row counts by ReportDate and RegulationReportID.
-- - Duplicate checks on TransactionReferenceNumber business key.
-- - Required-null checks and aggregate quantity/price checks.
-- - Source-to-output reconciliation (EU/EU-UK/UK branch evidence).
-- - EDNF/IB join coverage checks and liquidity-account/LEI coverage checks.
-- - Report-scoped exclusion behavior checks for instruments and position keys.

-- -----------------------------------------------------------------------------
-- 6) COMMENTED EXECUTION TEMPLATE ONLY - DO NOT RUN UNTIL ALL GATES PASS.
-- -----------------------------------------------------------------------------
/*
-- Final report-date scoped load logic is intentionally deferred to Step 14B3.
-- DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
-- WHERE ReportDate = CAST('{{report_date}}' AS DATE);
--
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report (...)
-- SELECT ...
-- FROM ...
-- WHERE 1 = 0;
*/
