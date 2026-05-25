USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[MIFID2_Failed_TRAX]    Script Date: 5/13/2026 3:54:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIFID2_Failed_TRAX](
	[CID] [int] NULL,
	[GCID] [int] NULL,
	[PlayerLevelID] [int] NULL,
	[PlayerStatusID] [int] NULL,
	[CountryID] [int] NULL,
	[LabelID] [int] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[BirthDate] [datetime] NULL,
	[CountryIDByIP] [int] NULL,
	[curFirstName] [nvarchar](50) NULL,
	[curLastName] [nvarchar](50) NULL,
	[curBirthDate] [datetime] NULL,
	[CitizenshipCountryID] [int] NULL,
	[PIN_ID] [int] NULL,
	[PIN_Type] [varchar](50) NULL,
	[PIN] [nvarchar](128) NULL,
	[UAPI_CountryID] [int] NULL,
	[ReportDate] [datetime] NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

