USE [RegReportDB_Prod]
GO

/****** Object:  Table [Dictionary].[Ext_SpecialChar]    Script Date: 5/15/2026 4:52:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dictionary].[Ext_SpecialChar](
	[Key] [nchar](1) NOT NULL,
	[Value] [char](1) NOT NULL,
	[UpdateDate] [datetime] NULL
) ON [Data]
WITH
(
DATA_COMPRESSION = PAGE
)
GO

ALTER TABLE [Dictionary].[Ext_SpecialChar] ADD  CONSTRAINT [df_UpdateDate_SpecialChar]  DEFAULT (getdate()) FOR [UpdateDate]
GO

