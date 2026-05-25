# dbo.ReplaceChar Mapping

`dbo.ReplaceChar` is used by:
- `SP_MIFID2_Customer`
- `SP_MIFID2_RegChange_Customer`

Authoritative mapping exported from SQL Server:

```text
š -> s
Š -> S
ß -> s
É -> E
é -> e
- -> space
_ -> space
```

Remove:

```text
| \ / ~ { } ; : " , . ] [ ! @ # $ % ^ & * ( ) + = ` ´ ? ¶ ƒ non-breaking-space U+00A0 U+0081 ² U+008F soft-hyphen U+00AD © ¸ digits 0-9
```

Important:
- Preserve SQL Server behavior: trim before replacement, not after replacement.
- Do not use Databricks `chr(353)`, `chr(352)`, or `chr(402)` for `š`, `Š`, or `ƒ`; use actual Unicode literals.
- Add unit tests comparing Databricks output to SQL Server output.
