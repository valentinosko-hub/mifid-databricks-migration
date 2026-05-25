USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Ext_Trade_InstrumentMetaData]    Script Date: 5/13/2026 3:53:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Ext_Trade_InstrumentMetaData](
	[InstrumentID] [int] NOT NULL,
	[InstrumentDisplayName] [varchar](100) NOT NULL,
	[InstrumentTypeImage] [varchar](max) NULL,
	[Ticker] [varchar](max) NULL,
	[ChartTicker] [varchar](max) NULL,
	[InstrumentImageSmall] [varchar](max) NULL,
	[InstrumentImageMedium] [varchar](max) NULL,
	[InstrumentImageLarge] [varchar](max) NULL,
	[Exchange] [varchar](max) NULL,
	[Industry] [varchar](max) NULL,
	[CompanyInfo] [varchar](max) NULL,
	[DailyRolloverFee] [numeric](18, 4) NULL,
	[WeekendRolloverFee] [numeric](18, 4) NULL,
	[ContractRolloverFee] [numeric](18, 4) NULL,
	[InstrumentVisible] [int] NULL,
	[Symbol] [varchar](100) NULL,
	[CandleTimeframeGroup] [int] NULL,
	[SymbolFull] [varchar](100) NULL,
	[Tradable] [bit] NULL,
	[ExchangeID] [int] NULL,
	[StocksIndustryID] [int] NULL,
	[ISINCode] [varchar](30) NULL,
	[ISINCountryCode] [varchar](15) NULL,
	[ContractExpire] [bit] NOT NULL,
	[InstrumentTypeSubCategoryID] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[PriceSourceID] [int] NOT NULL,
	[Cusip] [varchar](255) NULL,
	[CreateDate] [datetime] NULL,
	[UnderlyingExchangeID] [int] NULL,
	[DbLoginName] [nvarchar](128) NULL,
	[AppLoginName] [varchar](500) NULL,
	[SysStartTime] [datetime2](7) NOT NULL,
	[SysEndTime] [datetime2](7) NOT NULL,
	[UpdateDate] [datetime] NOT NULL
) ON [Data] TEXTIMAGE_ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [dbo].[Reg_Ext_Trade_InstrumentMetaData] ADD  CONSTRAINT [df_UpdateDate_Reg_Ext_Trade_InsertedInstrument]  DEFAULT (getdate()) FOR [UpdateDate]
GO

