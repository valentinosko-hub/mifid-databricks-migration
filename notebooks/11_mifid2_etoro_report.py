# Databricks notebook source
# DBTITLE 1,MIFID2 ETORO Report
# MAGIC %md
# MAGIC # 11 — MIFID2 ETORO Report
# MAGIC
# MAGIC Migration of `SP_MIFID2_ETORO_Report` from SSMS to Databricks.
# MAGIC
# MAGIC **Source:** `main.regtech.gold_regreportdb_prod_dbo_asic_transactions` (mirrored from SSMS `dbo.ASIC_Transactions`)
# MAGIC
# MAGIC **Target:** `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
# MAGIC
# MAGIC **Logic:** Reads ASIC transactions for a given date, joins with instrument metadata (SCD + currency + full description), applies instrument classification (CASE by InstrumentTypeID), buyer/seller LEI assignment, and exclusion filters. Output is MiFID-formatted trade report for ASIC-regulated positions.
# MAGIC
# MAGIC **Validation:** Compare row count against `main.regtech.gold_regreportdb_prod_dbo_mifid2_etoro_report` for same date.
# MAGIC
# MAGIC **IsMifid filter:** Uses `main.regtech.gold_regreportdb_prod_dbo_reg_instruments_scd` (production SCD mirror) which has the original `IsMifid` column. Do NOT use `gold_regtech_reg_instruments_scd` (only has IsMifidByESMA/IsMifidByFCA which don't match the SP semantics).
# MAGIC
# MAGIC **Validated:** 5,427 / 5,427 rows (0.00% diff vs gold mirror for 2026-06-04)

# COMMAND ----------

# DBTITLE 1,Parameters
dbutils.widgets.text("report_date", "2026-06-04", "Report Date (YYYY-MM-DD)")
report_date = dbutils.widgets.get("report_date")
print(f"MIFID2 ETORO Report - report_date = {report_date}")

# COMMAND ----------

# DBTITLE 1,Generate and persist MIFID2_ETORO_Report
spark.sql(f"""
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report
USING DELTA
LOCATION 'abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/mifid2_etoro_report'
AS
WITH instruments_full_desc AS (
  SELECT IndexNameFullDescription, InstrumentID
  FROM (
    SELECT IndexNameFullDescription, InstrumentID, ReportDate,
           MAX(ReportDate) OVER () AS mx_ReportDate
    FROM main.regtech.gold_regtech_reg_instruments_full_description
  ) m
  WHERE ReportDate = mx_ReportDate
),
metadata AS (
  SELECT
    SCD.InstrumentID,
    SCD.InstrumentTypeID,
    SCD.BuyCurrencyID,
    SCD.SellCurrencyID,
    SCD.ISINCode,
    FD.IndexNameFullDescription,
    REPLACE(SCD.InstrumentDisplayName, ',', ' ') AS InstrumentFullName,
    CASE WHEN SCD.SellCurrencyID = 666 THEN 1 ELSE 0 END AS IsGBX,
    CASE
      WHEN SCD.SellCurrencyID = 666 THEN REPLACE(DC1.Abbreviation, 'GBX', 'GBP')
      WHEN SCD.SellCurrencyID = 38 THEN REPLACE(DC1.Abbreviation, 'CNH', 'CNY')
      ELSE DC1.Abbreviation
    END AS SellAbbreviation,
    DC.Abbreviation AS BuyAbbreviation
  FROM main.regtech.gold_regreportdb_prod_dbo_reg_instruments_scd SCD
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency DC
    ON DC.CurrencyID = SCD.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency DC1
    ON DC1.CurrencyID = SCD.SellCurrencyID
  LEFT JOIN instruments_full_desc FD
    ON FD.InstrumentID = SCD.InstrumentID
  WHERE SCD.Tradable = true
    AND SCD.IsMifid = 1
    AND CAST(SCD.ValidFrom AS DATE) <= CAST('{report_date}' AS DATE)
    AND SCD.ValidTo > CAST('{report_date}' AS DATE)
)
SELECT
  1 AS RegulationReportID,
  T.DateID,
  CAST(T.ReportDate AS DATE) AS ReportDate,
  T.CID,
  1 AS RegulationID,
  T.PositionID,
  T.InstrumentID,
  T.OpenORClose,
  CAST(T.IsBuy AS INT) AS BuyORSell,
  CAST(NULL AS INT) AS IDType,
  0 AS IsCopy,
  CAST(NULL AS INT) AS CopyFund,
  CAST(NULL AS INT) AS FundTypeID,
  'NEWT' AS ReportStatus,
  CAST(T.PositionID AS STRING) || T.OpenORClose || 'AUS' || CAST(T.DateID AS STRING) AS TransactionReferenceNumber,
  '' AS TradingVenueTransactionIdentificationCode,
  '213800GIFQMSV7HROS23' AS ExecutingEntityIdentificationCode,
  'TRUE' AS InvestmentFirmCoveredBy201465EU,
  'LEI' AS BuyerIdentificationCodeType,
  '' AS BuyerNPCode,
  CASE WHEN T.IsBuy = '1' THEN '549300OK2V4QF20B0D04' ELSE '213800GIFQMSV7HROS23' END AS BuyerIdentificationCode,
  CASE WHEN T.IsBuy = '1' THEN 'CY' ELSE '' END AS BuyerCountryOfTheBranch,
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
  CASE WHEN T.IsBuy = '1' THEN '213800GIFQMSV7HROS23' ELSE '549300OK2V4QF20B0D04' END AS SellerIdentificationCode,
  CASE WHEN T.IsBuy = '1' THEN '' ELSE 'CY' END AS SellerCountryOfTheBranch,
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
  REPLACE(LEFT(T.OpenTime, 19), ' ', 'T') || 'Z' AS TradingDateTime,
  'DEAL' AS TradingCapacity,
  'UNIT' AS QuantityType,
  T.Volume AS Quantity,
  '' AS QuantityCurrency,
  '' AS DerivativeNotionalIncreaseDecrease,
  CASE WHEN CTP.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
  T.OpenPrice AS Price,
  SUBSTRING(M.SellAbbreviation, 1, 3) AS PriceCurrency,
  '' AS NetAmount,
  'XXXX' AS Venue,
  '' AS CountryOfTheBranchMembership,
  '' AS UpfrontPayment,
  '' AS UpfrontPaymentCurrency,
  '' AS ComplexTradeComponentId,
  '' AS InstrumentIdentificationCode,
  LEFT(M.InstrumentFullName, 50) || ' CFD' AS InstrumentFullName,
  CASE
    WHEN M.InstrumentTypeID = 1 THEN 'JFTXCC'
    WHEN M.InstrumentTypeID = 2 AND T.InstrumentID IN (92,93,96,331,332,334,337,338,311,317,318,324,325,381,382,422) THEN 'JTAXCC'
    WHEN M.InstrumentTypeID = 2 AND T.InstrumentID IN (17,22,335,336,341,300,299,298,297,296,295,294,293,292,291,290,289,288,287,286,285,284,283,282,281,280,279,278,277,276,319,116,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,95,481,482,484,485,486,487,489,490,491,502,510,524,613,614,615,616,617,618,619,620,621,622,623,628,629,630,631,632,633,634,635,636,637,638,379,387,388,389) THEN 'JTJXCC'
    WHEN M.InstrumentTypeID = 2 AND T.InstrumentID IN (18,19,21,40,91,99,100,339,340,343,344,380) THEN 'JTKXCC'
    WHEN M.InstrumentTypeID = 2 AND T.InstrumentID NOT IN (92,93,96,97,331,332,334,337,338,17,22,333,335,336,341,18,19,21,40,91,99,100,339,340,344) THEN 'JTMXCC'
    WHEN M.InstrumentTypeID = 4 AND T.InstrumentID NOT IN (312,313,314) THEN 'JEIXCC'
    WHEN M.InstrumentTypeID IN (5,6) THEN 'JESXCC'
    WHEN M.InstrumentTypeID IN (10,2) THEN 'JTMXCC'
    WHEN T.InstrumentID IN (312,313,314) THEN 'FFDCSX'
  END AS InstrumentClassification,
  SUBSTRING(M.SellAbbreviation, 1, 3) AS NotionalCurrency1,
  '' AS NotionalCurrency2,
  1 AS PriceMultiplier,
  COALESCE(M.ISINCode, '') AS UnderlyingInstrumentCode,
  CASE
    WHEN M.InstrumentID IN (312,313,314) THEN ''
    WHEN M.InstrumentTypeID = 4 AND M.IndexNameFullDescription IS NOT NULL THEN M.IndexNameFullDescription
    WHEN M.InstrumentTypeID = 4 AND M.IndexNameFullDescription IS NULL THEN COALESCE(LEFT(M.InstrumentFullName, 50), '')
    ELSE ''
  END AS UnderlyingIndexName,
  CASE
    WHEN M.InstrumentID = 26 THEN '1MNTH'
    WHEN M.InstrumentID IN (225000,225001,225002,225003,225004,225005,225006,225007,225008,225009,225010,225011,225012,225013,225014,225015,225016) THEN '10YEAR'
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
  CASE WHEN M.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
  'false' AS SecuritiesFinancingTransactionIndicator,
  '' AS BranchLocation,
  '' AS TransactionType,
  '' AS LifecycleEvent,
  CASE WHEN CTP.CurrencyTypeID IN (4,5,6) THEN 'Equity' ELSE CTP.Name END AS AssetClass,
  0 AS IsRealStockETF,
  current_timestamp() AS UpdateDate,
  0 AS BackReportingIndicator,
  T.RegChange
FROM main.regtech.gold_regreportdb_prod_dbo_asic_transactions T
JOIN metadata M ON T.InstrumentID = M.InstrumentID
JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype CTP
  ON CTP.CurrencyTypeID = M.InstrumentTypeID
LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids f
  ON f.cid = T.CID
WHERE f.cid IS NULL
  AND CAST(T.ReportDate AS DATE) = CAST('{report_date}' AS DATE)
  AND T.InstrumentID NOT IN (
    SELECT COALESCE(instrument_id, 0)
    FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
    WHERE table_name = '[MIFID2_ETORO_Report]'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids b
    WHERE CAST(T.PositionID AS STRING) = CAST(b.position_id AS STRING)
      AND b.table_name = '[MIFID2_ETORO_Report]'
  )
""")

row_count = spark.sql("SELECT COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report").collect()[0][0]
print(f"\n✅ MIFID2_ETORO_Report created: {row_count:,} rows for {report_date}")

# COMMAND ----------

# DBTITLE 1,Validation: Compare vs gold mirror
# MAGIC %sql
# MAGIC SELECT
# MAGIC   'mifid2_etoro_report' AS table_name,
# MAGIC   (SELECT COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report) AS dbx_count,
# MAGIC   (SELECT COUNT(*) FROM main.regtech.gold_regreportdb_prod_dbo_mifid2_etoro_report
# MAGIC    WHERE CAST(ReportDate AS DATE) = CAST(getArgument('report_date') AS DATE)) AS gold_count,
# MAGIC   (SELECT COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report) -
# MAGIC   (SELECT COUNT(*) FROM main.regtech.gold_regreportdb_prod_dbo_mifid2_etoro_report
# MAGIC    WHERE CAST(ReportDate AS DATE) = CAST(getArgument('report_date') AS DATE)) AS diff
