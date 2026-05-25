-- Compatibility view: Dictionary.Country / Ext_Country handling for MiFID customer logic

CREATE OR REPLACE VIEW main.regtech_ops_stg.bi_output_regtechops_vw_ext_country AS
SELECT *
FROM main.general.bronze_etoro_dictionary_country;

