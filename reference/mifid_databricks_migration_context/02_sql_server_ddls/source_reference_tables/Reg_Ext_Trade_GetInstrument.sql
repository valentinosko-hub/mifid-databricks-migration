USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Ext_Trade_GetInstrument]    Script Date: 5/13/2026 3:52:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Ext_Trade_GetInstrument](
	[Industry] [varchar](max) NULL,
	[InstrumentID] [int] NULL,
	[ExchangeID] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[BuyCurrencyID] [int] NULL,
	[SellCurrencyID] [int] NULL,
	[Name] [varchar](41) NULL,
	[TradeRange] [smallint] NULL,
	[DollarRatio] [numeric](8, 2) NULL,
	[Passport] [binary](8) NULL,
	[PipDifferenceThreshold] [bigint] NULL,
	[IsMajor] [bit] NULL,
	[UpdateDate] [datetime] NULL
) ON [Data] TEXTIMAGE_ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [dbo].[Reg_Ext_Trade_GetInstrument] ADD  CONSTRAINT [df_UpdateDate_Trade_GetInstrument]  DEFAULT (getdate()) FOR [UpdateDate]
GO

