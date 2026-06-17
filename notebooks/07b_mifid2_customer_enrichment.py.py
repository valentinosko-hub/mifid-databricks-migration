# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "5"
# ///
# DBTITLE 1,Module 9b: MIFID2_Customer Enrichment
# MAGIC %md
# MAGIC # Module 9b: MIFID2_Customer Enrichment
# MAGIC
# MAGIC **SP parity:** `SP_MIFID2_Customer`
# MAGIC
# MAGIC **Purpose:** Build enriched `MIFID2_Customer` from raw `MIFID2_ext_Customer` + reference data.
# MAGIC Feeds both `mifid2_report` (NB08) and `mifid2_npd_trax` (NB10).
# MAGIC
# MAGIC **Enrichment:** ext_customer UNION failed_trax → Latin names → Country mapping → IDType/PIN_LEI → TraxEntity → Exclusions
# MAGIC
# MAGIC **PII ACCESS PENDING:** Tables are masked. When `main.pii_data` granted, swap masked → unmasked sources.
# MAGIC
# MAGIC **PIN COLUMNS MISSING:** `mifid2_ext_customer` lacks PIN_ID/PIN_Type/PIN. PIN_LEI = NULL until re-staged.
# MAGIC
# MAGIC **Target:** `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer` | Validation: 59,561 rows (SSMS 2026-06-14)

# COMMAND ----------

# DBTITLE 0,Parameters
dbutils.widgets.text("report_date", "2026-06-14", "Report Date (yyyy-MM-dd)")
report_date = dbutils.widgets.get("report_date")
print(f"Running Module 9b: MIFID2_Customer Enrichment for report_date = {report_date}")

# COMMAND ----------

# DBTITLE 1,Build MIFID2_Customer enrichment
# SP_MIFID2_Customer parity - full enrichment logic
# Sources: mifid2_ext_customer + mifid2_failed_trax + reference tables
# PII NOTE: Names are masked. Latin name translation skipped (5.9M row join, no value when masked).
#   When main.pii_data access granted: re-enable latin_names join and swap sources.
# PERF: Uses NOT EXISTS (not NOT IN) for anti-join. UNION ALL (not UNION) for speed.

customer_sql = f"""
WITH no_concat AS (SELECT CountryID FROM (VALUES (67),(95),(102),(126),(164),(191)) AS t(CountryID)),
ext_cust AS (
  SELECT a.CID, a.PlayerLevelID, a.PlayerStatusID, a.CountryID, a.LabelID,
    UPPER(a.FirstName) AS FirstName, UPPER(a.LastName) AS LastName, a.BirthDate,
    CASE WHEN a.RegulationID IN (4,10) THEN 4 ELSE a.RegulationID END AS RegulationID,
    a.AccountTypeID, a.Lei, a.CountryIDByIP,
    CAST(NULL AS INT) AS PIN_ID, CAST(NULL AS STRING) AS PIN_Type, CAST(NULL AS STRING) AS PIN,
    a.CitizenshipCountryID, a.ReportDate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer a
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts b ON a.CID = b.CID
  WHERE NOT (a.CountryID = 250 OR (a.PlayerLevelID = 4 AND b.CID IS NULL))
),
failed_cust AS (
  SELECT f.CID, f.PlayerLevelID, f.PlayerStatusID, f.CountryID, f.LabelID,
    UPPER(f.FirstName) AS FirstName, UPPER(f.LastName) AS LastName, f.BirthDate,
    CAST(NULL AS INT) AS RegulationID, CAST(NULL AS INT) AS AccountTypeID, CAST(NULL AS STRING) AS Lei,
    f.CountryIDByIP, f.PIN_ID, f.PIN_Type, UPPER(TRIM(f.PIN)) AS PIN,
    f.CitizenshipCountryID, CAST('{report_date}' AS DATE) AS ReportDate
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax f
  WHERE NOT EXISTS (SELECT 1 FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer e WHERE e.CID = f.CID)
),
cust_base AS (SELECT * FROM ext_cust UNION ALL SELECT * FROM failed_cust),
cust_final AS (
  SELECT
    COALESCE(a.CID, 0) AS CID, COALESCE(a.RegulationID, 0) AS RegulationID, COALESCE(a.PlayerLevelID, 0) AS PlayerLevelID,
    CASE WHEN COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID)=144 THEN 143
      ELSE COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID) END AS CountryID,
    CAST('2015-04-26' AS DATE) AS FTD,
    a.AccountTypeID, country.Abbreviation AS Country,
    CASE WHEN funds.FundAccountID IS NOT NULL THEN 1 ELSE 0 END AS CopyFund,
    funds.FundName AS CopyFundName, CAST(funds.FundType AS INT) AS FundTypeID,
    CASE WHEN funds.FundType=1 THEN 'People' WHEN funds.FundType=2 THEN 'Partners' WHEN funds.FundType=3 THEN 'Market' END AS FundType,
    CASE WHEN a.AccountTypeID=9 THEN 3 WHEN (a.Lei IS NOT NULL AND LENGTH(a.Lei)=20) OR a.AccountTypeID=2 THEN 2 ELSE 1 END AS IDType,
    CASE WHEN LENGTH(COALESCE(a.Lei,''))=20 OR COALESCE(a.AccountTypeID,0)=2 THEN 'LEI' ELSE COALESCE(a.PIN_Type,'') END AS PIN_Type,
    CASE WHEN a.Lei IS NOT NULL AND (LENGTH(COALESCE(a.Lei,''))=20 OR COALESCE(a.AccountTypeID,0)=2) THEN UPPER(a.Lei)
      WHEN NOT (LENGTH(COALESCE(a.Lei,''))=20 OR COALESCE(a.AccountTypeID,0)=2) AND LENGTH(COALESCE(a.PIN,''))>0 THEN CONCAT(country.Abbreviation, a.PIN)
    END AS PIN_LEI,
    a.BirthDate, a.FirstName, a.LastName,
    CASE WHEN COALESCE(a.RegulationID,0)=2 THEN 1 ELSE 0 END AS IsUKReport,
    CASE WHEN COALESCE(a.RegulationID,0) IN (1,9,11) THEN 1 ELSE 0 END AS IsEUReport,
    CASE WHEN nc.CountryID IS NOT NULL THEN 1 ELSE 0 END AS NotAllowedCONCAT,
    a.ReportDate,
    CASE WHEN COALESCE(a.AccountTypeID,0) NOT IN (2,9) OR a.Lei IS NULL THEN
      CASE WHEN COALESCE(a.RegulationID,0) IN (1,9,11) THEN 'EU' WHEN COALESCE(a.RegulationID,0)=2 THEN 'UK' END END AS TraxEntity,
    CASE WHEN COALESCE(a.AccountTypeID,0) NOT IN (2,9) OR a.Lei IS NULL THEN
      CASE WHEN COALESCE(a.RegulationID,0) IN (1,9,11) THEN 800388 WHEN COALESCE(a.RegulationID,0)=2 THEN 800389 END END AS TraxAccount
  FROM cust_base a
  JOIN main.general.bronze_etoro_dictionary_country country ON
    CASE WHEN COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID)=144 THEN 143
      ELSE COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID) END = country.CountryID
  LEFT JOIN main.bi_db.bronze_etoro_trade_fund funds ON a.CID = funds.FundAccountID
  LEFT JOIN no_concat nc ON
    CASE WHEN COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID)=144 THEN 143
      ELSE COALESCE(CASE WHEN a.CitizenshipCountryID=0 THEN a.CountryID ELSE a.CitizenshipCountryID END, a.CountryID) END = nc.CountryID
  LEFT JOIN main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids excl ON excl.cid = a.CID
  WHERE excl.cid IS NULL
)
SELECT * FROM cust_final
"""

print(f"Building MIFID2_Customer for {report_date}...")
df_cust = spark.sql(customer_sql)
cust_count = df_cust.count()
print(f"MIFID2_Customer enriched: {cust_count:,} rows")
df_cust.groupBy("TraxEntity").count().orderBy("TraxEntity").show()

# Persist to external location (survives nightly cleanup)
df_cust.write.format("delta").mode("overwrite").option("overwriteSchema", "true") \
    .option("path", "abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/RegTechOps/mifid2_customer") \
    .saveAsTable("main.regtech_ops_stg.bi_output_regtechops_mifid2_customer")

print(f"\u2713 mifid2_customer persisted: {cust_count:,} rows for {report_date}")

# COMMAND ----------

# DBTITLE 1,Validation: Compare against SSMS baseline
# MAGIC %sql
# MAGIC -- Validation: MIFID2_Customer enrichment output
# MAGIC -- SSMS baseline (2026-06-14): 59,561 rows, 23 columns
# MAGIC
# MAGIC SELECT
# MAGIC   COUNT(*) AS total_rows,
# MAGIC   COUNT(DISTINCT CID) AS distinct_cids,
# MAGIC   SUM(CASE WHEN TraxEntity IS NOT NULL THEN 1 ELSE 0 END) AS has_trax_entity,
# MAGIC   SUM(CASE WHEN IDType = 1 THEN 1 ELSE 0 END) AS individual,
# MAGIC   SUM(CASE WHEN IDType = 2 THEN 1 ELSE 0 END) AS corporate,
# MAGIC   SUM(CASE WHEN IDType = 3 THEN 1 ELSE 0 END) AS copyfund,
# MAGIC   SUM(CASE WHEN RegulationID = 0 THEN 1 ELSE 0 END) AS snapshot_rows,
# MAGIC   SUM(CASE WHEN RegulationID IN (1,9,11) THEN 1 ELSE 0 END) AS eu_rows,
# MAGIC   SUM(CASE WHEN RegulationID = 2 THEN 1 ELSE 0 END) AS uk_rows,
# MAGIC   SUM(CASE WHEN PIN_LEI IS NOT NULL THEN 1 ELSE 0 END) AS has_pin_lei,
# MAGIC   SUM(CASE WHEN Country IS NOT NULL THEN 1 ELSE 0 END) AS has_country
# MAGIC FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
