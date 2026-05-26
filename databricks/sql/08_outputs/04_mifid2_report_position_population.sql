-- Step 12B2: MIFID2_Report intermediate position/trade population templates.
--
-- Scope in this file:
-- - Intermediate population only up to #tradesFinal equivalent.
-- - Optional customer EU/UK report-eligibility flag preparation.
-- - No final report branch projections (EU/UK/FCA-flow-in-EU/Seychelles/ME).
--
-- Out of scope in this file:
-- - Inserts into main.regtech_ops_stg.bi_output_regtechops_mifid2_report
-- - Inserts into main.regtech_ops_stg.bi_output_regtechops_mifid2_me_report
-- - Finalized insert into main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials
-- - MIFID2_ETORO_Report / MIFID2_Hedge_Report / MIFID2_NPD_TRAX
-- - Delivery/export/upload/response handling
--
-- IMPORTANT:
-- - Keep all execution logic gated/commented until upstream gates pass.
-- - Do not synthesize missing columns.
-- - Preserve legacy "Movments" spelling for movement dependency naming parity.
-- - FuturesMetaData is a Step 12B3 final-projection dependency only.

-- -----------------------------------------------------------------------------
-- 0) Parameter and gate scaffold (safe to run)
-- -----------------------------------------------------------------------------
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
required_inputs AS (
  SELECT *
  FROM VALUES
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_customer', 'implemented_gated', 'Step 10 output dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer', 'implemented_gated', 'Step 11 output dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position', 'implemented_gated', 'Step 9 position staging dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position', 'implemented_gated', 'Step 9 reg-change position staging dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog', 'implemented_gated', 'Step 9 change-log staging dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror', 'implemented_gated', 'Step 9 mirror staging dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population', 'implemented_gated', 'Step 6 migration dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions', 'implemented_gated', 'Step 6 movement dependency (legacy Movments spelling).'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio', 'expected_gated', 'Step 5B2 split dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata', 'expected_gated', 'Step 5B2 instrument metadata dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument', 'expected_gated', 'Step 5B2 instrument lookup dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency', 'expected_gated', 'Dictionary currency dependency used before unified trade pool.'),
    ('main.regtech_ops_stg.bi_output_regtechops_reg_instruments_ext', 'expected_gated', 'Instrument ext dependency (profile/access pending).'),
    ('main.regtech.gold_regtech_reg_instruments_scd', 'implemented_gated', 'Certified instrument SCD dependency.'),
    ('main.regtech.gold_regtech_reg_instruments_full_description', 'implemented_gated', 'Certified instrument full-description dependency.'),
    ('main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion', 'implemented_gated', 'Special-char conversion dependency (profile/access pending for feeder).'),
    ('{{ext_tradefund_source}}', 'unresolved_placeholder', 'Expected source/access pending for Dictionary.Ext_TradeFund mapping.'),
    ('{{mifid2_instruments_to_exclude_source}}', 'unresolved_placeholder', 'Expected source/access pending for MIFID2_Instruments_To_Exclude mapping.')
  AS t(required_input, dependency_status, dependency_note)
),
intermediate_targets AS (
  SELECT *
  FROM VALUES
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_report_trade_population'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_report_customer_reg_flags'),
    ('main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates')
  AS t(intermediate_target)
),
step12b2_gates AS (
  SELECT 'step12b2_position_family_ready' AS gate_name, 'pending' AS gate_status, 'Step 9 position/regchange/changelog/mirror staging gates unresolved.' AS gate_reason
  UNION ALL
  SELECT 'step12b2_customer_outputs_ready', 'pending', 'Step 10/11 customer outputs must be parity-validated.'
  UNION ALL
  SELECT 'step12b2_movement_ready', 'pending', 'Step 6 movement and migration parity gate unresolved (legacy Movments naming retained).'
  UNION ALL
  SELECT 'step12b2_price_split_ready', 'pending', 'Step 5B1/5B2 price+split gates unresolved (including HistorySplitRatio).'
  UNION ALL
  SELECT 'step12b2_tradefund_mapping', 'pending', 'Dictionary.Ext_TradeFund Databricks mapping unresolved for mirror copy-fund enrichment.'
  UNION ALL
  SELECT 'step12b2_instrument_exclusion_mapping', 'pending', 'MIFID2_Instruments_To_Exclude mapping unresolved.'
  UNION ALL
  SELECT 'step12b2_specialchar_conversion', 'pending', 'InstrumentMetaData_SpecialChar_Conversion remains profiling-gated.'
  UNION ALL
  SELECT 'step12b2_removed_partials_explicit_columns', 'pending', 'Removed partial finalization must use explicit target column lists.'
  UNION ALL
  SELECT 'step12b3_futuresmetadata_boundary', 'deferred', 'FuturesMetaData is used only in final branch projections and is deferred to Step 12B3.'
)
SELECT
  rw.report_date,
  ri.required_input,
  ri.dependency_status,
  ri.dependency_note,
  it.intermediate_target,
  g.gate_name,
  g.gate_status,
  g.gate_reason
FROM run_window rw
CROSS JOIN required_inputs ri
CROSS JOIN intermediate_targets it
CROSS JOIN step12b2_gates g
ORDER BY ri.required_input, it.intermediate_target, g.gate_name;

-- -----------------------------------------------------------------------------
-- 1) Optional checkpoint materialization note
-- -----------------------------------------------------------------------------
-- Optional checkpoint tables must not be materialized with dummy schemas.
-- Derive full schemas from finalized Step 12B2 CTE outputs first, then add
-- explicit CREATE TABLE templates in a follow-up gated update.

-- -----------------------------------------------------------------------------
-- 2) Step 12B2 intermediate CTE template (COMMENTED TEMPLATE ONLY - DO NOT RUN)
-- -----------------------------------------------------------------------------
/*
WITH run_parameters AS (
  SELECT CAST('{{report_date}}' AS DATE) AS report_date
),
run_window AS (
  SELECT
    report_date,
    CAST(report_date AS TIMESTAMP) AS window_start_ts,
    CAST(date_add(report_date, 1) AS TIMESTAMP) AS window_end_ts
  FROM run_parameters
),
latest_changelog AS (
  SELECT
    PositionID,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    IsSettled
  FROM (
    SELECT
      p.*,
      ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.ChangeLogOccurred DESC) AS rn
    FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_positionchangelog p
  ) x
  WHERE x.rn = 1
),
mirror_copyfund AS (
  SELECT
    m.MirrorID,
    m.ParentCID,
    m.MirrorOperationID,
    m.Occurred,
    m.CopyFund,
    tf.FundType AS FundType,
    CASE
      WHEN tf.FundType = 1 THEN 'People'
      WHEN tf.FundType = 2 THEN 'Partners'
      WHEN tf.FundType = 3 THEN 'Market'
      ELSE NULL
    END AS FundTypeName
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_mirror m
  LEFT JOIN {{ext_tradefund_source}} tf
    ON m.ParentCID = tf.FundAccountID
  WHERE m.CopyFund = 1
),
positions_main_base AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    CASE
      WHEN p.CloseOccurred >= rw.window_start_ts AND p.CloseOccurred < rw.window_end_ts THEN 'C'
      WHEN p.OpenOccurred >= rw.window_start_ts AND p.OpenOccurred < rw.window_end_ts THEN 'O'
      ELSE ''
    END AS OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    COALESCE(cl.ChangeLogLastOpPriceRate, cl_orig.ChangeLogLastOpPriceRate) AS ChangeLogLastOpPriceRate,
    COALESCE(cl.ChangeLogOccurred, cl_orig.ChangeLogOccurred) AS ChangeLogOccurred,
    COALESCE(cl.ChangeTypeID, cl_orig.ChangeTypeID) AS ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    COALESCE(cl.IsSettled, cl_orig.IsSettled) AS ChangeLogIsSettled,
    p.InitialUnits
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_position p
  CROSS JOIN run_window rw
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
    ON c.CID = p.CID
   AND p.OpenOccurred >= c.FTD
   AND p.OpenOccurred < rw.window_end_ts
   AND p.OpenOccurred >= TIMESTAMP('2015-04-26')
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata tim
    ON tim.InstrumentID = p.InstrumentID
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument gi
    ON gi.InstrumentID = tim.InstrumentID
  LEFT JOIN latest_changelog cl
    ON cl.PositionID = p.PositionID
  LEFT JOIN latest_changelog cl_orig
    ON cl_orig.PositionID = p.OriginalPositionID
),
positions_main_with_same_day_open AS (
  SELECT * FROM positions_main_base
  UNION ALL
  SELECT
    PositionID,
    ParentPositionID,
    CID,
    OpenOccurred,
    CloseOccurred,
    InitForexRate,
    EndForexRate,
    AmountInUnitsDecimal,
    InstrumentID,
    IsBuy,
    Leverage,
    'O' AS OpenORClose,
    MirrorID,
    HedgeServerID,
    IsSettled,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    InitForexPriceRateID,
    EndForexPriceRateID,
    LastOpPriceRate,
    OriginalPositionID,
    ChangeLogIsSettled,
    InitialUnits
  FROM positions_main_base b
  CROSS JOIN run_window rw
  WHERE b.OpenORClose = 'C'
    AND b.OpenOccurred >= rw.window_start_ts
    AND b.OpenOccurred < rw.window_end_ts
    AND b.CloseOccurred >= rw.window_start_ts
    AND b.CloseOccurred < rw.window_end_ts
),
positions_main_filtered AS (
  SELECT p.*
  FROM positions_main_with_same_day_open p
  LEFT JOIN {{mifid2_instruments_to_exclude_source}} ex
    ON ex.InstrumentID = p.InstrumentID
   AND p.IsSettled = 1
  WHERE ex.InstrumentID IS NULL
    AND p.OpenOccurred >= TIMESTAMP('2015-04-26')
),
main_partial_pop AS (
  SELECT DISTINCT OriginalPositionID
  FROM positions_main_filtered
  CROSS JOIN run_window rw
  WHERE PositionID <> OriginalPositionID
    AND OpenOccurred >= rw.window_start_ts
),
main_partial_pop_all AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    COALESCE(p.InitialUnits, p.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits
  FROM positions_main_filtered p
  JOIN main_partial_pop pop
    ON p.PositionID = pop.OriginalPositionID
  CROSS JOIN run_window rw
  WHERE p.OpenOccurred >= rw.window_start_ts
    AND p.OpenORClose = 'O'
  UNION ALL
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits
  FROM positions_main_filtered p
  JOIN main_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  CROSS JOIN run_window rw
  WHERE p.OpenOccurred >= rw.window_start_ts
    AND p.OpenORClose = 'C'
),
removed_partial_candidates_main AS (
  SELECT
    rw.report_date AS ReportDate,
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits,
    c.RegulationID
  FROM positions_main_filtered p
  JOIN main_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
    ON c.CID = p.CID
  CROSS JOIN run_window rw
  WHERE p.CloseOccurred < rw.window_end_ts
    AND p.OpenORClose = 'O'
    AND p.OriginalPositionID <> p.PositionID
),
positions_main_after_partials AS (
  SELECT p.*
  FROM positions_main_filtered p
  LEFT JOIN main_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  WHERE pop.OriginalPositionID IS NULL
  UNION ALL
  SELECT * FROM main_partial_pop_all
),
split_candidates AS (
  SELECT DISTINCT
    hs.InstrumentID,
    hs.MinDate,
    hs.MaxDate,
    hs.AmountRatio,
    hs.IsCompletedOpenPositions,
    hs.AmountRatioUnAdjusted
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_ext_historysplitratio hs
  JOIN positions_main_after_partials p
    ON p.InstrumentID = hs.InstrumentID
  WHERE hs.IsCompletedOpenPositions = 1
),
split_main_ratio AS (
  SELECT
    p.PositionID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InstrumentID,
    EXP(SUM(LOG(s.AmountRatioUnAdjusted))) AS AmountRatioSplit
  FROM positions_main_after_partials p
  JOIN split_candidates s
    ON s.InstrumentID = p.InstrumentID
  WHERE p.OpenORClose = 'O'
    AND p.OpenOccurred < s.MinDate
    AND COALESCE(p.CloseOccurred, TIMESTAMP('2100-01-01')) > s.MinDate
  GROUP BY p.PositionID, p.OpenOccurred, p.CloseOccurred, p.InstrumentID
),
instruments_full_description_latest AS (
  SELECT
    fd.InstrumentID,
    fd.IndexNameFullDescription
  FROM main.regtech.gold_regtech_reg_instruments_full_description fd
  QUALIFY fd.ReportDate = MAX(fd.ReportDate) OVER ()
),
instrument_scd_active AS (
  SELECT scd.*
  FROM main.regtech.gold_regtech_reg_instruments_scd scd
  CROSS JOIN run_window rw
  WHERE scd.Tradable = 1
    AND rw.report_date >= scd.ValidFrom
    AND rw.report_date < scd.ValidTo
),
instrument_specialchar_for_date AS (
  SELECT
    i.InstrumentID,
    i.New_InstrumentDisplayName
  FROM main.regtech_ops_stg.bi_output_regtechops_instrumentmetadata_specialchar_conversion i
  CROSS JOIN run_window rw
  WHERE i.ReportDate = rw.report_date
),
instrument_metadata_gbx AS (
  SELECT
    scd.InstrumentID,
    scd.InstrumentTypeID,
    scd.BuyCurrencyID,
    scd.SellCurrencyID,
    scd.ISINCode,
    scd.IsMifid,
    COALESCE(scd.IsMifidByFCA, scd.IsMifid) AS IsMifidByFCA,
    fd.IndexNameFullDescription,
    CASE
      WHEN sc.InstrumentID IS NOT NULL THEN REPLACE(sc.New_InstrumentDisplayName, ',', ' ')
      ELSE REPLACE(scd.InstrumentDisplayName, ',', ' ')
    END AS InstrumentFullName,
    CASE WHEN scd.SellCurrencyID = 666 THEN 1 ELSE 0 END AS IsGBX,
    CASE
      WHEN scd.SellCurrencyID = 666 THEN REPLACE(dc_sell.Abbreviation, 'GBX', 'GBP')
      WHEN scd.SellCurrencyID = 38 THEN REPLACE(dc_sell.Abbreviation, 'CNH', 'CNY')
      ELSE dc_sell.Abbreviation
    END AS SellAbbreviation,
    dc_buy.Abbreviation AS BuyAbbreviation,
    scd.IsFuture
  FROM instrument_scd_active scd
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_buy
    ON dc_buy.CurrencyID = scd.BuyCurrencyID
  LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_dictionarycurrency dc_sell
    ON dc_sell.CurrencyID = scd.SellCurrencyID
  LEFT JOIN instrument_specialchar_for_date sc
    ON sc.InstrumentID = scd.InstrumentID
  LEFT JOIN instruments_full_description_latest fd
    ON fd.InstrumentID = scd.InstrumentID
),
trades_main_pre_gbx AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    CASE WHEN p.OpenORClose = 'O' THEN p.ChangeLogLastOpPriceRate END AS InitForexRate,
    CASE WHEN p.OpenORClose = 'C' THEN p.LastOpPriceRate END AS EndForexRate,
    p.InitForexRate AS OrigInitForexRate,
    p.EndForexRate AS OrigEndForexRate,
    CASE
      WHEN p.OpenORClose = 'O'
        THEN CAST(p.AmountInUnitsDecimal / COALESCE(s.AmountRatioSplit, 1) AS DECIMAL(16,6))
      ELSE p.AmountInUnitsDecimal
    END AS AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    CONCAT(CAST(p.PositionID AS STRING), 'UK', p.OpenORClose) AS PositionIDOut,
    CASE
      WHEN (p.OpenORClose = 'O' AND p.IsBuy = 1) OR (p.OpenORClose = 'C' AND p.IsBuy = 0) THEN 1
      ELSE 0
    END AS BuyORSell,
    p.OriginalPositionID,
    CASE
      WHEN p.OpenORClose = 'O' THEN COALESCE(p.ChangeLogIsSettled, p.IsSettled)
      ELSE p.IsSettled
    END AS IsRealStockETF,
    COALESCE(m.CopyFund, 0) AS CopyFund,
    m.FundType,
    m.FundTypeName
  FROM positions_main_after_partials p
  LEFT JOIN mirror_copyfund m
    ON m.MirrorID = p.MirrorID
  LEFT JOIN split_main_ratio s
    ON s.PositionID = p.PositionID
),
trades_main AS (
  SELECT
    t.PositionID,
    t.ParentPositionID,
    t.CID,
    t.OpenOccurred,
    t.CloseOccurred,
    CASE WHEN md.IsGBX = 1 THEN t.InitForexRate / 100.0 ELSE t.InitForexRate END AS InitForexRate,
    CASE WHEN md.IsGBX = 1 THEN t.EndForexRate / 100.0 ELSE t.EndForexRate END AS EndForexRate,
    t.OrigInitForexRate,
    t.OrigEndForexRate,
    t.AmountInUnitsDecimal,
    t.InstrumentID,
    t.IsBuy,
    t.Leverage,
    t.OpenORClose,
    t.MirrorID,
    t.HedgeServerID,
    t.ChangeLogLastOpPriceRate,
    t.ChangeLogOccurred,
    t.ChangeTypeID,
    t.InitForexPriceRateID,
    t.EndForexPriceRateID,
    t.LastOpPriceRate,
    t.PositionIDOut,
    t.BuyORSell,
    t.OriginalPositionID,
    t.IsRealStockETF,
    t.CopyFund,
    t.FundType,
    t.FundTypeName
  FROM trades_main_pre_gbx t
  LEFT JOIN instrument_metadata_gbx md
    ON md.InstrumentID = t.InstrumentID
),
mifid_change_customers AS (
  SELECT DISTINCT reg.CID
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population reg
  CROSS JOIN run_window rw
  WHERE reg.RunDate = rw.report_date
    AND (reg.RegulationID IN (1,2,9) OR reg.PrevRegulationID IN (1,2,9))
),
reg_inout_intervals AS (
  SELECT
    mig.RunDate,
    mig.CID,
    mig.RegulationID,
    mig.Migration_Occurred AS ValidFrom,
    COALESCE(
      LEAD(mig.Migration_Occurred, 1) OVER (PARTITION BY mig.CID ORDER BY mig.Migration_Occurred),
      TIMESTAMP('2099-01-01')
    ) AS ValidTo,
    mig.PrevRegulationID,
    ROW_NUMBER() OVER (PARTITION BY mig.CID, mig.RunDate ORDER BY mig.Migration_Occurred) AS RegChangeRank
  FROM main.regtech_ops_stg.bi_output_regtechops_reg_migrationinout_population mig
  JOIN mifid_change_customers c
    ON c.CID = mig.CID
  CROSS JOIN run_window rw
  WHERE mig.RunDate = rw.report_date
),
trades_main_reg_pruned AS (
  SELECT t.*
  FROM trades_main t
  WHERE NOT EXISTS (
    SELECT 1
    FROM reg_inout_intervals reg
    LEFT JOIN main.regtech_ops_stg.bi_output_regtechops_reg_regulation_movments_positions pm
      ON pm.CID = reg.CID
     AND pm.PositionID = t.PositionID
     AND pm.ReportDate = reg.RunDate
    WHERE reg.CID = t.CID
      AND t.OpenORClose = 'O'
      AND (
        (
          t.OpenOccurred >= reg.ValidFrom
          AND t.OpenOccurred < reg.ValidTo
          AND reg.RegulationID NOT IN (1,2,9)
        )
        OR (
          t.OpenOccurred < reg.ValidFrom
          AND reg.RegChangeRank = 1
          AND reg.PrevRegulationID NOT IN (1,2,9)
        )
      )
      -- SQL Server parity:
      -- DATEDIFF(...) > 10 should not be true when the left-joined movement row
      -- is absent (NULL difference must remain non-true).
      AND pm.PositionID IS NOT NULL
      AND TIMESTAMPDIFF(SECOND, pm.OpenOccurred, pm.Migration_Occurred) > 10
  )
  AND NOT EXISTS (
    SELECT 1
    FROM reg_inout_intervals reg
    WHERE reg.CID = t.CID
      AND t.OpenORClose = 'C'
      AND (
        (
          t.CloseOccurred >= reg.ValidFrom
          AND t.CloseOccurred < reg.ValidTo
          AND reg.RegulationID NOT IN (1,2,9)
        )
        OR (
          t.CloseOccurred < reg.ValidFrom
          AND reg.RegChangeRank = 1
          AND reg.PrevRegulationID NOT IN (1,2,9)
        )
      )
  )
),
uk_to_eu_trades AS (
  SELECT DISTINCT t.PositionID, t.OpenORClose
  FROM reg_inout_intervals reg
  JOIN trades_main_reg_pruned t
    ON t.CID = reg.CID
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
    ON c.CID = t.CID
  WHERE c.RegulationID IN (1,9)
    AND (
      (
        t.OpenORClose = 'O'
        AND (
          (t.OpenOccurred >= reg.ValidFrom AND t.OpenOccurred < reg.ValidTo AND reg.RegulationID = 2)
          OR (t.OpenOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID = 2)
        )
      )
      OR (
        t.OpenORClose = 'C'
        AND (
          (t.CloseOccurred >= reg.ValidFrom AND t.CloseOccurred < reg.ValidTo AND reg.RegulationID = 2)
          OR (t.CloseOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID = 2)
        )
      )
    )
),
eu_to_uk_trades AS (
  SELECT DISTINCT t.PositionID, t.OpenORClose, reg.RegulationID
  FROM reg_inout_intervals reg
  JOIN trades_main_reg_pruned t
    ON t.CID = reg.CID
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
    ON c.CID = t.CID
  WHERE c.RegulationID = 2
    AND (
      (
        t.OpenORClose = 'O'
        AND (
          (t.OpenOccurred >= reg.ValidFrom AND t.OpenOccurred < reg.ValidTo AND reg.RegulationID IN (1,9))
          OR (t.OpenOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID IN (1,9))
        )
      )
      OR (
        t.OpenORClose = 'C'
        AND (
          (t.CloseOccurred >= reg.ValidFrom AND t.CloseOccurred < reg.ValidTo AND reg.RegulationID IN (1,9))
          OR (t.CloseOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID IN (1,9))
        )
      )
    )
),
positions_regchange_base AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    CASE
      WHEN p.CloseOccurred >= rw.window_start_ts AND p.CloseOccurred < rw.window_end_ts THEN 'C'
      WHEN p.OpenOccurred >= rw.window_start_ts AND p.OpenOccurred < rw.window_end_ts THEN 'O'
      ELSE ''
    END AS OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    COALESCE(cl.ChangeLogLastOpPriceRate, cl_orig.ChangeLogLastOpPriceRate) AS ChangeLogLastOpPriceRate,
    COALESCE(cl.ChangeLogOccurred, cl_orig.ChangeLogOccurred) AS ChangeLogOccurred,
    COALESCE(cl.ChangeTypeID, cl_orig.ChangeTypeID) AS ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    COALESCE(p.OriginalPositionID, p.PositionID) AS OriginalPositionID,
    COALESCE(cl.IsSettled, cl_orig.IsSettled) AS ChangeLogIsSettled,
    p.InitialUnits
  FROM main.regtech_ops_stg.bi_output_regtechops_mifid2_ext_regchange_position p
  CROSS JOIN run_window rw
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer c
    ON c.CID = p.CID
   AND p.OpenOccurred >= c.FTD
   AND p.OpenOccurred < rw.window_end_ts
   AND p.OpenOccurred >= TIMESTAMP('2015-04-26')
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_instrumentmetadata tim
    ON tim.InstrumentID = p.InstrumentID
  JOIN main.regtech_ops_stg.bi_output_regtechops_reg_ext_trade_getinstrument gi
    ON gi.InstrumentID = tim.InstrumentID
  LEFT JOIN latest_changelog cl
    ON cl.PositionID = p.PositionID
  LEFT JOIN latest_changelog cl_orig
    ON cl_orig.PositionID = p.OriginalPositionID
),
positions_regchange_with_same_day_open AS (
  SELECT * FROM positions_regchange_base
  UNION ALL
  SELECT
    PositionID,
    ParentPositionID,
    CID,
    OpenOccurred,
    CloseOccurred,
    InitForexRate,
    EndForexRate,
    AmountInUnitsDecimal,
    InstrumentID,
    IsBuy,
    Leverage,
    'O' AS OpenORClose,
    MirrorID,
    HedgeServerID,
    IsSettled,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    InitForexPriceRateID,
    EndForexPriceRateID,
    LastOpPriceRate,
    OriginalPositionID,
    ChangeLogIsSettled,
    InitialUnits
  FROM positions_regchange_base b
  CROSS JOIN run_window rw
  WHERE b.OpenORClose = 'C'
    AND b.OpenOccurred >= rw.window_start_ts
    AND b.OpenOccurred < rw.window_end_ts
    AND b.CloseOccurred >= rw.window_start_ts
    AND b.CloseOccurred < rw.window_end_ts
),
positions_regchange_under_mifid AS (
  SELECT DISTINCT
    p.*,
    CASE
      WHEN p.OpenORClose = 'O' AND p.OpenOccurred >= reg.ValidFrom THEN reg.RegulationID
      WHEN p.OpenORClose = 'C' AND p.CloseOccurred >= reg.ValidFrom THEN reg.RegulationID
      ELSE reg.PrevRegulationID
    END AS OrigRegulationID
  FROM positions_regchange_with_same_day_open p
  JOIN reg_inout_intervals reg
    ON reg.CID = p.CID
  WHERE (
    p.OpenORClose = 'O'
    AND (
      (p.OpenOccurred >= reg.ValidFrom AND p.OpenOccurred < reg.ValidTo AND reg.RegulationID IN (1,2))
      OR (p.OpenOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID IN (1,2))
    )
  )
  OR (
    p.OpenORClose = 'C'
    AND (
      (p.CloseOccurred >= reg.ValidFrom AND p.CloseOccurred < reg.ValidTo AND reg.RegulationID IN (1,2))
      OR (p.CloseOccurred < reg.ValidFrom AND reg.RegChangeRank = 1 AND reg.PrevRegulationID IN (1,2))
    )
  )
),
positions_regchange_filtered AS (
  SELECT *
  FROM positions_regchange_under_mifid
  WHERE OpenOccurred >= TIMESTAMP('2015-04-26')
),
regchange_partial_pop AS (
  SELECT DISTINCT OriginalPositionID
  FROM positions_regchange_filtered
  CROSS JOIN run_window rw
  WHERE PositionID <> OriginalPositionID
    AND OpenOccurred >= rw.window_start_ts
),
regchange_partial_pop_all AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    COALESCE(p.InitialUnits, p.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits,
    p.OrigRegulationID
  FROM positions_regchange_filtered p
  JOIN regchange_partial_pop pop
    ON p.PositionID = pop.OriginalPositionID
  CROSS JOIN run_window rw
  WHERE p.OpenOccurred >= rw.window_start_ts
    AND p.OpenORClose = 'O'
  UNION ALL
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits,
    p.OrigRegulationID
  FROM positions_regchange_filtered p
  JOIN regchange_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  CROSS JOIN run_window rw
  WHERE p.OpenOccurred >= rw.window_start_ts
    AND p.OpenORClose = 'C'
),
removed_partial_candidates_regchange AS (
  SELECT
    rw.report_date AS ReportDate,
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InitForexRate,
    p.EndForexRate,
    p.AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.IsSettled,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    p.OriginalPositionID,
    p.ChangeLogIsSettled,
    p.InitialUnits,
    c.RegulationID
  FROM positions_regchange_filtered p
  JOIN regchange_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer c
    ON c.CID = p.CID
  CROSS JOIN run_window rw
  WHERE p.CloseOccurred < rw.window_end_ts
    AND p.OpenORClose = 'O'
    AND p.OriginalPositionID <> p.PositionID
),
positions_regchange_after_partials AS (
  SELECT p.*
  FROM positions_regchange_filtered p
  LEFT JOIN regchange_partial_pop pop
    ON p.OriginalPositionID = pop.OriginalPositionID
  WHERE pop.OriginalPositionID IS NULL
  UNION ALL
  SELECT
    PositionID,
    ParentPositionID,
    CID,
    OpenOccurred,
    CloseOccurred,
    InitForexRate,
    EndForexRate,
    AmountInUnitsDecimal,
    InstrumentID,
    IsBuy,
    Leverage,
    OpenORClose,
    MirrorID,
    HedgeServerID,
    IsSettled,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    InitForexPriceRateID,
    EndForexPriceRateID,
    LastOpPriceRate,
    OriginalPositionID,
    ChangeLogIsSettled,
    InitialUnits,
    OrigRegulationID
  FROM regchange_partial_pop_all
),
split_regchange_ratio AS (
  SELECT
    p.PositionID,
    p.OpenOccurred,
    p.CloseOccurred,
    p.InstrumentID,
    EXP(SUM(LOG(s.AmountRatioUnAdjusted))) AS AmountRatioSplit
  FROM positions_regchange_after_partials p
  JOIN split_candidates s
    ON s.InstrumentID = p.InstrumentID
  WHERE p.OpenORClose = 'O'
    AND p.OpenOccurred < s.MinDate
    AND COALESCE(p.CloseOccurred, TIMESTAMP('2100-01-01')) > s.MinDate
  GROUP BY p.PositionID, p.OpenOccurred, p.CloseOccurred, p.InstrumentID
),
trades_regchange_pre_gbx AS (
  SELECT
    p.PositionID,
    p.ParentPositionID,
    p.CID,
    p.OpenOccurred,
    p.CloseOccurred,
    CASE WHEN p.OpenORClose = 'O' THEN p.ChangeLogLastOpPriceRate END AS InitForexRate,
    CASE WHEN p.OpenORClose = 'C' THEN p.LastOpPriceRate END AS EndForexRate,
    p.InitForexRate AS OrigInitForexRate,
    p.EndForexRate AS OrigEndForexRate,
    CASE
      WHEN p.OpenORClose = 'O'
        THEN CAST(p.AmountInUnitsDecimal / COALESCE(s.AmountRatioSplit, 1) AS DECIMAL(16,6))
      ELSE p.AmountInUnitsDecimal
    END AS AmountInUnitsDecimal,
    p.InstrumentID,
    p.IsBuy,
    p.Leverage,
    p.OpenORClose,
    p.MirrorID,
    p.HedgeServerID,
    p.ChangeLogLastOpPriceRate,
    p.ChangeLogOccurred,
    p.ChangeTypeID,
    p.InitForexPriceRateID,
    p.EndForexPriceRateID,
    p.LastOpPriceRate,
    CONCAT(CAST(p.PositionID AS STRING), 'UK', p.OpenORClose) AS PositionIDOut,
    CASE
      WHEN (p.OpenORClose = 'O' AND p.IsBuy = 1) OR (p.OpenORClose = 'C' AND p.IsBuy = 0) THEN 1
      ELSE 0
    END AS BuyORSell,
    p.OriginalPositionID,
    CASE
      WHEN p.OpenORClose = 'O' THEN COALESCE(p.ChangeLogIsSettled, p.IsSettled)
      ELSE p.IsSettled
    END AS IsRealStockETF,
    COALESCE(m.CopyFund, 0) AS CopyFund,
    m.FundType,
    m.FundTypeName,
    p.OrigRegulationID
  FROM positions_regchange_after_partials p
  LEFT JOIN mirror_copyfund m
    ON m.MirrorID = p.MirrorID
  LEFT JOIN split_regchange_ratio s
    ON s.PositionID = p.PositionID
),
trades_regchange AS (
  SELECT
    t.PositionID,
    t.ParentPositionID,
    t.CID,
    t.OpenOccurred,
    t.CloseOccurred,
    CASE WHEN md.IsGBX = 1 THEN t.InitForexRate / 100.0 ELSE t.InitForexRate END AS InitForexRate,
    CASE WHEN md.IsGBX = 1 THEN t.EndForexRate / 100.0 ELSE t.EndForexRate END AS EndForexRate,
    t.OrigInitForexRate,
    t.OrigEndForexRate,
    t.AmountInUnitsDecimal,
    t.InstrumentID,
    t.IsBuy,
    t.Leverage,
    t.OpenORClose,
    t.MirrorID,
    t.HedgeServerID,
    t.ChangeLogLastOpPriceRate,
    t.ChangeLogOccurred,
    t.ChangeTypeID,
    t.InitForexPriceRateID,
    t.EndForexPriceRateID,
    t.LastOpPriceRate,
    t.PositionIDOut,
    t.BuyORSell,
    t.OriginalPositionID,
    t.IsRealStockETF,
    t.CopyFund,
    t.FundType,
    t.FundTypeName,
    t.OrigRegulationID
  FROM trades_regchange_pre_gbx t
  LEFT JOIN instrument_metadata_gbx md
    ON md.InstrumentID = t.InstrumentID
),
trades_final_main AS (
  SELECT
    t.*,
    CASE
      WHEN eu.PositionID IS NOT NULL THEN eu.RegulationID
      WHEN uk.PositionID IS NOT NULL THEN 2
      ELSE c.RegulationID
    END AS OrigRegulationID,
    c.IDType,
    c.PIN_LEI,
    c.PIN_Type,
    c.RegulationID,
    CASE
      WHEN eu.PositionID IS NOT NULL OR uk.PositionID IS NOT NULL THEN 1
      ELSE 0
    END AS RegChange
  FROM trades_main_reg_pruned t
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_customer c
    ON c.CID = t.CID
  LEFT JOIN eu_to_uk_trades eu
    ON eu.PositionID = t.PositionID
   AND eu.OpenORClose = t.OpenORClose
  LEFT JOIN uk_to_eu_trades uk
    ON uk.PositionID = t.PositionID
   AND uk.OpenORClose = t.OpenORClose
),
trades_final_regchange AS (
  SELECT
    t.*,
    c.IDType,
    c.PIN_LEI,
    c.PIN_Type,
    c.RegulationID,
    2 AS RegChange
  FROM trades_regchange t
  JOIN main.regtech_ops_stg.bi_output_regtechops_mifid2_regchange_customer c
    ON c.CID = t.CID
),
trades_final AS (
  SELECT * FROM trades_final_main
  UNION ALL
  SELECT * FROM trades_final_regchange
),
customer_reg_activity_flags AS (
  SELECT
    t.CID,
    CASE WHEN MIN(t.OrigRegulationID) = 1 THEN 1 ELSE 0 END AS IsEUReport,
    CASE WHEN MAX(t.OrigRegulationID) = 2 THEN 1 ELSE 0 END AS IsUKReport
  FROM trades_final t
  WHERE t.OrigRegulationID IN (1,2)
    AND t.RegChange > 0
  GROUP BY t.CID
),
removed_partial_candidates AS (
  SELECT
    ReportDate,
    PositionID,
    ParentPositionID,
    CID,
    OpenOccurred,
    CloseOccurred,
    InitForexRate,
    EndForexRate,
    AmountInUnitsDecimal,
    InstrumentID,
    IsBuy,
    Leverage,
    OpenORClose,
    MirrorID,
    HedgeServerID,
    IsSettled,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    InitForexPriceRateID,
    EndForexPriceRateID,
    LastOpPriceRate,
    OriginalPositionID,
    ChangeLogIsSettled,
    InitialUnits,
    RegulationID
  FROM removed_partial_candidates_main
  UNION ALL
  SELECT
    ReportDate,
    PositionID,
    ParentPositionID,
    CID,
    OpenOccurred,
    CloseOccurred,
    InitForexRate,
    EndForexRate,
    AmountInUnitsDecimal,
    InstrumentID,
    IsBuy,
    Leverage,
    OpenORClose,
    MirrorID,
    HedgeServerID,
    IsSettled,
    ChangeLogLastOpPriceRate,
    ChangeLogOccurred,
    ChangeTypeID,
    InitForexPriceRateID,
    EndForexPriceRateID,
    LastOpPriceRate,
    OriginalPositionID,
    ChangeLogIsSettled,
    InitialUnits,
    RegulationID
  FROM removed_partial_candidates_regchange
)
SELECT *
FROM trades_final;
*/

-- -----------------------------------------------------------------------------
-- 3) Removed partials explicit-column template (scope warning)
-- -----------------------------------------------------------------------------
/*
-- COMMENTED TEMPLATE ONLY - DO NOT RUN STANDALONE.
-- removed_partial_candidates exists only inside the full Step 12B2 CTE stack.
-- Use a full CTE stack + explicit column insert when activating this logic.
--
-- Example activation pattern:
-- WITH ... full Step 12B2 CTE stack ...,
-- removed_partial_candidates AS ( ... )
-- INSERT INTO main.regtech_ops_stg.bi_output_regtechops_mifid2_removed_op_partials_candidates (
--   ReportDate,
--   PositionID,
--   ParentPositionID,
--   CID,
--   OpenOccurred,
--   CloseOccurred,
--   InitForexRate,
--   EndForexRate,
--   AmountInUnitsDecimal,
--   InstrumentID,
--   IsBuy,
--   Leverage,
--   OpenORClose,
--   MirrorID,
--   HedgeServerID,
--   IsSettled,
--   ChangeLogLastOpPriceRate,
--   ChangeLogOccurred,
--   ChangeTypeID,
--   InitForexPriceRateID,
--   EndForexPriceRateID,
--   LastOpPriceRate,
--   OriginalPositionID,
--   ChangeLogIsSettled,
--   InitialUnits,
--   RegulationID
-- )
-- SELECT
--   ReportDate,
--   PositionID,
--   ParentPositionID,
--   CID,
--   OpenOccurred,
--   CloseOccurred,
--   InitForexRate,
--   EndForexRate,
--   AmountInUnitsDecimal,
--   InstrumentID,
--   IsBuy,
--   Leverage,
--   OpenORClose,
--   MirrorID,
--   HedgeServerID,
--   IsSettled,
--   ChangeLogLastOpPriceRate,
--   ChangeLogOccurred,
--   ChangeTypeID,
--   InitForexPriceRateID,
--   EndForexPriceRateID,
--   LastOpPriceRate,
--   OriginalPositionID,
--   ChangeLogIsSettled,
--   InitialUnits,
--   RegulationID
-- FROM removed_partial_candidates;
*/

-- -----------------------------------------------------------------------------
-- 4) Step 12B3 reminder
-- -----------------------------------------------------------------------------
-- Final report branch projections (EU/UK/FCA-flow-in-EU/Seychelles/ME) are
-- explicitly deferred to Step 12B3, including all FuturesMetaData-dependent logic.
