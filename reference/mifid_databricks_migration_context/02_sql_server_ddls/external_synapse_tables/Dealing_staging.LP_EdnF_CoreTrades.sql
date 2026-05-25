/****** Object:  Table [Dealing_staging].[LP_EdnF_CoreTrades]    Script Date: 5/13/2026 3:47:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dealing_staging].[LP_EdnF_CoreTrades]
(
	[Rundate] [int] NULL,
	[TradeDate] [int] NULL,
	[Account] [int] NULL,
	[Office] [varchar](max) NULL,
	[Currency] [varchar](max) NULL,
	[Contract] [varchar](max) NULL,
	[OptionType] [varchar](max) NULL,
	[Strike] [float] NULL,
	[ContractDesc] [varchar](max) NULL,
	[BS] [varchar](max) NULL,
	[Lots] [float] NULL,
	[TradingFactor] [float] NULL,
	[TradePrice] [float] NULL,
	[MarketValue] [float] NULL,
	[TradeID] [varchar](max) NULL,
	[Comm] [float] NULL,
	[Fees] [float] NULL,
	[CommissionInclusion] [varchar](max) NULL,
	[PromptYear] [int] NULL,
	[PromptMonth] [int] NULL,
	[Prompt] [int] NULL,
	[ContractType] [varchar](max) NULL,
	[Market] [varchar](max) NULL,
	[Commission_RTHT] [varchar](max) NULL,
	[TradeType] [varchar](max) NULL,
	[Amount] [float] NULL,
	[RecordType] [varchar](max) NULL,
	[LastTradedDate] [int] NULL,
	[Strike2] [int] NULL,
	[CommissionCCY] [varchar](max) NULL,
	[Clearing_Fee_Amount] [float] NULL,
	[Clearing_Fee_CCY] [varchar](max) NULL,
	[Exchange_Fee] [float] NULL,
	[Exchange_Fee_CCY] [varchar](max) NULL,
	[NFA_Fee_Amount] [float] NULL,
	[NFA_Fee_CCY] [varchar](max) NULL,
	[CommEarned] [float] NULL,
	[ContractLongName] [varchar](max) NULL,
	[BaseID] [varchar](max) NULL,
	[Cusip] [varchar](max) NULL,
	[TradeComment] [varchar](max) NULL,
	[FileName] [varchar](max) NULL,
	[ReportDateID] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

