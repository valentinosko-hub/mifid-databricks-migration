-- Validation: Dictionary.Ext_SpecialChar duplicate key checks.
-- Returns rows only when duplicates exist.

SELECT
  `Key`,
  COUNT(*) AS duplicate_count
FROM main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar
GROUP BY `Key`
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, `Key`;

