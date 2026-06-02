-- Step 16B1 cross-module validation manifest (SELECT-only).
-- Manifest rows are readiness metadata and do not execute module business logic.

SELECT
    module_name,
    expected_output_object,
    validation_file,
    upstream_dependencies,
    gate_status_placeholder,
    execution_readiness_placeholder
FROM (
    SELECT
        'static references / UDFs' AS module_name,
        'main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts; main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar; main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro; main.regtech_ops_stg.bi_output_regtechops_fn_replacechar' AS expected_output_object,
        'databricks/sql/01_static_references/01_static_reference_compatibility.sql' AS validation_file,
        'main.regtech_stg.silver_sharepoint_transactionreporting_*; static LOCATION tables' AS upstream_dependencies,
        '{{gate_status_static_refs}}' AS gate_status_placeholder,
        '{{execution_readiness_static_refs}}' AS execution_readiness_placeholder
    UNION ALL
    SELECT
        'pre_regulation_ext staging',
        'main.regtech_ops_stg.bi_output_regtechops_reg_currencyprice_ext; main.regtech_ops_stg.bi_output_regtechops_reg_ext_dailymaxprices; main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit; main.regtech_ops_stg.bi_output_regtechops_reg_ext_t_pricecandle60min',
        'databricks/sql/03_pre_regulation_ext/03_price_currency_validation.sql; databricks/sql/03_pre_regulation_ext/06_non_price_validation.sql',
        'main.trading.bronze_etoro_trade_currencyprice; main.dealing.bronze_pricelog_history_currencypricemaxdate; dwh_daily_process.* or certified main.dwh candidate',
        '{{gate_status_pre_regulation}}',
        '{{execution_readiness_pre_regulation}}'
    UNION ALL
    SELECT
        'regulation movements',
        'main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions',
        'databricks/sql/04_regulation_movements/03_regulation_movments_validation.sql',
        'main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population; main.trading.bronze_etoro_history_position_datafactory; split-price staging',
        '{{gate_status_reg_movements}}',
        '{{execution_readiness_reg_movements}}'
    UNION ALL
    SELECT
        'hedge liquidity/scd',
        'main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext; main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext; main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid; main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders; main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd',
        'databricks/sql/05_hedge_liquidity/04_hedge_liquidity_validation.sql',
        'main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount; main.trading.bronze_etoro_trade_liquidityaccounts; main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei',
        '{{gate_status_hedge_liquidity}}',
        '{{execution_readiness_hedge_liquidity}}'
    UNION ALL
    SELECT
        'asic2-compatible subset',
        'main.regtech_ops_stg.bi_output_regtechops_asic2_transactions; main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions; main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions',
        'databricks/sql/06_asic2_subset/06_asic2_validation.sql',
        'position/history/open positions sources; instrument/dictionary sources; Step 5 dependencies',
        '{{gate_status_asic2}}',
        '{{execution_readiness_asic2}}'
    UNION ALL
    SELECT
        'mifid2_ext staging',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror; main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog; main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax',
        'databricks/sql/07_mifid2_ext/07_mifid2_ext_validation.sql',
        'main.pii_data.* customer tables; history/position/mirror sources; migration population',
        '{{gate_status_mifid2_ext}}',
        '{{execution_readiness_mifid2_ext}}'
    UNION ALL
    SELECT
        'mifid2_customer',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_customer',
        'databricks/sql/08_outputs/01_mifid2_customer_validation.sql',
        'mifid2_ext_customer; mifid2_failed_trax; dictionary/customer-latin-name prerequisites',
        '{{gate_status_mifid2_customer}}',
        '{{execution_readiness_mifid2_customer}}'
    UNION ALL
    SELECT
        'mifid2_regchange_customer',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer',
        'databricks/sql/08_outputs/02_mifid2_regchange_customer_validation.sql',
        'mifid2_ext_regchange_customer; migration interval parity; dictionary/customer-latin-name prerequisites',
        '{{gate_status_mifid2_regchange_customer}}',
        '{{execution_readiness_mifid2_regchange_customer}}'
    UNION ALL
    SELECT
        'mifid2_report/mifid2_me_report/mifid2_removed_op_partials',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_report; main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report; main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials',
        'databricks/sql/08_outputs/06_mifid2_report_final_reconciliation.sql',
        'regulation movements; split-price staging; instrument metadata conversion; futures metadata certification; exclusions',
        '{{gate_status_mifid2_report_family}}',
        '{{execution_readiness_mifid2_report_family}}'
    UNION ALL
    SELECT
        'mifid2_etoro_report',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report',
        'databricks/sql/08_outputs/07_mifid2_etoro_report_validation.sql',
        'mifid2_asic2_transactions; compatibility view parity; ETORO exclusions',
        '{{gate_status_mifid2_etoro_report}}',
        '{{execution_readiness_mifid2_etoro_report}}'
    UNION ALL
    SELECT
        'mifid2_hedge_report',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report',
        'databricks/sql/08_outputs/08_mifid2_hedge_report_validation.sql',
        'hedge ext staging; liquidity SCD; LEI coverage; EDNF/IB mapping; instrument/dictionary coverage',
        '{{gate_status_mifid2_hedge_report}}',
        '{{execution_readiness_mifid2_hedge_report}}'
    UNION ALL
    SELECT
        'mifid2_npd_trax',
        'main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax',
        'databricks/sql/08_outputs/09_mifid2_npd_trax_validation.sql',
        'mifid2_customer; mifid2_regchange_customer; mifid2_report; prior NPD history seed',
        '{{gate_status_mifid2_npd_trax}}',
        '{{execution_readiness_mifid2_npd_trax}}'
) manifest
ORDER BY module_name;
