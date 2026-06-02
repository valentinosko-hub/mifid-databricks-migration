-- Step 16B1 dependency gate checks (SELECT-only).
-- Placeholder values remain intentionally gated until execution inputs are available.

WITH expected_module_outputs AS (
    SELECT 'mifid2_ext staging' AS module_name, 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_customer' AS table_name UNION ALL
    SELECT 'mifid2_ext staging', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_regchange_customer' UNION ALL
    SELECT 'mifid2_ext staging', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_position' UNION ALL
    SELECT 'mifid2_ext staging', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_failed_trax' UNION ALL
    SELECT 'customer outputs', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_customer' UNION ALL
    SELECT 'customer outputs', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_regchange_customer' UNION ALL
    SELECT 'main report outputs', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_report' UNION ALL
    SELECT 'main report outputs', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_me_report' UNION ALL
    SELECT 'main report outputs', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_removed_op_partials' UNION ALL
    SELECT 'etoro output', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_etoro_report' UNION ALL
    SELECT 'hedge output', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_hedge_report' UNION ALL
    SELECT 'npd_trax output', 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_npd_trax'
)
SELECT
    'missing_expected_module_outputs' AS check_group,
    emo.module_name,
    emo.table_catalog,
    emo.table_schema,
    emo.table_name,
    CASE WHEN ist.table_name IS NULL THEN 'missing' ELSE 'present' END AS object_status
FROM expected_module_outputs emo
LEFT JOIN main.information_schema.tables ist
    ON ist.table_catalog = emo.table_catalog
   AND ist.table_schema = emo.table_schema
   AND ist.table_name = emo.table_name
ORDER BY emo.module_name, emo.table_name;

SELECT
    'active_blockers' AS check_group,
    blocker_category,
    blocker_object,
    blocker_status,
    required_owner
FROM (
    SELECT 'access' AS blocker_category, 'main.pii_data.bronze_etoro_customer_customer' AS blocker_object, 'no schema access' AS blocker_status, 'DE/Data Platform + Governance' AS required_owner UNION ALL
    SELECT 'access', 'main.pii_data.bronze_etoro_history_customer', 'no schema access', 'DE/Data Platform + Governance' UNION ALL
    SELECT 'access', 'dwh_daily_process.daily_snapshot.etoro_history_customer', 'no catalog access', 'DE/Data Platform' UNION ALL
    SELECT 'access', 'dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit', 'no catalog access', 'DE/Data Platform' UNION ALL
    SELECT 'storage', 'main.trading.bronze_etoro_trade_currencyprice', 'storage/data scan failure', 'DE/Data Platform' UNION ALL
    SELECT 'storage', 'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount', 'storage/data scan failure', 'DE/Data Platform' UNION ALL
    SELECT 'history_seed', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax', 'history/cutover unresolved', 'Data Engineering + SME' UNION ALL
    SELECT 'history_seed', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax', 'depends on NPD history policy', 'Data Engineering + SME' UNION ALL
    SELECT 'business', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report', 'RecordID strategy unresolved', 'Business/SME' UNION ALL
    SELECT 'business', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report', 'transaction reference parity unresolved', 'Business/SME'
) blockers
ORDER BY blocker_category, blocker_object, blocker_status;

SELECT
    'placeholder_dependency_status' AS check_group,
    dependency_placeholder,
    dependency_purpose,
    activation_rule
FROM (
    SELECT '{{trades_final_source}}' AS dependency_placeholder, 'Step 12 final reconciliation source checks' AS dependency_purpose, 'keep gated until source materialized' AS activation_rule UNION ALL
    SELECT '{{report_metadata_source}}', 'Step 12 metadata source checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{removed_partial_candidates_source}}', 'Step 12 removed partial reconciliation checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{hedge_eu_source}}', 'Step 14 branch reconciliation checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{hedge_eu_uk_source}}', 'Step 14 branch reconciliation checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{hedge_uk_source}}', 'Step 14 branch reconciliation checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{npd_customer_all_source}}', 'Step 15 source contribution checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{npd_new_candidates_source}}', 'Step 15 source contribution checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{npd_existing_changed_source}}', 'Step 15 source contribution checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{npd_failed_retry_source}}', 'Step 15 source contribution checks', 'keep gated until source materialized' UNION ALL
    SELECT '{{sqlserver_npd_trax_baseline_source}}', 'Step 15 SQL Server baseline comparison', 'keep optional and gated until baseline provided'
) placeholders
ORDER BY dependency_placeholder;

SELECT
    'output_dependencies_by_module' AS check_group,
    module_name,
    upstream_dependency,
    gate_type
FROM (
    SELECT 'static references / UDFs' AS module_name, 'static LOCATION tables in main.regtech_ops_stg' AS upstream_dependency, 'source availability' AS gate_type UNION ALL
    SELECT 'pre_regulation staging', 'currency price + split candidates + candle/max price sources', 'source access and certification' UNION ALL
    SELECT 'regulation movements', 'migration population + position history + split-price enrichment', 'materialization + parity' UNION ALL
    SELECT 'hedge liquidity/scd', 'hedge server mapping + liquidity + LEI', 'storage access + seed/cutover' UNION ALL
    SELECT 'asic2-compatible subset', 'open positions + changelog + customer profile + instruments', 'source contract + seed window' UNION ALL
    SELECT 'mifid2_ext staging', 'customer/history position/mirror + migration population', 'PII access + source contract' UNION ALL
    SELECT 'mifid2_customer', 'mifid2_ext_customer + mifid2_failed_trax + trade fund + latin-name', 'dependency + certification' UNION ALL
    SELECT 'mifid2_regchange_customer', 'mifid2_ext_regchange_customer + trade fund + latin-name', 'dependency + certification' UNION ALL
    SELECT 'mifid2_report/mifid2_me_report/mifid2_removed_op_partials', 'movements + instruments + dictionary + futures + exclusions', 'dependency + parity' UNION ALL
    SELECT 'mifid2_etoro_report', 'asic2 compatibility + exclusions + instrument classification parity', 'dependency + business decision' UNION ALL
    SELECT 'mifid2_hedge_report', 'hedge ext/sources + liquidity scd + EDNF/IB + dictionary', 'dependency + business decision' UNION ALL
    SELECT 'mifid2_npd_trax', 'customer/regchange/report outputs + prior npd history', 'dependency + history seed'
) deps
ORDER BY module_name, upstream_dependency;

SELECT
    'target_namespace_guardrail' AS check_group,
    target_object,
    CASE
        WHEN target_object LIKE 'main.regtech_ops_stg.bi_output_regtechops_%' THEN 'allowed namespace'
        ELSE 'review required'
    END AS namespace_check
FROM (
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer' AS target_object UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_report' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report' UNION ALL
    SELECT 'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax'
) targets
ORDER BY target_object;

WITH required_static_references AS (
    SELECT 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_dbo_internal_accounts' AS table_name UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_dictionary_ext_specialchar' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_ed_f_to_istrument_id_e_toro'
)
SELECT
    'static_reference_availability' AS check_group,
    rsr.table_catalog,
    rsr.table_schema,
    rsr.table_name,
    CASE WHEN ist.table_name IS NULL THEN 'missing' ELSE 'present' END AS object_status
FROM required_static_references rsr
LEFT JOIN main.information_schema.tables ist
    ON ist.table_catalog = rsr.table_catalog
   AND ist.table_schema = rsr.table_schema
   AND ist.table_name = rsr.table_name
ORDER BY rsr.table_name;

SELECT
    'pii_access_status_placeholders' AS check_group,
    pii_object,
    '{{pii_access_status}}' AS access_status_placeholder,
    '{{pii_access_owner_update}}' AS owner_update_placeholder
FROM (
    SELECT 'main.pii_data.bronze_etoro_customer_customer' AS pii_object UNION ALL
    SELECT 'main.pii_data.bronze_etoro_history_customer'
) pii
ORDER BY pii_object;

SELECT
    'storage_blocker_placeholders' AS check_group,
    storage_object,
    '{{storage_issue_status}}' AS storage_status_placeholder,
    '{{storage_owner_update}}' AS owner_update_placeholder
FROM (
    SELECT 'main.trading.bronze_etoro_trade_currencyprice' AS storage_object UNION ALL
    SELECT 'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount'
) storage
ORDER BY storage_object;
