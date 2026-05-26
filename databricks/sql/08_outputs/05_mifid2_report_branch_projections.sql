-- Step 12B3: Final branch projection templates for MIFID2 report outputs.
--
-- Scope in this file:
-- - Final branch projection templates only (EU/CySEC, UK/FCA, FCA-flow-in-EU,
--   Seychelles, ME, removed partials finalization).
-- - Target objects:
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_report
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
--     main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
--
-- Explicitly out of scope:
-- - MIFID2_ETORO_Report, MIFID2_Hedge_Report, MIFID2_NPD_TRAX
-- - file delivery / CSV / SFTP / 7z / upload / response handling / deployment
--
-- IMPORTANT:
-- - This file starts at Step 12B2 boundary only (`#tradesFinal` equivalent).
-- - Do not execute while upstream gates are unresolved.
-- - Keep all load statements commented until profiling + parity checks pass.
-- - Do not invent UpdateDate defaults. Keep UpdateDate nullable/unpopulated.
-- - Use explicit target column lists for all inserts.
-- - Removed partials finalization must read from a scoped/materialized Step 12B2
--   source (do not reference out-of-scope CTE names).

-- -----------------------------------------------------------------------------
-- 0) Parameter + gate/status scaffold (safe to run)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
required_sources AS (
  SELECT *
  FROM VALUES
    ('{{trades_final_source}}', 'pending', 'Step 12B2 unified trade pool source (`#tradesFinal` equivalent) is required.'),
    ('{{report_metadata_source}}', 'pending', 'Instrument metadata source with IsMifid / IsMifidByFCA / IsFuture is required.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype', 'pending', 'Instrument type/currency type dictionary for PriceType/AssetClass logic.'),
    ('main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments', 'pending', 'Excluded instruments filter.'),
    ('main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids', 'pending', 'Excluded position IDs filter.'),
    ('main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids', 'pending', 'FCA CID exclusion filter.'),
    ('{{isin_for_instrumentid_341_source}}', 'pending', 'InstrumentID 341 override source is required and must expose normalized logical columns (InstrumentID, OverrideISIN[, effective/report date if needed]).'),
    ('{{removed_partial_candidates_source}}', 'pending', 'Step 12B2 removed-partials candidate source required for finalization.'),
    ('{{mifid2_instruments_to_exclude_source}}', 'pending', 'Mapped MIFID2_Instruments_To_Exclude source must be confirmed.'),
    ('main.trading.bronze_etoro_trade_futuresmetadata', 'pending', 'Step 12B3 futures-only dependency. Required columns: InstrumentID, CFICode, ExpirationDateTime, Multiplier.')
  AS t(required_source, gate_status, gate_reason)
),
upstream_gates AS (
  SELECT *
  FROM VALUES
    ('step5_price_split_sources', 'pending', 'Step 5B1 price/split gates unresolved.'),
    ('step6_movement_regchange', 'pending', 'Step 6 movement parity unresolved.'),
    ('step9_position_staging', 'pending', 'Step 9 position/reg-change staging gates unresolved.'),
    ('step10_11_customer_outputs', 'pending', 'Step 10/11 customer outputs must be validated before branch activation.'),
    ('step12b2_trades_final_boundary', 'pending', 'Step 12B3 must start from Step 12B2 trades_final source.'),
    ('step12b3_futuresmetadata_profile', 'pending', 'FuturesMetaData required-column profiling pending.'),
    ('step12b3_specialchar_conversion', 'pending', 'InstrumentMetaData_SpecialChar_Conversion feeder/source gates pending.'),
    ('step12b3_removed_partials_explicit_columns', 'pending', 'Removed partial final insert must remain explicit-column and scoped.'),
    ('step12b3_instrumentclassification_exact_mapping', 'pending', 'HARD GATE: exact SP_MIFID_Report branch-specific InstrumentClassification/CFI mapping is not yet ported.'),
    ('step12b3_isin341_source_contract', 'pending', 'InstrumentID 341 override source column contract is not yet confirmed.')
  AS t(gate_name, gate_status, gate_reason)
)
SELECT
  rp.report_date,
  rs.required_source,
  rs.gate_status AS source_status,
  rs.gate_reason AS source_reason,
  ug.gate_name,
  ug.gate_status,
  ug.gate_reason
FROM run_parameters rp
CROSS JOIN required_sources rs
CROSS JOIN upstream_gates ug
ORDER BY rs.required_source, ug.gate_name;

-- -----------------------------------------------------------------------------
-- 1) COMMENTED TEMPLATE ONLY - FINAL BRANCH PROJECTIONS + LOADS
-- -----------------------------------------------------------------------------
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
trades_final_source AS (
  -- Required Step 12B2 boundary input:
  -- Expected shape matches `#tradesFinal` equivalent from Step 12B2.
  SELECT *
  FROM {{trades_final_source}}
),
report_metadata AS (
  -- Expected metadata source should already include special-char conversion outcomes
  -- and Step 12B2 pre-branch metadata enrichment fields.
  SELECT
    InstrumentID,
    InstrumentTypeID,
    SellAbbreviation,
    ISINCode,
    InstrumentFullName,
    IndexNameFullDescription,
    IsMifid,
    IsMifidByFCA,
    IsFuture
  FROM {{report_metadata_source}}
),
futures_metadata AS (
  -- Step 12B3-only dependency (profiling gate).
  SELECT
    InstrumentID,
    CFICode,
    ExpirationDateTime,
    Multiplier
  FROM main.trading.bronze_etoro_trade_futuresmetadata
),
dictionary_currency_type AS (
  SELECT
    CurrencyTypeID,
    Name
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype
),
excluded_instruments AS (
  SELECT DISTINCT CAST(instrument_id AS STRING) AS instrument_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments
  WHERE table_name = '[MIFID2_Report]'
),
excluded_position_ids AS (
  SELECT DISTINCT CAST(position_id AS STRING) AS position_id
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids
  WHERE table_name = '[MIFID2_Report]'
),
excluded_cids AS (
  SELECT DISTINCT CAST(cid AS INT) AS cid
  FROM main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids
),
inst_341_override AS (
  -- HARD GATE: do not activate final branch inserts until the real source schema
  -- for the InstrumentID 341 override is profiled and mapped.
  -- Expected normalized logical columns from {{isin_for_instrumentid_341_source}}:
  --   InstrumentID (INT-like), OverrideISIN (STRING-like)
  -- Optional source-level temporal columns (effective/report date) should be
  -- applied in a source adapter before this projection.
  SELECT
    CAST(InstrumentID AS INT) AS InstrumentID,
    CAST(OverrideISIN AS STRING) AS ISINCode_341
  FROM {{isin_for_instrumentid_341_source}}
),
branch_config AS (
  SELECT *
  FROM VALUES
    ('EU_CYSEC', 'REPORT', 1, 1, 1, 0, 0, 'STRIP_UK', '213800GIFQMSV7HROS23', 'false', 'EU_STYLE'),
    ('UK_FCA', 'REPORT', 2, 2, 0, 1, 1, 'STRIP_UK', '213800FLAB1OVA8OHT72', 'true', 'UK_STYLE'),
    ('FCA_FLOW_IN_EU', 'REPORT', 1, 2, 1, 1, 0, 'KEEP_POSITION_ID_OUT', '213800GIFQMSV7HROS23', 'false', 'FCA_FLOW_STYLE'),
    ('SEYCHELLES', 'REPORT', 1, 9, 1, 0, 0, 'SC_SUFFIX', '213800GIFQMSV7HROS23', 'false', 'SEYCHELLES_STYLE'),
    ('ME', 'ME', 1, 11, 1, 0, 0, 'ME_SUFFIX', '213800GIFQMSV7HROS23', 'false', 'ME_STYLE')
  AS t(
    branch_name,
    target_table,
    regulation_report_id,
    orig_regulation_id_filter,
    require_is_mifid,
    require_is_mifid_by_fca,
    apply_excluded_cids,
    transaction_reference_mode,
    executing_entity_code,
    transmission_of_order_indicator,
    branch_style
  )
),
branch_input AS (
  SELECT
    cfg.branch_name,
    cfg.target_table,
    cfg.regulation_report_id,
    cfg.transaction_reference_mode,
    cfg.executing_entity_code,
    cfg.transmission_of_order_indicator,
    cfg.branch_style,
    t.CID,
    t.OrigRegulationID,
    t.RegulationID AS CustomerRegulationID,
    t.PositionID,
    t.InstrumentID,
    t.OpenORClose,
    t.BuyORSell,
    t.IDType,
    t.MirrorID,
    t.CopyFund,
    t.FundType,
    t.PIN_LEI,
    t.PIN_Type,
    t.OpenOccurred,
    t.CloseOccurred,
    t.InitForexRate,
    t.EndForexRate,
    t.AmountInUnitsDecimal,
    t.PositionIDOut,
    t.RegChange,
    t.IsRealStockETF,
    m.InstrumentTypeID,
    m.SellAbbreviation,
    m.ISINCode,
    m.InstrumentFullName,
    m.IndexNameFullDescription,
    m.IsMifid,
    m.IsMifidByFCA,
    m.IsFuture,
    ctp.Name AS CurrencyTypeName,
    fm.CFICode AS FuturesCFICode,
    fm.ExpirationDateTime AS FuturesExpirationDateTime,
    fm.Multiplier AS FuturesMultiplier,
    i341.ISINCode_341,
    ex_cid.cid AS ExcludedCID
  FROM branch_config cfg
  JOIN trades_final_source t
    ON t.OrigRegulationID = cfg.orig_regulation_id_filter
  JOIN report_metadata m
    ON m.InstrumentID = t.InstrumentID
  JOIN dictionary_currency_type ctp
    ON ctp.CurrencyTypeID = m.InstrumentTypeID
  LEFT JOIN futures_metadata fm
    ON fm.InstrumentID = t.InstrumentID
  LEFT JOIN inst_341_override i341
    ON i341.InstrumentID = t.InstrumentID
  LEFT JOIN excluded_cids ex_cid
    ON ex_cid.cid = t.CID
  WHERE
    (cfg.require_is_mifid = 0 OR m.IsMifid = 1)
    AND (cfg.require_is_mifid_by_fca = 0 OR m.IsMifidByFCA = 1)
    AND (cfg.apply_excluded_cids = 0 OR ex_cid.cid IS NULL)
    AND CAST(t.InstrumentID AS STRING) NOT IN (SELECT instrument_id FROM excluded_instruments)
    AND CAST(t.PositionID AS STRING) NOT IN (SELECT position_id FROM excluded_position_ids)
    -- Optional additional exclusion gate. Keep disabled until source parity is confirmed.
    AND NOT EXISTS (
      SELECT 1
      FROM {{mifid2_instruments_to_exclude_source}} x
      WHERE CAST(x.InstrumentID AS STRING) = CAST(t.InstrumentID AS STRING)
    )
),
branch_projection AS (
  SELECT
    b.branch_name,
    b.target_table,
    b.regulation_report_id AS RegulationReportID,
    CAST(date_format(rp.report_date, 'yyyyMMdd') AS INT) AS DateID,
    rp.report_date AS ReportDate,
    b.CID,
    b.OrigRegulationID AS RegulationID,
    b.PositionID,
    b.InstrumentID,
    b.OpenORClose,
    b.BuyORSell,
    b.IDType,
    CASE WHEN b.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy,
    b.CopyFund,
    b.FundType AS FundTypeID,
    'NEWT' AS ReportStatus,
    CASE
      WHEN b.transaction_reference_mode = 'STRIP_UK' THEN REPLACE(b.PositionIDOut, 'UK', '')
      WHEN b.transaction_reference_mode = 'KEEP_POSITION_ID_OUT' THEN b.PositionIDOut
      WHEN b.transaction_reference_mode = 'SC_SUFFIX' THEN CONCAT(
        REPLACE(b.PositionIDOut, 'UK', ''),
        'SC',
        date_format(CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END, 'yyyyMMdd')
      )
      WHEN b.transaction_reference_mode = 'ME_SUFFIX' THEN CONCAT(
        REPLACE(b.PositionIDOut, 'UK', ''),
        'ME',
        date_format(CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END, 'yyyyMMdd')
      )
      ELSE b.PositionIDOut
    END AS TransactionReferenceNumber,
    '' AS TradingVenueTransactionIdentificationCode,
    b.executing_entity_code AS ExecutingEntityIdentificationCode,
    'TRUE' AS InvestmentFirmCoveredBy201465EU,
    CASE
      WHEN b.branch_style IN ('FCA_FLOW_STYLE', 'SEYCHELLES_STYLE', 'ME_STYLE') THEN 'LEI'
      WHEN b.BuyORSell = 1 AND b.IDType = 1 THEN 'INT'
      ELSE 'LEI'
    END AS BuyerIdentificationCodeType,
    '' AS BuyerNPCode,
    CASE
      WHEN b.branch_style = 'FCA_FLOW_STYLE' THEN CASE WHEN b.BuyORSell = 0 THEN '213800GIFQMSV7HROS23' ELSE '213800FLAB1OVA8OHT72' END
      WHEN b.branch_style = 'SEYCHELLES_STYLE' THEN CASE WHEN b.BuyORSell = 1 THEN '549300L7LPQNKJQ1IW32' ELSE '213800GIFQMSV7HROS23' END
      WHEN b.branch_style = 'ME_STYLE' THEN CASE WHEN b.BuyORSell = 1 THEN '254900TH30J939UL7C24' ELSE '213800GIFQMSV7HROS23' END
      WHEN b.BuyORSell = 1 THEN CASE WHEN b.PIN_Type = 'LEI' OR b.IDType <> 1 THEN b.PIN_LEI ELSE CAST(b.CID AS STRING) END
      ELSE '213800GIFQMSV7HROS23'
    END AS BuyerIdentificationCode,
    CASE
      WHEN b.branch_style = 'UK_STYLE' AND b.BuyORSell = 1 THEN 'GB'
      WHEN b.branch_style IN ('EU_STYLE', 'SEYCHELLES_STYLE', 'ME_STYLE') AND b.BuyORSell = 1 THEN 'CY'
      ELSE ''
    END AS BuyerCountryOfTheBranch,
    '' AS BuyerFirstNames,
    '' AS BuyerSurnames,
    '' AS BuyerDateOfBirth,
    CASE
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN ''
      WHEN b.BuyORSell = 1 AND b.MirrorID > 0 THEN 'LEI'
      ELSE ''
    END AS BuyerDecisionMakerCodeType,
    '' AS BuyerDecisionMakerNPCode,
    CASE
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN ''
      WHEN b.BuyORSell = 1 AND b.MirrorID > 0 AND b.branch_style = 'UK_STYLE' THEN '213800FLAB1OVA8OHT72'
      WHEN b.BuyORSell = 1 AND b.MirrorID > 0 THEN '213800GIFQMSV7HROS23'
      ELSE ''
    END AS BuyerDecisionMakerCode,
    '' AS BuyerDecisionMakerFirstNames,
    '' AS BuyerDecisionMakerSurnames,
    '' AS BuyerDecisionMakerDateOfBirth,
    CASE
      WHEN b.branch_style IN ('FCA_FLOW_STYLE', 'SEYCHELLES_STYLE', 'ME_STYLE') THEN 'LEI'
      WHEN b.BuyORSell = 0 AND b.IDType = 1 THEN 'INT'
      ELSE 'LEI'
    END AS SellerIdentificationCodeType,
    '' AS SellerNPCode,
    CASE
      WHEN b.branch_style = 'FCA_FLOW_STYLE' THEN CASE WHEN b.BuyORSell = 1 THEN '213800GIFQMSV7HROS23' ELSE '213800FLAB1OVA8OHT72' END
      WHEN b.branch_style = 'SEYCHELLES_STYLE' THEN CASE WHEN b.BuyORSell = 0 THEN '549300L7LPQNKJQ1IW32' ELSE '213800GIFQMSV7HROS23' END
      WHEN b.branch_style = 'ME_STYLE' THEN CASE WHEN b.BuyORSell = 0 THEN '254900TH30J939UL7C24' ELSE '213800GIFQMSV7HROS23' END
      WHEN b.BuyORSell = 0 THEN CASE WHEN b.PIN_Type = 'LEI' OR b.IDType <> 1 THEN b.PIN_LEI ELSE CAST(b.CID AS STRING) END
      ELSE '213800GIFQMSV7HROS23'
    END AS SellerIdentificationCode,
    CASE
      WHEN b.branch_style = 'UK_STYLE' AND b.BuyORSell = 0 THEN 'GB'
      WHEN b.branch_style IN ('EU_STYLE', 'SEYCHELLES_STYLE', 'ME_STYLE') AND b.BuyORSell = 0 THEN 'CY'
      ELSE ''
    END AS SellerCountryOfTheBranch,
    '' AS SellerFirstNames,
    '' AS SellerSurnames,
    '' AS SellerDateOfBirth,
    CASE
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN ''
      WHEN b.BuyORSell = 0 AND b.MirrorID > 0 THEN 'LEI'
      ELSE ''
    END AS SellerDecisionMakerCodeType,
    '' AS SellerDecisionMakerNPCode,
    CASE
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN ''
      WHEN b.BuyORSell = 0 AND b.MirrorID > 0 AND b.branch_style = 'UK_STYLE' THEN '213800FLAB1OVA8OHT72'
      WHEN b.BuyORSell = 0 AND b.MirrorID > 0 THEN '213800GIFQMSV7HROS23'
      ELSE ''
    END AS SellerDecisionMakerCode,
    '' AS SellerDecisionMakerFirstNames,
    '' AS SellerDecisionMakerSurnames,
    '' AS SellerDecisionMakerDateOfBirth,
    b.transmission_of_order_indicator AS TransmissionOfOrderIndicator,
    '' AS TransmittingFirmIdentificationCodeForTheBuyer,
    '' AS TransmittingFirmIdentificationCodeForTheSeller,
    CONCAT(
      date_format(CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END, 'yyyy-MM-dd'),
      'T',
      date_format(
        CASE
          WHEN second(CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END) = 0
            THEN (CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END) + INTERVAL 1 SECOND
          ELSE CASE WHEN b.OpenORClose = 'O' THEN b.OpenOccurred ELSE b.CloseOccurred END
        END,
        'HH:mm:ss'
      ),
      'Z'
    ) AS TradingDateTime,
    CASE
      WHEN b.branch_style = 'UK_STYLE' THEN 'AOTC'
      WHEN b.IsFuture = 1 THEN 'AOTC'
      ELSE 'DEAL'
    END AS TradingCapacity,
    'UNIT' AS QuantityType,
    CAST(b.AmountInUnitsDecimal AS STRING) AS Quantity,
    '' AS QuantityCurrency,
    '' AS DerivativeNotionalIncreaseDecrease,
    CASE WHEN b.InstrumentTypeID = 4 THEN 'BSPS' ELSE 'MNTR' END AS PriceType,
    CAST(CASE WHEN b.OpenORClose = 'O' THEN b.InitForexRate ELSE b.EndForexRate END AS STRING) AS Price,
    SUBSTRING(b.SellAbbreviation, 1, 3) AS PriceCurrency,
    '' AS NetAmount,
    CASE WHEN b.IsRealStockETF = 1 OR b.IsFuture = 1 THEN 'XOFF' ELSE 'XXXX' END AS Venue,
    '' AS CountryOfTheBranchMembership,
    '' AS UpfrontPayment,
    '' AS UpfrontPaymentCurrency,
    '' AS ComplexTradeComponentId,
    CASE WHEN b.IsRealStockETF = 1 THEN b.ISINCode ELSE '' END AS InstrumentIdentificationCode,
    CASE
      WHEN b.IsFuture = 1 THEN CAST(b.InstrumentFullName AS STRING)
      WHEN b.IsRealStockETF = 1 THEN ''
      ELSE CONCAT(CAST(b.InstrumentFullName AS STRING), ' CFD')
    END AS InstrumentFullName,
    -- HARD GATE - DO NOT ACTIVATE FINAL BRANCH PROJECTION UNTIL EXACT
    -- SP_MIFID_Report BRANCH-SPECIFIC InstrumentClassification / CFI mappings
    -- are ported for:
    -- - EU/CySEC
    -- - UK/FCA
    -- - FCA-flow-in-EU
    -- - Seychelles
    -- - ME
    -- The SQL Server mappings differ by branch and include explicit
    -- instrument-ID set handling (soft commodities, energy, metals, treasury,
    -- ETF/real-stock behavior, and futures).
    CAST(NULL AS STRING) AS InstrumentClassification,
    CASE
      WHEN b.IsFuture = 1 THEN SUBSTRING(b.SellAbbreviation, 1, 3)
      WHEN b.IsRealStockETF = 1 THEN ''
      ELSE SUBSTRING(b.SellAbbreviation, 1, 3)
    END AS NotionalCurrency1,
    '' AS NotionalCurrency2,
    CASE
      WHEN b.IsFuture = 1 THEN CAST(b.FuturesMultiplier AS STRING)
      WHEN b.IsRealStockETF = 1 THEN ''
      ELSE '1'
    END AS PriceMultiplier,
    CASE
      WHEN b.branch_style = 'UK_STYLE' AND b.ISINCode_341 IS NOT NULL THEN b.ISINCode_341
      WHEN b.IsRealStockETF = 1 THEN ''
      ELSE COALESCE(b.ISINCode, '')
    END AS UnderlyingInstrumentCode,
    CASE
      WHEN b.InstrumentID IN (312,313,314) THEN ''
      WHEN b.InstrumentTypeID = 4 AND b.IndexNameFullDescription IS NOT NULL THEN b.IndexNameFullDescription
      WHEN b.InstrumentTypeID = 4 AND b.IndexNameFullDescription IS NULL THEN CAST(b.InstrumentFullName AS STRING)
      ELSE ''
    END AS UnderlyingIndexName,
    CASE
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN
        CASE
          WHEN b.InstrumentID IN (225000,225001,225002,225003,225004,225005,225006,225007,225008,225009,225010,225011,225012,225013,225014,225015,225016) THEN '10YEAR'
          ELSE ''
        END
      ELSE
        CASE
          WHEN b.InstrumentID = 26 THEN '1MNTH'
          WHEN b.InstrumentID IN (225000,225001,225002,225003,225004,225005,225006,225007,225008,225009,225010,225011,225012,225013,225014,225015,225016) THEN '10YEAR'
          ELSE ''
        END
    END AS TermOfTheUnderlyingIndex,
    '' AS OptionType,
    '' AS StrikePriceType,
    '' AS StrikePrice,
    '' AS StrikePriceCurrency,
    '' AS OptionExerciseStyle,
    '' AS MaturityDate,
    CASE WHEN b.IsFuture = 1 THEN date_format(b.FuturesExpirationDateTime, 'd/M/yyyy') ELSE '' END AS ExpiryDate,
    CASE
      WHEN b.IsFuture = 1 THEN 'CASH'
      WHEN b.IsRealStockETF = 1 THEN ''
      ELSE 'CASH'
    END AS DeliveryType,
    CASE
      WHEN b.branch_style = 'UK_STYLE' THEN
        CASE
          WHEN b.MirrorID = 0 OR b.IsFuture = 1 THEN ''
          WHEN b.MirrorID > 0 AND b.FundType IN (2,3) THEN 'INT'
          ELSE 'ALG'
        END
      WHEN b.branch_style IN ('SEYCHELLES_STYLE', 'ME_STYLE') THEN
        CASE WHEN b.IsFuture = 1 THEN '' ELSE 'ALG' END
      ELSE
        CASE
          WHEN b.IsFuture = 1 THEN ''
          WHEN b.MirrorID > 0 AND b.FundType IN (2,3) THEN 'INT'
          ELSE 'ALG'
        END
    END AS InvestmentDecisionWithinFirmType,
    '' AS InvestmentDecisionWithinFirmNPCode,
    CASE
      WHEN b.IsFuture = 1 THEN ''
      WHEN b.branch_style = 'UK_STYLE' AND b.MirrorID = 0 THEN ''
      WHEN b.MirrorID = 0 THEN 'ETOROBROKERAGE01'
      WHEN b.MirrorID > 0 AND b.FundType IS NULL THEN 'ETOROPM01'
      WHEN b.MirrorID > 0 AND b.FundType = 1 THEN 'ETOROPEOPLECF01'
      WHEN b.MirrorID > 0 AND b.FundType IN (2,3) THEN '2001375'
      ELSE ''
    END AS InvestmentDecisionWithinFirm,
    '' AS CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision,
    'ALG' AS ExecutionWithinFirmType,
    '' AS ExecutionWithinFirmNPCode,
    'ETOROBROKERAGE01' AS ExecutionWithinFirm,
    '' AS CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution,
    '' AS WaiverIndicator,
    CASE
      WHEN b.InstrumentTypeID IN (5,6) AND b.IsRealStockETF = 1 AND b.BuyORSell = 0 AND b.OpenORClose = 'C' THEN 'SELL'
      WHEN b.InstrumentTypeID IN (5,6) AND b.IsRealStockETF = 1 AND b.BuyORSell = 1 AND b.OpenORClose = 'O' THEN 'SELL'
      ELSE ''
    END AS ShortSellingIndicator,
    '' AS OTCPostTradeIndicator,
    CASE
      WHEN b.branch_style = 'SEYCHELLES_STYLE' THEN ''
      WHEN b.InstrumentTypeID = 2 THEN 'false'
      ELSE ''
    END AS CommodityDerivativeIndicator,
    'false' AS SecuritiesFinancingTransactionIndicator,
    '' AS BranchLocation,
    '' AS TransactionType,
    '' AS LifecycleEvent,
    CASE WHEN b.InstrumentTypeID IN (4,5,6) THEN 'Equity' ELSE b.CurrencyTypeName END AS AssetClass,
    b.IsRealStockETF,
    CAST(NULL AS TIMESTAMP) AS UpdateDate,
    CAST(0 AS SMALLINT) AS BackReportingIndicator,
    b.RegChange
  FROM branch_input b
  CROSS JOIN run_parameters rp
),
report_rows AS (
  SELECT *
  FROM branch_projection
  WHERE target_table = 'REPORT'
),
me_rows AS (
  SELECT *
  FROM branch_projection
  WHERE target_table = 'ME'
)
-- Report-date scoped delete/insert skeleton for final targets.
-- Keep commented until gates pass and validation evidence is approved.
-- DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
-- WHERE ReportDate = (SELECT report_date FROM run_parameters);
--
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_report (
--   RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
--   IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
--   TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
--   BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
--   BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
--   BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
--   SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
--   SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
--   SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
--   TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
--   TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
--   PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
--   ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
--   NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
--   StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
--   InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
--   CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
--   ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
--   ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
--   BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
-- )
-- SELECT
--   RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
--   IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
--   TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
--   BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
--   BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
--   BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
--   SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
--   SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
--   SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
--   TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
--   TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
--   PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
--   ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
--   NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
--   StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
--   InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
--   CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
--   ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
--   ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
--   BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
-- FROM report_rows;
--
-- DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
-- WHERE ReportDate = (SELECT report_date FROM run_parameters);
--
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report (
--   RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
--   IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
--   TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
--   BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
--   BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
--   BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
--   SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
--   SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
--   SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
--   TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
--   TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
--   PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
--   ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
--   NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
--   StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
--   InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
--   CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
--   ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
--   ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
--   BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
-- )
-- SELECT
--   RegulationReportID, DateID, ReportDate, CID, RegulationID, PositionID, InstrumentID, OpenORClose, BuyORSell,
--   IDType, IsCopy, CopyFund, FundTypeID, ReportStatus, TransactionReferenceNumber,
--   TradingVenueTransactionIdentificationCode, ExecutingEntityIdentificationCode, InvestmentFirmCoveredBy201465EU,
--   BuyerIdentificationCodeType, BuyerNPCode, BuyerIdentificationCode, BuyerCountryOfTheBranch, BuyerFirstNames,
--   BuyerSurnames, BuyerDateOfBirth, BuyerDecisionMakerCodeType, BuyerDecisionMakerNPCode, BuyerDecisionMakerCode,
--   BuyerDecisionMakerFirstNames, BuyerDecisionMakerSurnames, BuyerDecisionMakerDateOfBirth, SellerIdentificationCodeType,
--   SellerNPCode, SellerIdentificationCode, SellerCountryOfTheBranch, SellerFirstNames, SellerSurnames,
--   SellerDateOfBirth, SellerDecisionMakerCodeType, SellerDecisionMakerNPCode, SellerDecisionMakerCode,
--   SellerDecisionMakerFirstNames, SellerDecisionMakerSurnames, SellerDecisionMakerDateOfBirth, TransmissionOfOrderIndicator,
--   TransmittingFirmIdentificationCodeForTheBuyer, TransmittingFirmIdentificationCodeForTheSeller, TradingDateTime,
--   TradingCapacity, QuantityType, Quantity, QuantityCurrency, DerivativeNotionalIncreaseDecrease, PriceType, Price,
--   PriceCurrency, NetAmount, Venue, CountryOfTheBranchMembership, UpfrontPayment, UpfrontPaymentCurrency,
--   ComplexTradeComponentId, InstrumentIdentificationCode, InstrumentFullName, InstrumentClassification, NotionalCurrency1,
--   NotionalCurrency2, PriceMultiplier, UnderlyingInstrumentCode, UnderlyingIndexName, TermOfTheUnderlyingIndex, OptionType,
--   StrikePriceType, StrikePrice, StrikePriceCurrency, OptionExerciseStyle, MaturityDate, ExpiryDate, DeliveryType,
--   InvestmentDecisionWithinFirmType, InvestmentDecisionWithinFirmNPCode, InvestmentDecisionWithinFirm,
--   CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision, ExecutionWithinFirmType, ExecutionWithinFirmNPCode,
--   ExecutionWithinFirm, CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution, WaiverIndicator,
--   ShortSellingIndicator, OTCPostTradeIndicator, CommodityDerivativeIndicator, SecuritiesFinancingTransactionIndicator,
--   BranchLocation, TransactionType, LifecycleEvent, AssetClass, IsRealStockETF, UpdateDate, BackReportingIndicator, RegChange
-- FROM me_rows;
SELECT
  branch_name,
  target_table,
  COUNT(*) AS projected_rows
FROM branch_projection
GROUP BY branch_name, target_table
ORDER BY target_table, branch_name;
*/

-- -----------------------------------------------------------------------------
-- 2) COMMENTED TEMPLATE ONLY - REMOVED PARTIALS FINALIZATION (EXPLICIT COLUMNS)
-- -----------------------------------------------------------------------------
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
removed_partial_candidates AS (
  -- This must point to a scoped/materialized Step 12B2 output.
  -- Do not reference `removed_partial_candidates` CTE outside its defining statement.
  SELECT *
  FROM {{removed_partial_candidates_source}}
)
-- DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
-- WHERE ReportDate = (SELECT report_date FROM run_parameters);
--
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials (
--   ReportDate,
--   PositionID,
--   ParentPositionID,
--   CID,
--   OpenOccurred,
--   CloseOccurred,
--   InitForexRate,
--   EndForexRate,
--   AmountInUnitsDecimal,
--   InstrumentID,
--   IsBuy,
--   Leverage,
--   OpenORClose,
--   MirrorID,
--   HedgeServerID,
--   IsSettled,
--   ChangeLogLastOpPriceRate,
--   ChangeLogOccurred,
--   ChangeTypeID,
--   InitForexPriceRateID,
--   EndForexPriceRateID,
--   LastOpPriceRate,
--   OriginalPositionID,
--   ChangeLogIsSettled,
--   InitialUnits,
--   RegulationID
-- )
-- SELECT
--   ReportDate,
--   PositionID,
--   ParentPositionID,
--   CID,
--   OpenOccurred,
--   CloseOccurred,
--   InitForexRate,
--   EndForexRate,
--   AmountInUnitsDecimal,
--   InstrumentID,
--   IsBuy,
--   Leverage,
--   OpenORClose,
--   MirrorID,
--   HedgeServerID,
--   IsSettled,
--   ChangeLogLastOpPriceRate,
--   ChangeLogOccurred,
--   ChangeTypeID,
--   InitForexPriceRateID,
--   EndForexPriceRateID,
--   LastOpPriceRate,
--   OriginalPositionID,
--   ChangeLogIsSettled,
--   InitialUnits,
--   RegulationID
-- FROM removed_partial_candidates
-- WHERE ReportDate = (SELECT report_date FROM run_parameters);
SELECT COUNT(*) AS removed_partial_candidate_rows
FROM removed_partial_candidates
WHERE ReportDate = (SELECT report_date FROM run_parameters);
*/
