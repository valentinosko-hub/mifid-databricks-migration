USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC2_Removed_OP_Partials]    Script Date: 5/15/2026 3:08:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC2_Removed_OP_Partials](
	[ReportDate] [date] NOT NULL,
	[PositionID] [bigint] NULL,
	[CID] [int] NULL,
	[InstrumentID] [int] NULL,
	[OpenOccurred] [datetime] NULL,
	[CloseOccurred] [datetime] NULL,
	[AmountInUnitsDecimal] [numeric](16, 6) NULL,
	[InitForexRate] [numeric](16, 8) NULL,
	[Amount] [money] NULL,
	[IsBuy] [tinyint] NULL,
	[IsSettled] [tinyint] NULL,
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
	[SettlementTypeID] [int] NULL,
	[OpenORClose] [varchar](1) NOT NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

