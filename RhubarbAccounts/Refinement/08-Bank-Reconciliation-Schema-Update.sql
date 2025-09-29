-- Rhubarb Press Accounting System - Bank Reconciliation Schema Updates
-- Adds bank reconciliation fields to support CSV import
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Add Bank Reconciliation Fields to Transactions Table
-- =============================================

-- Check if BankDate column exists, if not add it
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'BankDate')
BEGIN
    ALTER TABLE Transactions ADD BankDate DATE NULL;
    PRINT 'Added BankDate column to Transactions table';
END
ELSE
BEGIN
    PRINT 'BankDate column already exists in Transactions table';
END

-- Check if BankReference column exists, if not add it
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'BankReference')
BEGIN
    ALTER TABLE Transactions ADD BankReference NVARCHAR(50) NULL;
    PRINT 'Added BankReference column to Transactions table';
END
ELSE
BEGIN
    PRINT 'BankReference column already exists in Transactions table';
END

-- Check if ReconciliationStatus column exists, if not add it
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'ReconciliationStatus')
BEGIN
    ALTER TABLE Transactions ADD ReconciliationStatus NVARCHAR(20) DEFAULT 'Pending'
        CHECK (ReconciliationStatus IN ('Pending', 'Reconciled', 'Disputed'));
    PRINT 'Added ReconciliationStatus column to Transactions table';
END
ELSE
BEGIN
    PRINT 'ReconciliationStatus column already exists in Transactions table';
END

-- Add index for bank reconciliation queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_BankDate')
BEGIN
    CREATE INDEX IX_Transactions_BankDate ON Transactions(BankDate);
    PRINT 'Added index on BankDate column';
END

PRINT 'Bank reconciliation schema updates completed successfully';
GO