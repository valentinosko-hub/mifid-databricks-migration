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
- `main.regtech_ops_stg.bi_output_regtechops_fn_replacechar`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname` (gated dependency)
- `Dictionary.Ext_TradeFund` mapped Databricks equivalent (gated dependency)

### Minimum seed requirements for Step 11 parity windows

For a requested Step 11 `ReportDate`, ensure:

- Step 9 reg-change customer staging is available for the same report date window.
- Step 6 migration-in/out population history required by Step 9 reg-change derivation is already available for that run date.
- Internal-account and country-reference snapshots are available and current for the run window.
- ReplaceChar parity-validation inputs are available for the same run window before Step 11 activation.

### Seed/cutover policy for Step 11

- Phase-1 default remains validation-window seeding only.
- Step 11 should be rerun as report-date scoped delete/insert after Step 9 reg-change staging refresh.
- No full historical backfill is required unless parity checks explicitly request older windows.

### Known Step 11 history risks

- Missing migration/reg-change history in Step 9 inputs can alter reg-change customer population.
- Missing `Reg_Ext_CustomerLatinName` windows can alter Chinese/Cyrillic translation parity.
- Unconfirmed `Dictionary.Ext_TradeFund` mapping can affect copy-fund historical classification.
- Missing/partial PIN/UserAPI history in Step 9 sources can affect reg-change identity fields.
- Missing ReplaceChar parity evidence for the run window can alter normalized names/PIN-derived identifiers.

## Step 12 - MIFID2_Report / MIFID2_ME_Report / MIFID2_Removed_OP_Partials

Primary Step 12 targets:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials`

Supporting Step 12 dependencies (carry-forward gates):

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog`
- `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror`
- `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population`
- `main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions`
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio` (gated)
- `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion` (gated)
- `main.trading.bronze_etoro_trade_futuresmetadata` (expected source; profiling-gated)

Step 12B2 boundary note:

- Step 12B2 uses pre-branch intermediate population only and stops at unified trade pool (`#tradesFinal` equivalent).
- Futures metadata is not a Step 12B2 seed dependency because it is used in final branch projections (Step 12B3).

### Minimum seed requirements for Step 12 parity windows

For a requested Step 12 `ReportDate`, ensure:

- Step 10/11 customer snapshots for the same report date window are available.
- Step 9 position/reg-change-position/changelog/mirror snapshots for the same report date window are available.
- Movement and migration snapshots for the same report date are available (or explicitly marked gated and excluded from execution).
- Instrument coverage sources are available for the requested date window (`Reg_Instruments_SCD`, `Reg_Instruments_Full_Description`).
- Split and price sources for report-date pricing logic are available and approved by Step 5B1 gates.
- For Step 12B2 specifically, ensure intermediate instrument metadata dependencies are available:
  - `Reg_Ext_Trade_InstrumentMetaData`
  - `Reg_Ext_Trade_GetInstrument`
  - `Reg_Instruments_ext` / certified gold equivalents
  - `InstrumentMetaData_SpecialChar_Conversion` (if used before unified trade pool)
- Futures metadata required columns are needed for Step 12B3 final branch coverage:
  - `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`.

### Seed/cutover policy for Step 12

- Phase-1 default remains validation-window seeding only.
- Step 12 report targets should be rebuilt as report-date scoped delete/insert after upstream snapshots refresh.
- Full historical backfill is not required for Step 12B1 and is deferred until explicitly requested for reconciliation windows.

### Known Step 12 history risks

- Unresolved price/split source selection can alter report prices and quantity normalization.
- Migration/regchange interval parity gaps can alter branch membership and row composition.
- Missing `InstrumentMetaData_SpecialChar_Conversion` population can change instrument-name normalization outcomes.
- Missing FuturesMetaData required-column profiling can impact Step 12B3 futures-specific projection fields and coverage.
- `MIFID2_Removed_OP_Partials` implicit-order insert behavior from SQL Server must not be carried forward; explicit-column parity is required to avoid schema-order drift.
- `MIFID2_Report` / `MIFID2_ME_Report` `UpdateDate` must remain nullable with no synthesized default; default injection would create non-parity history artifacts.

## Step 12B3-specific seed notes

Step 12B3 final projection templates consume the Step 12B2 unified trades-final source and do not regenerate Step 12B2 intermediate logic.

Additional Step 12B3 seed dependencies:

- Branch source boundary:
  - validated `{{trades_final_source}}` (or approved materialized equivalent) for the requested report date.
- Futures-only enrichment source:
  - `main.trading.bronze_etoro_trade_futuresmetadata`
  - required columns: `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`.
- Removed partials finalization source:
  - scoped/materialized Step 12B2 removed-partials candidates (`{{removed_partial_candidates_source}}`).

Step 12B3 historical caution:

- If Step 12B2 intermediate snapshots are not reproducible for older windows, Step 12B3 branch outputs cannot be parity-reconstructed for those windows.

## Step 13 - MIFID2_ETORO_Report

Primary Step 13 target:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`

Supporting Step 13 source dependencies:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
- `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- `main.regtech.gold_regtech_reg_instruments_scd`
- `main.regtech.gold_regtech_reg_instruments_full_description`
- `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion` (gated)
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency` (gated)
- `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype` (gated)

### Minimum seed requirements for Step 13 parity windows

For a requested Step 13 `ReportDate`, ensure:

- Step 8 compatibility outputs are available for that date with full 11-field contract coverage.
- Source rows required for ETORO exclusions are available/current for ETORO table scope:
  - excluded CIDs
  - excluded instruments
  - excluded position IDs
- Instrument SCD/full-description report-date coverage exists for all ETORO candidate instruments.
- Step 8 parity checks are accepted for:
  - `CDE_Execution_timestamp -> OpenTime`
  - `Quantity -> Volume`
  - `OpenPrice`

### Seed/cutover policy for Step 13

- Phase-1 default remains validation-window seeding only.
- Do not block Step 13B1 scaffold authoring on full historical backfill.
- If older ETORO windows are requested:
  1. expand Step 8 compatibility seed for the required dates,
  2. re-validate OpenTime/Volume/OpenPrice parity,
  3. run ETORO reconciliation for those dates.

### Known Step 13 history risks

- Missing Step 8 history windows can break ETORO row-count parity for older dates.
- Historical format variation in `CDE_Execution_timestamp` can alter `OpenTime` parsing parity across windows.
- Historical gaps in instrument metadata conversion/dictionary sources can alter ETORO instrument/currency fields.
- `Reg_DWH_StaticPosition` fallback remains conditional; if fallback impact appears only in historical windows, OpenPrice parity can drift unless explicitly profiled.

## Step 13B3-specific seed notes (ETORO validation/reconciliation)

Step 13B3 validates ETORO output as read-only SQL and does not create synthetic historical rows.

Additional Step 13B3 seed dependencies:

- Validation source boundary:
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_etoro_report`
  - both must cover the requested `ReportDate` windows.
- Exclusion-source history boundary for ETORO scope checks:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regulation_report_excluded_cids`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
  - use report-scoped filters (`table_name = '[MIFID2_ETORO_Report]'`) for instruments/positions.
- Instrument/dictionary enrichment history boundary:
  - report-date-valid windows for SCD/full-description/conversion/dictionary dependencies are required for parity evidence.

Step 13B3 historical caution:

- If Step 8 compatibility history is not seeded for older dates, Step 13B3 source-to-output reconciliation cannot prove parity for those dates.
- SQL Server baseline parity remains optional and gated:
  - do not invent a baseline source or synthetic baseline rows;
  - run baseline anti-join checks only when a normalized baseline dataset is provided.

## Step 14 - MIFID2_Hedge_Report

Primary Step 14 target:

- `main.regtech_ops_stg.bi_output_regtechops_mifid2_hedge_report`

Supporting Step 14 dependencies:

- EU branch direct inputs:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_hedgeexecutionlog`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`
- UK branch direct inputs:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_liquidityaccountid`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_liquidtyacount_scd`
- Shared enrichment dependencies:
  - `main.regtech.gold_regtech_reg_instruments_scd`
  - `main.regtech.gold_regtech_reg_instruments_full_description`
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`
  - `main.general.gold_ednf_coretrades`
  - `main.general.gold_ib_u1059976_open_positions_all`
  - `main.regtech_ops_stg.bi_output_regtechops_ed_f_to_istrument_id_e_toro`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_ednf_to_instrumentid`

### Minimum seed requirements for Step 14 parity windows

For a requested Step 14 `ReportDate`, ensure:

- Hedge execution staging inputs cover execution rows in the report-day window:
  - `ExecutionTime >= ReportDate`
  - `ExecutionTime < ReportDate + 1 day`
- Liquidity account and SCD validity windows are available for all candidate rows.
- LEI mapping coverage is available for active/report-relevant liquidity accounts.
- Exclusion inputs are available/current for hedge report scope:
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_instruments`
  - `main.regtech_stg.silver_sharepoint_transactionreporting_regtech_excluded_position_ids`
- Instrument and dictionary enrichment dependencies are available for all candidate instruments.
- EDNF/IB mapping inputs are available where hedge enrichment/join behavior depends on these links.

### Seed/cutover policy for Step 14

- Phase-1 default remains validation-window seeding only.
- Step 14B1 is scaffold-only and does not execute report DML.
- Step 14B2 is source-preparation-only and does not execute final output DML.
- Step 14B3 is final projection/load template authoring only and keeps final DML commented/gated.
- Do not block Step 14B1 authoring on full historical backfill.
- If older hedge windows are requested later:
  1. expand hedge execution staging windows,
  2. confirm liquidity SCD/LEI historical coverage,
  3. confirm exclusion history for hedge table scope,
  4. run branch-level reconciliation checks by `RegulationReportID`.

### Known Step 14 history risks

- RecordID risk:
  - unresolved deterministic strategy can block parity signoff across reruns.
- Hedge source activation risk:
  - incomplete activation or history gaps in `MIFID2_ext_HedgeExecutionLog` / `Reg_Ext_HedgeExecutionLog` / `Reg_Ext_HedgeHBCOrderLog` can alter branch row counts.
- Liquidity SCD/LEI risk:
  - incomplete SCD or LEI history can alter buyer/seller LEI fields and branch eligibility.
- EDNF/IB mapping risk:
  - missing mapping history can reduce enrichment coverage in specific date windows.
- Exclusion history risk:
  - missing historical exclusion entries can change hedge output composition for older dates.
- Transaction-reference risk:
  - reference construction uses normalized provider execution id and row ordering; unstable ordering inputs can create cross-run drift without deterministic controls.

## Step 14B2-specific seed notes (hedge source preparation)

Step 14B2 source-preparation templates consume source-day windows and do not create synthetic final output rows.

Additional Step 14B2 seed dependencies:

- Branch source boundary:
  - `bi_output_regtechops_mifid2_ext_hedgeexecutionlog` (EU/EU-UK candidates),
  - `bi_output_regtechops_reg_ext_hedgeexecutionlog` + `bi_output_regtechops_reg_ext_hedgehbcorderlog` (UK candidates).
- Liquidity validity boundary:
  - `bi_output_regtechops_reg_ext_liquidityaccountid` + `bi_output_regtechops_reg_liquidtyacount_scd` coverage for `ExecutionTime` windows.
- Enrichment history boundary:
  - instrument SCD/full-description/special-char and dictionary sources for report-date joins.
  - EDNF/IB mapping coverage sources for candidate instruments.
- Exclusion history boundary:
  - report-scoped exclusion rows where `table_name = '[MIFID2_Hedge_Report]'`.

Step 14B2 historical caution:

- If source-day execution windows are incomplete, branch source-preparation counts can drift before final projection logic is even applied.
- If exclusion or mapping history is incomplete, Step 14B2 validation can under-report future Step 14B3 branch-level parity issues.

## Step 14B3-specific seed notes (hedge final projection template)

Step 14B3 templates consume Step 14B2-prepared branch source contracts and still do not produce active final output rows until gates pass.

Additional Step 14B3 seed dependencies:

- Final branch projection boundary:
  - report-date-complete EU / EU-UK / UK prepared source contracts.
- Transaction reference parity boundary:
  - stable provider execution id normalization and row id determinism for requested windows.
- Deterministic RecordID boundary:
  - stable ordering fields available for each requested report date:
    - `ReportDate`, `RegulationReportID`, `rowSource`, `TransactionReferenceNumber`, `ExecutionID`, `LiquidityAccountID`, `InstrumentID`.
- Exclusion parity boundary:
  - report-scoped instrument and position/reference exclusion sources must contain expected historical entries for requested dates.

Step 14B3 historical caution:

- If transaction-reference seed inputs are unstable across reruns, deterministic RecordID ordering can drift even with a fixed ordering specification.
- If exclusion history is incomplete, Step 14B3 projection template parity may appear correct while branch-level exclusion evidence fails in Step 14B4.

## Out of scope

- Full historical backfill of all movement dates.
- Full historical backfill of hedge liquidity SCD history.
- Production deployment/cutover workflows.
- File-delivery and response handling flows.
