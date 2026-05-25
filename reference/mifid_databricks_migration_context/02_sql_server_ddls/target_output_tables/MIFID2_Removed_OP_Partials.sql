USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[MIFID2_Removed_OP_Partials]    Script Date: 5/13/2026 1:31:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIFID2_Removed_OP_Partials](
	[ReportDate] [date] NULL,
	[PositionID] [bigint] NULL,
	[ParentPositionID] [bigint] NULL,
	[CID] [int] NULL,
	[OpenOccurred] [datetime] NULL,
	[CloseOccurred] [datetime] NULL,
	[InitForexRate] [numeric](16, 8) NULL,
	[EndForexRate] [numeric](16, 8) NULL,
	[AmountInUnitsDecimal] [numeric](16, 6) NULL,
	[InstrumentID] [int] NULL,
	[IsBuy] [tinyint] NULL,
	[Leverage] [int] NULL,
	[OpenORClose] [varchar](1) NOT NULL,
	[MirrorID] [int] NULL,
	[HedgeServerID] [int] NULL,
	[IsSettled] [tinyint] NULL,
	[ChangeLogLastOpPriceRate] [numeric](16, 8) NULL,
	[ChangeLogOccurred] [datetime] NULL,
	[ChangeTypeID] [tinyint] NULL,
	[InitForexPriceRateID] [bigint] NULL,
	[EndForexPriceRateID] [bigint] NULL,
	[LastOpPriceRate] [numeric](16, 8) NULL,
	[OriginalPositionID] [bigint] NULL,
	[ChangeLogIsSettled] [tinyint] NULL,
	[InitialUnits] [numeric](16, 8) NULL,
	[RegulationID] [int] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

