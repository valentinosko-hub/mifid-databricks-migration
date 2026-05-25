# GSheet / Excel / Fivetran Mapping

```text
ThirdParty_Fivetran.Fivetran.regtech.regulation_report_excluded_cids
-> main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids

ThirdParty_Fivetran.Fivetran.regulation.regtech_excluded_instruments
-> main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments

ThirdParty_Fivetran.Fivetran.regulation.regtech_excluded_position_ids
-> main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids

ThirdParty_Fivetran.Fivetran.google_sheets.isin_for_instrumentid_341
-> main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341

google_sheets.reg_liquidityaccountid_to_lei
-> main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei

ThirdParty_Fivetran.Fivetran.google_sheets.ed_n_f_to_istrumentid_etoro
-> main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro
```

## EDNF-to-InstrumentID note
The temporary EDNF table in `main.regtech_ops_stg` was manually uploaded from CSV and follows the staging cleanup-safe prefix.

Current columns:
- `InstrumentID`
- `ContractDesc`
- `IB_UnderlyingSymbol`
- `ContractLongName`

Create a prefixed compatibility view if needed:
`main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`.
