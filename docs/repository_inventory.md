# Repository Inventory (Step 16B2)

This inventory helps the next engineer or analyst find module SQL, validation SQL, and supporting documentation quickly.

Environment convention for all persistent targets:

- `main.regtech_ops_stg`
- Prefix: `bi_output_regtechops_`

## Top-level layout

| Path | Purpose |
| --- | --- |
| `docs/` | Analysis, gates, profiling, reconciliation, readiness, and handoff documentation |
| `databricks/sql/` | Gated SQL templates, profiling gates, validation, and config helpers |
| `reference/mifid_databricks_migration_context/` | **Read-only** SQL Server SPs, DDLs, SSIS packages, mappings (implementation authority for business logic) |

Do not modify files under `reference/`.

## `docs/` — key handoff and gate documents

| File | Purpose |
| --- | --- |
| `final_handoff_summary.md` | Primary handoff entry (Step 16B2) |
| `final_readiness_assessment.md` | Cross-module readiness state (Step 16B1) |
| `open_blockers_for_execution.md` | Consolidated execution blockers |
| `final_validation_execution_plan.md` | Validation run order after execution is enabled |
| `execution_prerequisites.md` | Prerequisites before any Databricks execution |
| `remaining_decisions.md` | Open business/technical decisions |
| `manager_status_summary.md` | Non-technical status for management |
| `repository_inventory.md` | This file |
| `source_profiling_results.md` | Latest profiling integration |
| `access_blockers.md` | DE/Data Platform access actions |
| `unresolved_dependencies.md` | Active unresolved dependencies |
| `dependency_coverage_matrix.md` | Object-level coverage and status |
| `validation_gates.md` | Go/no-go gate definitions |
| `reconciliation_plan.md` | Reconciliation scope and module evidence |
| `history_seed_requirements.md` | Seed/cutover requirements |
| `known_differences.md` | Intentional or gated differences vs SQL Server |
| `migration_execution_order.md` | Canonical module activation order |
| `implementation_module_plan.md` | Module-by-module implementation plan |
| `*_analysis.md` | Per-module output/staging analysis (customer, report, ETORO, hedge, NPD, etc.) |

## `databricks/sql/00_config/`

**Purpose:** Environment naming conventions and helpers; no business report logic.

| File | Role |
| --- | --- |
| `00_environment_config.sql` | Target catalog/schema/prefix conventions |
| `01_naming_helpers.sql` | Naming helper patterns for prefixed objects |

## `databricks/sql/01_static_references/`

**Purpose:** Static reference compatibility views and related SQL.

| File | Role |
| --- | --- |
| `01_static_reference_compatibility.sql` | Static reference compatibility layer |
| `11_vw_ednf_to_instrumentid.sql` | EDNF mapping view |
| `12_vw_internal_accounts.sql` | Internal accounts view |
| `13_vw_dictionary_ext_specialchar.sql` | Special-char dictionary view |
| `14_vw_ext_country.sql` | Country compatibility view |

## `databricks/sql/02_udfs/`

**Purpose:** UDF and deferred special-char conversion population.

| File | Role |
| --- | --- |
| `01_fn_replacechar.sql` | ReplaceChar UDF template |
| `02_instrumentmetadata_specialchar_conversion_deferred.sql` | Deferred conversion (gated on instrument metadata staging) |

## `databricks/sql/validation/`

**Purpose:** Early static reference and ReplaceChar validation (SELECT-only).

| File | Role |
| --- | --- |
| `01_static_reference_row_counts.sql` | Row-count checks |
| `02_static_reference_required_columns.sql` | Required-column checks |
| `03_static_reference_null_keys.sql` | Null-key checks |
| `04_static_reference_duplicate_keys.sql` | Duplicate-key checks |
| `05_ednf_mapping_duplicate_checks.sql` | EDNF duplicate checks |
| `06_internalaccounts_cid_duplicate_checks.sql` | Internal accounts duplicate checks |
| `07_dictionary_ext_specialchar_duplicate_key_checks.sql` | Dictionary duplicate checks |
| `08_replacechar_test_cases.sql` | ReplaceChar test cases |

## `databricks/sql/03_pre_regulation_ext/`

**Purpose:** Pre_Regulation price/currency/split and non-price staging gates.

| File | Role |
| --- | --- |
| `00_pre_regulation_parameters.sql` | Run parameters |
| `01_price_currency_source_profiling.sql` | Price/currency source profiling |
| `02_price_currency_staging.sql` | Price/currency staging template |
| `03_price_currency_validation.sql` | Price/currency validation |
| `04_non_price_source_profiling.sql` | Non-price profiling |
| `05_non_price_staging_gates.sql` | Non-price staging gates |
| `06_non_price_validation.sql` | Non-price validation |

## `databricks/sql/04_regulation_movements/`

**Purpose:** Regulation movement staging and validation.

| File | Role |
| --- | --- |
| `01_regulation_movments_source_profiling.sql` | Source profiling |
| `02_regulation_movments_staging.sql` | Staging template (gated) |
| `03_regulation_movments_validation.sql` | Validation SQL |

## `databricks/sql/05_hedge_liquidity/`

**Purpose:** Hedge liquidity mapping and SCD templates.

| File | Role |
| --- | --- |
| `01_hedge_liquidity_source_profiling.sql` | Source profiling |
| `02_liquidity_ext_staging.sql` | Liquidity ext staging |
| `03_reg_liquidtyacount_scd.sql` | SCD templates (seed/cutover gated) |
| `04_hedge_liquidity_validation.sql` | Validation SQL |

## `databricks/sql/06_asic2_subset/`

**Purpose:** ASIC2-compatible MiFID subset for ETORO dependency replacement.

| File | Role |
| --- | --- |
| `01_asic2_source_profiling.sql` | Source profiling |
| `02_asic2_ext_staging.sql` | ASIC2 ext staging |
| `03_asic2_positions_and_instruments.sql` | Positions and instrument metadata |
| `04_asic2_transactions.sql` | Transactions template |
| `05_mifid_asic_compatibility_view.sql` | MiFID compatibility view |
| `06_asic2_validation.sql` | Validation SQL |

## `databricks/sql/07_mifid2_ext/`

**Purpose:** MIFID2_ext and Failed TRAX staging.

| File | Role |
| --- | --- |
| `01_mifid2_ext_source_profiling.sql` | Source profiling |
| `02_customer_ext_staging.sql` | Customer ext staging |
| `03_position_ext_staging.sql` | Position ext staging |
| `04_positionchangelog_mirror_ext_staging.sql` | Changelog/mirror staging |
| `05_hedge_ext_staging.sql` | Hedge execution ext staging |
| `06_failed_trax_staging.sql` | Failed TRAX staging |
| `07_mifid2_ext_validation.sql` | Validation SQL |

## `databricks/sql/08_outputs/`

**Purpose:** Final MiFID output templates, scaffolding, and per-output validation.

| Prefix / files | Module |
| --- | --- |
| `01_mifid2_customer*` | MIFID2_Customer |
| `02_mifid2_regchange_customer*` | MIFID2_RegChange_Customer |
| `03_mifid2_report_scaffolding.sql`, `03_mifid2_report_validation_foundation.sql` | Report scaffolding (12B1) |
| `04_mifid2_report_position_population*` | Report intermediate population (12B2) |
| `05_mifid2_report_branch_projection*` | Report/ME/removed partials branches (12B3) |
| `06_mifid2_report_final_reconciliation.sql` | Final report reconciliation (12B4) |
| `07_mifid2_etoro_report*` | MIFID2_ETORO_Report (13B1-B3) |
| `08_mifid2_hedge_report*` | MIFID2_Hedge_Report (14B1-B4) |
| `09_mifid2_npd_trax*` | MIFID2_NPD_TRAX (15B1-B3) |

## `databricks/sql/09_validation/`

**Purpose:** Step 16B1 cross-module readiness and dependency gate checks (SELECT-only).

| File | Role |
| --- | --- |
| `07_phase1_readiness_summary.sql` | Target/static existence, blocker summary, validation inventory |
| `08_cross_module_validation_manifest.sql` | Module manifest (outputs, validation paths, placeholders) |
| `09_cross_module_dependency_gate_checks.sql` | Dependency/blocker/placeholder gate checks |

## `reference/mifid_databricks_migration_context/`

**Purpose:** Authoritative SQL Server and SSIS lineage (read-only).

Typical subfolders:

- `01_sql_server_stored_procedures/`
- `02_sql_server_ddls/`
- `03_sql_server_functions/`
- `05_ssis/selected_packages/`
- `06_mappings/`

NOC documents and old Databricks attempt materials may appear elsewhere under `reference/`; they are **reference-only** and must not override SP/SSIS/DDL logic in this migration.

## Module-to-folder quick map

| Module | Primary SQL folder | Primary analysis doc |
| --- | --- | --- |
| Config / static / UDFs | `00_config`, `01_static_references`, `02_udfs`, `validation` | `docs/static_reference_tables.md` |
| Pre_Regulation | `03_pre_regulation_ext` | `docs/pre_regulation_ext_analysis.md` |
| Regulation movements | `04_regulation_movements` | `docs/regulation_movements_analysis.md` |
| Hedge liquidity | `05_hedge_liquidity` | `docs/hedge_liquidity_mapping_analysis.md` |
| ASIC2 subset | `06_asic2_subset` | `docs/asic2_mifid_subset_analysis.md` |
| MIFID2_ext | `07_mifid2_ext` | `docs/mifid2_ext_staging_analysis.md` |
| Customer outputs | `08_outputs/01_*`, `02_*` | `docs/mifid2_*_customer_output_analysis.md` |
| Report family | `08_outputs/03_*`–`06_*` | `docs/mifid2_report_output_analysis.md` |
| ETORO | `08_outputs/07_*` | `docs/mifid2_etoro_report_output_analysis.md` |
| Hedge report | `08_outputs/08_*` | `docs/mifid2_hedge_report_output_analysis.md` |
| NPD TRAX | `08_outputs/09_*` | `docs/mifid2_npd_trax_output_analysis.md` |
| Cross-module readiness | `09_validation` | `docs/final_readiness_assessment.md` |
