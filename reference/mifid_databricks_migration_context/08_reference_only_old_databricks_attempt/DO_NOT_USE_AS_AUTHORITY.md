# Reference Only: Old Databricks Attempt

This folder is reference-only.

The previous Databricks MiFID attempt should not be treated as authoritative. Do not copy its implementation logic unless explicitly approved.

Use it only for:
- old assumptions,
- output delivery hints,
- reference-file hints,
- dependency discovery.

Known issues with the old attempt:
- It was incomplete / skeleton-level for core MiFID report logic.
- It did not fully port `SP_MIFID2_Report`.
- It did not solve `Reg_Regulation_Movments_Positions`.
- It contained approximate `ReplaceChar` logic; use the real SQL Server mapping instead.
