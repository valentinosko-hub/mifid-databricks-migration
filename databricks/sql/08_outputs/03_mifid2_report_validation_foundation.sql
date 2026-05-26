-- Step 12B1: Validation foundation for MIFID2_Report / MIFID2_ME_Report /
-- MIFID2_Removed_OP_Partials.
--
-- This file defines validation templates only.
-- Execute after Step 12 output tables are materialized.

-- -----------------------------------------------------------------------------
-- 0) Run parameter scaffold
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
)
SELECT report_date
FROM run_parameters;

-- -----------------------------------------------------------------------------
-- 1) Schema parity foundation (name, order, type, nullability, precision/scale)
-- -----------------------------------------------------------------------------
WITH report_contract AS (
  SELECT *
  FROM VALUES
    (1, 'RegulationReportID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (2, 'DateID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (3, 'ReportDate', 'DATE', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (4, 'CID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (5, 'RegulationID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (6, 'PositionID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (7, 'InstrumentID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (8, 'OpenORClose', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (9, 'BuyORSell', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (10, 'IDType', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (11, 'IsCopy', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (12, 'CopyFund', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (13, 'FundTypeID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (14, 'ReportStatus', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (15, 'TransactionReferenceNumber', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (16, 'TradingVenueTransactionIdentificationCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (17, 'ExecutingEntityIdentificationCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (18, 'InvestmentFirmCoveredBy201465EU', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (19, 'BuyerIdentificationCodeType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (20, 'BuyerNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (21, 'BuyerIdentificationCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (22, 'BuyerCountryOfTheBranch', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (23, 'BuyerFirstNames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (24, 'BuyerSurnames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (25, 'BuyerDateOfBirth', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (26, 'BuyerDecisionMakerCodeType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (27, 'BuyerDecisionMakerNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (28, 'BuyerDecisionMakerCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (29, 'BuyerDecisionMakerFirstNames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (30, 'BuyerDecisionMakerSurnames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (31, 'BuyerDecisionMakerDateOfBirth', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (32, 'SellerIdentificationCodeType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (33, 'SellerNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (34, 'SellerIdentificationCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (35, 'SellerCountryOfTheBranch', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (36, 'SellerFirstNames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (37, 'SellerSurnames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (38, 'SellerDateOfBirth', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (39, 'SellerDecisionMakerCodeType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (40, 'SellerDecisionMakerNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (41, 'SellerDecisionMakerCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (42, 'SellerDecisionMakerFirstNames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (43, 'SellerDecisionMakerSurnames', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (44, 'SellerDecisionMakerDateOfBirth', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (45, 'TransmissionOfOrderIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (46, 'TransmittingFirmIdentificationCodeForTheBuyer', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (47, 'TransmittingFirmIdentificationCodeForTheSeller', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (48, 'TradingDateTime', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (49, 'TradingCapacity', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (50, 'QuantityType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (51, 'Quantity', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (52, 'QuantityCurrency', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (53, 'DerivativeNotionalIncreaseDecrease', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (54, 'PriceType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (55, 'Price', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (56, 'PriceCurrency', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (57, 'NetAmount', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (58, 'Venue', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (59, 'CountryOfTheBranchMembership', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (60, 'UpfrontPayment', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (61, 'UpfrontPaymentCurrency', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (62, 'ComplexTradeComponentId', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (63, 'InstrumentIdentificationCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (64, 'InstrumentFullName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (65, 'InstrumentClassification', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (66, 'NotionalCurrency1', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (67, 'NotionalCurrency2', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (68, 'PriceMultiplier', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (69, 'UnderlyingInstrumentCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (70, 'UnderlyingIndexName', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (71, 'TermOfTheUnderlyingIndex', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (72, 'OptionType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (73, 'StrikePriceType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (74, 'StrikePrice', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (75, 'StrikePriceCurrency', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (76, 'OptionExerciseStyle', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (77, 'MaturityDate', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (78, 'ExpiryDate', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (79, 'DeliveryType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (80, 'InvestmentDecisionWithinFirmType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (81, 'InvestmentDecisionWithinFirmNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (82, 'InvestmentDecisionWithinFirm', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (83, 'CountryOfTheBranchResponsibleForThePersonMakingTheInvestmentDecision', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (84, 'ExecutionWithinFirmType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (85, 'ExecutionWithinFirmNPCode', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (86, 'ExecutionWithinFirm', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (87, 'CountryOfTheBranchSupervisingThePersonResponsibleForTheExecution', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (88, 'WaiverIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (89, 'ShortSellingIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (90, 'OTCPostTradeIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (91, 'CommodityDerivativeIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (92, 'SecuritiesFinancingTransactionIndicator', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (93, 'BranchLocation', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (94, 'TransactionType', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (95, 'LifecycleEvent', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (96, 'AssetClass', 'STRING', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (97, 'IsRealStockETF', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (98, 'UpdateDate', 'TIMESTAMP', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (99, 'BackReportingIndicator', 'SMALLINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (100, 'RegChange', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT))
  AS t(expected_ordinal_position, column_name, expected_data_type, expected_is_nullable, expected_numeric_precision, expected_numeric_scale)
),
removed_partials_contract AS (
  SELECT *
  FROM VALUES
    (1, 'ReportDate', 'DATE', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (2, 'PositionID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (3, 'ParentPositionID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (4, 'CID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (5, 'OpenOccurred', 'TIMESTAMP', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (6, 'CloseOccurred', 'TIMESTAMP', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (7, 'InitForexRate', 'DECIMAL', 'YES', 16, 8),
    (8, 'EndForexRate', 'DECIMAL', 'YES', 16, 8),
    (9, 'AmountInUnitsDecimal', 'DECIMAL', 'YES', 16, 6),
    (10, 'InstrumentID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (11, 'IsBuy', 'TINYINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (12, 'Leverage', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (13, 'OpenORClose', 'STRING', 'NO', CAST(NULL AS INT), CAST(NULL AS INT)),
    (14, 'MirrorID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (15, 'HedgeServerID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (16, 'IsSettled', 'TINYINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (17, 'ChangeLogLastOpPriceRate', 'DECIMAL', 'YES', 16, 8),
    (18, 'ChangeLogOccurred', 'TIMESTAMP', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (19, 'ChangeTypeID', 'TINYINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (20, 'InitForexPriceRateID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (21, 'EndForexPriceRateID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (22, 'LastOpPriceRate', 'DECIMAL', 'YES', 16, 8),
    (23, 'OriginalPositionID', 'BIGINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (24, 'ChangeLogIsSettled', 'TINYINT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT)),
    (25, 'InitialUnits', 'DECIMAL', 'YES', 16, 8),
    (26, 'RegulationID', 'INT', 'YES', CAST(NULL AS INT), CAST(NULL AS INT))
  AS t(expected_ordinal_position, column_name, expected_data_type, expected_is_nullable, expected_numeric_precision, expected_numeric_scale)
),
expected_columns AS (
  SELECT
    'bi_output_regtechops_mifid2_report' AS table_name,
    expected_ordinal_position,
    column_name,
    expected_data_type,
    expected_is_nullable,
    expected_numeric_precision,
    expected_numeric_scale
  FROM report_contract
  UNION ALL
  SELECT
    'bi_output_regtechops_mifid2_me_report',
    expected_ordinal_position,
    column_name,
    expected_data_type,
    expected_is_nullable,
    expected_numeric_precision,
    expected_numeric_scale
  FROM report_contract
  UNION ALL
  SELECT
    'bi_output_regtechops_mifid2_removed_op_partials',
    expected_ordinal_position,
    column_name,
    expected_data_type,
    expected_is_nullable,
    expected_numeric_precision,
    expected_numeric_scale
  FROM removed_partials_contract
),
actual_columns AS (
  SELECT
    lower(c.table_name) AS table_name,
    c.ordinal_position AS actual_ordinal_position,
    c.column_name,
    upper(c.data_type) AS actual_data_type,
    upper(c.is_nullable) AS actual_is_nullable,
    CAST(c.numeric_precision AS INT) AS actual_numeric_precision,
    CAST(c.numeric_scale AS INT) AS actual_numeric_scale
  FROM system.information_schema.columns c
  WHERE lower(c.table_catalog) = 'main'
    AND lower(c.table_schema) = 'regtech_ops_stg'
    AND lower(c.table_name) IN (
      'bi_output_regtechops_mifid2_report',
      'bi_output_regtechops_mifid2_me_report',
      'bi_output_regtechops_mifid2_removed_op_partials'
    )
),
missing_columns AS (
  SELECT
    e.table_name,
    e.column_name,
    'missing_column' AS mismatch_type,
    e.expected_ordinal_position,
    CAST(NULL AS INT) AS actual_ordinal_position,
    e.expected_data_type,
    CAST(NULL AS STRING) AS actual_data_type,
    e.expected_is_nullable,
    CAST(NULL AS STRING) AS actual_is_nullable,
    e.expected_numeric_precision,
    CAST(NULL AS INT) AS actual_numeric_precision,
    e.expected_numeric_scale,
    CAST(NULL AS INT) AS actual_numeric_scale
  FROM expected_columns e
  LEFT JOIN actual_columns a
    ON lower(e.table_name) = lower(a.table_name)
   AND lower(e.column_name) = lower(a.column_name)
  WHERE a.column_name IS NULL
),
extra_columns AS (
  SELECT
    a.table_name,
    a.column_name,
    'extra_column' AS mismatch_type,
    CAST(NULL AS INT) AS expected_ordinal_position,
    a.actual_ordinal_position,
    CAST(NULL AS STRING) AS expected_data_type,
    a.actual_data_type,
    CAST(NULL AS STRING) AS expected_is_nullable,
    a.actual_is_nullable,
    CAST(NULL AS INT) AS expected_numeric_precision,
    a.actual_numeric_precision,
    CAST(NULL AS INT) AS expected_numeric_scale,
    a.actual_numeric_scale
  FROM actual_columns a
  LEFT JOIN expected_columns e
    ON lower(a.table_name) = lower(e.table_name)
   AND lower(a.column_name) = lower(e.column_name)
  WHERE e.column_name IS NULL
),
type_mismatches AS (
  SELECT
    e.table_name,
    e.column_name,
    'unexpected_data_type' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.table_name) = lower(a.table_name)
   AND lower(e.column_name) = lower(a.column_name)
  WHERE lower(e.expected_data_type) <> lower(a.actual_data_type)
),
nullability_mismatches AS (
  SELECT
    e.table_name,
    e.column_name,
    'unexpected_nullability' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.table_name) = lower(a.table_name)
   AND lower(e.column_name) = lower(a.column_name)
  WHERE upper(e.expected_is_nullable) <> upper(a.actual_is_nullable)
),
order_mismatches AS (
  SELECT
    e.table_name,
    e.column_name,
    'unexpected_ordinal_position' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.table_name) = lower(a.table_name)
   AND lower(e.column_name) = lower(a.column_name)
  WHERE e.expected_ordinal_position <> a.actual_ordinal_position
),
precision_scale_mismatches AS (
  SELECT
    e.table_name,
    e.column_name,
    'unexpected_precision_scale' AS mismatch_type,
    e.expected_ordinal_position,
    a.actual_ordinal_position,
    e.expected_data_type,
    a.actual_data_type,
    e.expected_is_nullable,
    a.actual_is_nullable,
    e.expected_numeric_precision,
    a.actual_numeric_precision,
    e.expected_numeric_scale,
    a.actual_numeric_scale
  FROM expected_columns e
  JOIN actual_columns a
    ON lower(e.table_name) = lower(a.table_name)
   AND lower(e.column_name) = lower(a.column_name)
  WHERE lower(e.expected_data_type) = 'decimal'
    AND (
      COALESCE(e.expected_numeric_precision, -1) <> COALESCE(a.actual_numeric_precision, -1)
      OR COALESCE(e.expected_numeric_scale, -1) <> COALESCE(a.actual_numeric_scale, -1)
    )
)
SELECT *
FROM missing_columns
UNION ALL
SELECT *
FROM extra_columns
UNION ALL
SELECT *
FROM type_mismatches
UNION ALL
SELECT *
FROM nullability_mismatches
UNION ALL
SELECT *
FROM order_mismatches
UNION ALL
SELECT *
FROM precision_scale_mismatches
ORDER BY table_name, mismatch_type, column_name;

-- -----------------------------------------------------------------------------
-- 2) Row-count placeholders (ReportDate / RegulationReportID / RegulationID / RegChange)
-- -----------------------------------------------------------------------------
SELECT
  'mifid2_report' AS table_name,
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate
UNION ALL
SELECT
  'mifid2_me_report',
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
GROUP BY ReportDate
UNION ALL
SELECT
  'mifid2_removed_op_partials',
  ReportDate,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
GROUP BY ReportDate;

SELECT
  ReportDate,
  RegulationReportID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate, RegulationReportID
ORDER BY ReportDate, RegulationReportID;

SELECT
  ReportDate,
  RegulationID,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate, RegulationID
ORDER BY ReportDate, RegulationID;

SELECT
  ReportDate,
  RegChange,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate, RegChange
ORDER BY ReportDate, RegChange;

-- -----------------------------------------------------------------------------
-- 3) Duplicate checks
-- -----------------------------------------------------------------------------
-- 3a) Required uniqueness intent for MIFID2_Report
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

-- 3b) Analogous uniqueness check for MIFID2_ME_Report
SELECT
  ReportDate,
  RegulationReportID,
  TransactionReferenceNumber,
  BackReportingIndicator,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
GROUP BY ReportDate, RegulationReportID, TransactionReferenceNumber, BackReportingIndicator
HAVING COUNT(*) > 1;

-- 3c) Position/open-close business-key duplicates (report)
SELECT
  ReportDate,
  CID,
  PositionID,
  OpenORClose,
  RegulationReportID,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
GROUP BY ReportDate, CID, PositionID, OpenORClose, RegulationReportID
HAVING COUNT(*) > 1;

-- 3d) Removed partials business-key duplicate placeholder
SELECT
  ReportDate,
  CID,
  PositionID,
  OriginalPositionID,
  OpenORClose,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
GROUP BY ReportDate, CID, PositionID, OriginalPositionID, OpenORClose
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 4) Required null checks
-- -----------------------------------------------------------------------------
SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transaction_reference_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_regchange_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN DateID IS NULL THEN 1 ELSE 0 END) AS null_dateid_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN TransactionReferenceNumber IS NULL OR length(trim(TransactionReferenceNumber)) = 0 THEN 1 ELSE 0 END) AS null_transaction_reference_count,
  SUM(CASE WHEN TradingDateTime IS NULL OR length(trim(TradingDateTime)) = 0 THEN 1 ELSE 0 END) AS null_tradingdatetime_count,
  SUM(CASE WHEN Quantity IS NULL OR length(trim(Quantity)) = 0 THEN 1 ELSE 0 END) AS null_quantity_count,
  SUM(CASE WHEN Price IS NULL OR length(trim(Price)) = 0 THEN 1 ELSE 0 END) AS null_price_count,
  SUM(CASE WHEN RegulationReportID IS NULL THEN 1 ELSE 0 END) AS null_regulationreportid_count,
  SUM(CASE WHEN RegChange IS NULL THEN 1 ELSE 0 END) AS null_regchange_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

SELECT
  SUM(CASE WHEN ReportDate IS NULL THEN 1 ELSE 0 END) AS null_reportdate_count,
  SUM(CASE WHEN CID IS NULL THEN 1 ELSE 0 END) AS null_cid_count,
  SUM(CASE WHEN PositionID IS NULL THEN 1 ELSE 0 END) AS null_positionid_count,
  SUM(CASE WHEN InstrumentID IS NULL THEN 1 ELSE 0 END) AS null_instrumentid_count,
  SUM(CASE WHEN OpenOccurred IS NULL THEN 1 ELSE 0 END) AS null_openoccurred_count,
  SUM(CASE WHEN CloseOccurred IS NULL THEN 1 ELSE 0 END) AS null_closeoccurred_count,
  SUM(CASE WHEN AmountInUnitsDecimal IS NULL THEN 1 ELSE 0 END) AS null_amountinunits_count,
  SUM(CASE WHEN InitForexRate IS NULL THEN 1 ELSE 0 END) AS null_initforexrate_count,
  SUM(CASE WHEN EndForexRate IS NULL THEN 1 ELSE 0 END) AS null_endforexrate_count,
  SUM(CASE WHEN LastOpPriceRate IS NULL THEN 1 ELSE 0 END) AS null_lastoppricerate_count,
  SUM(CASE WHEN RegulationID IS NULL THEN 1 ELSE 0 END) AS null_regulationid_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

-- -----------------------------------------------------------------------------
-- 5) Exclusion validation placeholders
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS excluded_instruments_present_in_mifid2_report
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments e
  ON CAST(r.InstrumentID AS STRING) = CAST(e.instrument_id AS STRING)
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE);

SELECT
  COUNT(*) AS excluded_position_ids_present_in_mifid2_report
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids e
  ON CAST(r.PositionID AS STRING) = CAST(e.position_id AS STRING)
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE);

-- Optional placeholder for MIFID2_Instruments_To_Exclude once mapping is confirmed.
/*
SELECT
  COUNT(*) AS mifid2_instruments_to_exclude_present_in_mifid2_report
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
JOIN {{mifid2_instruments_to_exclude_source}} x
  ON CAST(r.InstrumentID AS STRING) = CAST(x.InstrumentID AS STRING)
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE);
*/

-- -----------------------------------------------------------------------------
-- 6) Instrument coverage placeholders
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS report_rows_without_reg_instruments_scd_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd s
  ON r.InstrumentID = s.InstrumentID
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND s.InstrumentID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_reg_instruments_full_description_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech.gold_regtech_reg_instruments_full_description f
  ON r.InstrumentID = f.InstrumentID
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND f.InstrumentID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_specialchar_conversion_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion c
  ON r.InstrumentID = c.InstrumentID
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND c.InstrumentID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_futuresmetadata_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.trading.bronze_etoro_trade_futuresmetadata f
  ON r.InstrumentID = f.InstrumentID
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND f.InstrumentID IS NULL;

-- -----------------------------------------------------------------------------
-- 7) Movement/RegChange validation placeholders
-- -----------------------------------------------------------------------------
SELECT
  RegChange,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE)
GROUP BY RegChange
ORDER BY RegChange;

SELECT
  COUNT(*) AS report_rows_without_movement_stage_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions m
  ON r.PositionID = m.PositionID
 AND r.CID = m.CID
 AND r.ReportDate = m.ReportDate
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND m.PositionID IS NULL;

SELECT
  SUM(CASE WHEN IsOpenedAfterLastMigration = 1 THEN 1 ELSE 0 END) AS movement_rows_opened_after_last_migration,
  SUM(CASE WHEN IsOpenedAfterLastMigration = 0 THEN 1 ELSE 0 END) AS movement_rows_not_opened_after_last_migration
FROM main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

SELECT
  COUNT(DISTINCT CID) AS migration_population_cid_count_for_report_date
FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population
WHERE RunDate = CAST('{{report_date}}' AS DATE);

-- -----------------------------------------------------------------------------
-- 8) Removed partials validation placeholders
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS removed_partials_row_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

-- Placeholder reconciliation: source open rows tied to partial-close chains vs removed-partials rows.
SELECT
  rp.ReportDate,
  COUNT(*) AS removed_partials_rows
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials rp
WHERE rp.ReportDate = CAST('{{report_date}}' AS DATE)
GROUP BY rp.ReportDate;

SELECT
  COUNT(*) AS same_day_open_close_rows_in_removed_partials
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials rp
WHERE rp.ReportDate = CAST('{{report_date}}' AS DATE)
  AND DATE(rp.OpenOccurred) = DATE(rp.CloseOccurred);

-- -----------------------------------------------------------------------------
-- 9) Aggregate validation placeholders
-- -----------------------------------------------------------------------------
SELECT
  ReportDate,
  RegulationReportID,
  SUM(CAST(Quantity AS DOUBLE)) AS quantity_sum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE)
GROUP BY ReportDate, RegulationReportID
ORDER BY RegulationReportID;

SELECT
  ReportDate,
  RegulationReportID,
  SUM(CAST(Price AS DOUBLE)) AS price_sum
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE)
GROUP BY ReportDate, RegulationReportID
ORDER BY RegulationReportID;

SELECT
  ReportDate,
  RegulationReportID,
  COUNT(*) AS branch_level_count
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report
WHERE ReportDate = CAST('{{report_date}}' AS DATE)
GROUP BY ReportDate, RegulationReportID
ORDER BY RegulationReportID;

-- -----------------------------------------------------------------------------
-- 10) Source-to-output validation placeholders
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*) AS report_rows_without_customer_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
  ON r.CID = c.CID
 AND r.ReportDate = c.ReportDate
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer rc
  ON r.CID = rc.CID
 AND r.ReportDate = rc.ReportDate
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND c.CID IS NULL
  AND rc.CID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_position_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position p
  ON r.PositionID = p.PositionID
 AND r.CID = p.CID
 AND r.ReportDate = p.ReportDate
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND p.PositionID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_regchange_position_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position rp
  ON r.PositionID = rp.PositionID
 AND r.CID = rp.CID
 AND r.ReportDate = rp.ReportDate
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND r.RegChange > 0
  AND rp.PositionID IS NULL;

SELECT
  COUNT(*) AS report_rows_without_movement_source_match
FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_report r
LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions m
  ON r.PositionID = m.PositionID
 AND r.CID = m.CID
 AND r.ReportDate = m.ReportDate
WHERE r.ReportDate = CAST('{{report_date}}' AS DATE)
  AND m.PositionID IS NULL;
