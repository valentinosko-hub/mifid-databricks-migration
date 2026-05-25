# Known Differences (Current Safe Module)

This document tracks known or intentional differences for the currently implemented safe module scope:

- Environment/config/naming helpers
- Static reference compatibility views
- `ReplaceChar` UDF
- Validation SQL scripts for static references and `ReplaceChar`

## Scope and non-goals in this step

- No `Pre_Regulation_Ext` staging implementation.
- No `MIFID2_ext` staging implementation.
- No final MiFID output table-generation implementation.
- No population logic for `InstrumentMetaData_SpecialChar_Conversion`.
- No CSV/7z/SFTP/Cappitech/TRAX upload/response handling.
- No production deployment to `main.regtech`.
- No full historical backfill.

## Implementation-phase assumptions

- Existing static sources are treated as available:
  - `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
  - `main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts`
  - `main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar`
- Country compatibility source for MiFID customer logic is exposed from:
  - `main.general.bronze_etoro_dictionary_country`
  - through view `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`.

## ReplaceChar parity notes

- UDF object:
  - `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`
- Behavior implemented to match SQL Server intent:
  - trim before replacement
  - no trim after replacement
  - replacements for `š`, `Š`, `ß`, `É`, `é`
  - `-` and `_` replaced with spaces
  - listed punctuation/symbol characters removed
  - digits `0-9` removed
- Validation is script-based and must be executed later in test environment.
- Required-column validation now covers static base tables and compatibility views for EDNF, InternalAccounts, and Dictionary.Ext_SpecialChar.
- `vw_ext_country` column-contract validation is intentionally deferred until customer-logic schema expectations are finalized.

## Explicitly deferred to later module

- `InstrumentMetaData_SpecialChar_Conversion` population is deferred until `Pre_Regulation_Ext` creates:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata`
- Deferred artifact note:
  - `databricks/sql/02_udfs/02_instrumentmetadata_specialchar_conversion_deferred.sql`

## Reference-only policy

- NOC artifacts and old Databricks attempt remain reference-only discovery sources and are not authoritative implementation logic.

