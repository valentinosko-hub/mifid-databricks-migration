-- Step 6: Regulation movement staging (gated authoring).
--
-- Primary target:
--   main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
--
-- IMPORTANT:
-- - This file intentionally keeps executable movement staging logic gated.
-- - Do not execute final CREATE OR REPLACE TABLE logic until:
--   1) Step 6 source profiling confirms required columns and access.
--   2) Step 5 migration snapshot policy is finalized for:
--      - main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population
--      - main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata
--   3) Step 5 split-price source for post-load enrichment is resolved/parity-validated.
--
-- Support copy note:
-- - SQL Server uses RegSupportDB.dbo.Ext_MigrationInOut_Population as a support copy.
-- - In Databricks Step 6, represent this as a temporary CTE relation (non-persistent).

-- -----------------------------------------------------------------------------
-- Gate status table
-- -----------------------------------------------------------------------------
WITH gate_status AS (
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions' AS target_object,
    'pending' AS executable_staging_status,
    'Awaiting migration snapshot parity + split-price source parity + source-column profiling.' AS gate_reason
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population',
    'pending',
    'Certified gold exists; prefixed snapshot materialization remains parity-gated.'
  UNION ALL
  SELECT
    'main.regtech_ops_stg.bi_output_regtechops_reg_regulationinoutdailydata',
    'pending',
    'Certified gold exists; output-column contract parity remains gated.'
)
SELECT *
FROM gate_status
ORDER BY target_object;

-- -----------------------------------------------------------------------------
-- Intended final movement load logic (for later activation only)
-- -----------------------------------------------------------------------------
-- COMMENTED TEMPLATE ONLY - DO NOT UNCOMMENT UNTIL ALL GATES PASS.
-- Required source profiling, schema validation, and parity checks must pass first.
/*
CREATE OR REPLACE TABLE main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions
USING DELTA
AS
WITH run_parameters AS (
  SELECT
    CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS report_end_ts
  FROM run_parameters
),
migration_population_for_run AS (
  -- Databricks equivalent of SQL Server support-copy object:
  -- RegSupportDB.dbo.Ext_MigrationInOut_Population
  SELECT
    src.RunDate,
    src.CID,
    src.Lei,
    src.RegulationID,
    src.Migration_Occurred,
    src.PrevRegulationID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population src
  JOIN run_parameters p
    ON src.RunDate = p.report_date
),
max_migration AS (
  SELECT
    CID,
    MAX(Migration_Occurred) AS max_migration_occurred
  FROM migration_population_for_run
  GROUP BY CID
),
open_positions AS (
  -- Branch 1: open positions path from Trade.Position
  SELECT
    p.report_date AS ReportDate,
    mig.CID,
    mig.RegulationID,
    mig.Migration_Occurred,
    mig.PrevRegulationID,
    tp.PositionID,
    tp.Occurred AS OpenOccurred,
    CAST(NULL AS TIMESTAMP) AS CloseOccurred,
    tp.IsBuy,
    tp.AmountInUnitsDecimal AS Quantity,
    tp.InitForexRate AS OpenPrice,
    CAST(NULL AS DECIMAL(16, 8)) AS ClosePrice,
    tp.InstrumentID,
    tp.IsSettled,
    CASE WHEN tp.Occurred >= mm.max_migration_occurred THEN 1 ELSE 0 END AS IsOpenedAfterLastMigration
  FROM migration_population_for_run mig
  JOIN max_migration mm
    ON mig.CID = mm.CID
  JOIN run_parameters p
    ON 1 = 1
  JOIN run_window w
    ON 1 = 1
  JOIN main.trading.silver_etoro_trade_position tp
    ON tp.CID = mig.CID
   AND tp.Occurred < w.report_end_ts
   AND (
        tp.Occurred < mig.Migration_Occurred
        OR (tp.Occurred >= mm.max_migration_occurred AND mig.Migration_Occurred = mm.max_migration_occurred)
   )
),
closed_positions AS (
  -- Branch 2: closed positions path from History.Position
  SELECT
    p.report_date AS ReportDate,
    mig.CID,
    mig.RegulationID,
    mig.Migration_Occurred,
    mig.PrevRegulationID,
    hp.PositionID,
    hp.OpenOccurred,
    hp.CloseOccurred,
    hp.IsBuy,
    hp.AmountInUnitsDecimal AS Quantity,
    hp.InitForexRate AS OpenPrice,
    hp.EndForexRate AS ClosePrice,
    hp.InstrumentID,
    hp.IsSettled,
    CASE WHEN hp.OpenOccurred >= mm.max_migration_occurred THEN 1 ELSE 0 END AS IsOpenedAfterLastMigration
  FROM migration_population_for_run mig
  JOIN max_migration mm
    ON mig.CID = mm.CID
  JOIN run_parameters p
    ON 1 = 1
  JOIN run_window w
    ON 1 = 1
  JOIN main.trading.bronze_etoro_history_position_datafactory hp
    ON hp.CID = mig.CID
   AND hp.OpenOccurred < w.report_end_ts
   AND (
        (hp.OpenOccurred < mig.Migration_Occurred AND hp.CloseOccurred >= mig.Migration_Occurred)
        OR (hp.OpenOccurred >= mm.max_migration_occurred AND mig.Migration_Occurred = mm.max_migration_occurred)
   )
),
migration_only_rows AS (
  -- Branch 3: migration-only rows where no position activity matches
  SELECT
    p.report_date AS ReportDate,
    mig.CID,
    mig.RegulationID,
    mig.Migration_Occurred,
    mig.PrevRegulationID,
    CAST(NULL AS BIGINT) AS PositionID,
    CAST(NULL AS TIMESTAMP) AS OpenOccurred,
    CAST(NULL AS TIMESTAMP) AS CloseOccurred,
    CAST(NULL AS INT) AS IsBuy,
    CAST(NULL AS DECIMAL(16, 6)) AS Quantity,
    CAST(NULL AS DECIMAL(16, 8)) AS OpenPrice,
    CAST(NULL AS DECIMAL(16, 8)) AS ClosePrice,
    CAST(NULL AS BIGINT) AS InstrumentID,
    CAST(NULL AS INT) AS IsSettled,
    0 AS IsOpenedAfterLastMigration
  FROM migration_population_for_run mig
  JOIN run_parameters p
    ON 1 = 1
  LEFT JOIN open_positions op
    ON op.CID = mig.CID
   AND op.RegulationID = mig.RegulationID
   AND op.PrevRegulationID = mig.PrevRegulationID
   AND op.Migration_Occurred = mig.Migration_Occurred
  LEFT JOIN closed_positions cp
    ON cp.CID = mig.CID
   AND cp.RegulationID = mig.RegulationID
   AND cp.PrevRegulationID = mig.PrevRegulationID
   AND cp.Migration_Occurred = mig.Migration_Occurred
  WHERE op.PositionID IS NULL
    AND cp.PositionID IS NULL
),
movement_base AS (
  SELECT * FROM open_positions
  UNION ALL
  SELECT * FROM closed_positions
  UNION ALL
  SELECT * FROM migration_only_rows
),
movement_enriched AS (
  SELECT
    b.*,
    scd.Symbol,
    scd.IsMifid,
    scd.IsMifidByFCA,
    CASE
      WHEN b.InstrumentID IS NULL THEN NULL
      WHEN b.IsBuy = 1 THEN CASE WHEN scd.SellCurrencyID = 666 THEN cp.AskSpreaded / 100.0 ELSE cp.AskSpreaded END
      ELSE CASE WHEN scd.SellCurrencyID = 666 THEN cp.BidSpreaded / 100.0 ELSE cp.BidSpreaded END
    END AS EOD_Price,
    CURRENT_TIMESTAMP() AS UpdateDate
  FROM movement_base b
  LEFT JOIN run_parameters p
    ON 1 = 1
  LEFT JOIN main.regtech.gold_regtech_reg_instruments_scd scd
    ON b.InstrumentID = scd.InstrumentID
   AND scd.ValidFrom <= p.report_date
   AND scd.ValidTo > p.report_date
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_currencypricemaxdatewithsplit cp
    ON b.InstrumentID = cp.InstrumentID
   AND cp.OccurredDate = p.report_date
)
SELECT *
FROM movement_enriched;
*/

