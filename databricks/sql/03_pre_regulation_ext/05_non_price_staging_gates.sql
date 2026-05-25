-- Step 5B2: non-price staging gates.
--
-- This file intentionally contains no CREATE OR REPLACE TABLE statements.
-- Source profiling has not been executed, so no Step 5B2 staging object is
-- safe for active materialization yet.
--
-- Once `04_non_price_source_profiling.sql` confirms access and required
-- columns, add executable staging SQL in a follow-up module. Keep all targets
-- in main.regtech_ops_stg with the bi_output_regtechops_ prefix.

WITH staging_gates AS (
  SELECT
    'Reg_Ext_MigrationInOut_STG' AS staging_object,
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_migrationinout_stg' AS target_object,
    'pending' AS executable_staging_status,
    'Requires reconstructed ##TRAN_DATA source mapping and run-date parity validation.' AS gate_reason
  UNION ALL
  SELECT
    'Reg_MigrationInOut_Population',
    'main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population',
    'pending',
    'Certified gold source exists; materialize prefixed snapshot only after schema and row-count parity is accepted.'
  UNION ALL
  SELECT
    'Reg_RegulationInOutDailyData',
    'main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata',
    'pending',
    'Certified gold source exists, but procedure output-column contract is not visible in DTSX.'
  UNION ALL
  SELECT
    'Reg_Ext_CustomerLatinName',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_customerlatinname',
    'pending',
    'Expected customer-latin source access and columns must be profiled first.'
  UNION ALL
  SELECT
    'Reg_Ext_HistorySplitRatio',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio',
    'pending',
    'Candidate source and IsCompletedOpenPositions filter must be validated first.'
  UNION ALL
  SELECT
    'Reg_Ext_Trade_GetInstrument',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument',
    'pending',
    'Expected trade get-instrument source access and columns must be profiled first.'
  UNION ALL
  SELECT
    'Reg_Ext_Trade_InstrumentMetaData',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata',
    'pending',
    'Expected trade metadata source access and columns must be profiled first; this gates special-character conversion.'
  UNION ALL
  SELECT
    'Reg_Ext_DictionaryCurrency',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency',
    'pending',
    'Expected dictionary currency source access, columns, and EEAStockExchange cast parity must be validated first.'
  UNION ALL
  SELECT
    'Reg_Ext_DictionaryCurrencyType',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrencytype',
    'pending',
    'Expected dictionary currency-type source access and columns must be profiled first.'
  UNION ALL
  SELECT
    'Reg_Ext_HedgeExecutionLog',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgeexecutionlog',
    'pending',
    'Confirmed raw source exists; package date filter, casts, and required columns must be validated first.'
  UNION ALL
  SELECT
    'Reg_Ext_HedgeHBCExecutionLog',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcexecutionlog',
    'pending',
    'Confirmed raw source exists; IsSuccess/date filters and required columns must be validated first.'
  UNION ALL
  SELECT
    'Reg_Ext_HedgeHBCOrderLog',
    'main.regtech_ops_stg.bi_output_regtechops_reg_ext_hedgehbcorderlog',
    'pending',
    'Confirmed raw source exists; date filters, casts, and required columns must be validated first.'
  UNION ALL
  SELECT
    'Reg_Instruments_ext',
    'main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext',
    'pending',
    'Gold/FIRDS replacement shape must be validated against SSIS raw join output contract.'
)
SELECT *
FROM staging_gates
ORDER BY staging_object;

