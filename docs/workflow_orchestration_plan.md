# Workflow Orchestration Plan (Step 17B)

## Recommended format

Use a Databricks Asset Bundle YAML skeleton:

- `databricks/workflows/mifid_phase1_table_generation.yml`

This format is chosen because it can express ordered task dependencies and parameterized run modes while remaining template-only.

## Why this stays non-executing

- Execution blockers remain open (`docs/open_blockers_for_execution.md`).
- Final parity prerequisites are not closed (`docs/execution_prerequisites.md`).
- Step 17B scope is orchestration skeleton only.

The YAML and SQL wrappers are designed as readiness artifacts, not runnable production orchestration.

## Task graph

```mermaid
flowchart TD
  preflightReadinessChecks --> staticReferencesAndUdfs
  staticReferencesAndUdfs --> preRegulationExtStaging
  preRegulationExtStaging --> regulationMovements
  regulationMovements --> hedgeLiquidityScd
  hedgeLiquidityScd --> asic2CompatibleSubset
  asic2CompatibleSubset --> mifid2ExtStaging
  mifid2ExtStaging --> customerOutputs
  customerOutputs --> mainReportOutputs
  mainReportOutputs --> etoroReport
  etoroReport --> hedgeReport
  hedgeReport --> npdTraxTableGeneration
  npdTraxTableGeneration --> validationPackages
  validationPackages --> finalReadinessSummary
```

## Dependency chain by module group

- Preflight checks gate all downstream groups.
- Static/UDF checks gate pre-regulation and output normalization.
- Pre-regulation gates regulation movements and report dependency branches.
- Hedge liquidity gates hedge and parity-sensitive report branches.
- ASIC2 compatibility gates ETORO and certain report paths.
- `MIFID2_ext` gates customer/reg-change/output families.
- Customer outputs gate report family and NPD_TRAX downstream quality.
- Validation packages gate final readiness summary.

## SQL reference strategy

Workflow tasks reference:

- Existing module SQL as placeholders by scope comments in YAML.
- Step 17B gate wrappers for explicit readiness checks:
  - `databricks/sql/10_workflow/gates/gate_global_scope.sql`
  - `databricks/sql/10_workflow/gates/gate_module_validation_chain.sql`
  - `databricks/sql/10_workflow/gates/gate_cross_module_readiness.sql`

No existing business SQL is modified by Step 17B.

## Validation linkage

- Module validation references remain under:
  - `databricks/sql/validation/`
  - `databricks/sql/03_pre_regulation_ext/*validation*`
  - `databricks/sql/04_regulation_movements/*validation*`
  - `databricks/sql/05_hedge_liquidity/*validation*`
  - `databricks/sql/06_asic2_subset/*validation*`
  - `databricks/sql/07_mifid2_ext/*validation*`
  - `databricks/sql/08_outputs/*validation*`
- Cross-module readiness references remain under:
  - `databricks/sql/09_validation/07_phase1_readiness_summary.sql`
  - `databricks/sql/09_validation/08_cross_module_validation_manifest.sql`
  - `databricks/sql/09_validation/09_cross_module_dependency_gate_checks.sql`

## Explicit exclusions

- CSV generation
- 7z compression
- SFTP delivery
- Cappitech/TRAX upload
- TRAX response handling
- Production deployment

NOC and old Databricks attempt materials remain reference-only and are not implementation authority.
