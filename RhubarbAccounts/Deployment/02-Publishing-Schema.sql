-- Rhubarb Press Accounting System - Publishing Schema
-- Author management, book tracking, royalty systems, and publishing views
-- Target: Azure SQL Database (rhubarbpressdb)
-- IDEMPOTENT: Safe to run multiple times

USE rhubarbpressdb;
GO

PRINT 'Rhubarb Press Publishing Schema Deployment';
PRINT 'Deployment Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Authors (extends Contacts)
-- =============================================
PRINT 'Creating Authors table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Authors')
BEGIN
    CREATE TABLE Authors (
        AuthorID INT IDENTITY(1,1) PRIMARY KEY,
        ContactID INT NOT NULL,
        PenName NVARCHAR(100) NULL,
        RoyaltyRate DECIMAL(5,4) NOT NULL DEFAULT 0.4000, -- 40% default
        PaymentTerms NVARCHAR(50) DEFAULT 'Quarterly',
        PreferredPaymentMethod NVARCHAR(20) DEFAULT 'Bank Transfer',
        BankAccountName NVARCHAR(100) NULL,
        BankSortCode NVARCHAR(8) NULL,
        BankAccountNumber NVARCHAR(20) NULL,
        ContractStartDate DATE NULL,
        ContractEndDate DATE NULL,
        MinimumRoyaltyThreshold MONEY DEFAULT 25.00, -- Don't pay if under £25
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (ContactID) REFERENCES Contacts(ContactID)
    );

    PRINT 'Authors table created successfully';
END
ELSE
BEGIN
    PRINT 'Authors table already exists';
END
GO

-- =============================================
-- Book Categories/Genres
-- =============================================
PRINT 'Creating Book Categories table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookCategories')
BEGIN
    CREATE TABLE BookCategories (
        CategoryID INT IDENTITY(1,1) PRIMARY KEY,
        CategoryName NVARCHAR(50) NOT NULL UNIQUE,
        Description NVARCHAR(255) NULL,
        IsActive BIT DEFAULT 1
    );

    PRINT 'Book Categories table created successfully';
END
ELSE
BEGIN
    PRINT 'Book Categories table already exists';
END
GO

-- =============================================
-- Books/Publications
-- =============================================
PRINT 'Creating Books table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Books')
BEGIN
    CREATE TABLE Books (
        BookID INT IDENTITY(1,1) PRIMARY KEY,
        ISBN NVARCHAR(17) NOT NULL UNIQUE,
        Title NVARCHAR(255) NOT NULL,
        Subtitle NVARCHAR(255) NULL,
        AuthorID INT NOT NULL,
        CategoryID INT NULL,
        PublicationDate DATE NULL,
        PageCount INT NULL,
        Format NVARCHAR(20) NULL, -- Paperback, Hardcover, eBook, Audiobook
        PrintRun INT NULL,
        RetailPrice MONEY NULL,
        ProductionCosts MONEY DEFAULT 0,
        MarketingSpend MONEY DEFAULT 0,
        EditingCosts MONEY DEFAULT 0,
        CoverDesignCosts MONEY DEFAULT 0,
        Status NVARCHAR(20) DEFAULT 'Planning' CHECK (Status IN ('Planning', 'Production', 'Published', 'Out of Print')),
        ProjectAccountID INT NULL, -- Link to chart of accounts for project tracking
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID),
        FOREIGN KEY (CategoryID) REFERENCES BookCategories(CategoryID),
        FOREIGN KEY (ProjectAccountID) REFERENCES ChartOfAccounts(AccountID)
    );

    PRINT 'Books table created successfully';
END
ELSE
BEGIN
    PRINT 'Books table already exists';
END
GO

-- =============================================
-- Sales Channels
-- =============================================
PRINT 'Creating Sales Channels table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SalesChannels')
BEGIN
    CREATE TABLE SalesChannels (
        ChannelID INT IDENTITY(1,1) PRIMARY KEY,
        ChannelName NVARCHAR(50) NOT NULL UNIQUE,
        ChannelType NVARCHAR(20) NOT NULL, -- Online, Bookstore, Direct, Wholesale
        CommissionRate DECIMAL(5,4) DEFAULT 0, -- e.g., 0.3000 for 30%
        PaymentTerms NVARCHAR(50) NULL,
        ContactID INT NULL, -- Link to contact if applicable
        IsActive BIT DEFAULT 1,
        FOREIGN KEY (ContactID) REFERENCES Contacts(ContactID)
    );

    PRINT 'Sales Channels table created successfully';
END
ELSE
BEGIN
    PRINT 'Sales Channels table already exists';
END
GO

-- =============================================
-- Book Sales Tracking
-- =============================================
PRINT 'Creating Book Sales table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookSales')
BEGIN
    CREATE TABLE BookSales (
        SaleID INT IDENTITY(1,1) PRIMARY KEY,
        BookID INT NOT NULL,
        ChannelID INT NOT NULL,
        SaleDate DATE NOT NULL,
        QuantitySold INT NOT NULL,
        UnitPrice MONEY NOT NULL,
        GrossRevenue MONEY NOT NULL,
        ChannelCommission MONEY DEFAULT 0,
        NetRevenue MONEY NOT NULL,
        RoyaltyDue MONEY NOT NULL,
        VATAmount MONEY DEFAULT 0,
        TransactionID INT NULL, -- Link to accounting transaction
        ImportedFrom NVARCHAR(100) NULL, -- Source file/system
        ImportedDate DATETIME2 NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (BookID) REFERENCES Books(BookID),
        FOREIGN KEY (ChannelID) REFERENCES SalesChannels(ChannelID),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
    );

    PRINT 'Book Sales table created successfully';
END
ELSE
BEGIN
    PRINT 'Book Sales table already exists';
END
GO

-- =============================================
-- Royalty Calculations
-- =============================================
PRINT 'Creating Royalty Calculations table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoyaltyCalculations')
BEGIN
    CREATE TABLE RoyaltyCalculations (
        CalculationID INT IDENTITY(1,1) PRIMARY KEY,
        AuthorID INT NOT NULL,
        PeriodStart DATE NOT NULL,
        PeriodEnd DATE NOT NULL,
        TotalSales MONEY NOT NULL,
        TotalRoyalties MONEY NOT NULL,
        PreviousBalance MONEY DEFAULT 0,
        Adjustments MONEY DEFAULT 0,
        TotalDue MONEY NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Calculated' CHECK (Status IN ('Calculated', 'Approved', 'Paid', 'On Hold')),
        CalculatedDate DATETIME2 DEFAULT GETDATE(),
        CalculatedBy NVARCHAR(50) NOT NULL,
        ApprovedDate DATETIME2 NULL,
        ApprovedBy NVARCHAR(50) NULL,
        PaidDate DATETIME2 NULL,
        TransactionID INT NULL, -- Link to payment transaction
        FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
    );

    PRINT 'Royalty Calculations table created successfully';
END
ELSE
BEGIN
    PRINT 'Royalty Calculations table already exists';
END
GO

-- =============================================
-- Royalty Calculation Details
-- =============================================
PRINT 'Creating Royalty Calculation Details table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoyaltyCalculationDetails')
BEGIN
    CREATE TABLE RoyaltyCalculationDetails (
        DetailID INT IDENTITY(1,1) PRIMARY KEY,
        CalculationID INT NOT NULL,
        BookID INT NOT NULL,
        QuantitySold INT NOT NULL,
        NetRevenue MONEY NOT NULL,
        RoyaltyRate DECIMAL(5,4) NOT NULL,
        RoyaltyAmount MONEY NOT NULL,
        FOREIGN KEY (CalculationID) REFERENCES RoyaltyCalculations(CalculationID),
        FOREIGN KEY (BookID) REFERENCES Books(BookID)
    );

    PRINT 'Royalty Calculation Details table created successfully';
END
ELSE
BEGIN
    PRINT 'Royalty Calculation Details table already exists';
END
GO

-- =============================================
-- Production Costs Tracking
-- =============================================
PRINT 'Creating Production Costs table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductionCosts')
BEGIN
    CREATE TABLE ProductionCosts (
        CostID INT IDENTITY(1,1) PRIMARY KEY,
        BookID INT NOT NULL,
        CostType NVARCHAR(50) NOT NULL, -- Editing, Design, Printing, Marketing, etc.
        Supplier NVARCHAR(100) NULL,
        Description NVARCHAR(255) NOT NULL,
        Amount MONEY NOT NULL,
        CostDate DATE NOT NULL,
        InvoiceID INT NULL, -- Link to supplier invoice
        TransactionID INT NULL, -- Link to accounting transaction
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (BookID) REFERENCES Books(BookID),
        FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
    );

    PRINT 'Production Costs table created successfully';
END
ELSE
BEGIN
    PRINT 'Production Costs table already exists';
END
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating publishing performance indexes...';
GO

-- Books indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Books') AND name = 'IX_Books_Author')
    CREATE INDEX IX_Books_Author ON Books(AuthorID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Books') AND name = 'IX_Books_Category')
    CREATE INDEX IX_Books_Category ON Books(CategoryID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Books') AND name = 'IX_Books_Status')
    CREATE INDEX IX_Books_Status ON Books(Status);

-- Book Sales indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BookSales') AND name = 'IX_BookSales_Book')
    CREATE INDEX IX_BookSales_Book ON BookSales(BookID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BookSales') AND name = 'IX_BookSales_Channel')
    CREATE INDEX IX_BookSales_Channel ON BookSales(ChannelID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BookSales') AND name = 'IX_BookSales_Date')
    CREATE INDEX IX_BookSales_Date ON BookSales(SaleDate);

-- Royalty indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('RoyaltyCalculations') AND name = 'IX_RoyaltyCalculations_Author')
    CREATE INDEX IX_RoyaltyCalculations_Author ON RoyaltyCalculations(AuthorID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('RoyaltyCalculations') AND name = 'IX_RoyaltyCalculations_Period')
    CREATE INDEX IX_RoyaltyCalculations_Period ON RoyaltyCalculations(PeriodStart, PeriodEnd);

-- Production Costs indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('ProductionCosts') AND name = 'IX_ProductionCosts_Book')
    CREATE INDEX IX_ProductionCosts_Book ON ProductionCosts(BookID);

PRINT 'Publishing performance indexes created successfully';
GO

-- =============================================
-- Publishing Views (with vw_ prefix)
-- =============================================
PRINT 'Creating publishing views...';
GO

-- Book Profitability View
CREATE OR ALTER VIEW vw_BookProfitability AS
SELECT
    b.BookID,
    b.Title,
    CONCAT(c.FirstName, ' ', c.LastName) as AuthorName,
    b.RetailPrice,
    ISNULL(SUM(bs.NetRevenue), 0) as TotalRevenue,
    ISNULL(SUM(bs.RoyaltyDue), 0) as TotalRoyalties,
    ISNULL(SUM(pc.Amount), 0) as TotalProductionCosts,
    ISNULL(SUM(bs.NetRevenue), 0) - ISNULL(SUM(bs.RoyaltyDue), 0) - ISNULL(SUM(pc.Amount), 0) as NetProfit,
    COUNT(DISTINCT bs.SaleID) as TotalSales,
    ISNULL(SUM(bs.QuantitySold), 0) as TotalUnitsSold
FROM Books b
INNER JOIN Authors a ON b.AuthorID = a.AuthorID
INNER JOIN Contacts c ON a.ContactID = c.ContactID
LEFT JOIN BookSales bs ON b.BookID = bs.BookID
LEFT JOIN ProductionCosts pc ON b.BookID = pc.BookID
GROUP BY b.BookID, b.Title, c.FirstName, c.LastName, b.RetailPrice;
GO

-- Author Performance View
CREATE OR ALTER VIEW vw_AuthorPerformance AS
SELECT
    a.AuthorID,
    CONCAT(c.FirstName, ' ', c.LastName) as AuthorName,
    a.RoyaltyRate,
    COUNT(DISTINCT b.BookID) as TotalBooks,
    ISNULL(SUM(bs.NetRevenue), 0) as TotalRevenue,
    ISNULL(SUM(bs.RoyaltyDue), 0) as TotalRoyaltiesDue,
    ISNULL(SUM(CASE WHEN rc.Status = 'Paid' THEN rc.TotalDue ELSE 0 END), 0) as TotalRoyaltiesPaid,
    ISNULL(SUM(bs.QuantitySold), 0) as TotalUnitsSold
FROM Authors a
INNER JOIN Contacts c ON a.ContactID = c.ContactID
LEFT JOIN Books b ON a.AuthorID = b.AuthorID
LEFT JOIN BookSales bs ON b.BookID = bs.BookID
LEFT JOIN RoyaltyCalculations rc ON a.AuthorID = rc.AuthorID
GROUP BY a.AuthorID, c.FirstName, c.LastName, a.RoyaltyRate;
GO

PRINT 'Publishing views created successfully';
GO

PRINT '';
PRINT '=== Publishing Schema Deployment Complete ===';
PRINT 'Tables created/verified:';
PRINT '  - Authors: Author management with royalty rates';
PRINT '  - BookCategories: Book genre/category classifications';
PRINT '  - Books: Complete book catalog with costs tracking';
PRINT '  - SalesChannels: Sales channel management';
PRINT '  - BookSales: Book sales tracking with royalties';
PRINT '  - RoyaltyCalculations: Royalty calculation system';
PRINT '  - RoyaltyCalculationDetails: Detailed royalty breakdowns';
PRINT '  - ProductionCosts: Book production cost tracking';
PRINT '';
PRINT 'Views created:';
PRINT '  - vw_BookProfitability: Book profitability analysis';
PRINT '  - vw_AuthorPerformance: Author performance metrics';
PRINT '';
PRINT 'Publishing system ready for UK compliance and bank balance setup';
GO