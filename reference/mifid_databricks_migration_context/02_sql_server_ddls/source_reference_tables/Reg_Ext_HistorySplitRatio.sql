USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Ext_HistorySplitRatio]    Script Date: 5/13/2026 3:53:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Ext_HistorySplitRatio](
	[InstrumentID] [int] NULL,
	[MinDate] [datetime] NULL,
	[MaxDate] [datetime] NULL,
	[AmountRatio] [money] NULL,
	[IsCompletedOpenPositions] [tinyint] NULL,
	[AmountRatioUnAdjusted] [money] NULL,
	[UpdateDate] [datetime] NOT NULL,
	[PriceRatio] [money] NULL,
	[PriceRatioUnAdjusted] [money] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [dbo].[Reg_Ext_HistorySplitRatio] ADD  CONSTRAINT [df_UpdateDate_Reg_Ext_HistorySplitRatio]  DEFAULT (getdate()) FOR [UpdateDate]
GO

