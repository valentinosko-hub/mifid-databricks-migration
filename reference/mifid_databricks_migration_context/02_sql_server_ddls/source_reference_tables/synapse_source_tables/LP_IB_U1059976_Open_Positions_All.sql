/****** Object:  Table [Dealing_staging].[LP_IB_U1059976_Open_Positions_All]    Script Date: 5/13/2026 3:58:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dealing_staging].[LP_IB_U1059976_Open_Positions_All]
(
	[ClientAccountID] [varchar](max) NULL,
	[AccountAlias] [varchar](max) NULL,
	[Model] [varchar](max) NULL,
	[CurrencyPrimary] [varchar](max) NULL,
	[FXRateToBase] [varchar](max) NULL,
	[AssetClass] [varchar](max) NULL,
	[Symbol] [varchar](max) NULL,
	[Description] [varchar](max) NULL,
	[Conid] [varchar](max) NULL,
	[SecurityID] [varchar](max) NULL,
	[SecurityIDType] [varchar](max) NULL,
	[CUSIP] [varchar](max) NULL,
	[ISIN] [varchar](max) NULL,
	[ListingExchange] [varchar](max) NULL,
	[UnderlyingConid] [varchar](max) NULL,
	[UnderlyingSymbol] [varchar](max) NULL,
	[UnderlyingSecurityID] [varchar](max) NULL,
	[UnderlyingListingExchange] [varchar](max) NULL,
	[Issuer] [varchar](max) NULL,
	[Multiplier] [varchar](max) NULL,
	[Strike] [varchar](max) NULL,
	[Expiry] [varchar](max) NULL,
	[Put/Call] [varchar](max) NULL,
	[PrincipalAdjustFactor] [varchar](max) NULL,
	[ReportDate] [varchar](max) NULL,
	[Quantity] [varchar](max) NULL,
	[MarkPrice] [varchar](max) NULL,
	[PositionValue] [varchar](max) NULL,
	[OpenPrice] [varchar](max) NULL,
	[CostBasisPrice] [varchar](max) NULL,
	[CostBasisMoney] [varchar](max) NULL,
	[PercentOfNAV] [varchar](max) NULL,
	[FifoPnlUnrealized] [varchar](max) NULL,
	[Side] [varchar](max) NULL,
	[LevelOfDetail] [varchar](max) NULL,
	[OpenDateTime] [varchar](max) NULL,
	[HoldingPeriodDateTime] [varchar](max) NULL,
	[VestingDate] [varchar](max) NULL,
	[Code] [varchar](max) NULL,
	[OriginatingOrderID] [varchar](max) NULL,
	[OriginatingTransactionID] [varchar](max) NULL,
	[AccruedInterest] [varchar](max) NULL,
	[SerialNumber] [varchar](max) NULL,
	[DeliveryType] [varchar](max) NULL,
	[CommodityType] [varchar](max) NULL,
	[Fineness] [varchar](max) NULL,
	[Weight] [varchar](max) NULL,
	[FileName] [varchar](max) NULL,
	[ReportDateID] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

