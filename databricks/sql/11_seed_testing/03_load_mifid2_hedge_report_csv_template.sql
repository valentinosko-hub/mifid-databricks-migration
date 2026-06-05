-- Step 11: MIFID2_Hedge_Report manual CSV seed load template (GATED/COMMENTED).
--
-- Target (temporary staging test asset):
--   main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
--
-- Source:
--   Approved secure CSV with header at {{hedge_csv_location}}
--   External table: bi_output_regtechops_seed_test_ext_mifid2_hedge_report_csv (from 01_*)
--
-- Rules:
-- - Staging-only. No writes to main.regtech.
-- - Preserve RecordID values exactly from SQL Server export (no re-sequence on load).
-- - CSV files must not be committed to Git.
-- - Final Step 14 bi_output_regtechops_mifid2_hedge_report activation remains GATED.
--
-- Validation after load: 04_manual_seed_validation.sql (SELECT-only)
--
-- DO NOT UNCOMMENT UNTIL: 01_* DDL executed, export manifest row count recorded, RecordID range validated.

-- -----------------------------------------------------------------------------
-- 0) Run parameters (replace before load)
-- -----------------------------------------------------------------------------
-- {{sql_server_hedge_export_row_count}} = integer from SQL Server export manifest
-- Reference observed range: RecordID min 100253434, max 136314953 (evidence outside repo)

-- -----------------------------------------------------------------------------
-- 1) Schema validation gate (run SELECT-only before load — optional pre-check)
-- -----------------------------------------------------------------------------
/*
SELECT column_name, data_type
FROM system.information_schema.columns
WHERE table_catalog = 'main'
  AND table_schema = 'regtech_ops_stg'
  AND table_name = 'bi_output_regtechops_seed_test_ext_mifid2_hedge_report_csv'
ORDER BY ordinal_position;
*/

-- -----------------------------------------------------------------------------
-- 2) COPY INTO seed test table (preferred for large CSV; use chunked exports if needed)
-- -----------------------------------------------------------------------------
/*
COPY INTO main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
FROM '{{hedge_csv_location}}'
FILEFORMAT = CSV
FORMAT_OPTIONS (
  'header' = 'true',
  'inferSchema' = 'false'
)
COPY_OPTIONS (
  'mergeSchema' = 'false'
);
*/

-- -----------------------------------------------------------------------------
-- 3) Alternative: INSERT from external CSV table (explicit cast; preserves RecordID)
-- -----------------------------------------------------------------------------
/*
INSERT OVERWRITE main.regtech_ops_stg.bi_output_regtechops_seed_test_mifid2_hedge_report
SELECT
  CAST(DateID AS INT) AS DateID,
  CAST(ReportDate AS DATE) AS ReportDate,
  CAST(HedgeServerID AS INT) AS HedgeServerID,
  CAST(LiquidityProvider AS STRING) AS LiquidityProvider,
  CAST(ExecutionID AS INT) AS ExecutionID,
  CAST(InstrumentID AS INT) AS InstrumentID,
  CAST(BuyORSell AS INT) AS BuyORSell,
  CAST(ReportStatus AS STRING) AS ReportStatus,
  CAST(TransactionReferenceNumber AS STRING) AS TransactionReferenceNumber,
  CAST(TradingVenueTransactionIdentificationCode AS STRING) AS TradingVenueTransactionIdentificationCode,
  CAST(ExecutingEntityIdentificationCode AS STRING) AS ExecutingEntityIdentificationCode,
  CAST(InvestmentFirmCoveredBy201465EU AS STRING) AS InvestmentFirmCoveredBy201465EU,
  CAST(BuyerIdentificationCodeType AS STRING) AS BuyerIdentificationCodeType,
  CAST(BuyerNPCode AS STRING) AS BuyerNPCode,
  CAST(BuyerIdentificationCode AS STRING) AS BuyerIdentificationCode,
  CAST(BuyerCountryOfTheBranch AS STRING) AS BuyerCountryOfTheBranch,
  CAST(BuyerFirstNames AS STRING) AS BuyerFirstNames,
  CAST(BuyerSurnames AS STRING) AS BuyerSurnames,
  CAST(BuyerDateOfBirth AS STRING) AS BuyerDateOfBirth,
  CAST(BuyerDecisionMakerCodeType AS STRING) AS BuyerDecisionMakerCodeType,
  CAST(BuyerDecisionMakerNPCode AS STRING) AS BuyerDecisionMakerNPCode,
  CAST(BuyerDecisionMakerCode AS STRING) AS BuyerDecisionMakerCode,
  CAST(BuyerDecisionMakerFirstNames AS STRING) AS BuyerDecisionMakerFirstNames,
  CAST(BuyerDecisionMakerSurnames AS STRING) AS BuyerDecisionMakerSurnames,
  CAST(BuyerDecisionMakerDateOfBirth AS STRING) AS BuyerDecisionMakerDateOfBirth,
  CAST(SellerIdentificationCodeType AS STRING) AS SellerIdentificationCodeType,
  CAST(SellerNPCode AS STRING) AS SellerNPCode,
  CAST(SellerIdentificationCode AS STRING) AS SellerIdentificationCode,
  CAST(SellerCountryOfTheBranch AS STRING) AS SellerCountryOfTheBranch,
  CAST(SellerFirstNames AS STRING) AS SellerFirstNames,
  CAST(SellerSurnames AS STRING) AS SellerSurnames,
  CAST(SellerDateOfBirth AS STRING) AS SellerDateOfBirth,
  CAST(SellerDecisionMakerCodeType AS STRING) AS SellerDecisionMakerCodeType,
  CAST(SellerDecisionMakerNPCode AS STRING) AS SellerDecisionMakerNPCode,
  CAST(SellerDecisionMakerCode AS STRING) AS SellerDecisionMakerCode,
  CAST(SellerDecisionMakerFirstNames AS STRING) AS SellerDecisionMakerFirstNames,
  CAST(SellerDecisionMakerSurnames AS STRING) AS SellerDecisionMakerSurnames,
  CAST(SellerDecisionMakerDateOfBirth AS STRING) AS SellerDecisionMakerDateOfBirth,
  CAST(TransmissionOfOrderIndicator AS STRING) AS TransmissionOfOrderIndicator,
  CAST(TransmittingFirmIdentificationCodeForTheBuyer AS STRING) AS TransmittingFirmIdentificationCodeForTheBuyer,
  CAST(TransmittingFirmIdentificationCodeForTheSeller AS STRING) AS TransmittingFirmIdentificationCodeForTheSeller,
  CAST(TradingDateTime AS STRING) AS TradingDateTime,
  CAST(TradingCapacity AS STRING) AS TradingCapacity,
  CAST(QuantityType AS STRING) AS QuantityType,
  CAST(Quantity AS STRING) AS Quantity,
  CAST(QuantityCurrency AS STRING) AS QuantityCurrency,
  CAST(DerivativeNotionalIncreaseDecrease AS STRING) AS DerivativeNotionalIncreaseDecrease,
  CAST(PriceType AS STRING) AS PriceType,
  CAST(Price AS STRING) AS Price,
  CAST(PriceCurrency AS STRING) AS PriceCurrency,
  CAST(NetAmount AS STRING) AS NetAmount,
  CAST(Venue AS STRING) AS Venue,
  CAST(CountryOfTheBranchMembership AS STRING) AS CountryOfTheBranchMembership,
  CAST(UpfrontPayment AS STRING) AS UpfrontPayment,
  CAST(UpfrontPaymentCurrency AS STRING) AS UpfrontPaymentCurrency,
  CAST(ComplexTradeComponentId AS STRING) AS ComplexTradeComponentId,
  CAST(InstrumentIdentificationCode AS STRING) AS InstrumentIdentificationCode,
  CAST(InstrumentFullName AS STRING) AS InstrumentFullName,
  CAST(InstrumentClassification AS STRING) AS InstrumentClassification,
  CAST(NotionalCurrency1 AS STRING) AS NotionalCurrency1,
  CAST(NotionalCurrency2 AS STRING) AS NotionalCurrency2,
  CAST(PriceMultiplier AS STRING) AS PriceMultiplier,
  CAST(UnderlyingInstrumentCode AS STRING) AS UnderlyingInstrumentCode,
  CAST(UnderlyingIndexName AS STRING) AS UnderlyingIndexName,
  CAST(TermOfTheUnderlyingIndex AS STRING) AS TermOfTheUnderlyingIndex,
  CAST(OptionType AS STRING) AS OptionType,
  CAST(StrikePriceType AS STRING) AS StrikePriceType,
  CAST(StrikePrice AS STRING) AS StrikePrice,
  CAST(StrikePriceCurrency AS STRING) AS StrikePriceCurrency,
  CAST(OptionExerciseStyle AS STRING) AS OptionExerciseStyle,
  CAST(MaturityDate AS STRING) AS MaturityDate,
  CAST(ExpiryDate AS STRING) AS ExpiryDate,
  CAST(DeliveryType AS STRING) AS DeliveryType,
  CAST(InvestmentDecisionWithinFirmType AS STRING) AS InvestmentDecisionWithinFirmType,
  CAST(InvestmentDecisionWithinFirmNPCode AS STRING) AS InvestmentDecisionWithinFirmNPCode,
  CAST(InvestmentDecisionWithinFirm AS STRING) AS InvestmentDecisionWithinFirm,
  CAST(CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision AS STRING) AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
  CAST(ExecutionWithinFirmType AS STRING) AS ExecutionWithinFirmType,
  CAST(ExecutionWithinFirmNPCode AS STRING) AS ExecutionWithinFirmNPCode,
  CAST(ExecutionWithinFirm AS STRING) AS ExecutionWithinFirm,
  CAST(CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution AS STRING) AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
  CAST(WaiverIndicator AS STRING) AS WaiverIndicator,
  CAST(ShortSellingIndicator AS STRING) AS ShortSellingIndicator,
  CAST(OTCPostTradeIndicator AS STRING) AS OTCPostTradeIndicator,
  CAST(CommodityDerivativeIndicator AS STRING) AS CommodityDerivativeIndicator,
  CAST(SecuritiesFinancingTransactionIndicator AS STRING) AS SecuritiesFinancingTransactionIndicator,
  CAST(BranchLocation AS STRING) AS BranchLocation,
  CAST(TransactionType AS STRING) AS TransactionType,
  CAST(LifecycleEvent AS STRING) AS LifecycleEvent,
  CAST(RecordID AS INT) AS RecordID,
  CAST(RegulationReportID AS INT) AS RegulationReportID,
  CAST(AssetClass AS STRING) AS AssetClass,
  CAST(LiquidityAccountID AS INT) AS LiquidityAccountID,
  CAST(rowSource AS STRING) AS rowSource,
  CAST(BackReportingIndicator AS SMALLINT) AS BackReportingIndicator,
  CAST(EMSOrderID AS STRING) AS EMSOrderID
FROM main.regtech_ops_stg.bi_output_regtechops_seed_test_ext_mifid2_hedge_report_csv;
*/

-- -----------------------------------------------------------------------------
-- 4) Post-load validation requirements (run 04_manual_seed_validation.sql)
-- -----------------------------------------------------------------------------
-- Required checks:
-- - Row count vs {{sql_server_hedge_export_row_count}}
-- - Duplicate RecordID — expect 0
-- - Duplicate business key (ReportDate, RegulationReportID, TransactionReferenceNumber) — expect 0
-- - RecordID min/max vs SQL Server observed range
--
-- Final Hedge activation remains gated: RecordID registry, TRN exact parity, MAG-12/13.

SELECT
  'hedge_seed_load_gate' AS gate_name,
  'pending' AS gate_status,
  'Uncomment load SQL only after secure CSV path approval and DDL from 01_* is in place.' AS gate_reason
UNION ALL
SELECT
  'hedge_recordid_preserve_gate',
  'required',
  'Load must preserve SQL Server RecordID values exactly; no regeneration on seed test load.'
UNION ALL
SELECT
  'hedge_final_activation_gate',
  'pending',
  'Seed test load does not close final MIFID2_Hedge_Report activation gates.';
