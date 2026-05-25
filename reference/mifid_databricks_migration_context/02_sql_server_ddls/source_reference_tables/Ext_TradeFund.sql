USE [RegReportDB_Prod]
GO

/****** Object:  Table [Dictionary].[Ext_TradeFund]    Script Date: 5/13/2026 3:55:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dictionary].[Ext_TradeFund](
	[FundID] [int] NULL,
	[FundName] [nvarchar](255) NULL,
	[FundAccountID] [int] NULL,
	[FundOwnerID] [int] NULL,
	[IsPublic] [bit] NULL,
	[MinCopyAmount] [money] NULL,
	[RefreshIntervalMonths] [int] NULL,
	[CreateDate] [datetime] NULL,
	[LastUpdateDate] [datetime] NULL,
	[FundType] [int] NULL,
	[HasCrypto] [bit] NULL,
	[UpdateDate] [datetime] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [Dictionary].[Ext_TradeFund] ADD  CONSTRAINT [df_UpdateDate_TradeFund]  DEFAULT (getdate()) FOR [UpdateDate]
GO

