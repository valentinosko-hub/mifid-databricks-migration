USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC_ext_OpenPositions_PositionsReport]    Script Date: 5/15/2026 3:09:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC_ext_OpenPositions_PositionsReport](
	[PositionID] [bigint] NULL,
	[CID] [int] NULL,
	[InstrumentID] [int] NULL,
	[OpenOccurred] [datetime] NULL,
	[CloseOccurred] [datetime] NULL,
	[AmountInUnitsDecimal] [numeric](16, 6) NULL,
	[InitForexRate] [numeric](16, 8) NULL,
	[Amount] [money] NULL,
	[IsBuy] [bit] NULL,
	[IsSettled] [bit] NULL,
	[UpdateDate] [datetime] NULL,
	[EndForexRate] [numeric](16, 8) NULL,
	[NetProfit] [numeric](16, 8) NULL,
	[LastOpPriceRate] [decimal](16, 8) NULL,
	[OriginalPositionID] [bigint] NULL,
	[RegulationID] [int] NULL,
	[InitForexPriceRateID] [bigint] NULL,
	[EndForexPriceRateID] [bigint] NULL,
	[InitConversionRate] [decimal](16, 8) NULL,
	[InitialUnits] [numeric](16, 8) NULL,
	[PartialCloseRatio] [numeric](16, 15) NULL,
	[SettlementTypeID] [int] NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

