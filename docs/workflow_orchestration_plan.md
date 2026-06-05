# Workflow Orchestration Plan (Step 17B)

## Staging-only RegTechOps scope

Jobs and workflows defined here are **staging-only RegTechOps jobs** for `main.regtech_ops_stg`. They are **not production-grade** and must not create or overwrite `main.regtech` objects. Data Engineering will later use them as implementation input and adapt them to production criteria.

| Setting | Value |
| --- | --- |
| Read sources | `main.regtech` (and other catalogs) when DE-migrated sources are available |
| Write target | `main.regtech_ops_stg` |
| Generated prefix | `bi_output_regtechops_` |
| Seed prefix | `bi_output_regtechops_seed_` |

## Recommended format

Use Databricks Asset Bundle YAML skeletons:

| Workflow | File | Scope |
| --- | --- | --- |
| Staging smoke test | `databricks/workflows/mifid_phase1_staging_smoke_test.yml` | Ext/staging/audit structural validation |
| Full Phase 1 generation | `databricks/workflows/mifid_phase1_table_generation.yml` | Broader report/output ordering (gated) |

Shared defaults: `databricks/config/workflow_parameters.yml`

The staging smoke-test workflow is the **primary** orchestration artifact for non-production ext/staging/audit validation. The table-generation workflow remains a separate, broader skeleton for later enablement.

## Execution posture

- **Staging smoke-test / seed-load runs** are permitted under `development_structural_test` when scoped to `main.regtech_ops_stg`.
- **Final-parity and production-schedule deployment** remain blocked until blockers and MAG gates close (`docs/open_blockers_for_execution.md`, `docs/execution_prerequisites.md`).
- Step 17B YAML and SQL wrappers are staging orchestration templates — not production-grade orchestration.

NOC and old Databricks attempt materials remain reference-only.

## Task graph — staging smoke test (primary)

```mermaid
flowchart TD
  sourceReadinessChecks --> staticReferenceChecks
  staticReferenceChecks --> priceCurrencySplitExtStaging
  priceCurrencySplitExtStaging --> nonPriceRegExtStaging
  nonPriceRegExtStaging --> regulationMovementStaging
  regulationMovementStaging --> hedgeLiquidityExtStaging
  hedgeLiquidityExtStaging --> asic2StructuralStaging
  asic2StructuralStaging --> mifid2ExtNonPiiStaging
  mifid2ExtNonPiiStaging --> maskedCustomerStructuralTests
  maskedCustomerStructuralTests --> manualSeedTestingChecks
  manualSeedTestingChecks --> validationSummary
```

Optional groups: `maskedCustomerStructuralTests` (MAG-05), `manualSeedTestingChecks` (seed load evidence).

## Task graph — full Phase 1 generation (gated; separate workflow)

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

## Dependency chain — staging smoke test

- Source readiness gates all downstream groups (MAG-01, MAG-02).
- Static reference checks gate price/currency and non-price Reg_Ext staging.
- Price/currency/split staging gates non-price Reg_Ext staging.
- Non-price Reg_Ext gates regulation movement staging.
- Regulation movements gate hedge/liquidity ext staging.
- Hedge/liquidity ext gates ASIC2 structural subset.
- ASIC2 structural gates MIFID2_ext non-PII staging.
- MIFID2_ext non-PII gates optional masked customer tests (parameter + MAG-05).
- Masked customer gates optional manual seed checks.
- Manual seed gates validation summary.

## Dependency chain — full Phase 1 generation (gated)

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

## Explicit exclusions (both workflows)

- Regulatory CSV export/delivery (TRAX paths)
- 7z compression
- SFTP delivery
- Cappitech/TRAX upload
- TRAX response handling
- Writes to `main.regtech`
- Production-grade schedules and production deployment claims

## Staging smoke-test gated exclusions (not in `mifid_phase1_staging_smoke_test.yml`)

- Final `MIFID2_NPD_TRAX` flow (MAG-10)
- Final `MIFID2_Hedge_Report` activation (MAG-12, MAG-13; RecordID registry)
- Final PII customer parity (`main.pii_data`, MAG-06)
- Customer/report/NPD output chain (reserved for `mifid_phase1_table_generation.yml`)

## Explicit inclusions (staging)

- Staging job/workflow skeletons and smoke-test tasks
- Approved CSV **seed** loads into `bi_output_regtechops_seed_*` tables (secure storage; not Git)
- Initial feasible seed test: `MIFID2_NPD_TRAX` (staging validation only)
