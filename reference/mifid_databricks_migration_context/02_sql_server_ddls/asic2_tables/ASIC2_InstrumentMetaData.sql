USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC2_InstrumentMetaData]    Script Date: 5/15/2026 3:08:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC2_InstrumentMetaData](
	[InstrumentID] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[Exchange] [varchar](max) NULL,
	[BuyCurrencyID] [int] NULL,
	[SellCurrencyID] [int] NULL,
	[ISINCode] [varchar](30) NULL,
	[BuyAbbreviation] [varchar](20) NULL,
	[SellAbbreviation] [varchar](8000) NULL,
	[InstrumentName] [varchar](41) NULL,
	[IsGBX] [int] NULL,
	[ISINCountryCode] [varchar](15) NULL,
	[InstrumentOfficialName] [varchar](100) NULL,
	[DollarRatio] [money] NULL,
	[Precision] [tinyint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

