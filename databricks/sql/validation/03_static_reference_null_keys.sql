-- Validation: null-key checks for static references.

SELECT
  'EDNF.InstrumentID' AS check_name,
  COUNT(*) AS null_key_count
FROM main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro
WHERE InstrumentID IS NULL
UNION ALL
SELECT
  'InternalAccounts.CID' AS check_name,
  COUNT(*) AS null_key_count
FROM main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts
WHERE CID IS NULL
UNION ALL
SELECT
  'Dictionary.Ext_SpecialChar.Key' AS check_name,
  COUNT(*) AS null_key_count
FROM main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar
WHERE `Key` IS NULL;

