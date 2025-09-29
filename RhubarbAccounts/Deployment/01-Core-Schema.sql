-- Rhubarb Press Accounting System - Core Schema
-- Complete double-entry bookkeeping system with TransactionGroups
-- Target: Azure SQL Database (rhubarbpressdb)
-- IDEMPOTENT: Safe to run multiple times

USE rhubarbpressdb;
GO

PRINT 'Rhubarb Press Accounting System - Core Schema Deployment';
PRINT 'Deployment Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Transaction Groups Lookup Table
-- =============================================
PRINT 'Creating TransactionGroup lookup table...';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransactionGroup')
BEGIN
    CREATE TABLE TransactionGroup (
        TransactionGroupID INT IDENTITY(1,1) PRIMARY KEY,
        GroupName NVARCHAR(50) NOT NULL UNIQUE,
        GroupDescription NVARCHAR(255) NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );

    PRINT 'TransactionGroup table created successfully';
END
ELSE
BEGIN
    PRINT 'TransactionGroup table already exists';
END
GO

-- =============================================
-- Chart of Accounts
-- =============================================
PRINT 'Creating Chart of Accounts...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChartOfAccounts')
BEGIN
    CREATE TABLE ChartOfAccounts (
        AccountID INT IDENTITY(1,1) PRIMARY KEY,
        AccountCode NVARCHAR(20) NOT NULL UNIQUE,
        AccountName NVARCHAR(100) NOT NULL,
        AccountType NVARCHAR(20) NOT NULL CHECK (AccountType IN ('Asset', 'Liability', 'Equity', 'Revenue', 'Expense')),
        AccountSubType NVARCHAR(50) NULL, -- Current Asset, Fixed Asset, etc.
        PublishingCategory NVARCHAR(50) NULL, -- Production, Marketing, Royalties, Distribution
        ParentAccountID INT NULL,
        IsActive BIT DEFAULT 1,
        VATCode NVARCHAR(10) NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (ParentAccountID) REFERENCES ChartOfAccounts(AccountID)
    );

    PRINT 'Chart of Accounts created successfully';
END
ELSE
BEGIN
    PRINT 'Chart of Accounts already exists';
END
GO

-- =============================================
-- Transactions Header Table
-- =============================================
PRINT 'Creating Transactions table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionID INT IDENTITY(1,1) PRIMARY KEY,
        TransactionDate DATE NOT NULL,
        BankDate DATE NULL, -- For bank reconciliation
        Reference NVARCHAR(50) NOT NULL,
        Description NVARCHAR(255) NOT NULL,
        TotalAmount MONEY NOT NULL,
        VATAmount MONEY DEFAULT 0,
        TransactionType NVARCHAR(20) NOT NULL, -- Journal, Invoice, Payment, Receipt
        TransactionGroupID INT NULL, -- Link to transaction categories
        Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Reversed', 'Draft')),
        ReconciliationStatus NVARCHAR(20) DEFAULT 'Pending' CHECK (ReconciliationStatus IN ('Pending', 'Reconciled', 'Disputed')),
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NOT NULL,
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedBy NVARCHAR(50) NULL,
        FOREIGN KEY (TransactionGroupID) REFERENCES TransactionGroup(TransactionGroupID)
    );

    PRINT 'Transactions table created successfully';
END
ELSE
BEGIN
    -- Add TransactionGroupID if it doesn't exist (for upgrades)
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'TransactionGroupID')
    BEGIN
        ALTER TABLE Transactions ADD TransactionGroupID INT NULL;
        ALTER TABLE Transactions ADD CONSTRAINT FK_Transactions_TransactionGroup
            FOREIGN KEY (TransactionGroupID) REFERENCES TransactionGroup(TransactionGroupID);
        PRINT 'Added TransactionGroupID to existing Transactions table';
    END
    ELSE
    BEGIN
        PRINT 'Transactions table already exists with TransactionGroupID';
    END
END
GO

-- =============================================
-- Transaction Lines (Double-Entry)
-- =============================================
PRINT 'Creating Transaction Lines table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransactionLines')
BEGIN
    CREATE TABLE TransactionLines (
        LineID INT IDENTITY(1,1) PRIMARY KEY,
        TransactionID INT NOT NULL,
        AccountID INT NOT NULL,
        DebitAmount MONEY DEFAULT 0,
        CreditAmount MONEY DEFAULT 0,
        Description NVARCHAR(255) NULL,
        VATAmount MONEY DEFAULT 0,
        VATCode NVARCHAR(10) NULL,
        ProjectID INT NULL, -- For book-specific tracking
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID),
        CONSTRAINT CK_DebitOrCredit CHECK ((DebitAmount > 0 AND CreditAmount = 0) OR (CreditAmount > 0 AND DebitAmount = 0))
    );

    PRINT 'Transaction Lines table created successfully';
END
ELSE
BEGIN
    PRINT 'Transaction Lines table already exists';
END
GO

-- =============================================
-- Contacts (Authors, Suppliers, Customers)
-- =============================================
PRINT 'Creating Contacts table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Contacts')
BEGIN
    CREATE TABLE Contacts (
        ContactID INT IDENTITY(1,1) PRIMARY KEY,
        ContactType NVARCHAR(20) NOT NULL CHECK (ContactType IN ('Author', 'Supplier', 'Customer', 'Other')),
        CompanyName NVARCHAR(100) NULL,
        FirstName NVARCHAR(50) NULL,
        LastName NVARCHAR(50) NULL,
        Email NVARCHAR(100) NULL,
        Phone NVARCHAR(20) NULL,
        Address1 NVARCHAR(100) NULL,
        Address2 NVARCHAR(100) NULL,
        City NVARCHAR(50) NULL,
        PostCode NVARCHAR(20) NULL,
        Country NVARCHAR(50) DEFAULT 'United Kingdom',
        VATNumber NVARCHAR(20) NULL,
        TaxStatus NVARCHAR(20) NULL, -- Employee, Self-Employed, Company
        PaymentTerms NVARCHAR(50) NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );

    PRINT 'Contacts table created successfully';
END
ELSE
BEGIN
    PRINT 'Contacts table already exists';
END
GO

-- =============================================
-- Invoices and Bills
-- =============================================
PRINT 'Creating Invoices table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Invoices')
BEGIN
    CREATE TABLE Invoices (
        InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
        InvoiceType NVARCHAR(20) NOT NULL CHECK (InvoiceType IN ('Sales', 'Purchase')),
        InvoiceNumber NVARCHAR(50) NOT NULL UNIQUE,
        ContactID INT NOT NULL,
        InvoiceDate DATE NOT NULL,
        DueDate DATE NULL,
        SubTotal MONEY NOT NULL,
        VATAmount MONEY DEFAULT 0,
        TotalAmount MONEY NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled')),
        TransactionID INT NULL, -- Link to accounting transaction
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NOT NULL,
        FOREIGN KEY (ContactID) REFERENCES Contacts(ContactID),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
    );

    PRINT 'Invoices table created successfully';
END
ELSE
BEGIN
    PRINT 'Invoices table already exists';
END
GO

-- =============================================
-- Invoice Line Items
-- =============================================
PRINT 'Creating Invoice Lines table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InvoiceLines')
BEGIN
    CREATE TABLE InvoiceLines (
        LineID INT IDENTITY(1,1) PRIMARY KEY,
        InvoiceID INT NOT NULL,
        Description NVARCHAR(255) NOT NULL,
        Quantity DECIMAL(10,2) DEFAULT 1,
        UnitPrice MONEY NOT NULL,
        LineTotal MONEY NOT NULL,
        VATRate DECIMAL(5,4) DEFAULT 0,
        VATAmount MONEY DEFAULT 0,
        AccountID INT NULL, -- Link to chart of accounts
        BookID INT NULL, -- Link to specific book if applicable
        FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID),
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID)
    );

    PRINT 'Invoice Lines table created successfully';
END
ELSE
BEGIN
    PRINT 'Invoice Lines table already exists';
END
GO

-- =============================================
-- Audit Trail
-- =============================================
PRINT 'Creating Audit Log table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog')
BEGIN
    CREATE TABLE AuditLog (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        TableName NVARCHAR(50) NOT NULL,
        Action NVARCHAR(10) NOT NULL CHECK (Action IN ('INSERT', 'UPDATE', 'DELETE')),
        RecordID INT NOT NULL,
        OldValues NVARCHAR(MAX) NULL,
        NewValues NVARCHAR(MAX) NULL,
        ChangedBy NVARCHAR(100) NOT NULL,
        ChangedDate DATETIME2 DEFAULT GETDATE(),
        IPAddress NVARCHAR(50) NULL
    );

    PRINT 'Audit Log table created successfully';
END
ELSE
BEGIN
    PRINT 'Audit Log table already exists';
END
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating performance indexes...';
GO

-- Transaction indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_Date')
    CREATE INDEX IX_Transactions_Date ON Transactions(TransactionDate);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_Reference')
    CREATE INDEX IX_Transactions_Reference ON Transactions(Reference);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_TransactionGroup')
    CREATE INDEX IX_Transactions_TransactionGroup ON Transactions(TransactionGroupID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_Date_ID')
    CREATE INDEX IX_Transactions_Date_ID ON Transactions(TransactionDate, TransactionID);

-- Transaction Lines indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('TransactionLines') AND name = 'IX_TransactionLines_Account')
    CREATE INDEX IX_TransactionLines_Account ON TransactionLines(AccountID);

-- Contact indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Contacts') AND name = 'IX_Contacts_Type')
    CREATE INDEX IX_Contacts_Type ON Contacts(ContactType);

-- Invoice indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Invoices') AND name = 'IX_Invoices_Number')
    CREATE INDEX IX_Invoices_Number ON Invoices(InvoiceNumber);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Invoices') AND name = 'IX_Invoices_Contact')
    CREATE INDEX IX_Invoices_Contact ON Invoices(ContactID);

-- Audit Log indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('AuditLog') AND name = 'IX_AuditLog_Table_Action')
    CREATE INDEX IX_AuditLog_Table_Action ON AuditLog(TableName, Action);

PRINT 'Performance indexes created successfully';
GO

PRINT '';
PRINT '=== Core Schema Deployment Complete ===';
PRINT 'Tables created/verified:';
PRINT '  - TransactionGroup: Transaction categories lookup';
PRINT '  - ChartOfAccounts: Account structure for double-entry';
PRINT '  - Transactions: Transaction headers with TransactionGroupID';
PRINT '  - TransactionLines: Double-entry transaction details';
PRINT '  - Contacts: Authors, suppliers, customers';
PRINT '  - Invoices & InvoiceLines: Invoice management';
PRINT '  - AuditLog: Complete audit trail';
PRINT '';
PRINT 'Performance indexes and constraints applied';
PRINT 'System ready for publishing schema and data setup';
GO