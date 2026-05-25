USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[MIFID2_RegChange_Customer]    Script Date: 5/13/2026 1:33:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIFID2_RegChange_Customer](
	[CID] [int] NOT NULL,
	[RegulationID] [int] NOT NULL,
	[PlayerLevelID] [int] NOT NULL,
	[CountryID] [int] NOT NULL,
	[FTD] [datetime] NOT NULL,
	[AccountTypeID] [int] NULL,
	[Country] [varchar](2) NULL,
	[CopyFund] [int] NULL,
	[CopyFundName] [varchar](50) NULL,
	[FundTypeID] [int] NULL,
	[FundType] [varchar](50) NULL,
	[IDType] [int] NULL,
	[PIN_Type] [varchar](50) NULL,
	[PIN_LEI] [varchar](50) NULL,
	[BirthDate] [date] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[IsUKReport] [int] NULL,
	[IsEUReport] [int] NULL,
	[NotAllowedCONCAT] [bit] NULL,
	[ReportDate] [date] NOT NULL,
	[TraxEntity] [varchar](20) NULL,
	[TraxAccount] [varchar](6) NULL,
 CONSTRAINT [PK_test_MIFID2_RegChange_Customer] PRIMARY KEY CLUSTERED 
(
	[ReportDate] ASC,
	[CID] ASC,
	[RegulationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
GO

