-- Rhubarb Press Accounting System - Sample Transactions Insert
-- Seeds a small set of transactions using sp_ImportBankTransaction after fresh deployment

USE rhubarbpressdb;
GO

PRINT 'Seeding sample bank transactions via sp_ImportBankTransaction';
PRINT 'Run Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

DECLARE @CreatedBy NVARCHAR(50) = 'Sample Data Load 2025-09';

-- Helper macro to keep script DRY
IF NOT EXISTS (
    SELECT 1 FROM BankBalance b
    INNER JOIN ChartOfAccounts ca ON b.AccountID = ca.AccountID
    WHERE ca.AccountCode = '1001')
BEGIN
    PRINT 'Initializing bank balance for account 1001';
    EXEC sp_InitializeBankBalance @AccountCode = '1001', @OpeningBalance = 10000.00;
END

DECLARE @Transactions TABLE (
    TransactionDate DATE,
    BankDate DATE,
    Description NVARCHAR(255),
    TransactionGroupID INT,
    AmountIn MONEY,
    AmountOut MONEY
);

INSERT INTO @Transactions (TransactionDate, BankDate, Description, TransactionGroupID, AmountIn, AmountOut)
VALUES
    ('2025-09-01','2025-09-01','Twitter Marketing',       2, 0,    8.00),
    ('2025-09-01','2025-09-02','Hoxton Mix Office',       1, 0,   55.19),
    ('2025-09-03','2025-09-03','Book Sales - Waterstones',5,120.00,0),
    ('2025-09-05','2025-09-05','Print Run - ABC Printers',7,0,  640.00),
    ('2025-09-08','2025-09-08','Author Royalty - J Smith',9,0,  250.00);

DECLARE @TransactionDate DATE,
        @BankDate DATE,
        @Description NVARCHAR(255),
        @TransactionGroupID INT,
        @AmountIn MONEY,
        @AmountOut MONEY;

DECLARE cur CURSOR FOR
    SELECT TransactionDate, BankDate, Description, TransactionGroupID, AmountIn, AmountOut
    FROM @Transactions;

OPEN cur;
FETCH NEXT FROM cur INTO @TransactionDate, @BankDate, @Description, @TransactionGroupID, @AmountIn, @AmountOut;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Transactions
        WHERE TransactionDate = @TransactionDate
          AND Description = @Description
          AND ABS(TotalAmount) = ABS(@AmountIn - @AmountOut)
          AND TransactionGroupID = @TransactionGroupID
    )
    BEGIN
        PRINT 'Importing: ' + @Description + ' (' + CONVERT(NVARCHAR(10), @TransactionDate, 120) + ')';
        EXEC sp_ImportBankTransaction
            @ActualDate          = @TransactionDate,
            @BankDate            = @BankDate,
            @Description         = @Description,
            @TransactionGroupID  = @TransactionGroupID,
            @AmountIn            = @AmountIn,
            @AmountOut           = @AmountOut,
            @CreatedBy           = @CreatedBy;
    END
    ELSE
    BEGIN
        PRINT 'SKIPPED: ' + @Description + ' (' + CONVERT(NVARCHAR(10), @TransactionDate, 120) + ') - already exists';
    END

    FETCH NEXT FROM cur INTO @TransactionDate, @BankDate, @Description, @TransactionGroupID, @AmountIn, @AmountOut;
END

CLOSE cur;
DEALLOCATE cur;

PRINT '';
PRINT 'Sample transactions seeding complete.';
GO
