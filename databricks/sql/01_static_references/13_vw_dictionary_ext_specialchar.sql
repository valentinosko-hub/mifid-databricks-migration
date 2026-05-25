-- Compatibility view: Dictionary.Ext_SpecialChar

CREATE OR REPLACE VIEW main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar AS
SELECT
  `Key`,
  `Value`,
  UpdateDate,
  `Key` AS replace_key,
  `Value` AS replace_value,
  UpdateDate AS update_date
FROM main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar;

