-- Rhubarb Press Accounting System - UK Compliance Tables
-- VAT, Making Tax Digital (MTD), Corporation Tax
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- VAT Rates
-- =============================================
CREATE TABLE VATRates (
    VATRateID INT IDENTITY(1,1) PRIMARY KEY,
    VATCode NVARCHAR(10) NOT NULL UNIQUE,
    Rate DECIMAL(5,4) NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE NULL,
    IsActive BIT DEFAULT 1
);

-- =============================================
-- VAT Returns (MTD Compliance)
-- =============================================
CREATE TABLE VATReturns (
    ReturnID INT IDENTITY(1,1) PRIMARY KEY,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    Box1_VATDueOnSales MONEY NOT NULL DEFAULT 0,
    Box2_VATDueOnAcquisitions MONEY NOT NULL DEFAULT 0,
    Box3_TotalVATDue MONEY NOT NULL DEFAULT 0,
    Box4_VATReclaimed MONEY NOT NULL DEFAULT 0,
    Box5_NetVATDue MONEY NOT NULL DEFAULT 0,
    Box6_NetSalesAndOutputs MONEY NOT NULL DEFAULT 0,
    Box7_NetPurchasesAndInputs MONEY NOT NULL DEFAULT 0,
    Box8_GoodsSuppliedEU MONEY NOT NULL DEFAULT 0,
    Box9_GoodsAcquiredEU MONEY NOT NULL DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Calculated', 'Submitted', 'Accepted')),
    CalculatedDate DATETIME2 NULL,
    CalculatedBy NVARCHAR(50) NULL,
    SubmittedDate DATETIME2 NULL,
    SubmittedBy NVARCHAR(50) NULL,
    HMRCReference NVARCHAR(50) NULL,
    HMRCCorrelationID NVARCHAR(100) NULL,
    PaymentDueDate DATE NULL,
    PaymentTransactionID INT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (PaymentTransactionID) REFERENCES Transactions(TransactionID)
);

-- =============================================
-- Corporation Tax Calculations
-- =============================================
CREATE TABLE CorporationTaxCalculations (
    CalculationID INT IDENTITY(1,1) PRIMARY KEY,
    FinancialYearStart DATE NOT NULL,
    FinancialYearEnd DATE NOT NULL,
    TotalRevenue MONEY NOT NULL DEFAULT 0,
    TotalExpenses MONEY NOT NULL DEFAULT 0,
    TaxableProfit MONEY NOT NULL DEFAULT 0,
    CorporationTaxRate DECIMAL(5,4) NOT NULL DEFAULT 0.1900, -- 19% current rate
    CorporationTaxDue MONEY NOT NULL DEFAULT 0,
    SmallCompaniesRate DECIMAL(5,4) NULL, -- If applicable
    R_DReliefClaimed MONEY DEFAULT 0,
    CapitalAllowances MONEY DEFAULT 0,
    OtherAdjustments MONEY DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Calculated', 'Filed', 'Paid')),
    CalculatedDate DATETIME2 NULL,
    CalculatedBy NVARCHAR(50) NULL,
    FiledDate DATETIME2 NULL,
    HMRCReference NVARCHAR(50) NULL,
    PaymentDueDate DATE NULL,
    PaymentTransactionID INT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (PaymentTransactionID) REFERENCES Transactions(TransactionID)
);

-- =============================================
-- Capital Allowances (for equipment/assets)
-- =============================================
CREATE TABLE CapitalAllowances (
    AllowanceID INT IDENTITY(1,1) PRIMARY KEY,
    AssetDescription NVARCHAR(255) NOT NULL,
    AssetType NVARCHAR(50) NOT NULL, -- Computer Equipment, Office Equipment, etc.
    PurchaseDate DATE NOT NULL,
    PurchasePrice MONEY NOT NULL,
    AllowanceType NVARCHAR(50) NOT NULL, -- Annual Investment Allowance, Writing Down Allowance
    AllowanceRate DECIMAL(5,4) NOT NULL, -- e.g., 1.0000 for 100% AIA
    AllowanceClaimed MONEY NOT NULL,
    TaxYear NVARCHAR(10) NOT NULL, -- e.g., '2023-24'
    TransactionID INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);

-- =============================================
-- MTD VAT Transaction Mapping
-- =============================================
CREATE TABLE VATTransactionMapping (
    MappingID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionLineID INT NOT NULL,
    VATReturnID INT NULL,
    VATBox NVARCHAR(10) NOT NULL, -- Box1, Box2, Box4, Box6, Box7, etc.
    VATAmount MONEY NOT NULL,
    NetAmount MONEY NOT NULL,
    MappedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (TransactionLineID) REFERENCES TransactionLines(LineID),
    FOREIGN KEY (VATReturnID) REFERENCES VATReturns(ReturnID)
);

-- =============================================
-- Compliance Documents Storage
-- =============================================
CREATE TABLE ComplianceDocuments (
    DocumentID INT IDENTITY(1,1) PRIMARY KEY,
    DocumentType NVARCHAR(50) NOT NULL, -- VAT Return, CT600, Receipt, etc.
    ReferenceID INT NULL, -- Link to related record
    ReferenceType NVARCHAR(50) NULL, -- VATReturn, CorporationTax, Transaction, etc.
    FileName NVARCHAR(255) NOT NULL,
    FilePath NVARCHAR(500) NULL,
    FileSize INT NULL,
    ContentType NVARCHAR(100) NULL,
    DocumentDate DATE NULL,
    UploadedDate DATETIME2 DEFAULT GETDATE(),
    UploadedBy NVARCHAR(50) NOT NULL,
    IsArchived BIT DEFAULT 0
);

-- =============================================
-- Audit Trail Triggers
-- =============================================
CREATE TRIGGER TR_Transactions_Audit
ON Transactions
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        -- UPDATE
        INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, NewValues, ChangedBy)
        SELECT
            'Transactions',
            'UPDATE',
            i.TransactionID,
            (SELECT d.* FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
            (SELECT i.* FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
            i.ModifiedBy
        FROM inserted i
        INNER JOIN deleted d ON i.TransactionID = d.TransactionID;
    END
    ELSE IF EXISTS(SELECT * FROM inserted)
    BEGIN
        -- INSERT
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, ChangedBy)
        SELECT
            'Transactions',
            'INSERT',
            TransactionID,
            (SELECT i.* FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
            CreatedBy
        FROM inserted i;
    END
    ELSE IF EXISTS(SELECT * FROM deleted)
    BEGIN
        -- DELETE
        INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, ChangedBy)
        SELECT
            'Transactions',
            'DELETE',
            TransactionID,
            (SELECT d.* FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
            'SYSTEM' -- Deletes should be rare and logged separately
        FROM deleted d;
    END
END;

-- =============================================
-- Stored Procedures for Compliance
-- =============================================

-- Calculate VAT Return
CREATE PROCEDURE sp_CalculateVATReturn
    @PeriodStart DATE,
    @PeriodEnd DATE,
    @CreatedBy NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReturnID INT;

    -- Create new VAT return
    INSERT INTO VATReturns (PeriodStart, PeriodEnd, CalculatedBy, CalculatedDate, Status)
    VALUES (@PeriodStart, @PeriodEnd, @CreatedBy, GETDATE(), 'Calculated');

    SET @ReturnID = SCOPE_IDENTITY();

    -- Calculate Box 1: VAT due on sales and other outputs
    UPDATE VATReturns
    SET Box1_VATDueOnSales = (
        SELECT ISNULL(SUM(tl.VATAmount), 0)
        FROM TransactionLines tl
        INNER JOIN Transactions t ON tl.TransactionID = t.TransactionID
        INNER JOIN ChartOfAccounts ca ON tl.AccountID = ca.AccountID
        WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
        AND ca.AccountType = 'Revenue'
        AND tl.VATAmount > 0
    )
    WHERE ReturnID = @ReturnID;

    -- Calculate Box 4: VAT reclaimed on purchases and other inputs
    UPDATE VATReturns
    SET Box4_VATReclaimed = (
        SELECT ISNULL(SUM(ABS(tl.VATAmount)), 0)
        FROM TransactionLines tl
        INNER JOIN Transactions t ON tl.TransactionID = t.TransactionID
        INNER JOIN ChartOfAccounts ca ON tl.AccountID = ca.AccountID
        WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
        AND ca.AccountType = 'Expense'
        AND tl.VATAmount < 0
    )
    WHERE ReturnID = @ReturnID;

    -- Calculate Box 6: Net sales and other outputs (excluding VAT)
    UPDATE VATReturns
    SET Box6_NetSalesAndOutputs = (
        SELECT ISNULL(SUM(tl.CreditAmount), 0)
        FROM TransactionLines tl
        INNER JOIN Transactions t ON tl.TransactionID = t.TransactionID
        INNER JOIN ChartOfAccounts ca ON tl.AccountID = ca.AccountID
        WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
        AND ca.AccountType = 'Revenue'
    )
    WHERE ReturnID = @ReturnID;

    -- Calculate Box 7: Net purchases and other inputs (excluding VAT)
    UPDATE VATReturns
    SET Box7_NetPurchasesAndInputs = (
        SELECT ISNULL(SUM(tl.DebitAmount), 0)
        FROM TransactionLines tl
        INNER JOIN Transactions t ON tl.TransactionID = t.TransactionID
        INNER JOIN ChartOfAccounts ca ON tl.AccountID = ca.AccountID
        WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
        AND ca.AccountType = 'Expense'
    )
    WHERE ReturnID = @ReturnID;

    -- Calculate totals
    UPDATE VATReturns
    SET
        Box3_TotalVATDue = Box1_VATDueOnSales + Box2_VATDueOnAcquisitions,
        Box5_NetVATDue = (Box1_VATDueOnSales + Box2_VATDueOnAcquisitions) - Box4_VATReclaimed
    WHERE ReturnID = @ReturnID;

    -- Map transactions to VAT boxes
    INSERT INTO VATTransactionMapping (TransactionLineID, VATReturnID, VATBox, VATAmount, NetAmount)
    SELECT
        tl.LineID,
        @ReturnID,
        CASE
            WHEN ca.AccountType = 'Revenue' AND tl.VATAmount > 0 THEN 'Box1'
            WHEN ca.AccountType = 'Expense' AND tl.VATAmount < 0 THEN 'Box4'
            WHEN ca.AccountType = 'Revenue' THEN 'Box6'
            WHEN ca.AccountType = 'Expense' THEN 'Box7'
        END,
        tl.VATAmount,
        CASE WHEN tl.DebitAmount > 0 THEN tl.DebitAmount ELSE tl.CreditAmount END
    FROM TransactionLines tl
    INNER JOIN Transactions t ON tl.TransactionID = t.TransactionID
    INNER JOIN ChartOfAccounts ca ON tl.AccountID = ca.AccountID
    WHERE t.TransactionDate BETWEEN @PeriodStart AND @PeriodEnd
    AND ca.AccountType IN ('Revenue', 'Expense');

    SELECT @ReturnID as ReturnID;
END;

-- =============================================
-- Indexes for Performance
-- =============================================
CREATE INDEX IX_VATReturns_Period ON VATReturns(PeriodStart, PeriodEnd);
CREATE INDEX IX_VATTransactionMapping_Return ON VATTransactionMapping(VATReturnID);
CREATE INDEX IX_CorporationTaxCalculations_Year ON CorporationTaxCalculations(FinancialYearStart, FinancialYearEnd);
CREATE INDEX IX_CapitalAllowances_TaxYear ON CapitalAllowances(TaxYear);
CREATE INDEX IX_ComplianceDocuments_Type ON ComplianceDocuments(DocumentType);

PRINT 'UK compliance schema created successfully for Rhubarb Press';