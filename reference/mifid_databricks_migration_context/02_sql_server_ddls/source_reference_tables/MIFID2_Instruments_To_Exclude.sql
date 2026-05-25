USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[MIFID2_Instruments_To_Exclude]    Script Date: 5/13/2026 3:54:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIFID2_Instruments_To_Exclude](
	[InstrumentID] [int] NOT NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

