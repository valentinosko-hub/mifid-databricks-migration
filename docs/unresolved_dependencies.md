# Phase 1D / Steps 5-13B1 - Unresolved Dependencies

This file tracks dependencies from `docs/dependency_coverage_matrix.md` that are not yet fully resolved for phase-1 implementation and validation.

## Active unresolved items

| dependency | why unresolved | impact if not resolved | required decision/action | blocking for phase 1 |
| --- | --- | --- | --- | --- |
| `Reg_CurrencyPrice_Ext` source column parity (`History.CurrencyPrice_Active`) | Candidate (`main.trading.bronze_etoro_trade_currencyprice`) has not yet been runtime-profiled against the full SSIS-selected column set | Staging build can fail at execution time or silently diverge if columns are missing/renamed | Run `databricks/sql/03_pre_regulation_ext/01_price_currency_source_profiling.sql` and confirm all required columns before execution | Yes |
| `Reg_Ext_DailyMaxPrices` source column parity (`History.CurrencyPriceMaxDate`) | Candidate (`main.dealing.bronze_pricelog_history_currencypricemaxdate`) has not yet been runtime-profiled against required columns | Price/max-date staging parity can drift or fail at runtime | Run source profiling and confirm required columns before execution | Yes |
| `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection | Two candidate mappings are documented and both are plausible | Price/split parity differences in MiFID and movement outputs | Choose source after candidate comparison checks (columns, run-window row counts, min/max dates, duplicate `PriceRateID`, `InstrumentID` coverage, freshness) | Yes (for full parity) |
| `Reg_Ext_T_PriceCandle60Min` source shape confirmation | Candidate mapping exists, but required columns are not yet runtime-validated in target environment | Latest-price extraction may fail if source schema differs | Confirm `InstrumentID`, `BidLast`, `AskLast`, `DateFrom` via profiling before execution | Yes |
| `MIFID2_Hedge_Report.RecordID` identity behavior | SQL Server uses `IDENTITY(100000001,1)` but Databricks has no direct equivalent behavior by default | Record sequencing drift and potential downstream mismatch | Decide deterministic generation strategy and document it | Yes |
| ASIC2 replacement for legacy `ASIC_Transactions` | `SP_MIFID2_ETORO_Report` still references legacy object shape | MiFID ETORO output may not match intended ASIC2 source-of-truth | Keep Step 8 compatibility projection/view gated until validation SQL proves field-contract parity | Yes |
| `Trade.PositionForExternalUse` and `History.PositionForExternalUse` source contract for ASIC2 ext open positions | Step 8 expects these as primary ASIC2 open-position inputs but runtime column/access profiling is still pending | `ASIC2_ext_OpenPositions_PositionsReport` may fail or drift if source shapes differ from package assumptions | Run `databricks/sql/06_asic2_subset/01_asic2_source_profiling.sql` and confirm required columns before un-gating Step 8 ext staging SQL | Yes |
| `History.BackOfficeCustomer` / customer-history source contract for ASIC2 customer profile | ASIC2 customer-position shaping needs historical customer/regulation enrichment, but final source-column contract is not confirmed | `ASIC2_Customer_PositionReport` parity can diverge and propagate into `ASIC2_Transactions` | Confirm source mapping and required-column contract before un-gating customer-profile staging template | Yes |
| `ASIC2_InstrumentMetaData` source contract (`Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Trade.Instrument`, `Trade.ProviderToInstrument`, `Dictionary.Currency`) | Inputs are expected in lineage, but runtime source availability/columns are still gated from Step 5B2 profiling | Instrument metadata can be incomplete or fail, impacting positions/transactions and MiFID compatibility fields | Complete profiling and document confirmed source path before activating `ASIC2_InstrumentMetaData` template | Yes |
| `SP_ASIC2_Instrument_Automation` conditional dependency | Out of scope only if `ASIC2_InstrumentMetaData` can be recreated from profiled sources without procedure-only logic | Silent omission can break parity if automation-specific logic is required | Keep dependency conditional and explicitly re-check after profiling; activate only if proven necessary | Yes |
| `SP_ASIC2_PositionReport_Agg` / aggregate ASIC2 outputs dependency | Out of scope only if they do not feed `ASIC2_Positions` / `ASIC2_Transactions` / MiFID projection | If required but skipped, downstream transaction parity may be incomplete | Verify with profiling and gate activation if direct feed is proven | Yes |
| `CDE_Execution_timestamp -> OpenTime` mapping | Mapping is still unproven for ETORO semantics | MiFID compatibility view may expose incorrect transaction timing | Validate parse success, round-trip format behavior, and projected `OpenTime` parity before activation | Yes |
| EMIR Refit UPI non-dependency proof for MiFID fields | UPI is present in full ASIC2 schema but should not affect MiFID-consumed compatibility columns unless proven | Pulling UPI logic into Step 8 unnecessarily can add avoidable dependencies and complexity | Use Step 8 validation checks to prove UPI does not alter the 11 required MiFID compatibility fields | No (unless validation proves impact) |
| Step 9 `History.BackOfficeCustomer` required-column/access profiling | Mapping is confirmed (`main.general.bronze_etoro_history_backofficecustomer`) but Step 9-specific required-column/runtime parity is not yet profiled | Customer/reg-change customer staging can fail or drift on regulation/account-type/as-of filters | Run `databricks/sql/07_mifid2_ext/01_mifid2_ext_source_profiling.sql` and confirm required columns for Step 9 contracts before un-gating customer templates | Yes |
| Step 9 `Trade/History.PositionForExternalUse` source-shape parity | Mappings are confirmed, but SSIS date-window/filter parity and required-column checks are not runtime-validated | `MIFID2_ext_Position` / `MIFID2_ext_RegChange_Position` can diverge from SQL Server position population | Validate required columns and day-window parity before un-gating `03_position_ext_staging.sql` | Yes |
| Step 9 PIN/UserAPI source contract | Customer and Failed TRAX flows require PIN enrichment, but exact runtime source object/column contracts are still discovery-gated | `PIN_ID` / `PIN_Type` / `PIN` / `UAPI_CountryID` outputs can be null/incorrect in staging | Complete UserAPI/PIN discovery + required-column profiling, then replace temporary gated placeholders in Step 9 templates | Yes |
| Step 9 reg-change migration population parity | Step 9 reg-change customer/position flows depend on Step 6 migration population representation and interval semantics (`PrevRegulationID`, `RegValidFrom`, `RegValidTo`, `RegChangeRank`) | Incorrect reg-change CID/position inclusion around migration boundaries | Confirm Step 6 parity behavior for `main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population` before un-gating reg-change templates | Yes |
| Step 9 `MIFID2_Failed_TRAX` history/current dependency | Step 9 requires latest-row logic over `MIFID2_NPD_TRAX`, but history/cutover window and availability are unresolved | Failed-TRAX customer supplementation can be incomplete or non-deterministic for requested validation windows | Define validation-window seed policy and confirm `main.regtech_ops_stg.bi_output_regtechops_mifid2_npd_trax` availability before un-gating `06_failed_trax_staging.sql` | Yes |
| Step 9 missing formal DDLs for seven `MIFID2_ext_*` tables | Only `MIFID2_Failed_TRAX` has formal DDL in ssis-created DDL folder; other contracts are reconstructed | Silent schema drift risk if runtime source columns differ from SSIS metadata/SP usage assumptions | Keep contracts documented as "derived from SSIS metadata + consumer stored procedure usage" and validate target required columns before activation | Yes |
| Step 10/11 `Dictionary.Ext_TradeFund` Databricks mapping for customer outputs | `SP_MIFID2_Customer` and `SP_MIFID2_RegChange_Customer` use `Dictionary.Ext_TradeFund` for `CopyFund`/`CopyFundName`/`FundType`, but no confirmed Databricks object mapping is documented yet | `MIFID2_Customer` and `MIFID2_RegChange_Customer` outputs can miss or misclassify copy-fund attributes | Confirm source mapping and required-column contract (`FundAccountID`, `FundName`, `FundType`) before un-gating `databricks/sql/08_outputs/01_mifid2_customer.sql` and `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql` | Yes |
| Step 10/11 `Reg_Ext_CustomerLatinName` source/access gate for customer outputs | Customer Latin-name staging object is still expected-source/access-pending from Step 5B2 | Chinese/Cyrillic name-translation parity can diverge from SQL Server | Complete source profiling and stage population for `main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname` before enabling Step 10/11 output SQL | Yes |
| Step 10 `MIFID2_Customer` activation dependency on Step 9 gates | Step 10 consumes `bi_output_regtechops_mifid2_ext_customer` and `bi_output_regtechops_mifid2_failed_trax`, both still gated on PIN/UserAPI and failed-TRAX prerequisites | Final customer output can be incomplete or non-parity if activated early | Keep Step 10 SQL as commented template until Step 9 gating prerequisites pass | Yes |
| Step 10 `ReplaceChar` parity validation gate for `MIFID2_Customer` | Step 10 name/PIN normalization relies on `bi_output_regtechops_fn_replacechar`; production activation requires parity confirmation against SQL Server behavior | Customer identity/name fields can drift even if upstream staging is available | Execute and approve ReplaceChar parity checks before un-gating `databricks/sql/08_outputs/01_mifid2_customer.sql` | Yes |
| Step 11 `MIFID2_RegChange_Customer` activation dependency on Step 9 gates | Step 11 consumes `bi_output_regtechops_mifid2_ext_regchange_customer`, which is still gated on migration/reg-change interval parity and PIN/UserAPI prerequisites | Reg-change customer output can be incomplete or non-parity if activated early | Keep Step 11 SQL as commented template until Step 9 reg-change customer prerequisites pass | Yes |
| Step 11 `ReplaceChar` parity validation gate for `MIFID2_RegChange_Customer` | Step 11 name/PIN normalization relies on `bi_output_regtechops_fn_replacechar`; activation without parity evidence can drift from SQL Server identity output | Reg-change customer names and PIN-derived identifiers can diverge even if staging is available | Execute and approve ReplaceChar parity checks before un-gating `databricks/sql/08_outputs/02_mifid2_regchange_customer.sql` | Yes |
| Step 12 price/split carry-forward gate (`Reg_CurrencyPrice_Ext`) | Step 12 report pricing logic depends on Step 5B1 `Reg_CurrencyPrice_Ext`, but source-shape parity evidence is still pending | Price derivation and report branch outputs can drift or fail | Complete runtime source-shape profiling and required-column parity checks before Step 12 activation | Yes |
| Step 12 price/split carry-forward gate (`Reg_Ext_DailyMaxPrices`) | Step 12 report pricing logic depends on Step 5B1 `Reg_Ext_DailyMaxPrices`, but source-shape parity evidence is still pending | Max-price lookups can drift or fail for report-day calculations | Complete runtime source-shape profiling and required-column parity checks before Step 12 activation | Yes |
| Step 12 price/split carry-forward gate (`Reg_Ext_CurrencyPriceMaxDateWithSplit`) | Candidate source selection remains unresolved and Step 12 split/price logic depends on the selected source | Report prices and split-adjusted calculations can diverge from SQL Server parity | Finalize candidate source selection from profiling evidence and lock the contract before Step 12 activation | Yes |
| Step 12 price/split carry-forward gate (`Reg_Ext_T_PriceCandle60Min`) | Required-column validation is still pending for the expected source | Latest-price dependent report enrichments can fail or be inconsistent | Complete required-column validation (`InstrumentID`, `BidLast`, `AskLast`, `DateFrom`) before Step 12 activation | Yes |
| Step 12 migration/in-out materialization policy (`Reg_MigrationInOut_Population` / `Reg_RegulationInOutDailyData`) | Policy between prefixed gold snapshot vs SSIS-compatible recreation is not finalized for all consumers | RegChange and movement-driven report population can produce inconsistent lineage and counts | Lock materialization policy with parity evidence and document run-snapshot behavior before report activation | Yes |
| Step 12 movement gate (`Reg_Regulation_Movments_Positions`) | Step 6 source parity and enrichment gates remain unresolved for movement staging consumed by Step 12 report logic | RegChange branch composition and movement-related report rows can drift | Clear Step 6 movement gates (source contracts, join/date parity, price enrichment parity) before Step 12 activation | Yes |
| Step 12 dependency gate (`InstrumentMetaData_SpecialChar_Conversion`) | Conversion output depends on unresolved `Reg_Ext_Trade_InstrumentMetaData` source profiling | Instrument full-name/classification enrichment can diverge | Confirm source mapping/required columns and validate conversion parity before Step 12 activation | Yes |
| Step 12 dependency gate (`FuturesMetaData`) | Expected mapping is `main.trading.bronze_etoro_trade_futuresmetadata`, but required-column profiling is not complete | Futures CFI/expiration/multiplier fields can be missing or incorrect | Profile required columns (`InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`) and validate coverage before activation | Yes |
| Step 12 parity rule (`MIFID2_Removed_OP_Partials` explicit-column insert) | SQL Server has implicit insert usage in part of SP flow; Databricks parity requires explicit column list | Silent column-order drift risk in removed-partials output | Enforce explicit column-list insert pattern in Step 12 implementation and validate schema order parity | Yes |
| Step 12 caution (`MIFID2_Report` / `MIFID2_ME_Report` `UpdateDate`) | DDL shows nullable `UpdateDate` and SQL Server insert lists do not populate it | Invented defaults would introduce non-parity behavior | Preserve nullable `UpdateDate` with no synthesized default and validate null behavior in reconciliation | Yes |
| Step 12B2 mirror/copy-fund dependency (`Dictionary.Ext_TradeFund`) | Step 12B2 mirror enrichment uses fund-type attributes before the unified trade pool, but Databricks mapping is still unresolved | Copy-fund and fund-type intermediate flags can be missing or misclassified before final projection branches | Confirm mapped source and required columns (`FundAccountID`, `FundName`, `FundType`) before enabling Step 12B2 population templates | Yes |
| Step 12B2 excluded-instrument dependency (`MIFID2_Instruments_To_Exclude`) | Pre-branch position filtering requires mapped equivalent for SQL Server exclusion behavior | Intermediate trade population can include rows that should be filtered out | Confirm mapped equivalent and validate exclusion parity in Step 12B2 reconciliation checks | Yes |
| Step 12B2 dictionary-currency dependency (`Reg_Ext_DictionaryCurrency`) | Pre-branch instrument metadata and GBX handling use dictionary-currency fields, but source/access confirmation remains under Step 5B2 expected-source gates | Intermediate currency abbreviation and GBX tagging can drift or fail before unified trade pool | Confirm Databricks source/access and required-column parity for `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency` before Step 12B2 activation | Yes |
| Step 12B2/12B3 boundary enforcement for FuturesMetaData | Futures metadata is not used in pre-branch trade-pool population but is required in final branch projections | Mixing boundary scope can delay Step 12B2 or create premature final-branch coupling | Keep FuturesMetaData as Step 12B3 activation gate and validate only with final-branch projection logic | Yes |
| Step 12B2 optional checkpoint materialization decision (`trade_population` / `customer_reg_flags` / removed-partials candidates) | CTE-only approach is preferred, but reproducibility/reconciliation may require temporary materialized checkpoints | Inconsistent validation evidence across reruns if checkpoint strategy is undefined | Decide whether optional prefixed checkpoint tables are needed and keep any activation gated | No |
| Step 12B2 split/GBX parity-proof fields | Current validation cannot prove split/GBX parity unless audit fields are materialized in the intermediate checkpoint output | Split and GBX behavior may appear validated without evidence of before/after transformations | Materialize and validate audit fields (`AmountRatioSplit`, `IsSplitAdjusted`, `IsGBX`, `InitForexRateBeforeGBX`, `InitForexRateAfterGBX`, `EndForexRateBeforeGBX`, `EndForexRateAfterGBX`) before treating split/GBX parity as passed | Yes |
| Historical seed strategy for `MIFID2_NPD_TRAX` | Full historical backfill is out of scope; optional seed policy not finalized | Backdated reconciliation windows may fail parity | Define minimal seed approach for validation-only windows | No (unless older validation window is requested) |
| Historical seed strategy for `ASIC2_Transactions` | Same as above; history required only for some parity windows | Backdated ETORO parity may diverge | Define optional seed/rebuild boundaries and triggers | No (unless older validation window is requested) |
| Materialization choice for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` | Both SSIS-created staging and mapped gold equivalents exist | Inconsistent lineage and row-count mismatches between flows | Step 5B2 decision gate: prefer prefixed snapshots from certified gold only after row-count/schema parity passes; otherwise recreate SSIS-compatible materialized logic from run-date inputs | Yes (for deterministic reproducibility) |
| `Reg_Ext_MigrationInOut_STG` source reconstruction | SSIS builds `##TRAN_DATA` from multiple operational sources before loading the staging table | Incorrect migration/in-out rows can affect movement and MiFID report logic | Confirm Databricks equivalents for the temp-table inputs and validate reconstructed row counts against SQL Server | Yes |
| Step 5B2 expected source access/schema validation | Several non-price sources are expected but not yet confirmed in runtime schema (`CustomerLatinName`, `Trade.GetInstrument`, `Trade.InstrumentMetaData`, `Dictionary.Currency`, `Dictionary.CurrencyType`) | Staging SQL may fail or silently diverge if expected sources/columns differ | Run `databricks/sql/03_pre_regulation_ext/04_non_price_source_profiling.sql` and document missing columns before authoring executable staging SQL | Yes |
| `Reg_Instruments_ext` gold/FIRDS replacement shape | SSIS builds the object from raw trade joins, while phase 1 prefers certified gold/FIRDS sources | Missing columns such as visibility, currency IDs, or `IsFuture` can break downstream instrument logic | Validate `main.regtech.gold_regtech_reg_instruments_scd` / full-description coverage against the SSIS output contract before materialization | Yes |
| `Reg_Regulation_Movments_Positions` Step 6 source parity | Active movement load depends on migration population, position/history branches, and post-load instrument/price enrichment | Movement rows, branch composition, and MIFID report filters can drift if join/date logic diverges | Validate Step 6 source contracts via `databricks/sql/04_regulation_movements/01_regulation_movments_source_profiling.sql` before enabling executable staging SQL | Yes |
| `Reg_Regulation_Movments_Positions` price enrichment dependency | Step 6 post-load `EOD_Price` depends on split-price staging source choice still unresolved in Step 5B1 | Missing or incorrect `EOD_Price`/`Symbol` enrichment for movement rows | Resolve/validate `Reg_Ext_CurrencyPriceMaxDateWithSplit` parity before activating Step 6 enrichment logic | Yes |
| Step 7 liquidity source required-column/access profiling | Step 7 mapping sources are confirmed, but runtime source schema/access has not yet been profiled in target workspace | Hedge-liquidity staging activation can fail or drift if columns/access differ | Run `databricks/sql/05_hedge_liquidity/01_hedge_liquidity_source_profiling.sql` and resolve missing columns/access before un-gating Step 7 staging SQL | Yes |
| Step 7 sensitive-column handling for `Reg_LiquidtyAcount_Ext` | SQL Server SSIS selected `Username`, `Password`, `SettingsXML`, but phase-1 staging excludes sensitive fields | Potential downstream shape mismatch if a consumer expects legacy sensitive columns | Confirm whether a compatibility object with masked/null placeholders is needed; keep normal staging object free of raw secrets | Yes |
| `Reg_LiquidtyAcount_SCD` seed/cutover strategy | Step 7 SCD is persistent history and cannot use unconditional full replace pattern | Incorrect cutover can break SCD history and hedge-report dependencies | Approve seed/rebuild vs incremental cutover strategy before activating SCD templates in `databricks/sql/05_hedge_liquidity/03_reg_liquidtyacount_scd.sql` | Yes |
| `Reg_LiquidtyAcount_SCD` removed-account `IsLast` behavior | SQL Server removed-account update does not explicitly set `IsLast = 0`; parity vs data-quality behavior must be explicit | Silent correction can break parity; strict parity can leave edge-case current flags | Preserve SQL Server behavior by default; if correction is desired, document and approve as intentional known difference before execution | Yes |
| Step 7 LEI completeness dependency | Hedge-liquidity mapping depends on gsheet LEI coverage for active/report-relevant accounts | Missing LEI can cause downstream hedge report/data-quality failures | Execute Step 7 LEI completeness checks and decide remediation policy for active accounts with missing LEI | Yes |
| `Ext_MigrationInOut_Population` support-copy representation | SQL Server uses RegSupportDB support copy for cross-DB join behavior | Persistent/non-persistent mismatch can add lineage confusion or duplicate state | Represent as non-persistent CTE/temp relation in Databricks Step 6 flow; do not introduce a separate persistent business target | No |
| `dbo.ReplaceChar` parity implementation | Function behavior is strict (trim-before-replace, specific character map) | Customer identifier/name outputs can drift from SQL Server | SQL authored in Step 4; execute targeted unit tests and compare against SQL Server outputs | Yes |
| `Reg_DWH_StaticPosition` dependency treatment | Referenced in ASIC2 SPs but investigated as stale/legacy; OpenPrice fallback impact still unproven | Incorrect inclusion/exclusion policy can change `OpenPrice` parity in some windows | Keep conditional by default and activate only if fallback-impact validation proves MiFID-field effect | No (unless OpenPrice impact is proven) |
| Audit/control persistence scope (`Reg_SSIS_Log`, `Reports_Control`, SQL Agent metadata) | Needed for lineage and reconciliation governance but not always required for table generation | Reduced observability and harder run diagnostics | Decide minimum audit/control artifacts to replicate in phase 1 | No |

## Explicitly non-blocking by current phase scope

- Delivery/file handling (`CSV`, `7z`, `SFTP`, `TRAX/Cappitech upload`, response processing) remains out of scope for phase 1.
- Optional/reference packages (`MIFID2_TRAX_BACKREP2025.dtsx`, `BestEX_Daily.dtsx`) remain reference-only.
- NOC and old Databricks attempt remain reference-only and are not implementation authorities.

## Recommended resolution order

1. Complete Step 5B1 source profiling for `Reg_CurrencyPrice_Ext` and `Reg_Ext_DailyMaxPrices`.
2. Resolve `Reg_Ext_CurrencyPriceMaxDateWithSplit` source selection from candidate comparison evidence.
3. Complete Step 5B1 runtime validation for `Reg_Ext_T_PriceCandle60Min`.
4. Complete Step 8 source profiling for open-positions, customer-profile, and instrument-metadata dependencies.
5. Validate `CDE_Execution_timestamp -> OpenTime` semantics and approve compatibility mapping.
6. Confirm whether `SP_ASIC2_Instrument_Automation` is required or remains conditional/out of scope.
7. Confirm whether `SP_ASIC2_PositionReport_Agg` or aggregate ASIC2 outputs are truly non-feeding for Step 8.
8. Validate UPI non-dependency for the 11 MiFID compatibility fields.
9. Complete Step 9 source profiling for BackOfficeCustomer, PositionForExternalUse, and reg-change migration dependencies.
10. Confirm Step 9 PIN/UserAPI source contract and replace gated placeholders in customer/failed-TRAX templates.
11. Confirm Step 9 `MIFID2_NPD_TRAX` history/current availability for Failed TRAX validation windows.
12. Validate Step 9 target required-column contracts for all eight staging targets.
13. Confirm Step 10/11 `Dictionary.Ext_TradeFund` mapping and required columns for copy-fund enrichment.
14. Confirm Step 10/11 `Reg_Ext_CustomerLatinName` staging/source contract before activating translation path.
15. Clear Step 11 reg-change customer activation gates after Step 9 reg-change source prerequisites pass.
16. Decide `RecordID` strategy for `MIFID2_Hedge_Report`.
17. Lock staging-vs-gold materialization policy for migration/in-out tables using Step 5B2 parity profiling.
18. Confirm Step 5B2 expected source access/schema before authoring active non-price staging SQL.
19. Confirm Step 6 movement source contracts and join/date parity before activating Step 6 staging DDL.
20. Complete Step 7 liquidity source profiling and close required-column/access gaps.
21. Decide Step 7 SCD seed/cutover strategy and removed-account `IsLast` parity/correction policy.
22. Confirm Step 7 sensitive-column compatibility needs (if any) without exposing secrets.
23. Validate and lock Step 12 price/split carry-forward dependencies (`Reg_CurrencyPrice_Ext`, `Reg_Ext_DailyMaxPrices`, `Reg_Ext_CurrencyPriceMaxDateWithSplit`, `Reg_Ext_T_PriceCandle60Min`) before enabling report logic.
24. Finalize Step 12 migration/movement dependencies (`Reg_MigrationInOut_Population`, `Reg_RegulationInOutDailyData`, `Reg_Regulation_Movments_Positions`) for report-date parity.
25. Clear Step 12 instrument dependencies (`Reg_Ext_Trade_InstrumentMetaData` -> `InstrumentMetaData_SpecialChar_Conversion`) and futures metadata required-column profiling.
26. Confirm Step 12 exclusion mapping parity, enforce `MIFID2_Removed_OP_Partials` explicit-column insert behavior, and retain nullable/no-default `UpdateDate` behavior for `MIFID2_Report` and `MIFID2_ME_Report`.
27. Confirm Step 12B2 `Dictionary.Ext_TradeFund` mapping for mirror/copy-fund intermediate enrichment.
28. Keep FuturesMetaData validation strictly in Step 12B3 final-branch activation checks.
29. Confirm Step 12B2 dictionary-currency source/profile parity for pre-branch metadata and GBX handling.
30. Materialize Step 12B2 split/GBX audit fields before declaring parity checks as passed.

## Step 12B3 carry-forward unresolved dependencies

The following items remain explicitly unresolved for Step 12B3 activation of final branch projections:

- FuturesMetaData profiling gate:
  - `main.trading.bronze_etoro_trade_futuresmetadata`
  - required columns pending final signoff: `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`.
  - validation gate: futures candidate detection must use a pre-output source with `IsFuture = 1` (for example `{{report_metadata_source}}` / `{{trades_final_source}}` enrichment), not output-populated futures fields.
- InstrumentClassification/CFI parity hard gate:
  - exact `SP_MIFID_Report` branch-specific mappings are not fully ported yet for EU/CySEC, UK/FCA, FCA-flow-in-EU, Seychelles, and ME.
  - final branch activation remains blocked while `InstrumentClassification` is intentionally hard-gated in templates.
- Instrument metadata conversion gate:
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion`
  - feeder/source parity remains blocked by unresolved `Reg_Ext_Trade_InstrumentMetaData` profiling.
- `MIFID2_Instruments_To_Exclude` source gate:
  - mapped equivalent is still unresolved and remains a blocking exclusion-parity gate for final branch activation.
- Exclusion mapping gates:
  - validate and lock final behavior for excluded instruments / excluded position IDs / UK excluded CIDs.
  - InstrumentID 341 override source is still required-column profiling pending and remains placeholder-gated as `{{isin_for_instrumentid_341_source}}` with normalized logical columns (`InstrumentID`, `OverrideISIN`, optional effective/report date).
- Step 12B2 boundary gate:
  - final branch templates require either a full in-statement CTE stack or a validated materialized `{{trades_final_source}}`.
  - no out-of-scope CTE reference is allowed.
- Step 5/6 carry-forward gates:
  - unresolved price/split/movement contracts continue to block Step 12B3 execution even though templates are authored.

## Step 12B4 carry-forward unresolved dependencies

The following items remain explicitly unresolved for Step 12B4 final reconciliation evidence signoff:

- `{{trades_final_source}}` availability gate:
  - source-to-output reconciliation checks in Step 12B4 remain optional until this source is materialized/validated.
- `{{report_metadata_source}}` availability gate:
  - IsFuture-driven futures coverage checks remain optional until metadata source contract is validated.
- `{{removed_partial_candidates_source}}` availability gate:
  - candidate-vs-output removed-partials reconciliation remains optional until source is materialized/validated.
- FuturesMetaData profiling gate:
  - `main.trading.bronze_etoro_trade_futuresmetadata`
  - required columns still required for final signoff: `InstrumentID`, `CFICode`, `ExpirationDateTime`, `Multiplier`.
- InstrumentClassification/CFI hard gate:
  - exact `SP_MIFID_Report` branch-specific mappings are still required for full parity signoff.
- InstrumentID 341 override source gate:
  - `{{isin_for_instrumentid_341_source}}` remains required-column profiling pending (`InstrumentID`, `OverrideISIN`, optional effective/report date).
- Optional mapped exclusion source gate:
  - `{{mifid2_instruments_to_exclude_source}}` remains unresolved; exclusion parity check stays optional until mapped source confirmation.
- Optional Step 12B2 checkpoint gate:
  - checkpoint-dependent validations remain optional until optional B2 checkpoint tables are materialized with full schemas.
- Split/GBX audit-field gate:
  - split/GBX parity checks remain optional until audit fields are materialized:
    - `AmountRatioSplit`
    - `IsSplitAdjusted`
    - `IsGBX`
    - `InitForexRateBeforeGBX`
    - `InitForexRateAfterGBX`
    - `EndForexRateBeforeGBX`
    - `EndForexRateAfterGBX`
- Upstream activation gates:
  - Step 5/6/9/10/11 activation gates remain blocking for final Step 12 report-module reconciliation signoff.

## Step 13B1 carry-forward unresolved dependencies

The following items remain explicitly unresolved for Step 13 ETORO activation:

- Step 8 compatibility activation gate:
  - `main.regtech_ops_stg.bi_output_regtechops_mifid2_asic2_transactions`
  - `main.regtech_ops_stg.bi_output_regtechops_vw_mifid2_asic_transactions`
- OpenTime parity gate:
  - `CDE_Execution_timestamp -> OpenTime` parsing and semantic parity must be accepted for ETORO windows.
- ASIC2 history/seed gate:
  - requested ETORO reconciliation windows require confirmed ASIC2 seed coverage.
- OpenPrice conditional fallback gate:
  - `Reg_DWH_StaticPosition` remains conditional/non-blocking unless profiling proves fallback impact on consumed fields (especially `OpenPrice`).
- Instrument metadata conversion gate:
  - `main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion` must be report-date ready for ETORO joins.
- Dictionary currency gates:
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency`
  - `main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype`
- Instrument coverage gate:
  - report-date coverage/contract validation for:
    - `main.regtech.gold_regtech_reg_instruments_scd`
    - `main.regtech.gold_regtech_reg_instruments_full_description`
- ETORO classification hard gate:
  - exact `SP_MIFID2_ETORO_Report` `InstrumentClassification` mapping must be ported; simplified mapping is not parity-safe.
