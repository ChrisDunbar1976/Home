-- Rhubarb Press Accounting System - Test Transaction Data
-- Generates realistic test transactions across all transaction groups
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating Test Transaction Data for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- Check if bank balance is initialized
-- =============================================
DECLARE @BankBalanceExists INT;
SELECT @BankBalanceExists = COUNT(*)
FROM BankBalance bb
INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
WHERE coa.AccountCode = '1001' AND bb.IsActive = 1;

IF @BankBalanceExists = 0
BEGIN
    PRINT 'Initializing bank balance with opening balance of £10,000.00...';
    EXEC sp_InitializeBankBalance '1001', 10000.00, '2025-09-01';
    PRINT 'Bank balance initialized';
    PRINT '';
END
ELSE
BEGIN
    PRINT 'Bank balance already initialized';
    PRINT '';
END
GO

-- =============================================
-- Generate Test Transactions
-- =============================================
PRINT 'Generating test transactions...';
PRINT 'This will create approximately 60 days of realistic publishing transactions';
PRINT '';
GO

-- September 2025 Transactions
-- Week 1: Initial activity
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-02', @Description = 'Book Design Software Subscription', @TransactionGroupID = 3, @AmountOut = 89.99, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-03', @Description = 'Amazon Sales - August Royalties', @TransactionGroupID = 5, @AmountIn = 1250.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-04', @Description = 'Printing Services - First Run', @TransactionGroupID = 7, @AmountOut = 850.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-05', @Description = 'Google Ads Campaign', @TransactionGroupID = 2, @AmountOut = 200.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-06', @Description = 'Office Supplies - Stationery', @TransactionGroupID = 1, @AmountOut = 45.50, @CreatedBy = 'Test Data';

-- Week 2: Marketing push
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-09', @Description = 'Facebook Marketing Campaign', @TransactionGroupID = 2, @AmountOut = 175.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-10', @Description = 'Direct Sales - Book Fair', @TransactionGroupID = 5, @AmountIn = 340.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-11', @Description = 'Industry Conference Ticket', @TransactionGroupID = 4, @AmountOut = 295.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-12', @Description = 'Book Cover Design Service', @TransactionGroupID = 7, @AmountOut = 450.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-13', @Description = 'Author Royalty Payment - Q2', @TransactionGroupID = 9, @AmountOut = 680.00, @CreatedBy = 'Test Data';

-- Week 3: Production costs
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-16', @Description = 'ISBN Purchase - 10 Numbers', @TransactionGroupID = 3, @AmountOut = 89.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-17', @Description = 'Proofreading Services', @TransactionGroupID = 7, @AmountOut = 325.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-18', @Description = 'Waterstones - Bulk Order', @TransactionGroupID = 5, @AmountIn = 890.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-19', @Description = 'Courier Services - Distribution', @TransactionGroupID = 8, @AmountOut = 125.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-20', @Description = 'Social Media Marketing', @TransactionGroupID = 2, @AmountOut = 150.00, @CreatedBy = 'Test Data';

-- Week 4: Revenue and expenses
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-21', @Description = 'Book Design Software', @TransactionGroupID = 3, @AmountOut = 89.99, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-22', @BankDate = '2025-09-23', @Description = 'Office Supplies', @TransactionGroupID = 1, @AmountOut = 75.50, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-23', @BankDate = '2025-09-24', @Description = 'Book Sales Revenue', @TransactionGroupID = 5, @AmountIn = 450.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-24', @Description = 'Industry Research Subscription', @TransactionGroupID = 4, @AmountOut = 125.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-25', @Description = 'Email Marketing Platform', @TransactionGroupID = 2, @AmountOut = 89.00, @CreatedBy = 'Test Data';

-- Week 5: End of month
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-26', @Description = 'Author Podcast Sponsorship', @TransactionGroupID = 2, @AmountOut = 450.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-27', @Description = 'Bulk Paper Stock Replenishment', @TransactionGroupID = 7, @AmountOut = 612.75, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-28', @Description = 'Regional Courier Distribution', @TransactionGroupID = 8, @AmountOut = 248.40, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-29', @Description = 'Direct Fair Sales Receipts', @TransactionGroupID = 5, @AmountIn = 1320.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-09-30', @Description = 'Audiobook Licensing Advance', @TransactionGroupID = 5, @AmountIn = 980.00, @CreatedBy = 'Test Data';

-- October 2025 Transactions
-- Week 1
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-01', @Description = 'Website Hosting Annual Renewal', @TransactionGroupID = 1, @AmountOut = 145.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-02', @Description = 'Kindle Direct Publishing Revenue', @TransactionGroupID = 5, @AmountIn = 560.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-03', @Description = 'Book Launch Event Catering', @TransactionGroupID = 2, @AmountOut = 380.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-04', @Description = 'Professional Editing Service', @TransactionGroupID = 7, @AmountOut = 725.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-05', @Description = 'BookTok Influencer Campaign', @TransactionGroupID = 2, @AmountOut = 300.00, @CreatedBy = 'Test Data';

-- Week 2
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-08', @Description = 'Independent Bookstore Sales', @TransactionGroupID = 5, @AmountIn = 675.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-09', @Description = 'Accounting Software Subscription', @TransactionGroupID = 1, @AmountOut = 49.99, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-10', @Description = 'Print-on-Demand Services', @TransactionGroupID = 7, @AmountOut = 420.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-11', @Description = 'Market Research Report Purchase', @TransactionGroupID = 4, @AmountOut = 199.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-12', @Description = 'WHSmith Bulk Order Payment', @TransactionGroupID = 5, @AmountIn = 1150.00, @CreatedBy = 'Test Data';

-- Week 3
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-15', @Description = 'Shipping Materials & Packaging', @TransactionGroupID = 8, @AmountOut = 180.50, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-16', @Description = 'Author Advance Payment', @TransactionGroupID = 9, @AmountOut = 1500.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-17', @Description = 'Magazine Advertisement', @TransactionGroupID = 2, @AmountOut = 425.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-18', @Description = 'Direct Website Sales', @TransactionGroupID = 5, @AmountIn = 890.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-19', @Description = 'Legal Review - Contract', @TransactionGroupID = 1, @AmountOut = 350.00, @CreatedBy = 'Test Data';

-- Week 4
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-22', @Description = 'Book Fair Table Rental', @TransactionGroupID = 2, @AmountOut = 195.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-23', @Description = 'Audiobook Production Services', @TransactionGroupID = 7, @AmountOut = 890.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-24', @Description = 'Amazon Sales - September', @TransactionGroupID = 5, @AmountIn = 1680.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-25', @Description = 'Courier Premium Service', @TransactionGroupID = 8, @AmountOut = 145.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-26', @Description = 'Industry Newsletter Sponsorship', @TransactionGroupID = 2, @AmountOut = 250.00, @CreatedBy = 'Test Data';

-- Week 5: End of month
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-29', @Description = 'Author Royalty Payment - Q3', @TransactionGroupID = 9, @AmountOut = 845.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-30', @Description = 'Bulk Printing - New Title', @TransactionGroupID = 7, @AmountOut = 1250.00, @CreatedBy = 'Test Data';
EXEC sp_ImportBankTransaction @ActualDate = '2025-10-31', @Description = 'Waterstones October Settlement', @TransactionGroupID = 5, @AmountIn = 2150.00, @CreatedBy = 'Test Data';

PRINT '';
PRINT '=== Test Transaction Data Created Successfully ===';
PRINT '';
GO

-- =============================================
-- Display Summary
-- =============================================
PRINT 'Transaction Summary by Group:';
SELECT
    tg.GroupName,
    COUNT(*) as TransactionCount,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as TotalExpenses,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) as TotalRevenue
FROM Transactions t
INNER JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE t.CreatedBy = 'Test Data'
GROUP BY tg.GroupName
ORDER BY tg.GroupName;
GO

PRINT '';
PRINT 'Current Bank Balance:';
SELECT * FROM vw_CurrentBankBalances;
GO

PRINT '';
PRINT 'Recent Transactions (Last 10):';
SELECT TOP 10
    ActualDate,
    Item,
    TransactionGroup,
    [In],
    [Out],
    Balance
FROM vw_BankRunningBalance
ORDER BY ActualDate DESC;
GO

PRINT '';
PRINT '=== Test Data Generation Complete ===';
PRINT 'Run this query to view all transactions:';
PRINT '  SELECT * FROM vw_BankRunningBalance ORDER BY ActualDate;';
PRINT '';
PRINT 'Run this query to view summary by group:';
PRINT '  SELECT * FROM vw_TransactionSummaryByGroup ORDER BY TotalExpenses DESC;';
GO
