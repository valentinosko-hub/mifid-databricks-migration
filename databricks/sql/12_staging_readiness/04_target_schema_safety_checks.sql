-- Staging readiness: target schema safety checks (SELECT-only).
-- No CREATE, INSERT, UPDATE, DELETE, MERGE, DROP.
-- Parameters: {{source_catalog}}, {{source_schema}}, {{target_catalog}}, {{target_schema}},
--               {{object_prefix}}, {{skip_delivery_steps}}

WITH param_eval AS (
  SELECT
    lower(trim('{{source_catalog}}')) AS source_catalog,
    lower(trim('{{source_schema}}')) AS source_schema,
    lower(trim('{{target_catalog}}')) AS target_catalog,
    lower(trim('{{target_schema}}')) AS target_schema,
    lower(trim('{{object_prefix}}')) AS object_prefix,
    lower(trim('{{skip_delivery_steps}}')) AS skip_delivery_steps
),
policy_checks AS (
  SELECT
    'target_safety' AS check_group,
    concat(p.target_catalog, '.', p.target_schema) AS object_name,
    'target_catalog' AS check_name,
    'main' AS expected,
    p.target_catalog AS actual,
    CASE WHEN p.target_catalog = 'main' THEN 'PASS' ELSE 'FAIL' END AS status,
    'Write catalog must be main' AS notes
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    concat(p.target_catalog, '.', p.target_schema),
    'target_schema',
    'regtech_ops_stg',
    p.target_schema,
    CASE WHEN p.target_schema = 'regtech_ops_stg' THEN 'PASS' ELSE 'FAIL' END,
    'Write schema must be regtech_ops_stg — never main.regtech'
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    concat(p.target_catalog, '.', p.target_schema),
    'forbid_regtech_write',
    'target_schema <> regtech',
    p.target_schema,
    CASE WHEN p.target_schema <> 'regtech' THEN 'PASS' ELSE 'FAIL' END,
    'main.regtech must never be a write target from RegTech staging jobs'
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    p.object_prefix,
    'object_prefix',
    'starts with bi_output_regtechops_',
    p.object_prefix,
    CASE WHEN p.object_prefix LIKE 'bi_output_regtechops_%' THEN 'PASS' ELSE 'FAIL' END,
    'Generated persistent objects must use bi_output_regtechops_ prefix'
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    concat(p.source_catalog, '.', p.source_schema),
    'source_read_schema',
    'regtech (primary)',
    p.source_schema,
    CASE WHEN p.source_schema = 'regtech' THEN 'PASS' ELSE 'WARN' END,
    'Primary read policy is main.regtech; dev fallback must be documented in evidence if not regtech'
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    'delivery_scope',
    'skip_delivery_steps',
    'true',
    p.skip_delivery_steps,
    CASE
      WHEN p.skip_delivery_steps = 'true' THEN 'PASS'
      ELSE 'FAIL'
    END,
    CASE
      WHEN p.skip_delivery_steps = 'true' THEN
        'Delivery/upload/response excluded — parameter explicitly true'
      WHEN p.skip_delivery_steps IN ('false', '0', 'no') THEN
        'FAIL: delivery scope must remain excluded for staging readiness'
      WHEN p.skip_delivery_steps = '' OR p.skip_delivery_steps IS NULL THEN
        'FAIL: skip_delivery_steps empty or null — substitute true before execution'
      WHEN p.skip_delivery_steps = lower(trim('{{skip_delivery_steps}}')) THEN
        'FAIL: skip_delivery_steps unsubstituted template literal — set to true'
      ELSE
        'FAIL: skip_delivery_steps must be exactly true (case-insensitive after trim)'
    END
  FROM param_eval p
  UNION ALL
  SELECT
    'target_safety',
    concat(p.target_catalog, '.', p.target_schema),
    'target_schema_exists',
    'EXISTS',
    CASE WHEN s.schema_name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
    CASE WHEN s.schema_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
    'Target schema must exist before staging writes'
  FROM param_eval p
  LEFT JOIN system.information_schema.schemata s
    ON lower(s.catalog_name) = p.target_catalog
   AND lower(s.schema_name) = p.target_schema
)
SELECT
  check_group,
  object_name,
  check_name,
  expected,
  actual,
  status,
  notes
FROM policy_checks
ORDER BY check_name;
