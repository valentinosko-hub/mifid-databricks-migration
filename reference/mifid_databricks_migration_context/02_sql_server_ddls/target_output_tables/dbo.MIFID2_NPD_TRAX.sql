USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[MIFID2_NPD_TRAX]    Script Date: 5/13/2026 4:53:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIFID2_NPD_TRAX](
	[ReportDate] [date] NOT NULL,
	[CID] [int] NOT NULL,
	[ReportTypeID] [int] NOT NULL,
	[Entity] [nvarchar](20) NOT NULL,
	[RegulationID] [int] NULL,
	[AccountTypeID] [int] NULL,
	[IDType] [int] NULL,
	[OrigPINType] [nvarchar](100) NULL,
	[PIN] [nvarchar](50) NULL,
	[NotAllowedCONCAT] [bit] NULL,
	[MessageID] [nvarchar](1) NULL,
	[Action] [nvarchar](4) NULL,
	[InternalCode] [nvarchar](20) NULL,
	[ExpiryDate] [nvarchar](1) NULL,
	[EffectiveFromDate] [nvarchar](10) NULL,
	[ExecutingEntity] [nvarchar](20) NULL,
	[CountryofBranch] [nvarchar](2) NULL,
	[LEI] [nvarchar](1) NULL,
	[LEIType] [nvarchar](1) NULL,
	[NaturalPersonType] [nvarchar](4) NULL,
	[BusinessUnit] [nvarchar](1) NULL,
	[ContactEmail] [nvarchar](1) NULL,
	[ParentOfCollectiveInvestmentSchemeStatus] [nvarchar](1) NULL,
	[CountryofNationality] [nvarchar](2) NULL,
	[PassportNumber] [nvarchar](50) NULL,
	[NationalID] [nvarchar](50) NULL,
	[CONCAT] [nvarchar](1) NULL,
	[FirstNames] [nvarchar](140) NULL,
	[Surnames] [nvarchar](140) NULL,
	[DateofBirth] [nvarchar](10) NULL,
	[AcceptedTRAX] [bit] NULL,
	[ErrorColumn] [varchar](100) NULL,
	[ErrorDescription] [nvarchar](400) NULL,
	[FailedSinceDate] [date] NULL,
	[DateFixedTRAX] [datetime] NULL,
	[RowNum] [int] NULL,
	[TraxAccount] [nvarchar](6) NULL,
	[NonLatinOrEmptyName] [bit] NULL,
	[UpdateDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ReportDate] ASC,
	[Entity] ASC,
	[CID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
GO

