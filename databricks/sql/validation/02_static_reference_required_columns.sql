-- Validation: required columns for static reference inputs and compatibility views.
-- Expected result: zero rows (missing columns only).
--
-- Note: vw_ext_country schema is sourced from main.general.bronze_etoro_dictionary_country
-- and is intentionally not hard-pinned here yet. Schema-level assertions for that view
-- are deferred until customer-logic column contract is finalized.

WITH required_columns AS (
  SELECT 'bi_output_regtechops_ed_f_to_istrument_id_e_toro' AS table_name, 'InstrumentID' AS column_name UNION ALL
  SELECT 'bi_output_regtechops_ed_f_to_istrument_id_e_toro', 'ContractDesc' UNION ALL
  SELECT 'bi_output_regtechops_ed_f_to_istrument_id_e_toro', 'IB_UnderlyingSymbol' UNION ALL
  SELECT 'bi_output_regtechops_ed_f_to_istrument_id_e_toro', 'ContractLongName' UNION ALL
  SELECT 'bi_output_regtechops_dbo_internal_accounts', 'CID' UNION ALL
  SELECT 'bi_output_regtechops_dbo_internal_accounts', 'LEI' UNION ALL
  SELECT 'bi_output_regtechops_dbo_internal_accounts', 'Description' UNION ALL
  SELECT 'bi_output_regtechops_dictionary_ext_specialchar', 'Key' UNION ALL
  SELECT 'bi_output_regtechops_dictionary_ext_specialchar', 'Value' UNION ALL
  SELECT 'bi_output_regtechops_dictionary_ext_specialchar', 'UpdateDate' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'InstrumentID' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'ContractDesc' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'IB_UnderlyingSymbol' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'ContractLongName' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'instrument_id' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'contract_desc' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'ib_underlying_symbol' UNION ALL
  SELECT 'bi_output_regtechops_vw_ednf_to_instrumentid', 'contract_long_name' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'CID' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'LEI' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'Description' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'cid' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'lei' UNION ALL
  SELECT 'bi_output_regtechops_vw_internal_accounts', 'description' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'Key' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'Value' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'UpdateDate' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'replace_key' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'replace_value' UNION ALL
  SELECT 'bi_output_regtechops_vw_dictionary_ext_specialchar', 'update_date'
),
actual_columns AS (
  SELECT
    table_name,
    column_name
  FROM system.information_schema.columns
  WHERE table_catalog = 'main'
    AND table_schema = 'regtech_ops_stg'
    AND table_name IN (
      'bi_output_regtechops_ed_f_to_istrument_id_e_toro',
      'bi_output_regtechops_dbo_internal_accounts',
      'bi_output_regtechops_dictionary_ext_specialchar',
      'bi_output_regtechops_vw_ednf_to_instrumentid',
      'bi_output_regtechops_vw_internal_accounts',
      'bi_output_regtechops_vw_dictionary_ext_specialchar'
    )
)
SELECT
  rc.table_name,
  rc.column_name AS missing_column
FROM required_columns rc
LEFT JOIN actual_columns ac
  ON rc.table_name = ac.table_name
 AND lower(rc.column_name) = lower(ac.column_name)
WHERE ac.column_name IS NULL
ORDER BY rc.table_name, rc.column_name;

