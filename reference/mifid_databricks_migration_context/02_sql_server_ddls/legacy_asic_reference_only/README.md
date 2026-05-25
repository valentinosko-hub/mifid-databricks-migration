# Legacy ASIC reference only

These files are legacy ASIC DDLs, not authoritative for the current MiFID migration.

Current decision:

- ASIC2_Transactions is the current authoritative ASIC reporting table.
- Legacy ASIC_Transactions still runs, but should not be used as the MiFID migration source of truth.
- Use files in `../asic2_tables/` for current ASIC2 schema.
