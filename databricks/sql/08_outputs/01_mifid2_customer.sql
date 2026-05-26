-- Step 10: MIFID2_Customer output generation (gated authoring only).
--
-- In-scope target:
--   main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
--
-- Out of scope in this step:
--   MIFID2_RegChange_Customer, MIFID2_Report, MIFID2_ME_Report,
--   MIFID2_ETORO_Report, MIFID2_Hedge_Report, MIFID2_NPD_TRAX,
--   file delivery/SFTP/upload/response handling/production deployment/backfill.
--
-- IMPORTANT:
-- - Keep executable SQL gated while Step 9 customer/failed-trax inputs remain gated.
-- - Preserve SQL Server fallback behavior:
--     FTD = COALESCE(FirstTimeDepositSuccessDate, '2015-04-26')
--   without inventing upstream FTD source logic.
-- - Do not synthesize unresolved source mappings for:
--     PIN/UserAPI source contract
--     Reg_Ext_CustomerLatinName
--     Dictionary.Ext_TradeFund

WITH output_gates AS (
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer' AS target_object,
    'pending' AS executable_status,
    'Step 9 MIFID2_ext_Customer profiling and PIN/UserAPI source contract remain unresolved.' AS gate_reason
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer',
    'pending',
    'Step 9 MIFID2_Failed_TRAX remains gated; MIFID2_NPD_TRAX history/current availability dependency unresolved.'
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer',
    'pending',
    'Reg_Ext_CustomerLatinName mapping/profile gate is unresolved; translation path must remain gated.'
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer',
    'pending',
    'Dictionary.Ext_TradeFund Databricks mapping is unresolved; CopyFund/FundType enrichment must remain gated.'
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer',
    'pending',
    'ReplaceChar parity validation is pending; final customer output activation must remain gated.'
)
SELECT *
FROM output_gates;

-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATE ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- DDL contract source: reference/.../target_output_tables/MIFID2_Customer.sql
-- -----------------------------------------------------------------------------
/*
CREATE TABLE IF NOT EXISTS main.regtech_ops_stg.bi_output_regtechops_mifid2_customer (
  CID INT NOT NULL,
  RegulationID INT NOT NULL,
  PlayerLevelID INT NOT NULL,
  CountryID INT NOT NULL,
  FTD TIMESTAMP NOT NULL,
  AccountTypeID INT,
  Country STRING,
  CopyFund INT,
  CopyFundName STRING,
  FundTypeID INT,
  FundType STRING,
  IDType INT,
  PIN_Type STRING,
  PIN_LEI STRING,
  BirthDate DATE,
  FirstName STRING,
  LastName STRING,
  IsUKReport INT,
  IsEUReport INT,
  NotAllowedCONCAT BOOLEAN,
  ReportDate DATE NOT NULL,
  TraxEntity STRING,
  TraxAccount STRING
)
USING DELTA;

-- SQL Server PK intent is (ReportDate, CID, RegulationID). Enforce with validation checks.
DELETE FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
WHERE ReportDate = CAST('{{report_date}}' AS DATE);

INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_customer (
  CID,
  RegulationID,
  PlayerLevelID,
  CountryID,
  FTD,
  AccountTypeID,
  Country,
  CopyFund,
  CopyFundName,
  FundTypeID,
  FundType,
  IDType,
  PIN_Type,
  PIN_LEI,
  BirthDate,
  FirstName,
  LastName,
  IsUKReport,
  IsEUReport,
  NotAllowedCONCAT,
  ReportDate,
  TraxEntity,
  TraxAccount
)
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
no_concat AS (
  SELECT CountryID
  FROM VALUES (67), (95), (102), (126), (164), (191) AS t(CountryID)
),
ext_customers AS (
  SELECT
    e.CID,
    e.PlayerLevelID,
    e.PlayerStatusID,
    CASE
      WHEN COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(e.CitizenshipCountryID, 0), e.CountryID)
    END AS CountryID,
    e.LabelID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName)) AS FirstName,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName)) AS LastName,
    e.BirthDate,
    CASE WHEN e.RegulationID IN (4, 10) THEN 4 ELSE e.RegulationID END AS RegulationID,
    e.AccountTypeID,
    -- Step 9 customer staging does not currently provide FirstTimeDepositSuccessDate.
    -- Keep SQL Server fallback at output projection: COALESCE(..., '2015-04-26').
    CAST(NULL AS TIMESTAMP) AS FirstTimeDepositSuccessDate,
    COALESCE(e.Lei, ia.LEI) AS Lei,
    e.CountryIDByIP,
    e.curFirstName,
    e.curLastName,
    e.curBirthDate,
    e.PIN_ID,
    e.PIN_Type,
    UPPER(TRIM(e.PIN)) AS PIN,
    e.UAPI_CountryID,
    CASE
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 65520 AND 65533
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 65520 AND 65533
      ) THEN 'Chinese'
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.FirstName), 1, 1)) BETWEEN 1024 AND 1279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(e.LastName), 1, 1)) BETWEEN 1024 AND 1279
      ) THEN 'Cyrillic'
      ELSE NULL
    END AS Lang,
    rp.report_date AS ReportDate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
  JOIN run_parameters rp
    ON e.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON e.CID = ia.CID
  WHERE NOT (
    e.CountryID = 250
    OR (e.PlayerLevelID = 4 AND ia.CID IS NULL)
  )
),
failed_customers AS (
  SELECT
    f.CID,
    f.PlayerLevelID,
    f.PlayerStatusID,
    CASE
      WHEN COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID) = 144 THEN 143
      ELSE COALESCE(NULLIF(f.CitizenshipCountryID, 0), f.CountryID)
    END AS CountryID,
    f.LabelID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName)) AS FirstName,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName)) AS LastName,
    f.BirthDate,
    CAST(NULL AS INT) AS RegulationID,
    CAST(NULL AS INT) AS AccountTypeID,
    CAST(NULL AS TIMESTAMP) AS FirstTimeDepositSuccessDate,
    CAST(NULL AS STRING) AS Lei,
    f.CountryIDByIP,
    f.curFirstName,
    f.curLastName,
    f.curBirthDate,
    f.PIN_ID,
    f.PIN_Type,
    UPPER(TRIM(f.PIN)) AS PIN,
    f.UAPI_CountryID,
    CASE
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 65520 AND 65533
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 11904 AND 65279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 65520 AND 65533
      ) THEN 'Chinese'
      WHEN (
        unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.FirstName), 1, 1)) BETWEEN 1024 AND 1279
        OR unicode(substr(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(f.LastName), 1, 1)) BETWEEN 1024 AND 1279
      ) THEN 'Cyrillic'
      ELSE NULL
    END AS Lang,
    rp.report_date AS ReportDate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  JOIN run_parameters rp
    ON f.ReportDate = rp.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts ia
    ON f.CID = ia.CID
  WHERE NOT EXISTS (
    SELECT 1
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e
    WHERE e.CID = f.CID
      AND e.ReportDate = rp.report_date
  )
    AND NOT (
      f.CountryID = 250
      OR (f.PlayerLevelID = 4 AND ia.CID IS NULL)
    )
),
customer_union AS (
  SELECT * FROM ext_customers
  UNION ALL
  SELECT * FROM failed_customers
),
latin_names AS (
  SELECT
    c.CID,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(l.FirstName)) AS FirstName,
    UPPER(main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(l.LastName)) AS LastName
  FROM customer_union c
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname l
    ON c.CID = l.CID
  WHERE c.RegulationID <> 4
    AND c.Lang IS NOT NULL
),
customer_with_translation AS (
  SELECT
    c.*,
    CASE
      WHEN c.Lang = 'Chinese' AND ln.CID IS NOT NULL THEN ln.FirstName
      ELSE c.FirstName
    END AS translated_first_name,
    CASE
      WHEN c.Lang = 'Chinese' AND ln.CID IS NOT NULL THEN ln.LastName
      ELSE c.LastName
    END AS translated_last_name
  FROM customer_union c
  LEFT JOIN latin_names ln
    ON c.CID = ln.CID
),
customer_names_fixed AS (
  SELECT
    c.*,
    CASE
      WHEN length(COALESCE(c.translated_first_name, '')) = 0
           AND length(COALESCE(c.translated_last_name, '')) > 0
        THEN c.translated_last_name
      ELSE c.translated_first_name
    END AS final_first_name,
    CASE
      WHEN length(COALESCE(c.translated_last_name, '')) = 0
           AND length(COALESCE(c.translated_first_name, '')) > 0
        THEN c.translated_first_name
      ELSE c.translated_last_name
    END AS final_last_name
  FROM customer_with_translation c
),
final_rows AS (
  SELECT
    COALESCE(c.CID, 0) AS CID,
    COALESCE(c.RegulationID, 0) AS RegulationID,
    COALESCE(c.PlayerLevelID, 0) AS PlayerLevelID,
    c.CountryID,
    COALESCE(c.FirstTimeDepositSuccessDate, CAST('2015-04-26' AS TIMESTAMP)) AS FTD,
    c.AccountTypeID,
    country.Abbreviation AS Country,
    CASE WHEN funds.FundAccountID IS NOT NULL THEN 1 ELSE 0 END AS CopyFund,
    funds.FundName AS CopyFundName,
    funds.FundType AS FundTypeID,
    CASE
      WHEN funds.FundType = 1 THEN 'People'
      WHEN funds.FundType = 2 THEN 'Partners'
      WHEN funds.FundType = 3 THEN 'Market'
      ELSE NULL
    END AS FundType,
    CASE
      WHEN c.AccountTypeID = 9 THEN 3
      WHEN (c.Lei IS NOT NULL AND length(c.Lei) = 20) OR c.AccountTypeID = 2 THEN 2
      ELSE 1
    END AS IDType,
    CASE
      WHEN length(COALESCE(c.Lei, '')) = 20 OR COALESCE(c.AccountTypeID, 0) = 2 THEN 'LEI'
      ELSE COALESCE(c.PIN_Type, '')
    END AS PIN_Type,
    CASE
      WHEN c.Lei IS NOT NULL
           AND (length(COALESCE(c.Lei, '')) = 20 OR COALESCE(c.AccountTypeID, 0) = 2)
        THEN UPPER(c.Lei)
      WHEN NOT (length(COALESCE(c.Lei, '')) = 20 OR COALESCE(c.AccountTypeID, 0) = 2)
           AND length(COALESCE(c.PIN, '')) > 0
           AND nc.CountryID IS NULL
        THEN CONCAT(country.Abbreviation, c.PIN)
      WHEN NOT (length(COALESCE(c.Lei, '')) = 20 OR COALESCE(c.AccountTypeID, 0) = 2)
           AND length(COALESCE(c.PIN, '')) > 0
           AND nc.CountryID IS NOT NULL
        THEN c.PIN
      ELSE NULL
    END AS PIN_LEI,
    c.BirthDate,
    REPLACE(REPLACE(c.final_first_name, 'І', 'I'), 'Ё', 'Е') AS FirstName,
    REPLACE(REPLACE(c.final_last_name, 'І', 'I'), 'Ё', 'Е') AS LastName,
    CASE WHEN COALESCE(c.RegulationID, 0) = 2 THEN 1 ELSE 0 END AS IsUKReport,
    CASE WHEN COALESCE(c.RegulationID, 0) IN (1, 9, 11) THEN 1 ELSE 0 END AS IsEUReport,
    CASE WHEN nc.CountryID IS NOT NULL THEN TRUE ELSE FALSE END AS NotAllowedCONCAT,
    c.ReportDate,
    CASE
      WHEN c.AccountTypeID NOT IN (2, 9) OR c.Lei IS NULL THEN
        CASE
          WHEN c.RegulationID IN (1, 9, 11) THEN 'EU'
          WHEN c.RegulationID = 2 THEN 'UK'
          ELSE NULL
        END
      ELSE NULL
    END AS TraxEntity,
    CASE
      WHEN c.AccountTypeID NOT IN (2, 9) OR c.Lei IS NULL THEN
        CASE
          WHEN c.RegulationID IN (1, 9, 11) THEN '800388'
          WHEN c.RegulationID = 2 THEN '800389'
          ELSE NULL
        END
      ELSE NULL
    END AS TraxAccount
  FROM customer_names_fixed c
  JOIN main.regtech_ops_stg.bi_output_regtechops_vw_ext_country country
    ON c.CountryID = country.CountryID
  -- TODO: replace {{ext_tradefund_source}} with confirmed Databricks mapping for Dictionary.Ext_TradeFund.
  -- Required columns: FundAccountID, FundName, FundType
  LEFT JOIN {{ext_tradefund_source}} funds
    ON c.CID = funds.FundAccountID
  LEFT JOIN no_concat nc
    ON c.CountryID = nc.CountryID
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids excluded
    ON excluded.cid = c.CID
  WHERE excluded.cid IS NULL
)
SELECT
  CID,
  RegulationID,
  PlayerLevelID,
  CountryID,
  FTD,
  AccountTypeID,
  Country,
  CopyFund,
  CopyFundName,
  FundTypeID,
  FundType,
  IDType,
  PIN_Type,
  PIN_LEI,
  BirthDate,
  FirstName,
  LastName,
  IsUKReport,
  IsEUReport,
  NotAllowedCONCAT,
  ReportDate,
  TraxEntity,
  TraxAccount
FROM final_rows;
*/
