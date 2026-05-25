USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC2_Customer_PositionReport]    Script Date: 5/15/2026 3:07:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC2_Customer_PositionReport](
	[CID] [int] NOT NULL,
	[RegulationID] [int] NOT NULL,
	[LabelID] [int] NOT NULL,
	[PlayerLevelID] [int] NOT NULL,
	[PlayerStatusID] [int] NOT NULL,
	[ExternalID] [varchar](50) NULL,
	[PrevRegulationID] [int] NULL,
	[PrevLabelID] [int] NULL,
	[PrevPlayerLevelID] [int] NULL,
	[PrevPlayerStatusID] [int] NULL,
	[PrevLabel] [varchar](50) NULL,
	[CountryID] [int] NULL,
	[Country] [varchar](50) NULL,
	[UpdateDate] [datetime] NULL,
	[CurLabel] [varchar](50) NULL,
	[FirstName] [nvarchar](200) NULL,
	[LastName] [nvarchar](200) NULL,
	[LEI] [nvarchar](50) NULL,
	[AccountTypeID] [tinyint] NULL,
 CONSTRAINT [PK_ASIC2_Customer_v1] PRIMARY KEY CLUSTERED 
(
	[CID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
GO

