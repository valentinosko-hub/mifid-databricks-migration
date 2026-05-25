USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Instruments_ext]    Script Date: 5/15/2026 3:15:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Instruments_ext](
	[InstrumentID] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[InstrumentDisplayName] [varchar](100) NULL,
	[Symbol] [varchar](100) NULL,
	[SymbolFull] [varchar](100) NULL,
	[Tradable] [bit] NULL,
	[ISINCode] [varchar](30) NULL,
	[InstrumentVisible] [int] NULL,
	[BuyCurrencyID] [int] NULL,
	[SellCurrencyID] [int] NULL,
	[ContractExpire] [bit] NULL,
	[ExchangeID] [int] NULL,
	[VisibleInternallyOnly] [bit] NULL,
	[UpdateDate] [datetime] NULL,
	[IsFuture] [bit] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

