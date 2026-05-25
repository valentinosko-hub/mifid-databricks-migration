# ZIP Completeness Check

## Confirmed included

The ZIP includes:

- Core MiFID stored procedures.
- MiFID target table DDLs.
- Supporting stored procedures including SP_InstrumentMetaData_SpecialChar_Conversion, SP_RegInRegOutPopulation, SP_Reg_LiquidtyAcount_SCD, and SP_Reg_Instruments_SCD.
- ASIC2 stored procedures and ASIC2 table DDLs needed for the MiFID ETORO dependency replacement.
- SQL Agent job scripts and job metadata CSVs.
- Reports_Control.csv.
- SSIS project archive eToro_RegulatoryReports_PROD.ispac.
- Extracted SSIS packages: MIFID2, MIFID2 TRAX, Pre_Regulation_Ext, Regulation_Movments_Report, HedgeServerToLiquidity_Mapping, Reg_Instrument_Operation, ASIC2.
- SSIS parameter/environment metadata CSVs.
- Source-to-Databricks mapping files under 06_mappings.
- Static reference data for Dictionary.Ext_SpecialChar.
- Static-table notes for EDNF, InternalAccounts, and Dictionary.Ext_SpecialChar.
- Open questions and decisions.
- Final Cursor prompt.

## Reference-only / intentionally excluded from active scope

- US regulatory stored procedures are not active MiFID dependencies and are not part of the active migration scope.
- NOC docs are not included except as reference notes because the NOC procedure was not implemented.
- Previous Databricks attempt is not included as active implementation logic; use only if separately attached as reference.
- File delivery/SFTP/7z/TRAX response handling is out of scope for this phase.

## Remaining decisions, not missing core files

- Whether to seed/rebuild history for MIFID2_NPD_TRAX if exact historical parity is required.
- Whether to seed/rebuild history for ASIC2_Transactions if exact historical parity is required.
- Exact implementation choice for currency/price/split staging after Cursor inspects Pre_Regulation_Ext.dtsx.
- Whether delivery/response handling becomes phase 2.

