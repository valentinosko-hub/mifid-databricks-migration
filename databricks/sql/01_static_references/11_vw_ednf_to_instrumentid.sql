-- Compatibility view: EDNF to InstrumentID mapping

CREATE OR REPLACE VIEW main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid AS
SELECT
  InstrumentID,
  ContractDesc,
  IB_UnderlyingSymbol,
  ContractLongName,
  InstrumentID AS instrument_id,
  ContractDesc AS contract_desc,
  IB_UnderlyingSymbol AS ib_underlying_symbol,
  ContractLongName AS contract_long_name
FROM main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro;

