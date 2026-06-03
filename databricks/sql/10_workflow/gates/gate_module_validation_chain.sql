-- Step 17B module-chain gate wrapper (non-executing).
-- SELECT-only task-order and validation-link manifest.
-- Business SQL is referenced as placeholders only.

SELECT
  task_order,
  task_group,
  dependency_group,
  planned_sql_scope,
  validation_scope,
  manual_approval_dependency,
  execution_state
FROM VALUES
  (1,  'preflight_readiness_checks',    'none',                          'databricks/sql/10_workflow/gates/gate_global_scope.sql',                                       'Scope/policy/blocker checks',                                          'Required before any activation', 'TEMPLATE_ONLY'),
  (2,  'static_references_and_udfs',    'preflight_readiness_checks',    'databricks/sql/01_static_references/*; databricks/sql/02_udfs/01_fn_replacechar.sql',         'databricks/sql/validation/*',                                          'Static references available',   'TEMPLATE_ONLY'),
  (3,  'pre_regulation_ext_staging',    'static_references_and_udfs',    'databricks/sql/03_pre_regulation_ext/*',                                                         '03_pre_regulation_ext/03_* and 06_*',                                  'Source/storage gates closed',   'TEMPLATE_ONLY'),
  (4,  'regulation_movements',          'pre_regulation_ext_staging',    'databricks/sql/04_regulation_movements/*',                                                       '04_regulation_movements/03_*',                                         'Migration materialization approved', 'TEMPLATE_ONLY'),
  (5,  'hedge_liquidity_scd',           'regulation_movements',          'databricks/sql/05_hedge_liquidity/*',                                                            '05_hedge_liquidity/04_*',                                              'Hedge storage + SCD policy approved', 'TEMPLATE_ONLY'),
  (6,  'asic2_compatible_subset',       'hedge_liquidity_scd',           'databricks/sql/06_asic2_subset/*',                                                               '06_asic2_subset/06_*',                                                 'ASIC2 history/seed approved',   'TEMPLATE_ONLY'),
  (7,  'mifid2_ext_staging',            'asic2_compatible_subset',       'databricks/sql/07_mifid2_ext/*',                                                                 '07_mifid2_ext/07_*',                                                   'PII policy + source contracts approved', 'TEMPLATE_ONLY'),
  (8,  'customer_outputs',              'mifid2_ext_staging',            'databricks/sql/08_outputs/01_*; databricks/sql/08_outputs/02_*',                                '08_outputs/01_*_validation.sql; 02_*_validation.sql',                  'Customer parity approvals closed', 'TEMPLATE_ONLY'),
  (9,  'main_report_outputs',           'customer_outputs',              'databricks/sql/08_outputs/03_* through 06_*',                                                    '03_*_validation_foundation; 04_*_validation; 05_*_validation; 06_*',   'Main report branch approvals closed', 'TEMPLATE_ONLY'),
  (10, 'etoro_report',                  'main_report_outputs',           'databricks/sql/08_outputs/07_*',                                                                 '08_outputs/07_*_validation.sql',                                       'CFI/OpenTime/report exclusions approved', 'TEMPLATE_ONLY'),
  (11, 'hedge_report',                  'etoro_report',                  'databricks/sql/08_outputs/08_*',                                                                 '08_outputs/08_*_validation.sql',                                       'Hedge RecordID/TransactionReference approved', 'TEMPLATE_ONLY'),
  (12, 'npd_trax_table_generation',     'hedge_report',                  'databricks/sql/08_outputs/09_*',                                                                 '08_outputs/09_*_validation.sql',                                       'NPD history/cutover approved', 'TEMPLATE_ONLY'),
  (13, 'validation_packages',           'npd_trax_table_generation',     'databricks/sql/validation/*; databricks/sql/09_validation/07_* through 09_*',                   'Module + cross-module package checks',                                  'Validation evidence complete', 'TEMPLATE_ONLY'),
  (14, 'final_readiness_summary',       'validation_packages',           'databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql',                               'Cross-module blocker + baseline placeholder summary',                   'Final manual sign-off required', 'TEMPLATE_ONLY')
AS chain(
  task_order,
  task_group,
  dependency_group,
  planned_sql_scope,
  validation_scope,
  manual_approval_dependency,
  execution_state
)
ORDER BY task_order;

SELECT
  prohibited_item
FROM VALUES
  ('CSV generation'),
  ('7z compression'),
  ('SFTP delivery'),
  ('Cappitech upload'),
  ('TRAX upload'),
  ('TRAX response handling'),
  ('Production deployment to main.regtech')
AS out_of_scope(prohibited_item);
