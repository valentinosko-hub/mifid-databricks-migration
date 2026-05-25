USE [RegReportDB_Prod]
GO

/****** Object:  Table [Dictionary].[Ext_Country]    Script Date: 5/13/2026 3:55:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dictionary].[Ext_Country](
	[CountryID] [int] NULL,
	[RegionID] [int] NULL,
	[DefaultCurrencyID] [int] NULL,
	[LanguageID] [int] NULL,
	[Abbreviation] [varchar](2) NULL,
	[LongAbbreviation] [varchar](3) NULL,
	[Name] [varchar](50) NULL,
	[PhonePrefix] [varchar](3) NULL,
	[IsActive] [bit] NULL,
	[IsHighRiskCountry] [tinyint] NULL,
	[IsEligibleForRAFBonusCountry] [bit] NULL,
	[MarketingRegionID] [tinyint] NULL,
	[RiskGroupID] [int] NULL,
	[EconomicTypeID] [int] NULL,
	[IsSettlementRestricted] [bit] NULL,
	[IsoCode] [varchar](3) NULL,
	[UpdateDate] [datetime] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [Dictionary].[Ext_Country] ADD  CONSTRAINT [df_UpdateDate]  DEFAULT (getdate()) FOR [UpdateDate]
GO

