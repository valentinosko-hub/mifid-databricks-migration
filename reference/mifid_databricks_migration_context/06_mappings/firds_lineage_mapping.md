# FIRDS / FCA FIRDS Lineage

FIRDS / FCA FIRDS gold tables are confirmed certified sources for the current MiFID migration.

Use:

```text
main.regtech.gold_regtech_reg_instruments_scd
main.regtech.gold_regtech_reg_instruments_full_description
```

FIRDS lineage sources:

```text
main.regtech.silver_esma_full
main.regtech.silver_esma_delta
main.regtech.silver_fca_full
main.regtech.silver_fca_delta
```

Do not rebuild raw FIRDS logic unless explicitly required later.
