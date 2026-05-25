USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[InternalAccounts]    Script Date: 5/15/2026 3:14:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[InternalAccounts](
	[CID] [int] NULL,
	[LEI] [varchar](50) NULL,
	[Description] [varchar](50) NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

