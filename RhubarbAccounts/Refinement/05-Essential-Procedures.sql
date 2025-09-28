-- Rhubarb Press Accounting System - Essential Stored Procedures
-- Core Business Logic for Accounting Operations
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Create Journal Entry (Double-Entry Transaction)
-- =============================================
CREATE PROCEDURE sp_CreateJournalEntry
    @TransactionDate DATE,
    @Reference NVARCHAR(50),
    @Description NVARCHAR(255),
    @CreatedBy NVARCHAR(50),
    @JournalLines NVARCHAR(MAX) -- JSON format: [{"AccountCode":"1100","Debit":100,"Credit":0,"Description":"test"}]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    DECLARE @TransactionID INT;
    DECLARE @TotalDebits MONEY = 0;
    DECLARE @TotalCredits MONEY = 0;

    -- Parse JSON and calculate totals
    SELECT
        @TotalDebits = SUM(CAST(JSON_VALUE(value, '$.Debit') AS MONEY)),
        @TotalCredits = SUM(CAST(JSON_VALUE(value, '$.Credit') AS MONEY))
    FROM OPENJSON(@JournalLines);

    -- Validate double-entry rule
    IF @TotalDebits != @TotalCredits
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Debits must equal Credits in double-entry bookkeeping', 1;
        RETURN;
    END

    -- Create transaction header
    INSERT INTO Transactions (TransactionDate, Reference, Description, TotalAmount, TransactionType, CreatedBy)
    VALUES (@TransactionDate, @Reference, @Description, @TotalDebits, 'Journal', @CreatedBy);

    SET @TransactionID = SCOPE_IDENTITY();

    -- Create transaction lines
    INSERT INTO TransactionLines (TransactionID, AccountID, DebitAmount, CreditAmount, Description)
    SELECT
        @TransactionID,
        ca.AccountID,
        CAST(JSON_VALUE(value, '$.Debit') AS MONEY),
        CAST(JSON_VALUE(value, '$.Credit') AS MONEY),
        JSON_VALUE(value, '$.Description')
    FROM OPENJSON(@JournalLines) j
    INNER JOIN ChartOfAccounts ca ON ca.AccountCode = JSON_VALUE(j.value, '$.AccountCode');

    COMMIT TRANSACTION;

    SELECT @TransactionID as TransactionID, 'Journal Entry Created Successfully' as Message;
END;
GO

-- =============================================
-- Calculate Author Royalties for Period
-- =============================================
CREATE PROCEDURE sp_CalculateAuthorRoyalties
    @PeriodStart DATE,
    @PeriodEnd DATE,
    @AuthorID INT = NULL, -- NULL for all authors
    @CalculatedBy NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CalculationID INT;

    -- Loop through authors
    DECLARE author_cursor CURSOR FOR
    SELECT DISTINCT a.AuthorID, a.RoyaltyRate, a.MinimumRoyaltyThreshold
    FROM Authors a
    INNER JOIN Books b ON a.AuthorID = b.AuthorID
    INNER JOIN BookSales bs ON b.BookID = bs.BookID
    WHERE bs.SaleDate BETWEEN @PeriodStart AND @PeriodEnd
    AND (@AuthorID IS NULL OR a.AuthorID = @AuthorID)
    AND a.IsActive = 1;

    DECLARE @CurrentAuthorID INT, @RoyaltyRate DECIMAL(5,4), @MinThreshold MONEY;
    DECLARE @TotalSales MONEY, @TotalRoyalties MONEY;

    OPEN author_cursor;
    FETCH NEXT FROM author_cursor INTO @CurrentAuthorID, @RoyaltyRate, @MinThreshold;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calculate totals for this author
        SELECT
            @TotalSales = SUM(bs.NetRevenue),
            @TotalRoyalties = SUM(bs.RoyaltyDue)
        FROM BookSales bs
        INNER JOIN Books b ON bs.BookID = b.BookID
        WHERE b.AuthorID = @CurrentAuthorID
        AND bs.SaleDate BETWEEN @PeriodStart AND @PeriodEnd;

        -- Only create calculation if above minimum threshold
        IF @TotalRoyalties >= @MinThreshold
        BEGIN
            -- Create royalty calculation
            INSERT INTO RoyaltyCalculations (AuthorID, PeriodStart, PeriodEnd, TotalSales, TotalRoyalties, TotalDue, CalculatedBy)
            VALUES (@CurrentAuthorID, @PeriodStart, @PeriodEnd, @TotalSales, @TotalRoyalties, @TotalRoyalties, @CalculatedBy);

            SET @CalculationID = SCOPE_IDENTITY();

            -- Create calculation details
            INSERT INTO RoyaltyCalculationDetails (CalculationID, BookID, QuantitySold, NetRevenue, RoyaltyRate, RoyaltyAmount)
            SELECT
                @CalculationID,
                bs.BookID,
                SUM(bs.QuantitySold),
                SUM(bs.NetRevenue),
                @RoyaltyRate,
                SUM(bs.RoyaltyDue)
            FROM BookSales bs
            INNER JOIN Books b ON bs.BookID = b.BookID
            WHERE b.AuthorID = @CurrentAuthorID
            AND bs.SaleDate BETWEEN @PeriodStart AND @PeriodEnd
            GROUP BY bs.BookID;
        END

        FETCH NEXT FROM author_cursor INTO @CurrentAuthorID, @RoyaltyRate, @MinThreshold;
    END

    CLOSE author_cursor;
    DEALLOCATE author_cursor;

    SELECT 'Royalty calculations completed' as Message;
END;
GO

-- =============================================
-- Process Book Sales Import
-- =============================================
CREATE PROCEDURE sp_ProcessBookSales
    @BookID INT,
    @ChannelID INT,
    @SaleDate DATE,
    @QuantitySold INT,
    @UnitPrice MONEY,
    @ChannelCommission MONEY = 0,
    @ImportedFrom NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GrossRevenue MONEY = @QuantitySold * @UnitPrice;
    DECLARE @NetRevenue MONEY = @GrossRevenue - @ChannelCommission;
    DECLARE @RoyaltyRate DECIMAL(5,4);
    DECLARE @RoyaltyDue MONEY;

    -- Get royalty rate for this book's author
    SELECT @RoyaltyRate = a.RoyaltyRate
    FROM Books b
    INNER JOIN Authors a ON b.AuthorID = a.AuthorID
    WHERE b.BookID = @BookID;

    SET @RoyaltyDue = @NetRevenue * @RoyaltyRate;

    -- Insert book sale
    INSERT INTO BookSales (BookID, ChannelID, SaleDate, QuantitySold, UnitPrice, GrossRevenue, ChannelCommission, NetRevenue, RoyaltyDue, ImportedFrom, ImportedDate)
    VALUES (@BookID, @ChannelID, @SaleDate, @QuantitySold, @UnitPrice, @GrossRevenue, @ChannelCommission, @NetRevenue, @RoyaltyDue, @ImportedFrom, GETDATE());

    SELECT SCOPE_IDENTITY() as SaleID, 'Book sale recorded successfully' as Message;
END;
GO

-- =============================================
-- Create Customer Invoice
-- =============================================
CREATE PROCEDURE sp_CreateInvoice
    @ContactID INT,
    @InvoiceDate DATE,
    @DueDate DATE,
    @CreatedBy NVARCHAR(50),
    @InvoiceLines NVARCHAR(MAX) -- JSON format for invoice lines
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    DECLARE @InvoiceID INT;
    DECLARE @InvoiceNumber NVARCHAR(50);
    DECLARE @SubTotal MONEY = 0;
    DECLARE @VATAmount MONEY = 0;
    DECLARE @TotalAmount MONEY = 0;

    -- Generate invoice number
    SELECT @InvoiceNumber = 'INV' + FORMAT(GETDATE(), 'yyyyMM') + FORMAT(ISNULL(MAX(CAST(RIGHT(InvoiceNumber, 4) AS INT)), 0) + 1, '0000')
    FROM Invoices
    WHERE InvoiceNumber LIKE 'INV' + FORMAT(GETDATE(), 'yyyyMM') + '%';

    -- Calculate totals from JSON
    SELECT
        @SubTotal = SUM(CAST(JSON_VALUE(value, '$.Quantity') AS DECIMAL(10,2)) * CAST(JSON_VALUE(value, '$.UnitPrice') AS MONEY)),
        @VATAmount = SUM(CAST(JSON_VALUE(value, '$.VATAmount') AS MONEY))
    FROM OPENJSON(@InvoiceLines);

    SET @TotalAmount = @SubTotal + @VATAmount;

    -- Create invoice header
    INSERT INTO Invoices (InvoiceType, InvoiceNumber, ContactID, InvoiceDate, DueDate, SubTotal, VATAmount, TotalAmount, CreatedBy)
    VALUES ('Sales', @InvoiceNumber, @ContactID, @InvoiceDate, @DueDate, @SubTotal, @VATAmount, @TotalAmount, @CreatedBy);

    SET @InvoiceID = SCOPE_IDENTITY();

    -- Create invoice lines
    INSERT INTO InvoiceLines (InvoiceID, Description, Quantity, UnitPrice, LineTotal, VATRate, VATAmount, BookID)
    SELECT
        @InvoiceID,
        JSON_VALUE(value, '$.Description'),
        CAST(JSON_VALUE(value, '$.Quantity') AS DECIMAL(10,2)),
        CAST(JSON_VALUE(value, '$.UnitPrice') AS MONEY),
        CAST(JSON_VALUE(value, '$.Quantity') AS DECIMAL(10,2)) * CAST(JSON_VALUE(value, '$.UnitPrice') AS MONEY),
        CAST(JSON_VALUE(value, '$.VATRate') AS DECIMAL(5,4)),
        CAST(JSON_VALUE(value, '$.VATAmount') AS MONEY),
        CAST(JSON_VALUE(value, '$.BookID') AS INT)
    FROM OPENJSON(@InvoiceLines);

    COMMIT TRANSACTION;

    SELECT @InvoiceID as InvoiceID, @InvoiceNumber as InvoiceNumber, 'Invoice created successfully' as Message;
END;
GO

-- =============================================
-- Generate Trial Balance
-- =============================================
CREATE PROCEDURE sp_GenerateTrialBalance
    @AsOfDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
        SET @AsOfDate = GETDATE();

    SELECT
        ca.AccountCode,
        ca.AccountName,
        ca.AccountType,
        ca.AccountSubType,
        ISNULL(SUM(tl.DebitAmount), 0) as TotalDebits,
        ISNULL(SUM(tl.CreditAmount), 0) as TotalCredits,
        ISNULL(SUM(tl.DebitAmount), 0) - ISNULL(SUM(tl.CreditAmount), 0) as Balance
    FROM ChartOfAccounts ca
    LEFT JOIN TransactionLines tl ON ca.AccountID = tl.AccountID
    LEFT JOIN Transactions t ON tl.TransactionID = t.TransactionID
    WHERE ca.IsActive = 1
    AND (t.TransactionDate IS NULL OR t.TransactionDate <= @AsOfDate)
    AND (t.Status IS NULL OR t.Status = 'Active')
    GROUP BY ca.AccountID, ca.AccountCode, ca.AccountName, ca.AccountType, ca.AccountSubType
    ORDER BY ca.AccountCode;
END;
GO

-- =============================================
-- Book Profitability Report
-- =============================================
CREATE PROCEDURE sp_BookProfitabilityReport
    @BookID INT = NULL,
    @PeriodStart DATE = NULL,
    @PeriodEnd DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BookID,
        b.ISBN,
        b.Title,
        CONCAT(c.FirstName, ' ', c.LastName) as AuthorName,
        bc.CategoryName,
        b.RetailPrice,
        ISNULL(SUM(bs.NetRevenue), 0) as TotalRevenue,
        ISNULL(SUM(bs.RoyaltyDue), 0) as TotalRoyalties,
        ISNULL(SUM(pc.Amount), 0) as TotalProductionCosts,
        ISNULL(SUM(bs.NetRevenue), 0) - ISNULL(SUM(bs.RoyaltyDue), 0) - ISNULL(SUM(pc.Amount), 0) as NetProfit,
        ISNULL(SUM(bs.QuantitySold), 0) as TotalUnitsSold,
        COUNT(DISTINCT bs.SaleID) as TotalSales
    FROM Books b
    INNER JOIN Authors a ON b.AuthorID = a.AuthorID
    INNER JOIN Contacts c ON a.ContactID = c.ContactID
    LEFT JOIN BookCategories bc ON b.CategoryID = bc.CategoryID
    LEFT JOIN BookSales bs ON b.BookID = bs.BookID
        AND (@PeriodStart IS NULL OR bs.SaleDate >= @PeriodStart)
        AND (@PeriodEnd IS NULL OR bs.SaleDate <= @PeriodEnd)
    LEFT JOIN ProductionCosts pc ON b.BookID = pc.BookID
    WHERE (@BookID IS NULL OR b.BookID = @BookID)
    AND b.IsActive = 1
    GROUP BY b.BookID, b.ISBN, b.Title, c.FirstName, c.LastName, bc.CategoryName, b.RetailPrice
    ORDER BY NetProfit DESC;
END;
GO

-- =============================================
-- Dashboard Summary
-- =============================================
CREATE PROCEDURE sp_DashboardSummary
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Sales Summary
    SELECT
        'Sales Summary' as ReportSection,
        COUNT(DISTINCT bs.BookID) as BooksWithSales,
        SUM(bs.QuantitySold) as TotalUnitsSold,
        SUM(bs.GrossRevenue) as GrossRevenue,
        SUM(bs.NetRevenue) as NetRevenue,
        SUM(bs.RoyaltyDue) as TotalRoyaltiesDue
    FROM BookSales bs
    WHERE bs.SaleDate BETWEEN @PeriodStart AND @PeriodEnd

    UNION ALL

    -- Top Performing Books
    SELECT
        'Top Books' as ReportSection,
        NULL, NULL, NULL, NULL, NULL

    UNION ALL

    SELECT
        b.Title,
        NULL,
        SUM(bs.QuantitySold),
        SUM(bs.GrossRevenue),
        SUM(bs.NetRevenue),
        SUM(bs.RoyaltyDue)
    FROM BookSales bs
    INNER JOIN Books b ON bs.BookID = b.BookID
    WHERE bs.SaleDate BETWEEN @PeriodStart AND @PeriodEnd
    GROUP BY b.BookID, b.Title
    ORDER BY SUM(bs.NetRevenue) DESC;
END;
GO

PRINT 'Essential stored procedures created successfully for Rhubarb Press accounting system';
PRINT 'Created procedures: sp_CreateJournalEntry, sp_CalculateAuthorRoyalties, sp_ProcessBookSales, sp_CreateInvoice, sp_GenerateTrialBalance, sp_BookProfitabilityReport, sp_DashboardSummary';
GO