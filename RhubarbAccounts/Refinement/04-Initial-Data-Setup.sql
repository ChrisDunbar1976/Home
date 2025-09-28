-- Rhubarb Press Accounting System - Initial Data Setup
-- Chart of Accounts, VAT Rates, and Sample Data
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- UK VAT Rates Setup
-- =============================================
INSERT INTO VATRates (VATCode, Rate, Description, EffectiveFrom) VALUES
('ZR', 0.0000, 'Zero Rate (Books & Publications)', '2020-01-01'),
('ST', 0.2000, 'Standard Rate', '2011-01-04'),
('RR', 0.0500, 'Reduced Rate', '2020-01-01'),
('EX', 0.0000, 'Exempt', '2020-01-01');

-- =============================================
-- Chart of Accounts Setup for Publishing
-- =============================================

-- ASSETS
INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
('1000', 'Current Assets', 'Asset', 'Current Asset', NULL),
('1100', 'Bank Current Account', 'Asset', 'Current Asset', NULL),
('1200', 'Petty Cash', 'Asset', 'Current Asset', NULL),
('1300', 'Accounts Receivable', 'Asset', 'Current Asset', NULL),
('1310', 'Author Advances Recoverable', 'Asset', 'Current Asset', 'Royalties'),
('1400', 'Inventory - Finished Books', 'Asset', 'Current Asset', 'Production'),
('1410', 'Inventory - Work in Progress', 'Asset', 'Current Asset', 'Production'),
('1500', 'Prepayments', 'Asset', 'Current Asset', NULL),
('1600', 'VAT Receivable', 'Asset', 'Current Asset', NULL),

-- FIXED ASSETS
('1700', 'Fixed Assets', 'Asset', 'Fixed Asset', NULL),
('1710', 'Computer Equipment', 'Asset', 'Fixed Asset', NULL),
('1720', 'Office Equipment', 'Asset', 'Fixed Asset', NULL),
('1730', 'Accumulated Depreciation', 'Asset', 'Fixed Asset', NULL);

-- LIABILITIES
INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
('2000', 'Current Liabilities', 'Liability', 'Current Liability', NULL),
('2100', 'Accounts Payable', 'Liability', 'Current Liability', NULL),
('2200', 'Accrued Expenses', 'Liability', 'Current Liability', NULL),
('2300', 'Author Royalties Payable', 'Liability', 'Current Liability', 'Royalties'),
('2400', 'VAT Payable', 'Liability', 'Current Liability', NULL),
('2500', 'Corporation Tax Payable', 'Liability', 'Current Liability', NULL),
('2600', 'PAYE/NI Payable', 'Liability', 'Current Liability', NULL);

-- EQUITY
INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory) VALUES
('3000', 'Equity', 'Equity', 'Share Capital', NULL),
('3100', 'Share Capital', 'Equity', 'Share Capital', NULL),
('3200', 'Retained Earnings', 'Equity', 'Retained Earnings', NULL),
('3300', 'Current Year Earnings', 'Equity', 'Current Year', NULL);

-- REVENUE
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

-- EXPENSES
INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType, PublishingCategory, VATCode) VALUES
('5000', 'Cost of Goods Sold', 'Expense', 'Direct Costs', NULL, NULL),
('5100', 'Author Royalties', 'Expense', 'Direct Costs', 'Royalties', 'EX'),
('5200', 'Printing Costs', 'Expense', 'Direct Costs', 'Production', 'ST'),
('5300', 'Editing Costs', 'Expense', 'Direct Costs', 'Production', 'ST'),
('5400', 'Cover Design', 'Expense', 'Direct Costs', 'Production', 'ST'),
('5500', 'Proofreading', 'Expense', 'Direct Costs', 'Production', 'ST'),

-- OPERATING EXPENSES
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

-- =============================================
-- Sample Book Categories
-- =============================================
INSERT INTO BookCategories (CategoryName, Description) VALUES
('Crime Fiction', 'Mystery, thriller, and detective novels'),
('Literary Fiction', 'Contemporary and classic literature'),
('Historical Fiction', 'Novels set in historical periods'),
('Non-Fiction', 'Biography, memoir, and factual works'),
('Poetry', 'Poetry collections and anthologies'),
('Young Adult', 'Fiction targeted at teenage readers'),
('Children''s Books', 'Books for children of all ages');

-- =============================================
-- Sample Sales Channels
-- =============================================
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

-- =============================================
-- Sample Contact for Rhubarb Press
-- =============================================
INSERT INTO Contacts (ContactType, CompanyName, FirstName, LastName, Email, Country, TaxStatus) VALUES
('Supplier', 'Rhubarb Press Ltd', 'Chris', 'Dunbar', 'chris@rhubarbpress.com', 'United Kingdom', 'Company');

-- =============================================
-- Sample Author Setup
-- =============================================
-- Insert a sample contact for an author
INSERT INTO Contacts (ContactType, FirstName, LastName, Email, Address1, City, PostCode, Country, TaxStatus) VALUES
('Author', 'Jane', 'Smith', 'jane.smith@email.com', '123 Author Street', 'London', 'SW1A 1AA', 'United Kingdom', 'Self-Employed');

-- Link the contact to an author record
INSERT INTO Authors (ContactID, RoyaltyRate, PaymentTerms, MinimumRoyaltyThreshold)
SELECT ContactID, 0.4000, 'Quarterly', 25.00
FROM Contacts
WHERE FirstName = 'Jane' AND LastName = 'Smith' AND ContactType = 'Author';

-- =============================================
-- Sample Book
-- =============================================
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

-- =============================================
-- Useful Views for Reporting
-- =============================================

-- Trial Balance View
CREATE VIEW TrialBalance AS
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

-- Profit & Loss View
CREATE VIEW ProfitAndLoss AS
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

-- Balance Sheet View
CREATE VIEW BalanceSheet AS
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

PRINT 'Initial data setup completed successfully for Rhubarb Press';
PRINT 'Chart of Accounts created with ' + CAST(@@ROWCOUNT as VARCHAR(10)) + ' accounts';
PRINT 'Sample data includes VAT rates, sales channels, and a sample author/book';
PRINT 'Views created: TrialBalance, ProfitAndLoss, BalanceSheet';