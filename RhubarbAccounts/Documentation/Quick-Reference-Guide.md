# Rhubarb Press Accounting System - Quick Reference Guide

## Common Daily Tasks

### Import Bank Transactions
```sql
-- Import money received (e.g., book sales)
EXEC sp_ImportBankTransaction_v2
    @ActualDate = '2024-01-15',
    @Description = 'Book sales - Amazon',
    @TransactionGroupID = 5, -- Revenue
    @AmountIn = 1250.00,
    @CreatedBy = 'YourName';

-- Import money paid out (e.g., office expenses)
EXEC sp_ImportBankTransaction_v2
    @ActualDate = '2024-01-16',
    @Description = 'Office supplies',
    @TransactionGroupID = 1, -- Admin
    @AmountOut = 45.50,
    @CreatedBy = 'YourName';
```

### Check Current Bank Balance
```sql
SELECT * FROM vw_CurrentBankBalances;
```

### View Recent Transactions
```sql
SELECT TOP 20
    TransactionDate,
    Description,
    TransactionGroup,
    BankMovement,
    RunningBalance
FROM vw_BankRunningBalance
ORDER BY TransactionDate DESC;
```

## Transaction Categories Quick Reference

| Category | ID | Use For |
|----------|----|---------|
| **Revenue** | 5 | Book sales, licensing, advances received |
| **Admin** | 1 | Office rent, utilities, insurance, general business |
| **Marketing** | 2 | Advertising, promotions, social media costs |
| **Publishing** | 3 | Editing, design, printing, publishing tools |
| **Research** | 4 | Market research, manuscript development |
| **General** | 6 | Uncategorized (use sparingly) |

## Essential Reports

### Monthly Summary
```sql
SELECT * FROM vw_MonthlySummary
WHERE Year = 2024
ORDER BY Year DESC, Month DESC;
```

### Transaction Summary by Category
```sql
SELECT
    TransactionGroup,
    TotalIn,
    TotalOut,
    NetAmount,
    TransactionCount
FROM vw_TransactionSummaryByGroup
ORDER BY TransactionGroup;
```

### Author Performance
```sql
SELECT
    AuthorName,
    BookCount,
    TotalSales,
    TotalRoyalties
FROM vw_AuthorPerformance
ORDER BY TotalSales DESC;
```

### Book Profitability
```sql
SELECT
    Title,
    Author,
    TotalSales,
    ProductionCosts,
    GrossProfit,
    ProfitMargin
FROM vw_BookProfitability
ORDER BY GrossProfit DESC;
```

## Financial Statements

### Trial Balance
```sql
SELECT
    AccountCode,
    AccountName,
    DebitBalance,
    CreditBalance
FROM TrialBalance
ORDER BY AccountCode;
```

### Profit & Loss
```sql
SELECT
    AccountType,
    AccountName,
    Amount
FROM ProfitAndLoss
ORDER BY AccountType, Amount DESC;
```

### Balance Sheet
```sql
SELECT
    AccountType,
    AccountSubType,
    AccountName,
    Amount
FROM BalanceSheet
ORDER BY AccountType, AccountSubType, Amount DESC;
```

## VAT and Compliance

### VAT Return Calculation
```sql
-- Calculate VAT for quarter ending 31 March 2024
EXEC sp_CalculateVATReturn '2024-01-01', '2024-03-31';
```

### Check VAT Rates
```sql
SELECT
    VATCode,
    Rate,
    Description,
    EffectiveFrom,
    EffectiveTo
FROM VATRates
WHERE IsActive = 1
ORDER BY VATCode;
```

## Bank Reconciliation

### View Unreconciled Transactions
```sql
SELECT
    TransactionDate,
    Description,
    Amount,
    ReconciliationStatus
FROM vw_BankReconciliation
WHERE ReconciliationStatus = 'Pending'
ORDER BY TransactionDate;
```

### Mark Transaction as Reconciled
```sql
UPDATE Transactions
SET ReconciliationStatus = 'Reconciled'
WHERE TransactionID = [TransactionID];
```

## Common Troubleshooting

### Check for Unbalanced Transactions
```sql
SELECT
    t.TransactionID,
    t.Description,
    SUM(tl.DebitAmount) as TotalDebits,
    SUM(tl.CreditAmount) as TotalCredits,
    SUM(tl.DebitAmount) - SUM(tl.CreditAmount) as Difference
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
GROUP BY t.TransactionID, t.Description
HAVING SUM(tl.DebitAmount) != SUM(tl.CreditAmount);
```

### View Audit Log
```sql
SELECT TOP 50
    EventDate,
    EventType,
    TableName,
    UserName,
    Description
FROM AuditLog
ORDER BY EventDate DESC;
```

### Find Transactions by Reference
```sql
SELECT
    TransactionDate,
    Description,
    Reference,
    TransactionGroup
FROM vw_BankRunningBalance
WHERE Reference LIKE '%[search term]%'
ORDER BY TransactionDate DESC;
```

## Data Entry Best Practices

### Transaction Descriptions
- **Good**: "Book sales - Amazon UK - July 2024"
- **Poor**: "Amazon payment"

### References
- Use bank reference numbers when available
- Include invoice numbers for sales
- Add purchase order numbers for expenses

### Transaction Groups
- **Revenue**: All income (book sales, advances, licensing)
- **Admin**: Overhead costs (rent, utilities, insurance)
- **Marketing**: Customer-facing expenses (ads, promotions)
- **Publishing**: Direct publishing costs (editing, design, printing)
- **Research**: Future-focused investments
- **General**: Only when other categories don't fit

### Date Guidelines
- Use actual bank transaction date for BankDate
- Use invoice/bill date for TransactionDate
- Keep dates within reasonable range (no future dates)

## Month-End Checklist

1. **Import all bank transactions**
   ```sql
   -- Check for missing transactions
   SELECT * FROM vw_BankRunningBalance
   WHERE BankDate >= '2024-XX-01' AND BankDate <= '2024-XX-31'
   ORDER BY BankDate;
   ```

2. **Reconcile bank statement**
   ```sql
   -- Compare with bank statement
   SELECT * FROM vw_BankReconciliation
   WHERE ReconciliationStatus = 'Pending';
   ```

3. **Review categorization**
   ```sql
   -- Check for General category usage
   SELECT * FROM vw_TransactionSummaryByGroup
   WHERE TransactionGroup = 'General';
   ```

4. **Generate reports**
   - Monthly summary
   - Transaction summary by group
   - Author performance (if applicable)

5. **VAT preparation (quarterly)**
   ```sql
   EXEC sp_CalculateVATReturn '2024-XX-01', '2024-XX-31';
   ```

## Emergency Procedures

### Backup Before Changes
```sql
-- Always backup before major changes
BACKUP DATABASE rhubarbpressdb TO DISK = 'C:\Backup\rhubarbpressdb_backup.bak';
```

### Restore Transaction if Error
```sql
-- If transaction was entered incorrectly, mark as cancelled
-- DO NOT DELETE - maintain audit trail
UPDATE Transactions
SET Description = Description + ' [CANCELLED - corrected in TX#XXXX]'
WHERE TransactionID = [incorrect_transaction_id];
```

### Contact Support
- Database issues: Check error log first
- Business logic questions: Review this guide
- System performance: Monitor transaction counts and dates

---

**Quick Reference Version**: 1.0
**Last Updated**: September 2024
**For**: Daily Users and Bookkeepers
**Next Review**: December 2024