-- Rhubarb Press Accounting System - Core Schema
-- Double-Entry Bookkeeping Database for Publishing Company
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Chart of Accounts
-- =============================================
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

-- =============================================
-- Transaction Headers
-- =============================================
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionDate DATE NOT NULL,
    Reference NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NOT NULL,
    TotalAmount MONEY NOT NULL,
    VATAmount MONEY DEFAULT 0,
    TransactionType NVARCHAR(20) NOT NULL, -- Journal, Invoice, Payment, etc.
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Reversed', 'Draft')),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(50) NULL
);

-- =============================================
-- Transaction Lines (Double-Entry)
-- =============================================
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

-- =============================================
-- Contacts (Authors, Suppliers, Customers)
-- =============================================
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

-- =============================================
-- Invoices and Bills
-- =============================================
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

-- =============================================
-- Invoice Line Items
-- =============================================
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

-- =============================================
-- Audit Trail
-- =============================================
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

-- =============================================
-- Indexes for Performance
-- =============================================
CREATE INDEX IX_Transactions_Date ON Transactions(TransactionDate);
CREATE INDEX IX_Transactions_Reference ON Transactions(Reference);
CREATE INDEX IX_TransactionLines_Account ON TransactionLines(AccountID);
CREATE INDEX IX_Contacts_Type ON Contacts(ContactType);
CREATE INDEX IX_Invoices_Number ON Invoices(InvoiceNumber);
CREATE INDEX IX_Invoices_Contact ON Invoices(ContactID);
CREATE INDEX IX_AuditLog_Table_Action ON AuditLog(TableName, Action);

PRINT 'Core accounting schema created successfully for Rhubarb Press';