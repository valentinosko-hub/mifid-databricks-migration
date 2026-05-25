USE [RegReportDB_Prod]
GO

/****** Object:  Table [dbo].[Reg_Ext_HedgeHBCOrderLog]    Script Date: 5/13/2026 3:52:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Reg_Ext_HedgeHBCOrderLog](
	[OrderID] [uniqueidentifier] NULL,
	[IsBuy] [int] NULL,
	[OrderState] [smallint] NULL,
	[ExecutionRate] [numeric](16, 8) NULL,
	[FailReason] [varchar](250) NULL,
	[ExecutionID] [bigint] NULL,
	[HedgeID] [int] NULL,
	[IsCancelOrder] [int] NULL,
	[RequestAmountInLots] [numeric](16, 6) NULL,
	[ExecutionAmountInLots] [numeric](16, 6) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

