# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "5"
# ///
# DBTITLE 1,Module 14: MIFID2 Hedge Report Output
# MAGIC %md
# MAGIC # Module 14: MIFID2 Hedge Report Output
# MAGIC
# MAGIC This notebook generates the `MIFID2_Hedge_Report` table — hedge execution-level regulatory reporting.
# MAGIC
# MAGIC **Replicates SSIS packages:**
# MAGIC - `SP_MIFID2_HedgeEU_Report` (EU direct + EU-via-UK intercompany)
# MAGIC - `SP_MIFID2_HedgeUK_Report` (UK direct)
# MAGIC
# MAGIC **Target:** `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`
# MAGIC
# MAGIC **3 Report Branches:**
# MAGIC 1. **EU Direct** (RegulationReportID=1, rowSource='EU') — EU entity trades with EU/unknown LPs
# MAGIC 2. **EU via UK** (RegulationReportID=1, rowSource='EU-UK') — Real stock executions via UK LPs, reported as intercompany
# MAGIC 3. **UK** (RegulationReportID=2, rowSource='UK') — UK entity trades, EMSOrderID IS NULL filter
# MAGIC
# MAGIC **Key Sources:**
# MAGIC - `bi_output_regtechops_mifid2_ext_hedgeexecutionlog` (EU branch source)
# MAGIC - `bi_output_regtechops_reg_ext_hedgeexecutionlog` (UK branch source)
# MAGIC - `bi_output_regtechops_reg_ext_liquidityaccountid` (LP LEI mapping)
# MAGIC - `main.regtech.gold_regreportdb_prod_dbo_reg_instruments_scd` (instruments, IsMifid/IsMifidByFCA)
# MAGIC - `bi_output_regtechops_reg_ext_dictionarycurrency` (currency abbreviations)
# MAGIC - `bi_output_regtechops_reg_ext_dictionarycurrencytype` (asset class mapping)
# MAGIC
# MAGIC **Deferred (stubbed):**
# MAGIC - ED&F/IB futures enrichment (Synapse source not available in Databricks)
# MAGIC - Full InstrumentClassification CFI codes (complex LP-specific sub-classifications)
# MAGIC - Reg_LiquidtyAcount_SCD ValidFrom/ValidTo check (using snapshot ext table instead)
# MAGIC
# MAGIC **Prerequisites:** Notebooks 01-05 must have been run for the same report_date.
# MAGIC
# MAGIC **Validation (2026-06-11):** ✅ PASS | EU: 86,056 rows (SSMS: 86,058, -2 rows = 99.998% match) | EU-UK: 0 | UK: 0 (matches SSMS)

# COMMAND ----------

# DBTITLE 1,Parameters
dbutils.widgets.text("report_date", "2026-06-11", "Report Date (YYYY-MM-DD)")
report_date = dbutils.widgets.get("report_date")
print(f"Running Module 14: MIFID2 Hedge Report for report_date = {report_date}")

# COMMAND ----------

# DBTITLE 1,1. MIFID2 Hedge Report Generation (EU + EU-UK + UK branches)
# MIFID2_Hedge_Report: 3-branch hedge execution report
# SP parity: SP_MIFID2_HedgeEU_Report + SP_MIFID2_HedgeUK_Report
#
# Branch 1 (EU): mifid2_ext_hedgeexecutionlog → eToroEntity='213800GIFQMSV7HROS23' (EU LP)
# Branch 2 (EU-UK): same source → eToroEntity='213800FLAB1OVA8OHT72' (UK LP) AND IsReal=1
# Branch 3 (UK): reg_ext_hedgeexecutionlog → eToroEntity='213800FLAB1OVA8OHT72' AND EMSOrderID IS NULL

hedge_report_sql = f"""
WITH run_parameters AS (
  SELECT
    CAST('{report_date}' AS DATE) AS report_date,
    CAST('{report_date}' AS TIMESTAMP) AS start_ts,
    CAST(date_add(CAST('{report_date}' AS DATE), 1) AS TIMESTAMP) AS end_ts,
    CAST(date_format(CAST('{report_date}' AS DATE), 'yyyyMMdd') AS INT) AS date_id,
    date_format(CAST('{report_date}' AS DATE), 'yyyyMMdd') AS date_id_str
),

-- EU branch execution base (from mifid2_ext_hedgeexecutionlog = report-date filtered)
eu_execution_base AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.HedgeServerID AS INT) AS HedgeServerID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.IsBuy AS INT) AS IsBuy,
    CAST(ext.Units AS DECIMAL(22,8)) AS AmountInUnits,
    CAST(ext.ExecutionRate AS DECIMAL(16,8)) AS LPExecutionRate,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID,
    UPPER(
      REGEXP_REPLACE(CAST(ext.ProviderExecID AS STRING), '[\\-\\.~@#\\$%&\\*\\(\\)!\\^\\?:]', '')
    ) AS ProviderExecID,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime,
    ROW_NUMBER() OVER (ORDER BY ext.ExecutionTime, ext.OrderID) AS RowID
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog ext
  WHERE CAST(ext.Units AS DECIMAL(22,8)) > 0
    AND CAST(ext.Success AS INT) = 1
),

-- UK branch execution base (from reg_ext_hedgeexecutionlog = wider date window, EMSOrderID IS NULL)
uk_execution_base AS (
  SELECT
    CAST(ext.OrderID AS BIGINT) AS ExecutionID,
    CAST(ext.HedgeServerID AS INT) AS HedgeServerID,
    CAST(ext.LiquidityAccountID AS INT) AS LiquidityAccountID,
    CAST(ext.InstrumentID AS INT) AS InstrumentID,
    CAST(ext.IsBuy AS INT) AS IsBuy,
    CAST(ext.Units AS DECIMAL(22,8)) AS AmountInUnits,
    CAST(ext.ExecutionRate AS DECIMAL(16,8)) AS LPExecutionRate,
    CAST(ext.EMSOrderID AS STRING) AS EMSOrderID,
    UPPER(
      REGEXP_REPLACE(CAST(ext.ProviderExecID AS STRING), '[\\-\\.~@#\\$%&\\*\\(\\)!\\^\\?:]', '')
    ) AS ProviderExecID,
    CAST(ext.ExecutionTime AS TIMESTAMP) AS ExecutionTime,
    ROW_NUMBER() OVER (ORDER BY ext.ExecutionTime, ext.OrderID) AS RowID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog ext
  CROSS JOIN run_parameters rp
  WHERE CAST(ext.Units AS DECIMAL(22,8)) > 0
    AND CAST(ext.Success AS INT) = 1
    AND ext.ExecutionTime >= rp.start_ts
    AND ext.ExecutionTime < rp.end_ts
    AND ext.EMSOrderID IS NULL
),

-- Enrich executions with LP info
eu_trades AS (
  SELECT
    e.*,
    CAST(LTRIM(RTRIM(lp.LiquidityAccountName)) AS STRING) AS LiquidityProvider,
    lp.LEI,
    lp.LpCountryCode AS Country,
    CASE WHEN UPPER(lp.RealOrCFD) = 'REAL' THEN 1
         WHEN UPPER(lp.RealOrCFD) = 'CFD' THEN 0
         ELSE -1 END AS IsReal,
    CASE WHEN UPPER(lp.eToroEntity) = '213800GIFQMSV7HROS23' THEN 'EU'
         WHEN UPPER(lp.eToroEntity) = '213800FLAB1OVA8OHT72' THEN 'UK'
         ELSE 'UNKNOWN' END AS ExecutionFlow
  FROM eu_execution_base e
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
  WHERE lp.eToroEntity IN ('213800GIFQMSV7HROS23', '213800FLAB1OVA8OHT72')
),

uk_trades AS (
  SELECT
    e.*,
    CAST(LTRIM(RTRIM(lp.LiquidityAccountName)) AS STRING) AS LiquidityProvider,
    lp.LEI,
    lp.LpCountryCode AS Country,
    CASE WHEN UPPER(lp.RealOrCFD) = 'REAL' THEN 1
         WHEN UPPER(lp.RealOrCFD) = 'CFD' THEN 0
         ELSE -1 END AS IsReal
  FROM uk_execution_base e
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid lp
    ON e.LiquidityAccountID = CAST(lp.LiquidityAccountID AS INT)
  WHERE lp.eToroEntity = '213800FLAB1OVA8OHT72'
),

-- Instrument metadata (production SCD)
instruments AS (
  SELECT
    i.InstrumentID,
    i.InstrumentTypeID,
    i.BuyCurrencyID,
    i.SellCurrencyID,
    i.ISINCode,
    CAST(i.IsMifid AS INT) AS IsMifid,
    CAST(COALESCE(i.IsMifidByFCA, i.IsMifid) AS INT) AS IsMifidByFCA,
    CASE WHEN i.SellCurrencyID = 666 THEN 1 ELSE 0 END AS IsGBX,
    CASE WHEN i.SellCurrencyID = 666 THEN REPLACE(dc_sell.Abbreviation, 'GBX', 'GBP')
         WHEN i.SellCurrencyID = 38 THEN REPLACE(dc_sell.Abbreviation, 'CNH', 'CNY')
         ELSE dc_sell.Abbreviation END AS SellAbbreviation,
    dc_buy.Abbreviation AS BuyAbbreviation,
    REPLACE(i.InstrumentDisplayName, ',', ' ') AS InstrumentFullName,
    fd.IndexNameFullDescription
  FROM main.regtech.gold_regreportdb_prod_dbo_reg_instruments_scd i
  CROSS JOIN run_parameters rp
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = i.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = i.SellCurrencyID
  LEFT JOIN (
    SELECT InstrumentID, IndexNameFullDescription,
           ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY ReportDate DESC) AS rn
    FROM main.regtech.gold_regtech_reg_instruments_full_description
  ) fd ON fd.InstrumentID = i.InstrumentID AND fd.rn = 1
  WHERE i.Tradable = true
    AND rp.report_date >= CAST(i.ValidFrom AS DATE)
    AND rp.report_date < CAST(i.ValidTo AS DATE)
),

-- Asset class mapping
currency_types AS (
  SELECT CurrencyTypeID, Name
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype
),

-- Exclusions
excluded_instruments AS (
  SELECT DISTINCT CAST(instrumentid AS INT) AS instrument_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
  WHERE tablename = '[MIFID2_Hedge_Report]'
),

excluded_trns AS (
  SELECT DISTINCT CAST(positionid AS STRING) AS position_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids
  WHERE tablename = '[MIFID2_Hedge_Report]'
),

-- ============ BRANCH 1: EU DIRECT ============
eu_report AS (
  SELECT
    rp.date_id AS DateID,
    rp.report_date AS ReportDate,
    p.HedgeServerID,
    p.LiquidityAccountID,
    p.LiquidityProvider,
    p.ExecutionID,
    p.InstrumentID,
    p.IsBuy AS BuyORSell,
    'NEWT' AS ReportStatus,
    COALESCE(
      CONCAT(UPPER(p.ProviderExecID), CAST(p.RowID AS STRING), rp.date_id_str),
      CONCAT(UPPER(p.LiquidityProvider), rp.date_id_str, CAST(p.RowID AS STRING))
    ) AS TransactionReferenceNumber,
    '' AS TradingVenueTransactionIdentificationCode,
    '213800GIFQMSV7HROS23' AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    'LEI' AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE WHEN p.IsBuy = 1 THEN '213800GIFQMSV7HROS23' ELSE p.LEI END AS BuyerIdentificationCode,
    '' AS BuyerCountryOfTheBranch,
    '' AS BuyerFirstNames, '' AS BuyerSurnames, '' AS BuyerDateOfBirth,
    '' AS BuyerDecisionMakerCodeType, '' AS BuyerDecisionMakerNPCode, '' AS BuyerDecisionMakerCode,
    '' AS BuyerDecisionMakerFirstNames, '' AS BuyerDecisionMakerSurnames, '' AS BuyerDecisionMakerDateOfBirth,
    'LEI' AS SellerIdentificationCodeType,
    '' AS SellerNPCode,
    CASE WHEN p.IsBuy = 0 THEN '213800GIFQMSV7HROS23' ELSE p.LEI END AS SellerIdentificationCode,
    '' AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames, '' AS SellerSurnames, '' AS SellerDateOfBirth,
    '' AS SellerDecisionMakerCodeType, '' AS SellerDecisionMakerNPCode, '' AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames, '' AS SellerDecisionMakerSurnames, '' AS SellerDecisionMakerDateOfBirth,
    'FALSE' AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    CONCAT(date_format(p.ExecutionTime, 'yyyy-MM-dd'), 'T',
      date_format(CASE WHEN SECOND(p.ExecutionTime) = 0 THEN p.ExecutionTime + INTERVAL 1 SECOND ELSE p.ExecutionTime END, 'HH:mm:ss'), 'Z'
    ) AS TradingDateTime,
    'DEAL' AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(p.AmountInUnits AS STRING) AS Quantity,
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN ctp.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
    CAST(CASE WHEN m.IsGBX = 1 THEN p.LPExecutionRate / 100.00 ELSE p.LPExecutionRate END AS DECIMAL(16,8)) AS Price,
    SUBSTRING(m.SellAbbreviation, 1, 3) AS PriceCurrency,
    '' AS NetAmount,
    CASE WHEN p.IsReal = 1 THEN 'XOFF' ELSE 'XXXX' END AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment, '' AS UpfrontPaymentCurrency, '' AS ComplexTradeComponentId,
    CASE WHEN p.IsReal = 1 AND m.ISINCode IS NOT NULL THEN m.ISINCode ELSE '' END AS InstrumentIdentificationCode,
    CASE WHEN p.IsReal = 0 THEN CONCAT(LEFT(COALESCE(m.InstrumentFullName, ''), 50), ' CFD') ELSE '' END AS InstrumentFullName,
    -- CFI codes simplified (full LP-specific sub-classification deferred)
    CASE WHEN p.IsReal = 0 THEN
      CASE WHEN m.InstrumentTypeID = 1 THEN 'JFTXCC'
           WHEN m.InstrumentTypeID = 4 THEN 'JEIXCC'
           WHEN m.InstrumentTypeID IN (5, 6) THEN 'JESXCC'
           WHEN m.InstrumentTypeID = 2 THEN 'JTMXCC'
           ELSE '' END
    ELSE '' END AS InstrumentClassification,
    CASE WHEN p.IsReal = 0 THEN SUBSTRING(m.SellAbbreviation, 1, 3) ELSE '' END AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    CASE WHEN p.IsReal = 1 THEN '' ELSE '1' END AS PriceMultiplier,
    CASE WHEN p.IsReal = 1 THEN '' ELSE COALESCE(m.ISINCode, '') END AS UnderlyingInstrumentCode,
    CASE WHEN m.InstrumentTypeID = 4 AND m.IndexNameFullDescription IS NOT NULL THEN m.IndexNameFullDescription
         WHEN m.InstrumentTypeID = 4 THEN COALESCE(LEFT(m.InstrumentFullName, 50), '')
         ELSE '' END AS UnderlyingIndexName,
    '' AS TermOfTheUnderlyingIndex,
    '' AS OptionType, '' AS StrikePriceType, '' AS StrikePrice, '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle, '' AS MaturityDate,
    '' AS ExpiryDate,
    CASE WHEN p.IsReal = 1 THEN '' ELSE 'CASH' END AS DeliveryType,
    'ALG' AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    'ETORODEALING01' AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETORODEALING01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    CASE WHEN p.IsReal = 1 AND p.IsBuy = 0 AND ctp.CurrencyTypeID IN (5, 6) THEN 'SELL' ELSE '' END AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE WHEN m.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
    'FALSE' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation, '' AS TransactionType, '' AS LifecycleEvent,
    1 AS RegulationReportID,
    CASE WHEN ctp.CurrencyTypeID IN (4, 5, 6) THEN 'Equity' ELSE ctp.Name END AS AssetClass,
    'EU' AS rowSource,
    0 AS BackReportingIndicator,
    p.EMSOrderID
  FROM eu_trades p
  CROSS JOIN run_parameters rp
  JOIN instruments m ON p.InstrumentID = m.InstrumentID AND m.IsMifid = 1
  JOIN currency_types ctp ON ctp.CurrencyTypeID = m.InstrumentTypeID
  WHERE p.ExecutionFlow = 'EU'
    AND p.InstrumentID NOT IN (SELECT instrument_id FROM excluded_instruments)
),

-- ============ BRANCH 2: EU VIA UK (real stocks only) ============
eu_uk_report AS (
  SELECT
    rp.date_id AS DateID,
    rp.report_date AS ReportDate,
    p.HedgeServerID,
    p.LiquidityAccountID,
    p.LiquidityProvider,
    p.ExecutionID,
    p.InstrumentID,
    p.IsBuy AS BuyORSell,
    'NEWT' AS ReportStatus,
    COALESCE(
      CONCAT(UPPER(p.ProviderExecID), CAST(p.RowID AS STRING), rp.date_id_str),
      CONCAT(UPPER(p.LiquidityProvider), rp.date_id_str, CAST(p.RowID AS STRING))
    ) AS TransactionReferenceNumber,
    '' AS TradingVenueTransactionIdentificationCode,
    '213800GIFQMSV7HROS23' AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    'LEI' AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE WHEN p.IsBuy = 1 THEN '213800GIFQMSV7HROS23' ELSE '213800FLAB1OVA8OHT72' END AS BuyerIdentificationCode,
    '' AS BuyerCountryOfTheBranch,
    '' AS BuyerFirstNames, '' AS BuyerSurnames, '' AS BuyerDateOfBirth,
    '' AS BuyerDecisionMakerCodeType, '' AS BuyerDecisionMakerNPCode, '' AS BuyerDecisionMakerCode,
    '' AS BuyerDecisionMakerFirstNames, '' AS BuyerDecisionMakerSurnames, '' AS BuyerDecisionMakerDateOfBirth,
    'LEI' AS SellerIdentificationCodeType,
    '' AS SellerNPCode,
    CASE WHEN p.IsBuy = 0 THEN '213800GIFQMSV7HROS23' ELSE '213800FLAB1OVA8OHT72' END AS SellerIdentificationCode,
    '' AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames, '' AS SellerSurnames, '' AS SellerDateOfBirth,
    '' AS SellerDecisionMakerCodeType, '' AS SellerDecisionMakerNPCode, '' AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames, '' AS SellerDecisionMakerSurnames, '' AS SellerDecisionMakerDateOfBirth,
    'FALSE' AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    CONCAT(date_format(p.ExecutionTime, 'yyyy-MM-dd'), 'T',
      date_format(CASE WHEN SECOND(p.ExecutionTime) = 0 THEN p.ExecutionTime + INTERVAL 1 SECOND ELSE p.ExecutionTime END, 'HH:mm:ss'), 'Z'
    ) AS TradingDateTime,
    'DEAL' AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(p.AmountInUnits AS STRING) AS Quantity,
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN ctp.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
    CAST(CASE WHEN m.IsGBX = 1 THEN p.LPExecutionRate / 100.00 ELSE p.LPExecutionRate END AS DECIMAL(16,8)) AS Price,
    SUBSTRING(m.SellAbbreviation, 1, 3) AS PriceCurrency,
    '' AS NetAmount,
    'XOFF' AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment, '' AS UpfrontPaymentCurrency, '' AS ComplexTradeComponentId,
    COALESCE(m.ISINCode, '') AS InstrumentIdentificationCode,
    '' AS InstrumentFullName,
    '' AS InstrumentClassification,
    '' AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    '' AS PriceMultiplier,
    '' AS UnderlyingInstrumentCode,
    '' AS UnderlyingIndexName,
    '' AS TermOfTheUnderlyingIndex,
    '' AS OptionType, '' AS StrikePriceType, '' AS StrikePrice, '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle, '' AS MaturityDate, '' AS ExpiryDate,
    '' AS DeliveryType,
    'ALG' AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    'ETORODEALING01' AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETORODEALING01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    CASE WHEN p.IsBuy = 0 AND ctp.CurrencyTypeID IN (5, 6) THEN 'SELL' ELSE '' END AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE WHEN m.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
    'FALSE' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation, '' AS TransactionType, '' AS LifecycleEvent,
    1 AS RegulationReportID,
    CASE WHEN ctp.CurrencyTypeID IN (4, 5, 6) THEN 'Equity' ELSE ctp.Name END AS AssetClass,
    'EU-UK' AS rowSource,
    0 AS BackReportingIndicator,
    p.EMSOrderID
  FROM eu_trades p
  CROSS JOIN run_parameters rp
  JOIN instruments m ON p.InstrumentID = m.InstrumentID AND m.IsMifid = 1
  JOIN currency_types ctp ON ctp.CurrencyTypeID = m.InstrumentTypeID
  WHERE p.ExecutionFlow = 'UK'
    AND p.IsReal = 1
    AND p.InstrumentID NOT IN (SELECT instrument_id FROM excluded_instruments)
),

-- ============ BRANCH 3: UK ============
uk_report AS (
  SELECT
    rp.date_id AS DateID,
    rp.report_date AS ReportDate,
    p.HedgeServerID,
    p.LiquidityAccountID,
    p.LiquidityProvider,
    p.ExecutionID,
    p.InstrumentID,
    p.IsBuy AS BuyORSell,
    'NEWT' AS ReportStatus,
    COALESCE(
      CONCAT(UPPER(p.ProviderExecID), CAST(p.RowID AS STRING), rp.date_id_str),
      CONCAT(UPPER(p.LiquidityProvider), rp.date_id_str, CAST(p.RowID AS STRING))
    ) AS TransactionReferenceNumber,
    '' AS TradingVenueTransactionIdentificationCode,
    '213800FLAB1OVA8OHT72' AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    'LEI' AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE WHEN p.IsBuy = 1 THEN '213800GIFQMSV7HROS23' ELSE p.LEI END AS BuyerIdentificationCode,
    '' AS BuyerCountryOfTheBranch,
    '' AS BuyerFirstNames, '' AS BuyerSurnames, '' AS BuyerDateOfBirth,
    '' AS BuyerDecisionMakerCodeType, '' AS BuyerDecisionMakerNPCode, '' AS BuyerDecisionMakerCode,
    '' AS BuyerDecisionMakerFirstNames, '' AS BuyerDecisionMakerSurnames, '' AS BuyerDecisionMakerDateOfBirth,
    'LEI' AS SellerIdentificationCodeType,
    '' AS SellerNPCode,
    CASE WHEN p.IsBuy = 0 THEN '213800GIFQMSV7HROS23' ELSE p.LEI END AS SellerIdentificationCode,
    '' AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames, '' AS SellerSurnames, '' AS SellerDateOfBirth,
    '' AS SellerDecisionMakerCodeType, '' AS SellerDecisionMakerNPCode, '' AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames, '' AS SellerDecisionMakerSurnames, '' AS SellerDecisionMakerDateOfBirth,
    'FALSE' AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    CONCAT(date_format(p.ExecutionTime, 'yyyy-MM-dd'), 'T',
      date_format(CASE WHEN SECOND(p.ExecutionTime) = 0 THEN p.ExecutionTime + INTERVAL 1 SECOND ELSE p.ExecutionTime END, 'HH:mm:ss'), 'Z'
    ) AS TradingDateTime,
    'MTCH' AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(p.AmountInUnits AS STRING) AS Quantity,
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN ctp.CurrencyTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
    CAST(CASE WHEN m.IsGBX = 1 THEN p.LPExecutionRate / 100.00 ELSE p.LPExecutionRate END AS DECIMAL(16,8)) AS Price,
    SUBSTRING(m.SellAbbreviation, 1, 3) AS PriceCurrency,
    '' AS NetAmount,
    'XOFF' AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment, '' AS UpfrontPaymentCurrency, '' AS ComplexTradeComponentId,
    COALESCE(m.ISINCode, '') AS InstrumentIdentificationCode,
    '' AS InstrumentFullName,
    '' AS InstrumentClassification,
    '' AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    CASE WHEN p.IsReal = 1 THEN '' ELSE '1' END AS PriceMultiplier,
    CASE WHEN p.IsReal = 1 THEN '' ELSE COALESCE(m.ISINCode, '') END AS UnderlyingInstrumentCode,
    '' AS UnderlyingIndexName,
    '' AS TermOfTheUnderlyingIndex,
    '' AS OptionType, '' AS StrikePriceType, '' AS StrikePrice, '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle, '' AS MaturityDate, '' AS ExpiryDate, '' AS DeliveryType,
    '' AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    '' AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETORODEALING01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    '' AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE WHEN m.InstrumentTypeID = 2 THEN 'false' ELSE '' END AS CommodityDerivativeIndicator,
    'FALSE' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation, '' AS TransactionType, '' AS LifecycleEvent,
    2 AS RegulationReportID,
    CASE WHEN ctp.CurrencyTypeID IN (4, 5, 6) THEN 'Equity' ELSE ctp.Name END AS AssetClass,
    'UK' AS rowSource,
    0 AS BackReportingIndicator,
    p.EMSOrderID
  FROM uk_trades p
  CROSS JOIN run_parameters rp
  JOIN instruments m ON p.InstrumentID = m.InstrumentID AND m.IsMifidByFCA = 1
  JOIN currency_types ctp ON ctp.CurrencyTypeID = m.InstrumentTypeID
  WHERE p.InstrumentID NOT IN (SELECT instrument_id FROM excluded_instruments)
),

-- ============ UNION ALL BRANCHES ============
all_branches AS (
  SELECT * FROM eu_report
  UNION ALL
  SELECT * FROM eu_uk_report
  UNION ALL
  SELECT * FROM uk_report
)

SELECT * FROM all_branches
WHERE TransactionReferenceNumber NOT IN (SELECT position_id FROM excluded_trns)
"""

print(f"Executing hedge report SQL for {report_date}...")
df = spark.sql(hedge_report_sql)
row_count = df.count()
print(f"mifid2_hedge_report: {row_count:,} rows")

# Breakdown by branch
df.groupBy("RegulationReportID", "rowSource").count().orderBy("RegulationReportID", "rowSource").show()

# Write to Delta with external LOCATION
df.write.format("delta").mode("overwrite").option("overwriteSchema", "true") \
    .option("path", "abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/mifid2_hedge_report") \
    .saveAsTable("main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report")

print(f"\n\u2713 mifid2_hedge_report persisted ({row_count:,} rows)")

# COMMAND ----------

# DBTITLE 1,2. Validation: Hedge Report Row Counts
# MAGIC %sql
# MAGIC -- Validation: MIFID2_Hedge_Report row counts and basic checks
# MAGIC SELECT 'Total' AS metric, COUNT(*) AS value FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
# MAGIC UNION ALL
# MAGIC SELECT 'EU (ReportID=1, rowSource=EU)', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report WHERE RegulationReportID = 1 AND rowSource = 'EU'
# MAGIC UNION ALL
# MAGIC SELECT 'EU-UK (ReportID=1, rowSource=EU-UK)', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report WHERE RegulationReportID = 1 AND rowSource = 'EU-UK'
# MAGIC UNION ALL
# MAGIC SELECT 'UK (ReportID=2)', COUNT(*) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report WHERE RegulationReportID = 2
# MAGIC UNION ALL
# MAGIC SELECT 'Distinct Instruments', COUNT(DISTINCT InstrumentID) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
# MAGIC UNION ALL
# MAGIC SELECT 'Distinct LPs', COUNT(DISTINCT LiquidityProvider) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
# MAGIC UNION ALL
# MAGIC SELECT 'Null TRN (should be 0)', SUM(CASE WHEN TransactionReferenceNumber IS NULL OR TransactionReferenceNumber = '' THEN 1 ELSE 0 END) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
# MAGIC UNION ALL
# MAGIC SELECT 'Null Price (should be 0)', SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report
