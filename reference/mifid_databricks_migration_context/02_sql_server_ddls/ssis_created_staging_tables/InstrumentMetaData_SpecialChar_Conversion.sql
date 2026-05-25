USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[InstrumentMetaData_SpecialChar_Conversion]    Script Date: 5/15/2026 3:14:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[InstrumentMetaData_SpecialChar_Conversion](
	[InstrumentID] [int] NOT NULL,
	[InstrumentDisplayName] [varchar](100) NULL,
	[New_InstrumentDisplayName] [varchar](100) NULL,
	[ReportDate] [date] NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

