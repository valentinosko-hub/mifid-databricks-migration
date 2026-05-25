USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC2_Positions]    Script Date: 5/15/2026 3:07:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC2_Positions](
	[ReportDate] [datetime] NOT NULL,
	[DateID] [int] NOT NULL,
	[CID] [int] NOT NULL,
	[PositionID] [bigint] NOT NULL,
	[InstrumentID] [int] NULL,
	[Deal] [varchar](20) NOT NULL,
	[Login] [varchar](20) NULL,
	[Transaction Time] [datetime] NOT NULL,
	[Type] [varchar](4) NOT NULL,
	[Symbol] [varchar](100) NULL,
	[Volume] [decimal](16, 6) NULL,
	[Open Price] [decimal](16, 6) NULL,
	[Close Price] [decimal](16, 6) NULL,
	[Profit] [decimal](16, 6) NULL,
	[Login Name] [nvarchar](101) NOT NULL,
	[UpdateDate] [datetime] NULL,
	[LEI] [nvarchar](50) NULL,
	[ValuationDateTime] [datetime] NULL,
	[RegulationID] [int] NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

