# RegTech SME Decision List (Step 18B)

Business and regulatory decisions required from RegTech SME, data owners, and validation stakeholders before final parity sign-off and workflow activation.

**Status:** Most items remain open. Masked customer fallback is approved for **development/structural testing only**; it does not close final PII parity requirements.

Related registers:

- `docs/remaining_decisions.md` (D-01, D-05–D-14, D-19, D-20, D-23)
- `docs/manual_approval_gates.md` (MAG-05 through MAG-17)
- `docs/history_seed_requirements.md`

---

## Customer / PII policy

| # | Decision | Requirement | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 1 | Masked customer fallback | Approved **only** for `development_structural_test`; not final/production/regulatory parity source | D-01 (dev) | MAG-05 |
| 2 | Final PII parity | Final Customer, RegChange Customer, Failed TRAX, and NPD TRAX identity fields require unmasked `main.pii_data` **or** formal RegTech SME/Compliance approval documented externally | D-01 (final) | MAG-06 |

---

## History / seed / materialization

| # | Decision | Notes | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 3 | `MIFID2_NPD_TRAX` seed/cutover | Latest-row policy by `(CID, RegulationID)` vs forward-only start | D-06 | MAG-10 |
| 4 | `MIFID2_Failed_TRAX` history dependency | Must align with NPD TRAX history availability | D-07 | MAG-07 |
| 5 | `ASIC2_Transactions` history/seed window | Boundaries for older ETORO parity windows | D-08 | MAG-09 |
| 6 | `Reg_LiquidtyAcount_SCD` seed/cutover | Seed/rebuild vs incremental; removed-account `IsLast` behavior | D-09 | MAG-11 |
| 7 | `Reg_MigrationInOut_Population` materialization | Gold snapshot from `main.regtech` vs SSIS-compatible recreation | D-10 | MAG-08 |
| 8 | `Reg_RegulationInOutDailyData` materialization | Same policy family as migration population | D-11 | MAG-08 |

---

## Hedge and instrument parity

| # | Decision | Notes | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 9 | Hedge `RecordID` strategy | Deterministic generation vs approved alternative (SQL Server: `IDENTITY(100000001,1)`) | D-12 | MAG-12 |
| 10 | Hedge `TransactionReferenceNumber` parity | Expression behavior and exclusion-key matching | D-13 | MAG-13 |
| 11 | Exact CFI / `InstrumentClassification` parity | Sign-off where hard gates remain in ETORO/Hedge/report flows | D-14 | MAG-15 |

---

## Supporting SME decisions (engineering coordination)

| # | Decision | Owner overlap | Decision ID | MAG (support) |
| --- | --- | --- | --- | --- |
| 12 | `CurrencyPriceMaxDateWithSplit` source selection | DE certifies; SME approves business source | D-05 | MAG-14 |
| 13 | `Dictionary.Ext_TradeFund` mapping | Confirm Databricks object/columns | D-15 | MAG-02 |
| 14 | `Reg_Ext_CustomerLatinName` source | Confirm staging population source | D-16 | MAG-02 |
| 15 | PIN/UserAPI source contract | Customer ext and Failed TRAX enrichment | D-17 | MAG-02 |
| 16 | `CDE_Execution_timestamp` → `OpenTime` semantics | ASIC2 compatibility and ETORO timing | D-19 | MAG-09 |
| 17 | Report-scoped exclusion semantics | Row-level `table_name` scope for ETORO/Hedge | D-20 | MAG-15 |
| 18 | ReplaceChar parity sign-off | UDF tests vs SQL Server before customer activation | D-18 | MAG-02, MAG-17 |

---

## Validation and go/no-go

| # | Decision | Notes | Decision ID | MAG |
| --- | --- | --- | --- | --- |
| 19 | SQL Server baseline comparison dates | Define which modules require baseline and comparison windows | D-23 | MAG-16 |
| 20 | Final go/no-go criteria | Module + cross-module validation acceptance; unresolved deltas owned | — | MAG-17 |

**Final go/no-go criteria (summary):**

1. All applicable MAG gates **CLOSED** with external evidence (Jira or designated log).
2. No open hard gates in `docs/open_blockers_for_execution.md` without formal waiver.
3. Required-column and module validation evidence captured per `docs/final_validation_execution_plan.md`.
4. SQL Server baseline comparison completed where MAG-16 requires it.
5. Known differences documented in `docs/known_differences.md` with SME acceptance.
6. Delivery/upload/response and production deployment remain **out of scope** unless a separate program phase is approved.

---

## SME completion checklist

- [ ] Dev-only masked policy acknowledged; final PII path agreed (Items 1–2)
- [ ] NPD / Failed TRAX history policy signed (Items 3–4)
- [ ] ASIC2 seed window signed (Item 5)
- [ ] Liquidity SCD policy signed (Item 6)
- [ ] Migration / regulation in-out materialization signed (Items 7–8)
- [ ] Hedge RecordID and transaction-reference parity signed (Items 9–10)
- [ ] CFI/classification parity signed (Item 11)
- [ ] Baseline comparison scope and dates agreed (Item 19)
- [ ] MAG-05 through MAG-17 updated externally; `docs/remaining_decisions.md` reflects closures

Do not approve production-candidate runs or workflow deployment until DE blockers close and validation evidence is complete.
