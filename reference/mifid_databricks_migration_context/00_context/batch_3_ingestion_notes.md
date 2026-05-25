# Batch 3 ingestion notes

This batch added MiFID target table DDLs, additional source/reference DDLs, Synapse table DDLs, and several US regulatory stored procedures.

The US regulatory procedures are kept under `01_sql_server_stored_procedures/reference_other_regulatory_us/` and should be treated as reference-only unless Cursor discovers a direct dependency from the MiFID process.
