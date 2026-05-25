# Current Environment and Naming

```text
target_catalog = main
target_schema = regtech_ops_stg
object_prefix = bi_output_regtechops_
```

All persistent objects created in `main.regtech_ops_stg` must start with `bi_output_regtechops_`.

Correct examples:

```text
main.regtech_ops_stg.bi_output_regtechops_mifid2_report
main.regtech_ops_stg.bi_output_regtechops_mifid2_customer
main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid
main.regtech_ops_stg.bi_output_regtechops_mifid2_run_audit
```

Incorrect examples:

```text
main.regtech_ops_stg.mifid2_report
main.regtech_ops_stg.vw_ednf_to_instrumentid
main.regtech.mifid2_report
```
