-- Rhubarb Press Accounting System - UK Compliance Features
-- VAT registration, reporting, and UK-specific business requirements
-- Target: Azure SQL Database (rhubarbpressdb)
-- IDEMPOTENT: Safe to run multiple times

USE rhubarbpressdb;
GO

PRINT 'Rhubarb Press UK Compliance Features Deployment';
PRINT 'Deployment Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- VAT Rates Table
-- =============================================
PRINT 'Creating VAT Rates table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VATRates')
BEGIN
    CREATE TABLE VATRates (
        VATRateID INT IDENTITY(1,1) PRIMARY KEY,
        VATCode NVARCHAR(10) NOT NULL UNIQUE,
        VATDescription NVARCHAR(100) NOT NULL,
        VATPercentage DECIMAL(5,4) NOT NULL, -- e.g., 0.2000 for 20%
        EffectiveFrom DATE NOT NULL,
        EffectiveTo DATE NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE()
    );

    PRINT 'VAT Rates table created successfully';
END
ELSE
BEGIN
    PRINT 'VAT Rates table already exists';
END
GO

-- =============================================
-- UK Business Information
-- =============================================
PRINT 'Creating UK Business Info table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UKBusinessInfo')
BEGIN
    CREATE TABLE UKBusinessInfo (
        BusinessInfoID INT IDENTITY(1,1) PRIMARY KEY,
        CompanyName NVARCHAR(200) NOT NULL,
        CompanyNumber NVARCHAR(20) NULL, -- Companies House number
        VATNumber NVARCHAR(20) NULL,
        VATRegisteredDate DATE NULL,
        VATScheme NVARCHAR(50) NULL, -- Standard, Cash Accounting, etc.
        BusinessAddress1 NVARCHAR(100) NOT NULL,
        BusinessAddress2 NVARCHAR(100) NULL,
        BusinessCity NVARCHAR(50) NOT NULL,
        BusinessPostCode NVARCHAR(20) NOT NULL,
        BusinessCountry NVARCHAR(50) DEFAULT 'United Kingdom',
        TelephoneNumber NVARCHAR(20) NULL,
        EmailAddress NVARCHAR(100) NULL,
        WebsiteURL NVARCHAR(200) NULL,
        AccountingPeriodStart DATE NOT NULL,
        AccountingPeriodEnd DATE NOT NULL,
        VATSubmissionFrequency NVARCHAR(20) DEFAULT 'Quarterly', -- Monthly, Quarterly, Annual
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );

    PRINT 'UK Business Info table created successfully';
END
ELSE
BEGIN
    PRINT 'UK Business Info table already exists';
END
GO

-- =============================================
-- VAT Returns
-- =============================================
PRINT 'Creating VAT Returns table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VATReturns')
BEGIN
    CREATE TABLE VATReturns (
        VATReturnID INT IDENTITY(1,1) PRIMARY KEY,
        ReturnPeriodStart DATE NOT NULL,
        ReturnPeriodEnd DATE NOT NULL,
        VATDueSales MONEY DEFAULT 0, -- Box 1
        VATDueAcquisitions MONEY DEFAULT 0, -- Box 2
        TotalVATDue MONEY DEFAULT 0, -- Box 3
        VATReclaimedInputs MONEY DEFAULT 0, -- Box 4
        NetVATDue MONEY DEFAULT 0, -- Box 5
        TotalValueSalesExVAT MONEY DEFAULT 0, -- Box 6
        TotalValuePurchasesExVAT MONEY DEFAULT 0, -- Box 7
        TotalValueGoodsSuppliedExVAT MONEY DEFAULT 0, -- Box 8
        TotalAcquisitionsExVAT MONEY DEFAULT 0, -- Box 9
        Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Submitted', 'Accepted', 'Rejected')),
        SubmittedDate DATETIME2 NULL,
        DueDate DATE NOT NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NOT NULL,
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );

    PRINT 'VAT Returns table created successfully';
END
ELSE
BEGIN
    PRINT 'VAT Returns table already exists';
END
GO

-- =============================================
-- Corporation Tax Information
-- =============================================
PRINT 'Creating Corporation Tax table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CorporationTax')
BEGIN
    CREATE TABLE CorporationTax (
        CorporationTaxID INT IDENTITY(1,1) PRIMARY KEY,
        AccountingPeriodStart DATE NOT NULL,
        AccountingPeriodEnd DATE NOT NULL,
        TurnoverTotal MONEY DEFAULT 0,
        TotalExpenses MONEY DEFAULT 0,
        ProfitBeforeTax MONEY DEFAULT 0,
        CorporationTaxRate DECIMAL(5,4) DEFAULT 0.19, -- 19% standard rate
        CorporationTaxDue MONEY DEFAULT 0,
        PaymentDueDate DATE NULL,
        Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Filed', 'Paid', 'Overdue')),
        FiledDate DATETIME2 NULL,
        PaidDate DATETIME2 NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NOT NULL
    );

    PRINT 'Corporation Tax table created successfully';
END
ELSE
BEGIN
    PRINT 'Corporation Tax table already exists';
END
GO

-- =============================================
-- HMRC Communication Log
-- =============================================
PRINT 'Creating HMRC Communication Log...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HMRCCommunications')
BEGIN
    CREATE TABLE HMRCCommunications (
        CommunicationID INT IDENTITY(1,1) PRIMARY KEY,
        CommunicationType NVARCHAR(50) NOT NULL, -- VAT Return, Corporation Tax, Query, etc.
        ReferenceNumber NVARCHAR(50) NULL,
        CommunicationDate DATE NOT NULL,
        Description NVARCHAR(500) NOT NULL,
        Status NVARCHAR(30) DEFAULT 'Pending',
        ResponseReceived BIT DEFAULT 0,
        ResponseDate DATE NULL,
        ResponseDetails NVARCHAR(1000) NULL,
        RelatedVATReturnID INT NULL,
        RelatedCorporationTaxID INT NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NOT NULL,
        FOREIGN KEY (RelatedVATReturnID) REFERENCES VATReturns(VATReturnID),
        FOREIGN KEY (RelatedCorporationTaxID) REFERENCES CorporationTax(CorporationTaxID)
    );

    PRINT 'HMRC Communication Log created successfully';
END
ELSE
BEGIN
    PRINT 'HMRC Communication Log already exists';
END
GO

-- =============================================
-- UK Compliance Views
-- =============================================
PRINT 'Creating UK compliance views...';
GO

-- VAT Summary View
CREATE OR ALTER VIEW vw_VATSummary AS
SELECT
    YEAR(t.TransactionDate) as TaxYear,
    MONTH(t.TransactionDate) as TaxMonth,
    DATENAME(MONTH, t.TransactionDate) + ' ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4)) as TaxPeriod,
    SUM(t.VATAmount) as TotalVAT,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.VATAmount ELSE 0 END) as VATOnSales,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.VATAmount ELSE 0 END) as VATOnPurchases,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as SalesExVAT,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as PurchasesExVAT,
    COUNT(DISTINCT t.TransactionID) as TransactionCount
FROM Transactions t
WHERE t.VATAmount > 0
GROUP BY YEAR(t.TransactionDate), MONTH(t.TransactionDate), DATENAME(MONTH, t.TransactionDate)
HAVING SUM(t.VATAmount) > 0;
GO

-- Quarterly VAT Summary View
CREATE OR ALTER VIEW vw_QuarterlyVATSummary AS
SELECT
    YEAR(t.TransactionDate) as TaxYear,
    CASE
        WHEN MONTH(t.TransactionDate) IN (1,2,3) THEN 'Q1'
        WHEN MONTH(t.TransactionDate) IN (4,5,6) THEN 'Q2'
        WHEN MONTH(t.TransactionDate) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END as Quarter,
    CASE
        WHEN MONTH(t.TransactionDate) IN (1,2,3) THEN 'Jan-Mar ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4))
        WHEN MONTH(t.TransactionDate) IN (4,5,6) THEN 'Apr-Jun ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4))
        WHEN MONTH(t.TransactionDate) IN (7,8,9) THEN 'Jul-Sep ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4))
        ELSE 'Oct-Dec ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4))
    END as QuarterDescription,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.VATAmount ELSE 0 END) as VATDueSales,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.VATAmount ELSE 0 END) as VATReclaimedInputs,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.VATAmount ELSE 0 END) -
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.VATAmount ELSE 0 END) as NetVATDue,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as TotalSalesExVAT,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as TotalPurchasesExVAT
FROM Transactions t
WHERE t.VATAmount > 0
GROUP BY
    YEAR(t.TransactionDate),
    CASE
        WHEN MONTH(t.TransactionDate) IN (1,2,3) THEN 'Q1'
        WHEN MONTH(t.TransactionDate) IN (4,5,6) THEN 'Q2'
        WHEN MONTH(t.TransactionDate) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END;
GO

-- Corporation Tax View
CREATE OR ALTER VIEW vw_CorporationTaxSummary AS
SELECT
    YEAR(t.TransactionDate) as TaxYear,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) as TotalTurnover,
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as TotalExpenses,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) -
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as ProfitBeforeTax,
    0.19 as CorporationTaxRate, -- 19% standard rate
    (SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) -
     SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END)) * 0.19 as EstimatedCorporationTax
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
WHERE coa.AccountType IN ('Revenue', 'Expense')
GROUP BY YEAR(t.TransactionDate);
GO

-- =============================================
-- UK Compliance Procedures
-- =============================================
PRINT 'Creating UK compliance procedures...';
GO

-- Procedure to generate VAT return data
CREATE OR ALTER PROCEDURE sp_GenerateVATReturnData
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        'VAT Return Data for ' + FORMAT(@PeriodStart, 'dd/MM/yyyy') + ' to ' + FORMAT(@PeriodEnd, 'dd/MM/yyyy') as ReturnPeriod,

        -- Box 1: VAT due on sales
        SUM(CASE WHEN t.TransactionType = 'Receipt' AND t.VATAmount > 0 THEN t.VATAmount ELSE 0 END) as Box1_VATDueSales,

        -- Box 2: VAT due on acquisitions (usually 0 for small businesses)
        0.00 as Box2_VATDueAcquisitions,

        -- Box 3: Total VAT due (Box 1 + Box 2)
        SUM(CASE WHEN t.TransactionType = 'Receipt' AND t.VATAmount > 0 THEN t.VATAmount ELSE 0 END) as Box3_TotalVATDue,

        -- Box 4: VAT reclaimed on inputs
        SUM(CASE WHEN t.TransactionType = 'Payment' AND t.VATAmount > 0 THEN t.VATAmount ELSE 0 END) as Box4_VATReclaimedInputs,

        -- Box 5: Net VAT due (Box 3 - Box 4)
        SUM(CASE WHEN t.TransactionType = 'Receipt' AND t.VATAmount > 0 THEN t.VATAmount ELSE 0 END) -
        SUM(CASE WHEN t.TransactionType = 'Payment' AND t.VATAmount > 0 THEN t.VATAmount ELSE 0 END) as Box5_NetVATDue,

        -- Box 6: Total value of sales excluding VAT
        SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as Box6_TotalSalesExVAT,

        -- Box 7: Total value of purchases excluding VAT
        SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as Box7_TotalPurchasesExVAT,

        -- Box 8: Total value of goods supplied excluding VAT (usually same as Box 6 for services)
        SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount - t.VATAmount ELSE 0 END) as Box8_TotalGoodsSuppliedExVAT,

        -- Box 9: Total acquisitions excluding VAT (usually 0)
        0.00 as Box9_TotalAcquisitionsExVAT

    FROM Transactions t
    WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
        AND t.Status = 'Active';
END
GO

PRINT 'UK compliance procedures created successfully';
GO

-- =============================================
-- Indexes for UK Compliance
-- =============================================
PRINT 'Creating UK compliance indexes...';
GO

-- VAT Returns indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('VATReturns') AND name = 'IX_VATReturns_Period')
    CREATE INDEX IX_VATReturns_Period ON VATReturns(ReturnPeriodStart, ReturnPeriodEnd);

-- Corporation Tax indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('CorporationTax') AND name = 'IX_CorporationTax_Period')
    CREATE INDEX IX_CorporationTax_Period ON CorporationTax(AccountingPeriodStart, AccountingPeriodEnd);

-- HMRC Communications indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('HMRCCommunications') AND name = 'IX_HMRCCommunications_Date')
    CREATE INDEX IX_HMRCCommunications_Date ON HMRCCommunications(CommunicationDate);

PRINT 'UK compliance indexes created successfully';
GO

PRINT '';
PRINT '=== UK Compliance Features Deployment Complete ===';
PRINT 'Tables created/verified:';
PRINT '  - VATRates: UK VAT rate definitions';
PRINT '  - UKBusinessInfo: Company registration and VAT details';
PRINT '  - VATReturns: Quarterly VAT return management';
PRINT '  - CorporationTax: Annual corporation tax tracking';
PRINT '  - HMRCCommunications: HMRC correspondence log';
PRINT '';
PRINT 'Views created:';
PRINT '  - vw_VATSummary: Monthly VAT breakdown';
PRINT '  - vw_QuarterlyVATSummary: Quarterly VAT return data';
PRINT '  - vw_CorporationTaxSummary: Annual corporation tax summary';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_GenerateVATReturnData: Generate VAT return figures';
PRINT '';
PRINT 'UK compliance system ready for bank balance setup';
GO