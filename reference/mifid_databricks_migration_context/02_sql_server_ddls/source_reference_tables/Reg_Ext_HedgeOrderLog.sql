USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Ext_HedgeOrderLog]    Script Date: 5/13/2026 3:51:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Ext_HedgeOrderLog](
	[OrderID] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[IsBuy] [int] NULL,
	[Units] [numeric](22, 8) NULL,
	[SendTime] [datetime] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

