-- Step 16B1 consolidated readiness summary (SELECT-only).
-- Do not activate business logic from this file.

WITH expected_target_objects AS (
    SELECT 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_mifid2_ext_customer' AS table_name UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_regchange_customer' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_position' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_regchange_position' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_positionchangelog' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_ext_mirror' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_regulation_movments_positions' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_reg_liquidtyacount_scd' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_asic2_transactions' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_vw_mifid2_asic_transactions' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_customer' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_regchange_customer' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_report' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_me_report' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_removed_op_partials' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_etoro_report' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_hedge_report' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_mifid2_npd_trax'
),
required_static_references AS (
    SELECT 'main' AS table_catalog, 'regtech_ops_stg' AS table_schema, 'bi_output_regtechops_dbo_internal_accounts' AS table_name UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_dictionary_ext_specialchar' UNION ALL
    SELECT 'main', 'regtech_ops_stg', 'bi_output_regtechops_ed_f_to_istrument_id_e_toro'
),
known_blockers AS (
    SELECT 'access' AS blocker_category, 'main.pii_data.bronze_etoro_customer_customer' AS blocker_object, 'no schema access' AS blocker_status UNION ALL
    SELECT 'access', 'main.pii_data.bronze_etoro_history_customer', 'no schema access' UNION ALL
    SELECT 'access', 'dwh_daily_process.daily_snapshot.etoro_history_customer', 'no catalog access' UNION ALL
    SELECT 'access', 'dwh_daily_process.migration_tables.ext_fcupnl_currencypricemaxdatewithsplit', 'no catalog access' UNION ALL
    SELECT 'storage', 'main.trading.bronze_etoro_trade_currencyprice', 'storage/data scan failure' UNION ALL
    SELECT 'storage', 'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount', 'storage/data scan failure' UNION ALL
    SELECT 'history_seed', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax', 'history/cutover unresolved' UNION ALL
    SELECT 'history_seed', 'main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax', 'depends on NPD history policy'
),
module_validation_inventory AS (
    SELECT 'static references / UDFs' AS module_name, 'databricks/sql/01_static_references/01_static_reference_compatibility.sql' AS validation_file UNION ALL
    SELECT 'pre_regulation staging', 'databricks/sql/03_pre_regulation_ext/03_price_currency_validation.sql' UNION ALL
    SELECT 'pre_regulation staging', 'databricks/sql/03_pre_regulation_ext/06_non_price_validation.sql' UNION ALL
    SELECT 'regulation movements', 'databricks/sql/04_regulation_movements/03_regulation_movments_validation.sql' UNION ALL
    SELECT 'hedge liquidity/scd', 'databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql' UNION ALL
    SELECT 'asic2-compatible subset', 'databricks/sql/06_asic2_subset/06_asic2_validation.sql' UNION ALL
    SELECT 'mifid2_ext staging', 'databricks/sql/07_mifid2_ext/07_mifid2_ext_validation.sql' UNION ALL
    SELECT 'mifid2_customer', 'databricks/sql/08_outputs/01_mifid2_customer_validation.sql' UNION ALL
    SELECT 'mifid2_regchange_customer', 'databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql' UNION ALL
    SELECT 'mifid2_report/mifid2_me_report/removed_op_partials', 'databricks/sql/08_outputs/06_mifid2_report_final_reconciliation.sql' UNION ALL
    SELECT 'mifid2_etoro_report', 'databricks/sql/08_outputs/07_mifid2_etoro_report_validation.sql' UNION ALL
    SELECT 'mifid2_hedge_report', 'databricks/sql/08_outputs/08_mifid2_hedge_report_validation.sql' UNION ALL
    SELECT 'mifid2_npd_trax', 'databricks/sql/08_outputs/09_mifid2_npd_trax_validation.sql' UNION ALL
    SELECT 'cross-module readiness', 'databricks/sql/09_validation/07_phase1_readiness_summary.sql' UNION ALL
    SELECT 'cross-module readiness', 'databricks/sql/09_validation/08_cross_module_validation_manifest.sql' UNION ALL
    SELECT 'cross-module readiness', 'databricks/sql/09_validation/09_cross_module_dependency_gate_checks.sql'
)
SELECT
    'expected_target_object_existence' AS check_group,
    eto.table_catalog,
    eto.table_schema,
    eto.table_name,
    CASE WHEN ist.table_name IS NULL THEN 'missing' ELSE 'present' END AS check_result
FROM expected_target_objects eto
LEFT JOIN main.information_schema.tables ist
    ON ist.table_catalog = eto.table_catalog
   AND ist.table_schema = eto.table_schema
   AND ist.table_name = eto.table_name
ORDER BY eto.table_schema, eto.table_name;

SELECT
    'required_static_reference_existence' AS check_group,
    rsr.table_catalog,
    rsr.table_schema,
    rsr.table_name,
    CASE WHEN ist.table_name IS NULL THEN 'missing' ELSE 'present' END AS check_result
FROM required_static_references rsr
LEFT JOIN main.information_schema.tables ist
    ON ist.table_catalog = rsr.table_catalog
   AND ist.table_schema = rsr.table_schema
   AND ist.table_name = rsr.table_name
ORDER BY rsr.table_name;

SELECT
    'known_blocker_summary' AS check_group,
    blocker_category,
    blocker_object,
    blocker_status
FROM known_blockers
ORDER BY blocker_category, blocker_object;

SELECT
    'module_validation_inventory' AS check_group,
    module_name,
    validation_file
FROM module_validation_inventory
ORDER BY module_name, validation_file;

SELECT
    'phase1_execution_readiness' AS check_group,
    'Not ready for execution until open blockers are resolved' AS readiness_status,
    'Step 16B1 readiness and validation consolidation only' AS scope_status,
    'No business logic activation, no workflow/orchestration, no delivery/response handling' AS scope_boundary;
