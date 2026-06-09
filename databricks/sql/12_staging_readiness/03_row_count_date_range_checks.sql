-- Staging readiness: row-count and date-range checks (SELECT-only).
-- No CREATE, INSERT, UPDATE, DELETE, MERGE, DROP.
-- Run only after 01_source_table_existence_checks.sql passes for target objects.
-- Parameters: {{report_date}}, {{source_catalog}}, {{source_schema}}, {{target_catalog}},
--             {{target_schema}}, {{object_prefix}}
--
-- This file uses information_schema visibility only — no unconditional FROM main.* scans.
-- Visible objects return RUN_MANUAL with manual COUNT guidance; resolve before full readiness.
-- Preferred Reg_CurrencyPrice_Ext source: main.dealing.bronze_pricelog_history_currencyprice.
-- Fallback main.trading.bronze_etoro_trade_currencyprice is SKIP (not preferred).

WITH run_params AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date,
    date_sub(CAST('{{report_date}}' AS DATE), 1) AS prior_date
),
count_manifest AS (
  -- price / currency / split
  SELECT 'price_currency_split' AS check_group,
         'main.dealing.bronze_pricelog_history_currencyprice' AS object_name,
         'row_count_report_window' AS check_name,
         'main' AS cat, 'dealing' AS sch, 'bronze_pricelog_history_currencyprice' AS tbl,
         false AS is_todo, false AS is_optional, false AS is_fallback,
         '>0 rows where Occurred between prior_date and report_date' AS expected_rule,
         'Occurred BETWEEN prior_date AND report_date' AS filter_hint UNION ALL
  SELECT 'price_currency_split',
         'main.trading.bronze_etoro_trade_currencyprice',
         'row_count_policy',
         'main', 'trading', 'bronze_etoro_trade_currencyprice',
         false, true, true,
         'not_used_for_readiness',
         'fallback only — does not satisfy Reg_CurrencyPrice_Ext readiness' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit',
         'row_count_report_window',
         'main', 'dealing', 'bronze_pricelog_candles_currencypricemaxdatewithsplit',
         false, false, false,
         '>0 rows where Occurred between prior_date and report_date',
         'Occurred BETWEEN prior_date AND report_date' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_history_currencypricemaxdate',
         'row_count_report_window',
         'main', 'dealing', 'bronze_pricelog_history_currencypricemaxdate',
         false, false, false,
         '>0 rows where Occurred between prior_date and report_date',
         'Occurred BETWEEN prior_date AND report_date' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_candles_candles_t_pricecandle60min',
         'row_count_report_window',
         'main', 'dealing', 'bronze_candles_candles_t_pricecandle60min',
         false, false, false,
         '>0 rows where DateFrom between prior_date and report_date',
         'DateFrom BETWEEN prior_date AND report_date' UNION ALL
  SELECT 'price_currency_split',
         'main.dealing.bronze_pricelog_history_splitratio',
         'row_count_total',
         'main', 'dealing', 'bronze_pricelog_history_splitratio',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — validate split coverage manually' UNION ALL
  -- non-price Reg_Ext
  SELECT 'non_price_reg_ext',
         'main.trading.bronze_etoro_trade_getinstrument',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_trade_getinstrument',
         false, false, false,
         '>0 total rows',
         'COUNT(*)' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.trading.bronze_etoro_trade_instrumentmetadata',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_trade_instrumentmetadata',
         false, false, false,
         '>0 total rows',
         'COUNT(*)' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.general.bronze_etoro_dictionary_currency',
         'row_count_total',
         'main', 'general', 'bronze_etoro_dictionary_currency',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — static dictionary' UNION ALL
  SELECT 'non_price_reg_ext',
         'main.general.bronze_etoro_dictionary_currencytype',
         'row_count_total',
         'main', 'general', 'bronze_etoro_dictionary_currencytype',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — static dictionary' UNION ALL
  SELECT 'non_price_reg_ext',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_instruments_scd',
         'row_count_total',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_scd',
         true, false, false,
         '>0 total rows when certified',
         'TODO: DE-migrated gold name' UNION ALL
  SELECT 'non_price_reg_ext',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_instruments_full_description',
         'row_count_total',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_instruments_full_description',
         true, false, false,
         '>0 total rows when certified',
         'TODO: DE-migrated gold name' UNION ALL
  -- regulation movement
  SELECT 'regulation_movement',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_migrationinout_population',
         'row_count_report_date',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_migrationinout_population',
         true, false, false,
         '>0 rows where RunDate = report_date',
         'RunDate = report_date' UNION ALL
  SELECT 'regulation_movement',
         '{{source_catalog}}.{{source_schema}}.gold_regtech_reg_regulationinoutdailydata',
         'row_count_report_date',
         '{{source_catalog}}', '{{source_schema}}', 'gold_regtech_reg_regulationinoutdailydata',
         true, false, false,
         '>0 rows where ReportDate = report_date',
         'ReportDate = report_date' UNION ALL
  SELECT 'regulation_movement',
         'main.trading.silver_etoro_trade_position',
         'row_count_total',
         'main', 'trading', 'silver_etoro_trade_position',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — upstream position source' UNION ALL
  SELECT 'regulation_movement',
         'main.trading.bronze_etoro_history_position_datafactory',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_history_position_datafactory',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — history position source' UNION ALL
  -- hedge / liquidity
  SELECT 'hedge_liquidity',
         'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount',
         'row_count_total',
         'main', 'bi_db', 'bronze_etoro_hedge_hedgeservertoliquidityaccount',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — HedgeServerToLiquidityAccount mapping' UNION ALL
  SELECT 'hedge_liquidity',
         'main.trading.bronze_etoro_trade_liquidityaccounts',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_trade_liquidityaccounts',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — LiquidityAccounts' UNION ALL
  SELECT 'hedge_liquidity',
         'main.trading.bronze_etoro_trade_liquidityproviders',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_trade_liquidityproviders',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — LiquidityProviders' UNION ALL
  SELECT 'hedge_liquidity',
         'main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
         'row_count_total',
         'main', 'general', 'bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — LEI mapping sheet' UNION ALL
  SELECT 'hedge_liquidity',
         'main.bi_db.bronze_etoro_trade_liquidityprovidertype',
         'row_count_total',
         'main', 'bi_db', 'bronze_etoro_trade_liquidityprovidertype',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — LiquidityProviderType' UNION ALL
  -- MIFID2_ext non-PII
  SELECT 'mifid2_ext_non_pii',
         'main.bi_db.bronze_etoro_trade_positionforexternaluse',
         'row_count_report_window',
         'main', 'bi_db', 'bronze_etoro_trade_positionforexternaluse',
         false, false, false,
         '>0 open positions on report_date',
         'OpenOccurred <= report_date AND (CloseOccurred IS NULL OR CloseOccurred >= report_date)' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_position_datafactory',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_history_position_datafactory',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — history position' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_positionchangelog',
         'row_count_report_window',
         'main', 'trading', 'bronze_etoro_history_positionchangelog',
         false, false, false,
         '>0 rows where Occurred between prior_date and report_date',
         'Occurred BETWEEN prior_date AND report_date' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.trading.bronze_etoro_history_mirror',
         'row_count_total',
         'main', 'trading', 'bronze_etoro_history_mirror',
         false, false, false,
         '>0 total rows',
         'COUNT(*) — Mirror' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         'main.dealing.bronze_etoro_hedge_executionlog',
         'row_count_report_window',
         'main', 'dealing', 'bronze_etoro_hedge_executionlog',
         false, false, false,
         '>0 rows where ExecutionTime between prior_date and report_date',
         'ExecutionTime BETWEEN prior_date AND report_date' UNION ALL
  SELECT 'mifid2_ext_non_pii',
         '{{target_catalog}}.{{target_schema}}.{{object_prefix}}mifid2_npd_trax',
         'row_count_policy',
         '{{target_catalog}}', '{{target_schema}}', '{{object_prefix}}mifid2_npd_trax',
         true, true, false,
         'gated_dependency',
         'GATED — NPD seed/history required; skip on first pass'
),
table_visibility AS (
  SELECT
    m.*,
    CASE WHEN t.table_name IS NOT NULL THEN true ELSE false END AS is_visible
  FROM count_manifest m
  LEFT JOIN system.information_schema.tables t
    ON lower(t.table_catalog) = lower(m.cat)
   AND lower(t.table_schema) = lower(m.sch)
   AND lower(t.table_name) = lower(m.tbl)
),
manifest_output AS (
  SELECT
    tv.check_group,
    tv.object_name,
    tv.check_name,
    tv.expected_rule AS expected,
    CASE
      WHEN tv.is_fallback THEN 'not_enforced'
      WHEN tv.is_todo THEN 'NOT_RUN'
      WHEN NOT tv.is_visible THEN 'NOT_RUN'
      ELSE 'RUN_MANUAL'
    END AS actual,
    CASE
      WHEN tv.is_fallback THEN 'SKIP'
      WHEN tv.is_todo THEN 'TODO'
      WHEN tv.is_optional AND tv.check_name = 'row_count_policy' THEN 'SKIP'
      WHEN NOT tv.is_visible THEN 'NOT_RUN'
      WHEN tv.object_name = 'main.dealing.bronze_pricelog_history_currencyprice' AND tv.is_visible THEN 'RUN_MANUAL'
      WHEN tv.object_name = 'main.bi_db.bronze_etoro_trade_positionforexternaluse' AND tv.is_visible THEN 'RUN_MANUAL'
      ELSE 'RUN_MANUAL'
    END AS status,
    CASE
      WHEN tv.is_fallback THEN
        'SKIP: readable fallback for CurrencyPrice — preferred source is main.dealing.bronze_pricelog_history_currencyprice; fallback does not satisfy Reg_CurrencyPrice_Ext readiness'
      WHEN tv.is_todo THEN
        concat('TODO: ', tv.filter_hint, ' — resolve DE-migrated object name before automated count')
      WHEN tv.is_optional AND tv.check_name = 'row_count_policy' THEN
        tv.filter_hint
      WHEN NOT tv.is_visible THEN
        concat('NOT_RUN: table not visible in information_schema — confirm 01_source_table_existence_checks.sql PASS before manual COUNT; filter: ', tv.filter_hint)
      WHEN tv.object_name = 'main.dealing.bronze_pricelog_history_currencyprice' THEN
        concat('RUN_MANUAL: SELECT COUNT(*) FROM ', tv.object_name,
               ' WHERE CAST(Occurred AS DATE) BETWEEN prior_date AND report_date; FAIL if 0; report_date=',
               CAST((SELECT report_date FROM run_params) AS STRING))
      WHEN tv.object_name = 'main.bi_db.bronze_etoro_trade_positionforexternaluse' THEN
        concat('RUN_MANUAL: SELECT COUNT(*) FROM ', tv.object_name,
               ' WHERE CAST(OpenOccurred AS DATE) <= report_date AND (CloseOccurred IS NULL OR CAST(CloseOccurred AS DATE) >= report_date);',
               ' PASS if >0 for required report_date window; WARN if only full-table count >0 but window=0; FAIL if table empty; report_date=',
               CAST((SELECT report_date FROM run_params) AS STRING))
      ELSE
        concat('RUN_MANUAL: SELECT COUNT(*) FROM ', tv.object_name,
               CASE WHEN tv.check_name LIKE '%report%' THEN concat(' WHERE ', tv.filter_hint) ELSE '' END,
               '; FAIL if required source returns 0; report_date=',
               CAST((SELECT report_date FROM run_params) AS STRING))
    END AS notes
  FROM table_visibility tv
)
SELECT
  check_group,
  object_name,
  check_name,
  expected,
  actual,
  status,
  notes
FROM manifest_output
ORDER BY check_group, object_name, check_name;
