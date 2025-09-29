-- Rhubarb Press Accounting System - Publishing Views Rename
-- Updates view names to use vw_ prefix convention
-- From: 02-Publishing-Schema.sql (Views section only)
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Drop old views if they exist (without vw_ prefix)
-- =============================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'BookProfitability')
    DROP VIEW BookProfitability;

IF EXISTS (SELECT * FROM sys.views WHERE name = 'AuthorPerformance')
    DROP VIEW AuthorPerformance;

PRINT 'Dropped old publishing views (if they existed)';
GO

-- =============================================
-- Create renamed views with vw_ prefix
-- =============================================

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

PRINT 'Publishing views renamed successfully with vw_ prefix';
PRINT '';
PRINT 'Updated view names:';
PRINT '  - vw_BookProfitability: Book profitability analysis with revenue, costs, and royalties';
PRINT '  - vw_AuthorPerformance: Author performance metrics and royalty summaries';
PRINT '';
PRINT 'Usage examples:';
PRINT '  SELECT * FROM vw_BookProfitability ORDER BY NetProfit DESC;';
PRINT '  SELECT * FROM vw_AuthorPerformance ORDER BY TotalRevenue DESC;';
GO