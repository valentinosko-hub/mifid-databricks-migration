-- Module: Environment/config/naming helpers
-- Purpose: reusable naming checks/query snippets.
-- This file is intentionally query-only and safe to review without side effects.

-- Detect non-prefixed persistent objects in main.regtech_ops_stg.
-- Expected result for phase-1 owned objects: zero rows.
SELECT
  table_catalog,
  table_schema,
  table_name,
  table_type
FROM system.information_schema.tables
WHERE table_catalog = 'main'
  AND table_schema = 'regtech_ops_stg'
  AND table_name NOT LIKE 'bi_output_regtechops_%'
ORDER BY table_name;

-- Detect non-prefixed functions in main.regtech_ops_stg.
-- Expected result for phase-1 owned functions: zero rows.
SELECT
  function_catalog,
  function_schema,
  function_name
FROM system.information_schema.routines
WHERE function_catalog = 'main'
  AND function_schema = 'regtech_ops_stg'
  AND function_name NOT LIKE 'bi_output_regtechops_%'
ORDER BY function_name;

