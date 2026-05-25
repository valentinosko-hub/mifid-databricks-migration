# Phase 1A - Static/Reference Tables Already Available

This document captures static/reference datasets that are already available and should be used as inputs in Phase 1A.

## Confirmed available static/reference tables

| Logical reference | Source/system lineage | Existing Databricks table |
| --- | --- | --- |
| EDNF to InstrumentID mapping | `ThirdParty_Fivetran.Fivetran.google_sheets.ed_n_f_to_istrumentid_etoro` | `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro` |
| Internal accounts | `dbo.InternalAccounts` | `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts` |
| Dictionary special-character map | `Dictionary.Ext_SpecialChar` | `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar` |
| Country reference for MiFID customer logic | `Dictionary.Country` | `main.general.bronze_etoro_dictionary_country` |
| LiquidityAccountID to LEI mapping | `google_sheets.reg_liquidityaccountid_to_lei` | `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei` |
| Excluded CIDs | `ThirdParty_Fivetran.Fivetran.regtech.regulation_report_excluded_cids` | `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids` |
| Excluded instruments | `ThirdParty_Fivetran.Fivetran.regulation.regtech_excluded_instruments` | `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments` |
| Excluded position IDs | `ThirdParty_Fivetran.Fivetran.regulation.regtech_excluded_position_ids` | `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids` |
| ISIN for InstrumentID 341 | `ThirdParty_Fivetran.Fivetran.google_sheets.isin_for_instrumentid_341` | `main.regtech_stg.silver_sharepoint_transactionreporting_isin_for_instrumentid_341` |

## Known column notes for `main.regtech_ops_stg` static tables

- `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`: `InstrumentID`, `ContractDesc`, `IB_UnderlyingSymbol`, `ContractLongName`
- `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`: `CID`, `LEI`, `Description`
- `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`: `Key`, `Value`, `UpdateDate` (`Dictionary_Ext_SpecialChar.csv` has no header row; column order is `Key`, `Value`, `UpdateDate`)

## Safe module implementation artifacts (Module 1/2/3A)

Compatibility views defined in SQL artifacts:

- `main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`
- `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- `main.regtech_ops_stg.bi_output_regtechops_vw_dictionary_ext_specialchar`
- `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`

SQL files:
- `databricks/sql/01_static_references/01_static_reference_compatibility.sql`
- `databricks/sql/01_static_references/11_vw_ednf_to_instrumentid.sql`
- `databricks/sql/01_static_references/12_vw_internal_accounts.sql`
- `databricks/sql/01_static_references/13_vw_dictionary_ext_specialchar.sql`
- `databricks/sql/01_static_references/14_vw_ext_country.sql`

Validation scripts created:

- `databricks/sql/validation/01_static_reference_row_counts.sql`
- `databricks/sql/validation/02_static_reference_required_columns.sql`
- `databricks/sql/validation/03_static_reference_null_keys.sql`
- `databricks/sql/validation/04_static_reference_duplicate_keys.sql`
- `databricks/sql/validation/05_ednf_mapping_duplicate_checks.sql`
- `databricks/sql/validation/06_internalaccounts_cid_duplicate_checks.sql`
- `databricks/sql/validation/07_dictionary_ext_specialchar_duplicate_key_checks.sql`

## Deferred boundary

- `InstrumentMetaData_SpecialChar_Conversion` population is explicitly deferred to the `Pre_Regulation_Ext` dependency path because it needs `Reg_Ext_Trade_InstrumentMetaData`.

## Phase 1A usage boundary

- These objects are documented as already available reference/static inputs.
- Step 4 authored SQL files only for configuration, compatibility views, UDF, and validation queries.
- No SQL execution was performed in this step.
- No Databricks plugin usage, notebook work, or Pre_Regulation_Ext implementation was performed in this step.
