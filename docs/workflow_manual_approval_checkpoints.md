# Workflow Manual Approval Checkpoints (Step 17B)

This register defines manual approvals required before any workflow activation beyond Step 17B skeleton mode.

Status values:

- `OPEN`: approval not yet granted.
- `PARTIAL`: partially satisfied, still requires sign-off.
- `CLOSED`: approved with evidence recorded.

| Gate ID | Manual approval checkpoint | Owner | Required evidence | Current status |
| --- | --- | --- | --- | --- |
| AP-01 | Source access confirmed | DE/Data Platform | No active no-schema/no-catalog blockers for execution path | OPEN |
| AP-02 | Source required columns confirmed | DE + Validation | Required-column certifications for active module paths | OPEN |
| AP-03 | Storage/data scan blockers resolved | DE/Data Platform | Resolution evidence for currencyprice and hedge-server storage blockers | OPEN |
| AP-04 | Static reference tables available | Engineering + Validation | Availability evidence for internal accounts/special-char/EDNF refs | PARTIAL |
| AP-05 | PII source policy approved | Governance + RegTech SME + Compliance | Signed policy for run modes and customer-source constraints | OPEN |
| AP-06 | History/seed policy approved | RegTech SME + Data Owners | Approved policy for NPD_TRAX, Failed_TRAX, ASIC2, liquidity SCD | OPEN |
| AP-07 | Migration materialization policy approved | DE + RegTech SME | Decision for `Reg_MigrationInOut_Population` and `Reg_RegulationInOutDailyData` | OPEN |
| AP-08 | ASIC2 seed/history approved | RegTech SME + Validation | Approved window and parity evidence for ASIC2 history needs | OPEN |
| AP-09 | NPD_TRAX history/cutover approved | RegTech SME + Validation | Approved latest-row history/cutover policy | OPEN |
| AP-10 | Liquidity SCD seed/cutover approved | RegTech SME + Engineering | Approved SCD seed/rebuild vs incremental strategy | OPEN |
| AP-11 | Hedge `RecordID` strategy approved | RegTech SME + Engineering | Approved deterministic `RecordID` parity design | OPEN |
| AP-12 | Hedge `TransactionReferenceNumber` parity approved | RegTech SME + Validation | Approved expression and reconciliation evidence | OPEN |
| AP-13 | Final validation passed | Validation Owner | Module and cross-module validation outputs accepted | OPEN |
| AP-14 | SQL Server baseline comparison completed where required | Validation Owner + SQL Server Team | Baseline comparison outputs and sign-off notes | OPEN |

## Policy reminders

- Masked customer fallback is for development/structural testing only.
- Final parity mode requires unmasked PII sources or formal approval.
- NOC and old Databricks attempt materials remain reference-only.
- Delivery/upload/response and production deployment remain out of scope.
