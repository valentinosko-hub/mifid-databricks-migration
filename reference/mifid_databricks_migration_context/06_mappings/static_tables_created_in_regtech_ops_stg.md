# Static Tables Created in main.regtech_ops_stg

These are small/static references already created manually for this staging phase. They follow the required `bi_output_regtechops_` prefix.

## EDNF to InstrumentID

```text
main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro
```

Columns:
- `InstrumentID`
- `ContractDesc`
- `IB_UnderlyingSymbol`
- `ContractLongName`

## Internal accounts

```text
main.regtech_ops_stg.bi_output_regtechops_dbo_internal_accounts
```

Columns:
- `CID`
- `LEI`
- `Description`

## Dictionary.Ext_SpecialChar

```text
main.regtech_ops_stg.bi_output_regtechops_dictionary_ext_specialchar
```

Columns:
- `Key`
- `Value`
- `UpdateDate`

## Important
Do not create non-prefixed replacements in `main.regtech_ops_stg`.
