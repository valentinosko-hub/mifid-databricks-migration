# History Seed Requirements (Phase 1)

This document tracks history-seed expectations for phase-1 table/report generation modules. Full historical backfill remains out of scope unless a validation window explicitly requires it.

## Step 6 - Regulation movement staging

Primary target:

- `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`

## Minimum seed requirements for Step 6 parity windows

To validate a specific `ReportDate`, the following history scope must exist for the same date window:

- Migration population rows for `RunDate = ReportDate`:
  - preferred snapshot: `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
  - certified gold fallback (parity-gated): `main.regtech.gold_regtech_reg_migrationinout_population`
- Position/history sources with events up to report-day end:
  - `main.trading.silver_etoro_trade_position`
  - `main.trading.bronze_etoro_history_position_datafactory`
- Instrument/price enrichment for report date:
  - `main.regtech.gold_regtech_reg_instruments_scd` with valid-from/to coverage
  - split-price source for `OccurredDate = ReportDate` (still gated by Step 5B1 source selection)

## Seed/cutover policy for Step 6

- Phase 1 default: seed only the validation date windows requested by reconciliation checks.
- If older dates are required:
  - expand seed range for migration population and position/history inputs first,
  - then validate movement branch composition and enrichment completeness by date.

## Known Step 6 history risks

- Gold-vs-SSIS parity risk for migration population snapshots may change movement row composition.
- Split-price source selection risk affects `EOD_Price` completeness and value parity.
- Historical cutover risk exists if migration timestamps or position lifecycle events straddle date boundaries around report-date transitions.

## Step 7 - Hedge liquidity mapping staging

Primary Step 7 history target:

- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`

Supporting Step 7 ext staging targets:

- `main.regtech_ops_stg.bi_output_regtechops_reg_hedgeservertoliquidityaccount_ext`
- `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_ext`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityproviders`

### Minimum seed requirements for Step 7 parity windows

For Step 7 validation/execution windows, ensure availability of:

- Current liquidity account mappings:
  - `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount`
  - `main.trading.bronze_etoro_trade_liquidityaccounts`
  - `main.trading.bronze_etoro_trade_liquidityproviders`
  - `main.bi_db.bronze_etoro_trade_liquidityprovidertype`
- Current LEI mapping source:
  - `main.general.bronze_fivetran_google_sheets_reg_liquidityaccountid_to_lei`
- Existing SCD history baseline (if incremental cutover is selected):
  - prior contents of `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`

### Seed/cutover policy for Step 7

- Step 7 ext objects follow truncate/reload behavior and do not need deep historical backfill for phase-1 parity.
- `Reg_LiquidtyAcount_SCD` requires explicit cutover decision:
  - optional initial seed/rebuild template (history reset risk), or
  - incremental cutover that preserves existing SCD history.
- Phase-1 default should favor incremental cutover once source profiling and schema parity checks pass.

### Known Step 7 history risks

- SCD cutover risk: incorrect seed/rebuild choice can lose expected history windows.
- Removed-account behavior risk: SQL Server removed-account update does not explicitly set `IsLast = 0`; parity/correction decision must be explicit.
- LEI history risk: current gsheet state may not represent historical LEI values for prior windows.
- Sensitive-column governance risk: legacy source includes `Username`/`Password`/`SettingsXML`; phase-1 excludes these from normal staging by design.

## Step 8 - ASIC2-compatible MiFID subset

Primary Step 8 targets:

- `main.regtech_ops_stg.bi_output_regtechops_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`

Supporting Step 8 staging targets:

- `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_openpositions_positionsreport`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_ext_positionchangelog`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_customer_positionreport`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_instrumentmetadata`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_positions`
- `main.regtech_ops_stg.bi_output_regtechops_asic2_removed_op_partials`

### Minimum seed requirements for Step 8 parity windows

For Step 8 validation windows, ensure availability of:

- Target-day (`ReportDate`) source data for open positions, customer/regulation enrichment, and instrument metadata dependencies.
- Prior-day `ASIC2_Positions` when transaction parity branches depend on previous state.
- Prior `ASIC2_Transactions` only if validation includes non-MiFID carry-forward fields; not required for the core 11-field MiFID compatibility contract.

### Seed/cutover policy for Step 8

- Phase-1 default: seed only requested validation windows.
- Do not block Step 8 staging authoring on full historical backfill.
- If older parity windows are requested, expand seed scope incrementally:
  1. ext/customer/instrument dependencies,
  2. `ASIC2_Positions`,
  3. `ASIC2_Transactions`,
  4. MiFID projection/view parity checks.

### Known Step 8 history risks

- Prior-day dependency risk: missing previous-position context can change transaction shaping in edge windows.
- OpenTime semantics risk: `CDE_Execution_timestamp` parsing may differ across historical format variants.
- Conditional fallback risk: if `Reg_DWH_StaticPosition` fallback is required in specific windows, missing seed coverage may affect `OpenPrice`.
- UPI governance risk: UPI should remain non-blocking for MiFID fields unless validation proves impact.

## Step 9 - MIFID2_ext staging

Primary Step 9 history-sensitive target:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`

Supporting Step 9 targets (run-snapshot staging):

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`

### Minimum seed requirements for Step 9 parity windows

For a requested Step 9 `ReportDate` window, ensure:

- Source-day coverage exists for customer, backoffice, position-for-external-use, mirror, change-log, and hedge execution raw inputs.
- Step 6 migration-population snapshot is available for run date where reg-change staging is validated:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
- Latest-row lookup source for failed TRAX exists:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax`

### Seed/cutover policy for Step 9

- Phase-1 default: seed only requested validation windows (no full historical backfill).
- `MIFID2_ext_*` objects are truncate/reload day snapshots and do not require deep historical persistence for authoring.
- `MIFID2_Failed_TRAX` must not fabricate history. If historical parity is requested, seed `MIFID2_NPD_TRAX` first and then recompute failed-TRAX rows by latest-per-CID logic.

### Known Step 9 history risks

- Failed-TRAX dependency risk: missing or partial `MIFID2_NPD_TRAX` history changes latest-row outcomes for `AcceptedTRAX` filters.
- Reg-change interval risk: incomplete migration-population history can alter `PrevRegulationID`/interval-based inclusion.
- As-of history risk: incomplete `History.Customer` / `History.BackOfficeCustomer` windows can break customer as-of parity.
- PIN/UserAPI history risk: unresolved PIN source contract can produce null/incorrect identifiers in historical windows.

## Step 10 - MIFID2_Customer output

Primary Step 10 target:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`

Supporting Step 10 dependencies:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_failed_trax`
- `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`
- `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`

### Minimum seed requirements for Step 10 parity windows

For a requested Step 10 `ReportDate`, ensure:

- Step 9 customer and failed-TRAX staging are available for the same report date window.
- Any required historical window for failed-TRAX latest-CID derivation is already seeded in `MIFID2_NPD_TRAX` (Step 9 dependency).
- Internal-account and country references are available and current for the run window.
- ReplaceChar parity-validation inputs are available for the same run window to validate name/PIN normalization before activation.

### Seed/cutover policy for Step 10

- Phase-1 default remains validation-window seeding only.
- Step 10 should be rerun as report-date scoped delete/insert after supporting Step 9 snapshots are refreshed.
- No full historical backfill is required unless parity checks explicitly request older windows.

### Known Step 10 history risks

- Missing `MIFID2_NPD_TRAX` seed history can alter failed-customer supplementation via Step 9 `MIFID2_Failed_TRAX`.
- Missing `Reg_Ext_CustomerLatinName` windows can alter non-Latin name translation parity in customer output.
- Unconfirmed `Dictionary.Ext_TradeFund` mapping can affect copy-fund historical classification.
- Missing ReplaceChar parity evidence for the run window can alter normalized names/PIN-derived identifiers.

## Step 11 - MIFID2_RegChange_Customer output

Primary Step 11 target:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`

Supporting Step 11 dependencies:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_vw_internal_accounts`
- `main.regtech_ops_stg.bi_output_regtechops_vw_ext_country`

### Minimum seed requirements for Step 11 parity windows

For a requested Step 11 `ReportDate`, ensure:

- Step 9 reg-change customer staging is available for the same report date window.
- Step 6 migration-in/out population history required by Step 9 reg-change derivation is already available for that run date.
- Internal-account and country-reference snapshots are available and current for the run window.

### Seed/cutover policy for Step 11

- Phase-1 default remains validation-window seeding only.
- Step 11 should be rerun as report-date scoped delete/insert after Step 9 reg-change staging refresh.
- No full historical backfill is required unless parity checks explicitly request older windows.

### Known Step 11 history risks

- Missing migration/reg-change history in Step 9 inputs can alter reg-change customer population.
- Missing `Reg_Ext_CustomerLatinName` windows can alter Chinese/Cyrillic translation parity.
- Unconfirmed `Dictionary.Ext_TradeFund` mapping can affect copy-fund historical classification.
- Missing/partial PIN/UserAPI history in Step 9 sources can affect reg-change identity fields.

## Out of scope

- Full historical backfill of all movement dates.
- Full historical backfill of hedge liquidity SCD history.
- Production deployment/cutover workflows.
- File-delivery and response handling flows.
