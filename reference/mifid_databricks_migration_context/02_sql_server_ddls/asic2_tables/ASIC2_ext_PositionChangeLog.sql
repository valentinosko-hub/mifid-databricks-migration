USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[ASIC2_ext_PositionChangeLog]    Script Date: 5/15/2026 3:23:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASIC2_ext_PositionChangeLog](
	[PositionID] [bigint] NULL,
	[ChangeLogLastOpPriceRate] [numeric](16, 8) NULL,
	[ChangeLogOccurred] [datetime] NULL,
	[ChangeTypeID] [tinyint] NULL,
	[IsSettled] [bit] NULL
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

