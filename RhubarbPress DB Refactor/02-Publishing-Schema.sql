-- Rhubarb Press Accounting System - Publishing-Specific Tables
-- Author Management, Book Tracking, and Royalty Systems
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating Publishing-Specific Schema for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

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
    PRINT 'Authors table created';
END
ELSE
BEGIN
    PRINT 'Authors table already exists';
END
GO

-- =============================================
-- Book Categories/Genres
-- =============================================
PRINT 'Creating BookCategories table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookCategories')
BEGIN
    CREATE TABLE BookCategories (
        CategoryID INT IDENTITY(1,1) PRIMARY KEY,
        CategoryName NVARCHAR(50) NOT NULL UNIQUE,
        Description NVARCHAR(255) NULL,
        IsActive BIT DEFAULT 1
    );
    PRINT 'BookCategories table created';
END
ELSE
BEGIN
    PRINT 'BookCategories table already exists';
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
    PRINT 'Books table created';
END
ELSE
BEGIN
    PRINT 'Books table already exists';
END
GO

-- =============================================
-- Sales Channels
-- =============================================
PRINT 'Creating SalesChannels table...';
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
    PRINT 'SalesChannels table created';
END
ELSE
BEGIN
    PRINT 'SalesChannels table already exists';
END
GO

-- =============================================
-- Book Sales Tracking
-- =============================================
PRINT 'Creating BookSales table...';
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
    PRINT 'BookSales table created';
END
ELSE
BEGIN
    PRINT 'BookSales table already exists';
END
GO

-- =============================================
-- Royalty Calculations
-- =============================================
PRINT 'Creating RoyaltyCalculations table...';
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
    PRINT 'RoyaltyCalculations table created';
END
ELSE
BEGIN
    PRINT 'RoyaltyCalculations table already exists';
END
GO

-- =============================================
-- Royalty Calculation Details
-- =============================================
PRINT 'Creating RoyaltyCalculationDetails table...';
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
    PRINT 'RoyaltyCalculationDetails table created';
END
ELSE
BEGIN
    PRINT 'RoyaltyCalculationDetails table already exists';
END
GO

-- =============================================
-- Production Costs Tracking
-- =============================================
PRINT 'Creating ProductionCosts table...';
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
    PRINT 'ProductionCosts table created';
END
ELSE
BEGIN
    PRINT 'ProductionCosts table already exists';
END
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating indexes for performance...';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Books_Author' AND object_id = OBJECT_ID('Books'))
BEGIN
    CREATE INDEX IX_Books_Author ON Books(AuthorID);
    PRINT 'Created index IX_Books_Author';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Books_Category' AND object_id = OBJECT_ID('Books'))
BEGIN
    CREATE INDEX IX_Books_Category ON Books(CategoryID);
    PRINT 'Created index IX_Books_Category';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Books_Status' AND object_id = OBJECT_ID('Books'))
BEGIN
    CREATE INDEX IX_Books_Status ON Books(Status);
    PRINT 'Created index IX_Books_Status';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookSales_Book' AND object_id = OBJECT_ID('BookSales'))
BEGIN
    CREATE INDEX IX_BookSales_Book ON BookSales(BookID);
    PRINT 'Created index IX_BookSales_Book';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookSales_Channel' AND object_id = OBJECT_ID('BookSales'))
BEGIN
    CREATE INDEX IX_BookSales_Channel ON BookSales(ChannelID);
    PRINT 'Created index IX_BookSales_Channel';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookSales_Date' AND object_id = OBJECT_ID('BookSales'))
BEGIN
    CREATE INDEX IX_BookSales_Date ON BookSales(SaleDate);
    PRINT 'Created index IX_BookSales_Date';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RoyaltyCalculations_Author' AND object_id = OBJECT_ID('RoyaltyCalculations'))
BEGIN
    CREATE INDEX IX_RoyaltyCalculations_Author ON RoyaltyCalculations(AuthorID);
    PRINT 'Created index IX_RoyaltyCalculations_Author';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RoyaltyCalculations_Period' AND object_id = OBJECT_ID('RoyaltyCalculations'))
BEGIN
    CREATE INDEX IX_RoyaltyCalculations_Period ON RoyaltyCalculations(PeriodStart, PeriodEnd);
    PRINT 'Created index IX_RoyaltyCalculations_Period';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProductionCosts_Book' AND object_id = OBJECT_ID('ProductionCosts'))
BEGIN
    CREATE INDEX IX_ProductionCosts_Book ON ProductionCosts(BookID);
    PRINT 'Created index IX_ProductionCosts_Book';
END
GO

-- =============================================
-- Views for Reporting
-- =============================================
PRINT 'Creating reporting views...';
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

PRINT '';
PRINT '=== Publishing-Specific Schema Created Successfully ===';
PRINT 'Tables created:';
PRINT '  - Authors: Author contracts and payment details';
PRINT '  - BookCategories: Book genre classifications';
PRINT '  - Books: Book catalog with production tracking';
PRINT '  - SalesChannels: Sales channel configurations';
PRINT '  - BookSales: Sales transaction tracking';
PRINT '  - RoyaltyCalculations: Royalty period calculations';
PRINT '  - RoyaltyCalculationDetails: Detailed royalty breakdowns';
PRINT '  - ProductionCosts: Book production cost tracking';
PRINT '';
PRINT 'Views created:';
PRINT '  - vw_BookProfitability: Book profitability analysis';
PRINT '  - vw_AuthorPerformance: Author performance metrics';
PRINT '';
PRINT 'Publishing schema is ready for operations';
GO
