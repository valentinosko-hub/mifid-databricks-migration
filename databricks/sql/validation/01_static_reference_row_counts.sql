-- Validation: static reference row counts (base tables + compatibility views)

SELECT
  'main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar
UNION ALL
SELECT
  'main.regtech_ops_stg.bi_output_regtechops_vw_ext_country' AS object_name,
  COUNT(*) AS row_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_ext_country;

