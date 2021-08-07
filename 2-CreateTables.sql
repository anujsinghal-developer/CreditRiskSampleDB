USE [CreditRiskSample]
GO

/****** Object:  Table [dbo].[BANK]    Script Date: 8/4/2021 9:39:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BANK](
	[BANK_ID] [int] NOT NULL,
	[BANK_NAME] [varchar](255) NOT NULL,
	[IS_APPROVED] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[BANK_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


USE [CreditRiskSample]
GO

/****** Object:  Table [dbo].[BANK_RISK_RATING]    Script Date: 8/4/2021 9:40:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BANK_RISK_RATING](
	[BANK_RISK_RATING_ID] [int] NOT NULL,
	[BANK_ID] [int] NULL,
	[RISK_RATING] [int] NULL,
	[BUSINESS_DATE] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[BANK_RISK_RATING_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[BANK_RISK_RATING]  WITH CHECK ADD FOREIGN KEY([BANK_ID])
REFERENCES [dbo].[BANK] ([BANK_ID])
GO


USE [CreditRiskSample]
GO

/****** Object:  Table [dbo].[BANK_TOTAL_ASSET]    Script Date: 8/4/2021 9:40:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BANK_TOTAL_ASSET](
	[BANK_TOTAL_ASSET_ID] [int] NOT NULL,
	[BANK_ID] [int] NULL,
	[TOTAL_ASSETS] [decimal](19, 4) NULL,
	[BUSINESS_DATE] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[BANK_TOTAL_ASSET_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[BANK_TOTAL_ASSET]  WITH CHECK ADD FOREIGN KEY([BANK_ID])
REFERENCES [dbo].[BANK] ([BANK_ID])
GO


USE [CreditRiskSample]
GO

/****** Object:  UserDefinedFunction [dbo].[GetBankLimitByDate]    Script Date: 8/4/2021 9:40:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetBankLimitByDate](@businessDate date, @bank_Id int)
RETURNS decimal
AS 
  BEGIN	
	DECLARE @todayLimit decimal;

	DECLARE @isApprovedBank bit;
	SELECT @isApprovedBank = IS_APPROVED FROM dbo.BANK WHERE BANK_ID = @bank_Id

	IF (@isApprovedBank = 1)
	BEGIN
		SET @todayLimit=2000000;
		DECLARE @bankRiskRaiting int;
		SELECT @bankRiskRaiting = RISK_RATING FROM dbo.BANK_RISK_RATING WHERE BANK_ID = @bank_Id AND BUSINESS_DATE = @businessDate;

		IF(@bankRiskRaiting >= -5 AND @bankRiskRaiting <= -3)		
			SET @todayLimit = @todayLimit -  (@todayLimit * 12/100)
		ELSE IF(@bankRiskRaiting >= -2 AND @bankRiskRaiting <= 0)	
			SET @todayLimit = @todayLimit -  (@todayLimit * 9/100)
		ELSE IF(@bankRiskRaiting >= 1 AND @bankRiskRaiting <= 3)	
			SET @todayLimit = @todayLimit +  (@todayLimit * 5/100)
		ELSE IF(@bankRiskRaiting >= 4 AND @bankRiskRaiting <= 6)	
			SET @todayLimit = @todayLimit +  (@todayLimit * 8/100)
		ELSE IF(@bankRiskRaiting >= 7 AND @bankRiskRaiting <= 10)	
			SET @todayLimit = @todayLimit +  (@todayLimit * 13/100)

		DECLARE @bankTotalAssets decimal;
		SELECT @bankTotalAssets = TOTAL_ASSETS FROM dbo.BANK_TOTAL_ASSET WHERE BANK_ID = @bank_Id AND BUSINESS_DATE = @businessDate;

		if(@bankTotalAssets > 3000000)
			SET @todayLimit = @todayLimit +  (@todayLimit * 23/100)

	END

	return @todayLimit
	 
  END
GO


USE [CreditRiskSample]
GO

/****** Object:  Table [dbo].[CALC_BANK_LIMIT]    Script Date: 8/4/2021 9:41:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CALC_BANK_LIMIT](
	[BANK_ID] [int] NOT NULL,
	[BUSINESS_DATE] [date] NOT NULL,
	[CALC_LIMIT]  AS ([dbo].[GetBankLimitByDate]([BUSINESS_DATE],[BANK_ID]))
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[CALC_BANK_LIMIT]  WITH CHECK ADD FOREIGN KEY([BANK_ID])
REFERENCES [dbo].[BANK] ([BANK_ID])
GO


USE [CreditRiskSample]
GO

/****** Object:  StoredProcedure [dbo].[uspGetApprovedBankLimits]    Script Date: 8/4/2021 9:41:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspGetApprovedBankLimits]
    @businessDate date   
AS   
   SELECT @businessDate AS BusinessDate, B.BANK_NAME AS BankName, BR.RISK_RATING AS Rating, BTA.TOTAL_ASSETS AS TotalAssets,CBL.CALC_LIMIT AS CalculatedLimit  FROM
        BANK B 
		LEFT JOIN (Select BANK_ID, RISK_RATING from BANK_RISK_RATING where BUSINESS_DATE = @businessDate) as  BR ON B.BANK_ID = BR.BANK_ID
		LEFT JOIN  (Select BANK_ID, TOTAL_ASSETS from BANK_TOTAL_ASSET where BUSINESS_DATE = @businessDate) as  BTA ON B.BANK_ID = BTA.BANK_ID
		LEFT JOIN  (Select BANK_ID, CALC_LIMIT from CALC_BANK_LIMIT where BUSINESS_DATE = @businessDate) as  CBL ON B.BANK_ID = CBL.BANK_ID		
		WHERE B.IS_APPROVED = 1 
GO


