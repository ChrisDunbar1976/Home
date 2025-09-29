-- Rhubarb Press Accounting System - Initial Data Setup
-- Chart of Accounts, VAT Rates, and Sample Data
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Setting up Initial Data for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- UK VAT Rates Setup
-- =============================================
PRINT 'Setting up UK VAT rates...';
GO

IF NOT EXISTS (SELECT * FROM VATRates WHERE VATCode = 'ZR')
BEGIN
    INSERT INTO VATRates (VATCode, Rate, Description, EffectiveFrom) VALUES
    ('ZR', 0.0000, 'Zero Rate (Books & Publications)', '2020-01-01'),
    ('ST', 0.2000, 'Standard Rate', '2011-01-04'),
    ('RR', 0.0500, 'Reduced Rate', '2020-01-01'),
    ('EX', 0.0000, 'Exempt', '2020-01-01');
    PRINT 'VAT rates created';
END
ELSE
BEGIN
    PRINT 'VAT rates already exist';
END
GO

-- =============================================
-- Chart of Accounts Setup for Publishing
-- =============================================
PRINT 'Setting up Chart of Accounts...';
GO

-- ASSETS
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '1001')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
    ('1000', 'Current Assets', 'Asset', 'Current Asset', NULL),
    ('1001', 'Bank Current Account', 'Asset', 'Current Asset', NULL),
    ('1200', 'Petty Cash', 'Asset', 'Current Asset', NULL),
    ('1300', 'Accounts Receivable', 'Asset', 'Current Asset', NULL),
    ('1310', 'Author Advances Recoverable', 'Asset', 'Current Asset', 'Royalties'),
    ('1400', 'Inventory - Finished Books', 'Asset', 'Current Asset', 'Production'),
    ('1410', 'Inventory - Work in Progress', 'Asset', 'Current Asset', 'Production'),
    ('1500', 'Prepayments', 'Asset', 'Current Asset', NULL),
    ('1600', 'VAT Receivable', 'Asset', 'Current Asset', NULL);
    PRINT 'Current assets created';
END
ELSE
BEGIN
    PRINT 'Current assets already exist';
END
GO

-- FIXED ASSETS
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '1700')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
    ('1700', 'Fixed Assets', 'Asset', 'Fixed Asset', NULL),
    ('1710', 'Computer Equipment', 'Asset', 'Fixed Asset', NULL),
    ('1720', 'Office Equipment', 'Asset', 'Fixed Asset', NULL),
    ('1730', 'Accumulated Depreciation', 'Asset', 'Fixed Asset', NULL);
    PRINT 'Fixed assets created';
END
ELSE
BEGIN
    PRINT 'Fixed assets already exist';
END
GO

-- LIABILITIES
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '2000')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
    ('2000', 'Current Liabilities', 'Liability', 'Current Liability', NULL),
    ('2100', 'Accounts Payable', 'Liability', 'Current Liability', NULL),
    ('2200', 'Accrued Expenses', 'Liability', 'Current Liability', NULL),
    ('2300', 'Author Royalties Payable', 'Liability', 'Current Liability', 'Royalties'),
    ('2400', 'VAT Payable', 'Liability', 'Current Liability', NULL),
    ('2500', 'Corporation Tax Payable', 'Liability', 'Current Liability', NULL),
    ('2600', 'PAYE/NI Payable', 'Liability', 'Current Liability', NULL);
    PRINT 'Liabilities created';
END
ELSE
BEGIN
    PRINT 'Liabilities already exist';
END
GO

-- EQUITY
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '3000')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
    ('3000', 'Equity', 'Equity', 'Share Capital', NULL),
    ('3100', 'Share Capital', 'Equity', 'Share Capital', NULL),
    ('3200', 'Retained Earnings', 'Equity', 'Retained Earnings', NULL),
    ('3300', 'Current Year Earnings', 'Equity', 'Current Year', NULL);
    PRINT 'Equity accounts created';
END
ELSE
BEGIN
    PRINT 'Equity accounts already exist';
END
GO

-- REVENUE
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '4000')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory, VATCode) VALUES
    ('4000', 'Sales Revenue', 'Revenue', 'Book Sales', NULL, 'ZR'),
    ('4100', 'Book Sales - Direct', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4110', 'Book Sales - Amazon', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4120', 'Book Sales - Bookstores', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4130', 'Book Sales - Wholesale', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4200', 'eBook Sales', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4300', 'Audiobook Sales', 'Revenue', 'Book Sales', 'Distribution', 'ZR'),
    ('4400', 'Licensing Revenue', 'Revenue', 'Other Revenue', NULL, 'ST'),
    ('4500', 'Other Revenue', 'Revenue', 'Other Revenue', NULL, 'ST');
    PRINT 'Revenue accounts created';
END
ELSE
BEGIN
    PRINT 'Revenue accounts already exist';
END
GO

-- EXPENSES
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '5000')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory, VATCode) VALUES
    ('5000', 'Cost of Goods Sold', 'Expense', 'Direct Costs', NULL, NULL),
    ('5100', 'Author Royalties', 'Expense', 'Direct Costs', 'Royalties', 'EX'),
    ('5200', 'Printing Costs', 'Expense', 'Direct Costs', 'Production', 'ST'),
    ('5300', 'Editing Costs', 'Expense', 'Direct Costs', 'Production', 'ST'),
    ('5400', 'Cover Design', 'Expense', 'Direct Costs', 'Production', 'ST'),
    ('5500', 'Proofreading', 'Expense', 'Direct Costs', 'Production', 'ST');
    PRINT 'Direct cost accounts created';
END
ELSE
BEGIN
    PRINT 'Direct cost accounts already exist';
END
GO

-- OPERATING EXPENSES
IF NOT EXISTS (SELECT * FROM ChartOfAccounts WHERE AccountCode = '6000')
BEGIN
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory, VATCode) VALUES
    ('6000', 'Operating Expenses', 'Expense', 'Operating Expense', NULL, NULL),
    ('6100', 'Marketing & Advertising', 'Expense', 'Operating Expense', 'Marketing', 'ST'),
    ('6110', 'Digital Marketing', 'Expense', 'Operating Expense', 'Marketing', 'ST'),
    ('6120', 'Print Advertising', 'Expense', 'Operating Expense', 'Marketing', 'ST'),
    ('6130', 'Book Launch Events', 'Expense', 'Operating Expense', 'Marketing', 'ST'),
    ('6200', 'Office Expenses', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6210', 'Rent', 'Expense', 'Operating Expense', NULL, 'EX'),
    ('6220', 'Utilities', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6230', 'Internet & Phone', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6300', 'Professional Services', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6310', 'Accounting Fees', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6320', 'Legal Fees', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6330', 'Bank Charges', 'Expense', 'Operating Expense', NULL, 'EX'),
    ('6400', 'Travel & Subsistence', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6500', 'Software & Subscriptions', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6600', 'Insurance', 'Expense', 'Operating Expense', NULL, 'ST'),
    ('6700', 'Depreciation', 'Expense', 'Operating Expense', NULL, 'EX');
    PRINT 'Operating expense accounts created';
END
ELSE
BEGIN
    PRINT 'Operating expense accounts already exist';
END
GO

-- =============================================
-- Sample Book Categories
-- =============================================
PRINT 'Setting up book categories...';
GO

IF NOT EXISTS (SELECT * FROM BookCategories WHERE CategoryName = 'Crime Fiction')
BEGIN
    INSERT INTO BookCategories (CategoryName, Description) VALUES
    ('Crime Fiction', 'Mystery, thriller, and detective novels'),
    ('Literary Fiction', 'Contemporary and classic literature'),
    ('Historical Fiction', 'Novels set in historical periods'),
    ('Non-Fiction', 'Biography, memoir, and factual works'),
    ('Poetry', 'Poetry collections and anthologies'),
    ('Young Adult', 'Fiction targeted at teenage readers'),
    ('Children''s Books', 'Books for children of all ages');
    PRINT 'Book categories created';
END
ELSE
BEGIN
    PRINT 'Book categories already exist';
END
GO

-- =============================================
-- Sample Sales Channels
-- =============================================
PRINT 'Setting up sales channels...';
GO

IF NOT EXISTS (SELECT * FROM SalesChannels WHERE ChannelName = 'Amazon UK')
BEGIN
    INSERT INTO SalesChannels (ChannelName, ChannelType, CommissionRate, PaymentTerms) VALUES
    ('Amazon UK', 'Online', 0.4000, '60 days'),
    ('Amazon US', 'Online', 0.4000, '60 days'),
    ('Waterstones', 'Bookstore', 0.4500, '90 days'),
    ('WHSmith', 'Bookstore', 0.4500, '90 days'),
    ('Gardners Books', 'Wholesale', 0.5500, '30 days'),
    ('Bertrams', 'Wholesale', 0.5500, '30 days'),
    ('Direct Sales', 'Direct', 0.0000, 'Immediate'),
    ('Book Fairs', 'Direct', 0.0000, 'Immediate'),
    ('Independent Bookstores', 'Bookstore', 0.4000, '60 days'),
    ('Kindle Direct Publishing', 'Online', 0.3000, '60 days');
    PRINT 'Sales channels created';
END
ELSE
BEGIN
    PRINT 'Sales channels already exist';
END
GO

-- =============================================
-- Sample Contact for Rhubarb Press
-- =============================================
PRINT 'Setting up sample contacts...';
GO

IF NOT EXISTS (SELECT * FROM Contacts WHERE CompanyName = 'Rhubarb Press Ltd')
BEGIN
    INSERT INTO Contacts (ContactType, CompanyName, FirstName, LastName, Email, Country, TaxStatus) VALUES
    ('Supplier', 'Rhubarb Press Ltd', 'Chris', 'Dunbar', 'chris@rhubarbpress.com', 'United Kingdom', 'Company');
    PRINT 'Rhubarb Press contact created';
END
ELSE
BEGIN
    PRINT 'Rhubarb Press contact already exists';
END
GO

-- =============================================
-- Sample Author Setup
-- =============================================
PRINT 'Setting up sample author...';
GO

IF NOT EXISTS (SELECT * FROM Contacts WHERE FirstName = 'Jane' AND LastName = 'Smith' AND ContactType = 'Author')
BEGIN
    -- Insert a sample contact for an author
    INSERT INTO Contacts (ContactType, FirstName, LastName, Email, Address1, City, PostCode, Country, TaxStatus) VALUES
    ('Author', 'Jane', 'Smith', 'jane.smith@email.com', '123 Author Street', 'London', 'SW1A 1AA', 'United Kingdom', 'Self-Employed');
    PRINT 'Sample author contact created';
END
ELSE
BEGIN
    PRINT 'Sample author contact already exists';
END
GO

-- Link the contact to an author record
IF NOT EXISTS (SELECT * FROM Authors a INNER JOIN Contacts c ON a.ContactID = c.ContactID WHERE c.FirstName = 'Jane' AND c.LastName = 'Smith')
BEGIN
    INSERT INTO Authors (ContactID, RoyaltyRate, PaymentTerms, MinimumRoyaltyThreshold)
    SELECT ContactID, 0.4000, 'Quarterly', 25.00
    FROM Contacts
    WHERE FirstName = 'Jane' AND LastName = 'Smith' AND ContactType = 'Author';
    PRINT 'Sample author record created';
END
ELSE
BEGIN
    PRINT 'Sample author record already exists';
END
GO

-- =============================================
-- Sample Book
-- =============================================
PRINT 'Setting up sample book...';
GO

IF NOT EXISTS (SELECT * FROM Books WHERE ISBN = '978-1-234567-89-0')
BEGIN
    INSERT INTO Books (ISBN, Title, AuthorID, CategoryID, PublicationDate, Format, RetailPrice, Status)
    SELECT
        '978-1-234567-89-0',
        'The Mystery of Rhubarb House',
        a.AuthorID,
        c.CategoryID,
        '2024-03-15',
        'Paperback',
        12.99,
        'Published'
    FROM Authors a
    INNER JOIN Contacts con ON a.ContactID = con.ContactID
    CROSS JOIN BookCategories c
    WHERE con.FirstName = 'Jane' AND con.LastName = 'Smith'
    AND c.CategoryName = 'Crime Fiction';
    PRINT 'Sample book created';
END
ELSE
BEGIN
    PRINT 'Sample book already exists';
END
GO

-- =============================================
-- Useful Views for Reporting
-- =============================================
PRINT 'Creating reporting views...';
GO

-- Trial Balance View
CREATE OR ALTER VIEW TrialBalance AS
SELECT
    ca.AccountCode,
    ca.AccountName,
    ca.AccountType,
    ISNULL(SUM(tl.DebitAmount), 0) as TotalDebits,
    ISNULL(SUM(tl.CreditAmount), 0) as TotalCredits,
    ISNULL(SUM(tl.DebitAmount), 0) - ISNULL(SUM(tl.CreditAmount), 0) as Balance
FROM ChartOfAccounts ca
LEFT JOIN TransactionLines tl ON ca.AccountID = tl.AccountID
LEFT JOIN Transactions t ON tl.TransactionID = t.TransactionID
WHERE ca.IsActive = 1
AND (t.Status IS NULL OR t.Status = 'Active')
GROUP BY ca.AccountID, ca.AccountCode, ca.AccountName, ca.AccountType;
GO

-- Profit & Loss View
CREATE OR ALTER VIEW ProfitAndLoss AS
SELECT
    ca.AccountType,
    ca.AccountCode,
    ca.AccountName,
    CASE
        WHEN ca.AccountType = 'Revenue' THEN ISNULL(SUM(tl.CreditAmount), 0) - ISNULL(SUM(tl.DebitAmount), 0)
        WHEN ca.AccountType = 'Expense' THEN ISNULL(SUM(tl.DebitAmount), 0) - ISNULL(SUM(tl.CreditAmount), 0)
        ELSE 0
    END as Amount
FROM ChartOfAccounts ca
LEFT JOIN TransactionLines tl ON ca.AccountID = tl.AccountID
LEFT JOIN Transactions t ON tl.TransactionID = t.TransactionID
WHERE ca.AccountType IN ('Revenue', 'Expense')
AND ca.IsActive = 1
AND (t.Status IS NULL OR t.Status = 'Active')
GROUP BY ca.AccountID, ca.AccountType, ca.AccountCode, ca.AccountName;
GO

-- Balance Sheet View
CREATE OR ALTER VIEW BalanceSheet AS
SELECT
    ca.AccountType,
    ca.AccountSubType,
    ca.AccountCode,
    ca.AccountName,
    CASE
        WHEN ca.AccountType IN ('Asset', 'Expense') THEN ISNULL(SUM(tl.DebitAmount), 0) - ISNULL(SUM(tl.CreditAmount), 0)
        WHEN ca.AccountType IN ('Liability', 'Equity', 'Revenue') THEN ISNULL(SUM(tl.CreditAmount), 0) - ISNULL(SUM(tl.DebitAmount), 0)
        ELSE 0
    END as Balance
FROM ChartOfAccounts ca
LEFT JOIN TransactionLines tl ON ca.AccountID = tl.AccountID
LEFT JOIN Transactions t ON tl.TransactionID = t.TransactionID
WHERE ca.AccountType IN ('Asset', 'Liability', 'Equity')
AND ca.IsActive = 1
AND (t.Status IS NULL OR t.Status = 'Active')
GROUP BY ca.AccountID, ca.AccountType, ca.AccountSubType, ca.AccountCode, ca.AccountName;
GO

PRINT '';
PRINT '=== Initial Data Setup Completed Successfully ===';
PRINT 'Data created:';
PRINT '  - VAT rates: UK VAT configuration';
PRINT '  - Chart of Accounts: Publishing-specific accounts';
PRINT '  - Book categories: Genre classifications';
PRINT '  - Sales channels: Distribution channels';
PRINT '  - Sample contacts: Rhubarb Press and sample author';
PRINT '  - Sample book: The Mystery of Rhubarb House';
PRINT '';
PRINT 'Views created:';
PRINT '  - TrialBalance: Trial balance report';
PRINT '  - ProfitAndLoss: P&L statement';
PRINT '  - BalanceSheet: Balance sheet report';
PRINT '';
PRINT 'System is ready for publishing company operations';
GO