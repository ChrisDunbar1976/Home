-- Rhubarb Press Accounting System - Comprehensive Test Data (FIXED)
-- Fixed ContactID issues in invoice creation
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Simple Test Invoice (using existing contact)
-- =============================================
DECLARE @ContactID INT;

-- Use the first existing contact for the test invoice
SELECT TOP 1 @ContactID = ContactID
FROM Contacts
WHERE ContactType IN ('Customer', 'Supplier')
ORDER BY ContactID;

-- If no suitable contact found, create one
IF @ContactID IS NULL
BEGIN
    INSERT INTO Contacts (ContactType, CompanyName, Email, Country, TaxStatus)
    VALUES ('Customer', 'Test Bookstore', 'test@bookstore.com', 'United Kingdom', 'Company');

    SET @ContactID = SCOPE_IDENTITY();
END

PRINT 'Using ContactID: ' + CAST(@ContactID AS NVARCHAR(10));

-- Create a simple test invoice
EXEC sp_CreateInvoice
    @ContactID,
    '2024-03-20',
    '2024-04-19',
    'System',
    '[{"Description":"Test Book Sale - 5 copies","Quantity":5,"UnitPrice":12.99,"VATRate":0.0000,"VATAmount":0.00,"BookID":1}]'
GO

-- =============================================
-- Quick verification queries
-- =============================================

-- Show all contacts
SELECT ContactID, ContactType,
       COALESCE(CompanyName, FirstName + ' ' + LastName) as Name,
       Country
FROM Contacts
ORDER BY ContactID;

-- Show books for reference
SELECT BookID, ISBN, Title, Format, RetailPrice, Status
FROM Books
ORDER BY BookID;

-- Show recent transactions
SELECT TOP 5
    TransactionDate,
    Reference,
    Description,
    TotalAmount
FROM Transactions
ORDER BY CreatedDate DESC;

-- Show invoices
SELECT InvoiceID, InvoiceNumber, TotalAmount, Status
FROM Invoices;

-- Show trial balance summary
SELECT AccountType, SUM(Balance) as TotalBalance
FROM TrialBalance
GROUP BY AccountType
ORDER BY AccountType;

PRINT '=== SYSTEM VERIFICATION COMPLETE ===';
PRINT 'Your Rhubarb Press accounting system is ready!';
PRINT 'Next steps:';
PRINT '1. Add real author and book data';
PRINT '2. Import sales data from Amazon/distributors';
PRINT '3. Set up recurring expenses (Twitter, subscriptions)';
PRINT '4. Generate monthly reports';
GO