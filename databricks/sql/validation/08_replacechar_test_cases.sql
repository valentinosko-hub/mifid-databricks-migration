-- Validation: ReplaceChar test cases.
-- Expected: all rows PASS.

WITH test_cases AS (
  SELECT 'core_replacements' AS case_id, '  šŠßÉé-__123  ' AS input_value, 'sSsEe   ' AS expected_value UNION ALL
  SELECT 'trim_before_not_after', '  -A-  ', ' A ' UNION ALL
  SELECT 'symbol_removal', 'A|B/C\D~E', 'ABCDE' UNION ALL
  SELECT 'digit_removal', 'A1B2C3', 'ABC' UNION ALL
  SELECT 'null_passthrough', CAST(NULL AS STRING), CAST(NULL AS STRING)
),
evaluated AS (
  SELECT
    case_id,
    input_value,
    expected_value,
    main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(input_value) AS actual_value
  FROM test_cases
)
SELECT
  case_id,
  input_value,
  expected_value,
  actual_value,
  CASE
    WHEN actual_value <=> expected_value THEN 'PASS'
    ELSE 'FAIL'
  END AS test_status
FROM evaluated
ORDER BY case_id;

