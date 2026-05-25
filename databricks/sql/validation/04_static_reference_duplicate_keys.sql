-- Validation: duplicate-key checks for static references.
-- Returns rows only when duplicates exist.

SELECT
  'EDNF.InstrumentID' AS check_name,
  InstrumentID AS key_value,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro
GROUP BY InstrumentID
HAVING COUNT(*) > 1

UNION ALL

SELECT
  'InternalAccounts.CID' AS check_name,
  CAST(CID AS STRING) AS key_value,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts
GROUP BY CID
HAVING COUNT(*) > 1

UNION ALL

SELECT
  'Dictionary.Ext_SpecialChar.Key' AS check_name,
  CAST(`Key` AS STRING) AS key_value,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar
GROUP BY `Key`
HAVING COUNT(*) > 1;

