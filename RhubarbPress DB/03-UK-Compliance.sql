-- Rhubarb Press Accounting System - UK Compliance Tables
-- VAT, Making Tax Digital (MTD), Corporation Tax
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating UK Compliance Schema for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- VAT Rates
-- =============================================
PRINT 'Creating VATRates table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VATRates')
BEGIN
    CREATE TABLE VATRates (
        VATRateID INT IDENTITY(1,1) PRIMARY KEY,
        VATCode NVARCHAR(10) NOT NULL UNIQUE,
        Rate DECIMAL(5,4) NOT NULL,
        Description NVARCHAR(100) NOT NULL,
        EffectiveFrom DATE NOT NULL,
        EffectiveTo DATE NULL,
        IsActive BIT DEFAULT 1
    );
    PRINT 'VATRates table created';
END
ELSE
BEGIN
    PRINT 'VATRates table already exists';
END
GO

-- =============================================
-- VAT Returns (MTD Compliance)
-- =============================================
PRINT 'Creating VATReturns table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VATReturns')
BEGIN
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
    PRINT 'VATReturns table created';
END
ELSE
BEGIN
    PRINT 'VATReturns table already exists';
END
GO

-- =============================================
-- Corporation Tax Calculations
-- =============================================
PRINT 'Creating CorporationTaxCalculations table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CorporationTaxCalculations')
BEGIN
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
    PRINT 'CorporationTaxCalculations table created';
END
ELSE
BEGIN
    PRINT 'CorporationTaxCalculations table already exists';
END
GO

-- =============================================
-- Capital Allowances (for equipment/assets)
-- =============================================
PRINT 'Creating CapitalAllowances table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CapitalAllowances')
BEGIN
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
    PRINT 'CapitalAllowances table created';
END
ELSE
BEGIN
    PRINT 'CapitalAllowances table already exists';
END
GO

-- =============================================
-- MTD VAT Transaction Mapping
-- =============================================
PRINT 'Creating VATTransactionMapping table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VATTransactionMapping')
BEGIN
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
    PRINT 'VATTransactionMapping table created';
END
ELSE
BEGIN
    PRINT 'VATTransactionMapping table already exists';
END
GO

-- =============================================
-- Compliance Documents Storage
-- =============================================
PRINT 'Creating ComplianceDocuments table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ComplianceDocuments')
BEGIN
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
    PRINT 'ComplianceDocuments table created';
END
ELSE
BEGIN
    PRINT 'ComplianceDocuments table already exists';
END
GO

-- =============================================
-- Audit Trail Trigger for Transactions
-- =============================================
PRINT 'Creating audit trail trigger...';
GO

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_Transactions_Audit')
BEGIN
    EXEC('
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
                ''Transactions'',
                ''UPDATE'',
                i.TransactionID,
                CONCAT(''TransactionID:'', CAST(d.TransactionID AS NVARCHAR), '',Date:'', CAST(d.TransactionDate AS NVARCHAR), '',Ref:'', d.Reference, '',Amount:'', CAST(d.TotalAmount AS NVARCHAR)),
                CONCAT(''TransactionID:'', CAST(i.TransactionID AS NVARCHAR), '',Date:'', CAST(i.TransactionDate AS NVARCHAR), '',Ref:'', i.Reference, '',Amount:'', CAST(i.TotalAmount AS NVARCHAR)),
                ISNULL(i.ModifiedBy, ''SYSTEM'')
            FROM inserted i
            INNER JOIN deleted d ON i.TransactionID = d.TransactionID;
        END
        ELSE IF EXISTS(SELECT * FROM inserted)
        BEGIN
            -- INSERT
            INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, ChangedBy)
            SELECT
                ''Transactions'',
                ''INSERT'',
                TransactionID,
                CONCAT(''TransactionID:'', CAST(TransactionID AS NVARCHAR), '',Date:'', CAST(TransactionDate AS NVARCHAR), '',Ref:'', Reference, '',Amount:'', CAST(TotalAmount AS NVARCHAR)),
                CreatedBy
            FROM inserted;
        END
        ELSE IF EXISTS(SELECT * FROM deleted)
        BEGIN
            -- DELETE
            INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, ChangedBy)
            SELECT
                ''Transactions'',
                ''DELETE'',
                TransactionID,
                CONCAT(''TransactionID:'', CAST(TransactionID AS NVARCHAR), '',Date:'', CAST(TransactionDate AS NVARCHAR), ',Ref:'', Reference, '',Amount:'', CAST(TotalAmount AS NVARCHAR)),
                ''SYSTEM''
            FROM deleted;
        END
    END;
    ');
    PRINT 'Audit trail trigger created';
END
ELSE
BEGIN
    PRINT 'Audit trail trigger already exists';
END
GO

-- =============================================
-- Stored Procedures for Compliance
-- =============================================
PRINT 'Creating VAT return calculation procedure...';
GO

-- Calculate VAT Return
CREATE OR ALTER PROCEDURE sp_CalculateVATReturn
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
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating indexes for performance...';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VATReturns_Period' AND object_id = OBJECT_ID('VATReturns'))
BEGIN
    CREATE INDEX IX_VATReturns_Period ON VATReturns(PeriodStart, PeriodEnd);
    PRINT 'Created index IX_VATReturns_Period';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VATTransactionMapping_Return' AND object_id = OBJECT_ID('VATTransactionMapping'))
BEGIN
    CREATE INDEX IX_VATTransactionMapping_Return ON VATTransactionMapping(VATReturnID);
    PRINT 'Created index IX_VATTransactionMapping_Return';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CorporationTaxCalculations_Year' AND object_id = OBJECT_ID('CorporationTaxCalculations'))
BEGIN
    CREATE INDEX IX_CorporationTaxCalculations_Year ON CorporationTaxCalculations(FinancialYearStart, FinancialYearEnd);
    PRINT 'Created index IX_CorporationTaxCalculations_Year';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CapitalAllowances_TaxYear' AND object_id = OBJECT_ID('CapitalAllowances'))
BEGIN
    CREATE INDEX IX_CapitalAllowances_TaxYear ON CapitalAllowances(TaxYear);
    PRINT 'Created index IX_CapitalAllowances_TaxYear';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ComplianceDocuments_Type' AND object_id = OBJECT_ID('ComplianceDocuments'))
BEGIN
    CREATE INDEX IX_ComplianceDocuments_Type ON ComplianceDocuments(DocumentType);
    PRINT 'Created index IX_ComplianceDocuments_Type';
END
GO

PRINT '';
PRINT '=== UK Compliance Schema Created Successfully ===';
PRINT 'Tables created:';
PRINT '  - VATRates: VAT rate configurations';
PRINT '  - VATReturns: Making Tax Digital VAT returns';
PRINT '  - CorporationTaxCalculations: Corporation tax computations';
PRINT '  - CapitalAllowances: Capital allowance tracking';
PRINT '  - VATTransactionMapping: Transaction to VAT box mapping';
PRINT '  - ComplianceDocuments: Document storage for compliance';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_CalculateVATReturn: Calculate VAT return for period';
PRINT '';
PRINT 'Audit trail trigger created for transaction tracking';
PRINT 'UK compliance schema is ready for tax operations';
GO
