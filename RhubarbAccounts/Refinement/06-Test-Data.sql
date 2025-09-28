-- Rhubarb Press Accounting System - Comprehensive Test Data
-- Realistic publishing company transactions including social media
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Additional Contacts (Authors, Suppliers, Services)
-- =============================================
INSERT INTO Contacts (ContactType, FirstName, LastName, Email, Address1, City, PostCode, Country, TaxStatus) VALUES
('Author', 'Marcus', 'Thompson', 'marcus.thompson@email.com', '45 Writer Road', 'Edinburgh', 'EH1 2AB', 'United Kingdom', 'Self-Employed'),
('Author', 'Sarah', 'Williams', 'sarah.williams@email.com', '12 Novel Street', 'Bath', 'BA1 3CD', 'United Kingdom', 'Self-Employed'),
('Supplier', 'PrintCorp Ltd', NULL, 'orders@printcorp.co.uk', '67 Industrial Estate', 'Birmingham', 'B12 4EF', 'United Kingdom', 'Company'),
('Supplier', 'Cover Design Studio', NULL, 'hello@coverdesign.co.uk', '23 Creative Quarter', 'Bristol', 'BS1 5GH', 'United Kingdom', 'Company'),
('Supplier', 'ProofRead Services', NULL, 'info@proofread.co.uk', '89 Grammar Lane', 'Cambridge', 'CB2 6IJ', 'United Kingdom', 'Company'),
('Supplier', 'Twitter Inc', NULL, 'billing@twitter.com', '1355 Market Street', 'San Francisco', 'CA 94103', 'United States', 'Company'),
('Supplier', 'Facebook Ireland Ltd', NULL, 'billing@facebook.com', '4 Grand Canal Square', 'Dublin', 'D02 X525', 'Ireland', 'Company'),
('Supplier', 'Amazon Advertising', NULL, 'billing@amazon.co.uk', '1 Principal Place', 'London', 'EC2A 2FA', 'United Kingdom', 'Company'),
('Supplier', 'Mailchimp', NULL, 'billing@mailchimp.com', '675 Ponce de Leon Ave', 'Atlanta', 'GA 30308', 'United States', 'Company'),
('Customer', 'Blackwells Books', NULL, 'orders@blackwells.co.uk', '48-51 Broad Street', 'Oxford', 'OX1 3BQ', 'United Kingdom', 'Company');
GO

-- =============================================
-- Additional Authors
-- =============================================
INSERT INTO Authors (ContactID, RoyaltyRate, PaymentTerms, MinimumRoyaltyThreshold)
SELECT ContactID, 0.3500, 'Quarterly', 50.00 FROM Contacts WHERE FirstName = 'Marcus' AND LastName = 'Thompson' AND ContactType = 'Author'
UNION ALL
SELECT ContactID, 0.4500, 'Quarterly', 25.00 FROM Contacts WHERE FirstName = 'Sarah' AND LastName = 'Williams' AND ContactType = 'Author';
GO

-- =============================================
-- Additional Books
-- =============================================
INSERT INTO Books (ISBN, Title, AuthorID, CategoryID, PublicationDate, Format, RetailPrice, Status)
SELECT
    '978-1-234567-90-6',
    'The Edinburgh Conspiracy',
    a.AuthorID,
    c.CategoryID,
    '2024-01-20',
    'Paperback',
    14.99,
    'Published'
FROM Authors a
INNER JOIN Contacts con ON a.ContactID = con.ContactID
CROSS JOIN BookCategories c
WHERE con.FirstName = 'Marcus' AND con.LastName = 'Thompson'
AND c.CategoryName = 'Crime Fiction'

UNION ALL

SELECT
    '978-1-234567-91-3',
    'Literary Reflections',
    a.AuthorID,
    c.CategoryID,
    '2024-02-15',
    'Hardcover',
    19.99,
    'Published'
FROM Authors a
INNER JOIN Contacts con ON a.ContactID = con.ContactID
CROSS JOIN BookCategories c
WHERE con.FirstName = 'Sarah' AND con.LastName = 'Williams'
AND c.CategoryName = 'Literary Fiction'

UNION ALL

SELECT
    '978-1-234567-92-0',
    'Digital Marketing for Authors',
    a.AuthorID,
    c.CategoryID,
    '2024-06-01',
    'eBook',
    9.99,
    'Published'
FROM Authors a
INNER JOIN Contacts con ON a.ContactID = con.ContactID
CROSS JOIN BookCategories c
WHERE con.FirstName = 'Jane' AND con.LastName = 'Smith'
AND c.CategoryName = 'Non-Fiction';
GO

-- =============================================
-- Realistic Book Sales Data
-- =============================================
-- Mystery of Rhubarb House sales
EXEC sp_ProcessBookSales 1, 2, '2024-03-20', 25, 12.99, 3.25, 'Amazon Sales Report'
EXEC sp_ProcessBookSales 1, 3, '2024-03-22', 8, 12.99, 3.64, 'Waterstones'
EXEC sp_ProcessBookSales 1, 7, '2024-03-25', 5, 12.99, 0, 'Direct Sales'
EXEC sp_ProcessBookSales 1, 2, '2024-04-15', 30, 12.99, 3.90, 'Amazon Sales Report'
EXEC sp_ProcessBookSales 1, 10, '2024-04-18', 50, 9.99, 2.25, 'Kindle Sales'

-- Edinburgh Conspiracy sales
EXEC sp_ProcessBookSales 2, 2, '2024-02-01', 20, 14.99, 4.50, 'Amazon Sales Report'
EXEC sp_ProcessBookSales 2, 3, '2024-02-05', 12, 14.99, 6.75, 'Waterstones'
EXEC sp_ProcessBookSales 2, 9, '2024-02-10', 6, 14.99, 5.99, 'Independent Bookstore'

-- Literary Reflections sales
EXEC sp_ProcessBookSales 3, 2, '2024-03-01', 15, 19.99, 8.00, 'Amazon Sales Report'
EXEC sp_ProcessBookSales 3, 3, '2024-03-05', 10, 19.99, 8.99, 'Waterstones'
EXEC sp_ProcessBookSales 3, 7, '2024-03-08', 3, 19.99, 0, 'Direct Sales'

-- Digital Marketing for Authors sales
EXEC sp_ProcessBookSales 4, 10, '2024-06-05', 75, 9.99, 2.25, 'Kindle Sales'
EXEC sp_ProcessBookSales 4, 2, '2024-06-10', 25, 9.99, 2.50, 'Amazon eBook'
GO

-- =============================================
-- Production Costs
-- =============================================
INSERT INTO ProductionCosts (BookID, CostType, Supplier, Description, Amount, CostDate) VALUES
(1, 'Editing', 'Professional Editor', 'Copy editing and proofreading', 800.00, '2024-01-15'),
(1, 'Cover Design', 'Cover Design Studio', 'Front and back cover design', 350.00, '2024-01-20'),
(1, 'Printing', 'PrintCorp Ltd', 'Initial print run 500 copies', 1200.00, '2024-02-01'),

(2, 'Editing', 'Professional Editor', 'Developmental and copy editing', 1200.00, '2023-11-15'),
(2, 'Cover Design', 'Cover Design Studio', 'Hardcover design with dust jacket', 450.00, '2023-12-01'),
(2, 'Printing', 'PrintCorp Ltd', 'Print run 300 hardcovers', 1800.00, '2024-01-10'),

(3, 'Editing', 'ProofRead Services', 'Professional editing', 900.00, '2024-01-05'),
(3, 'Cover Design', 'Cover Design Studio', 'Hardcover design', 400.00, '2024-01-15'),
(3, 'Printing', 'PrintCorp Ltd', 'Print run 200 hardcovers', 1400.00, '2024-02-01'),

(4, 'Editing', 'Professional Editor', 'Copy editing for digital', 400.00, '2024-04-15'),
(4, 'Cover Design', 'Cover Design Studio', 'eBook cover design', 200.00, '2024-04-20');
GO

-- =============================================
-- Modern Publishing Expenses (Social Media & Digital Marketing)
-- =============================================

-- Twitter Blue subscription and advertising
EXEC sp_CreateJournalEntry
    '2024-01-01', 'TW001', 'Twitter Blue subscription - monthly', 'System',
    '[{"AccountCode":"6500","Debit":7.00,"Credit":0,"Description":"Twitter Blue subscription"},
      {"AccountCode":"1100","Debit":0,"Credit":7.00,"Description":"Bank payment"}]'

EXEC sp_CreateJournalEntry
    '2024-01-15', 'TW002', 'Twitter advertising campaign - Mystery book', 'System',
    '[{"AccountCode":"6110","Debit":150.00,"Credit":0,"Description":"Twitter ads for Mystery of Rhubarb House"},
      {"AccountCode":"1100","Debit":0,"Credit":150.00,"Description":"Bank payment"}]'

-- Facebook/Meta advertising
EXEC sp_CreateJournalEntry
    '2024-01-20', 'FB001', 'Facebook advertising campaign', 'System',
    '[{"AccountCode":"6110","Debit":200.00,"Credit":0,"Description":"Facebook ads for book promotion"},
      {"AccountCode":"1100","Debit":0,"Credit":200.00,"Description":"Bank payment"}]'

-- Amazon advertising
EXEC sp_CreateJournalEntry
    '2024-02-01', 'AMZ001', 'Amazon Advertising - sponsored products', 'System',
    '[{"AccountCode":"6110","Debit":300.00,"Credit":0,"Description":"Amazon sponsored product ads"},
      {"AccountCode":"1100","Debit":0,"Credit":300.00,"Description":"Bank payment"}]'

-- Mailchimp email marketing
EXEC sp_CreateJournalEntry
    '2024-01-01', 'MC001', 'Mailchimp email marketing subscription', 'System',
    '[{"AccountCode":"6110","Debit":30.00,"Credit":0,"Description":"Mailchimp monthly subscription"},
      {"AccountCode":"1100","Debit":0,"Credit":30.00,"Description":"Bank payment"}]'

-- Professional services
EXEC sp_CreateJournalEntry
    '2024-01-10', 'ACC001', 'Accountant fees - annual return', 'System',
    '[{"AccountCode":"6310","Debit":500.00,"Credit":0,"Description":"Annual company return preparation"},
      {"AccountCode":"2400","Debit":100.00,"Credit":0,"Description":"VAT on accounting fees"},
      {"AccountCode":"1100","Debit":0,"Credit":600.00,"Description":"Bank payment"}]'

-- Office expenses
EXEC sp_CreateJournalEntry
    '2024-01-05', 'OFF001', 'Office software subscriptions', 'System',
    '[{"AccountCode":"6500","Debit":25.00,"Credit":0,"Description":"Microsoft 365 subscription"},
      {"AccountCode":"2400","Debit":5.00,"Credit":0,"Description":"VAT on software"},
      {"AccountCode":"1100","Debit":0,"Credit":30.00,"Description":"Bank payment"}]'

-- Internet and phone
EXEC sp_CreateJournalEntry
    '2024-01-15', 'TEL001', 'Monthly internet and phone', 'System',
    '[{"AccountCode":"6230","Debit":45.00,"Credit":0,"Description":"Business internet and phone"},
      {"AccountCode":"2400","Debit":9.00,"Credit":0,"Description":"VAT"},
      {"AccountCode":"1100","Debit":0,"Credit":54.00,"Description":"Bank payment"}]'

-- Initial capital investment
EXEC sp_CreateJournalEntry
    '2024-01-01', 'CAP001', 'Initial capital investment', 'System',
    '[{"AccountCode":"1100","Debit":10000.00,"Credit":0,"Description":"Bank deposit - startup capital"},
      {"AccountCode":"3100","Debit":0,"Credit":10000.00,"Description":"Share capital"}]'

-- Book sales revenue (sample direct sales)
EXEC sp_CreateJournalEntry
    '2024-03-25', 'SAL001', 'Direct book sales - book fair', 'System',
    '[{"AccountCode":"1100","Debit":64.95,"Credit":0,"Description":"Cash from book sales"},
      {"AccountCode":"4100","Debit":0,"Credit":64.95,"Description":"Direct sales revenue - 5 books"}]'
GO

-- =============================================
-- Calculate author royalties for Q1 2024
-- =============================================
EXEC sp_CalculateAuthorRoyalties '2024-01-01', '2024-03-31', NULL, 'System'
GO

-- =============================================
-- Test invoice creation
-- =============================================
DECLARE @ContactID INT;
SELECT @ContactID = ContactID FROM Contacts WHERE CompanyName = 'Blackwells Books';

EXEC sp_CreateInvoice
    @ContactID,
    '2024-03-20',
    '2024-04-19',
    'System',
    '[{"Description":"The Mystery of Rhubarb House - 20 copies","Quantity":20,"UnitPrice":8.00,"VATRate":0.0000,"VATAmount":0.00,"BookID":1},
      {"Description":"The Edinburgh Conspiracy - 10 copies","Quantity":10,"UnitPrice":9.50,"VATRate":0.0000,"VATAmount":0.00,"BookID":2}]'
GO

-- =============================================
-- Verification and Summary
-- =============================================
PRINT '=== TEST DATA CREATION SUMMARY ===';

-- Count records created
SELECT 'Contacts' as TableName, COUNT(*) as RecordCount FROM Contacts
UNION ALL
SELECT 'Authors', COUNT(*) FROM Authors
UNION ALL
SELECT 'Books', COUNT(*) FROM Books
UNION ALL
SELECT 'BookSales', COUNT(*) FROM BookSales
UNION ALL
SELECT 'ProductionCosts', COUNT(*) FROM ProductionCosts
UNION ALL
SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL
SELECT 'TransactionLines', COUNT(*) FROM TransactionLines
UNION ALL
SELECT 'RoyaltyCalculations', COUNT(*) FROM RoyaltyCalculations
UNION ALL
SELECT 'Invoices', COUNT(*) FROM Invoices;

-- Show recent transactions
SELECT TOP 10
    TransactionDate,
    Reference,
    Description,
    TotalAmount,
    TransactionType
FROM Transactions
ORDER BY CreatedDate DESC;

-- Show trial balance
EXEC sp_GenerateTrialBalance;

PRINT 'Test data created successfully!';
PRINT 'Includes: Social media subscriptions, digital marketing, book sales, author royalties, and modern publishing expenses';
GO