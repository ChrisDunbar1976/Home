# Rhubarb Press Accounting System - Technical Reference

## Database Schema Reference

### Table Relationships and Dependencies

```
ChartOfAccounts (Core)
├── TransactionLines (Many-to-One)
├── BankBalance (One-to-One for bank accounts)
└── Authors.ContactID → Contacts.ContactID

Transactions (Core)
├── TransactionLines (One-to-Many)
├── TransactionGroup (Many-to-One)
├── BankBalance.LastTransactionID (One-to-Many)
└── AuditLog (One-to-Many)

Authors (Publishing)
├── Contacts (Many-to-One)
├── Books (One-to-Many)
└── RoyaltyCalculations (One-to-Many)

Books (Publishing)
├── Authors (Many-to-One)
├── BookCategories (Many-to-One)
├── BookSales (One-to-Many)
└── ProductionCosts (One-to-Many)
```

## Stored Procedures Reference

### Bank Balance Management

#### `sp_InitializeBankBalance`
**Purpose**: Initialize bank account opening balance
**Parameters**:
- `@AccountCode` (NVARCHAR(20)) - Bank account code (typically '1001')
- `@OpeningBalance` (MONEY) - Opening balance amount
- `@EffectiveDate` (DATE) - Date from which balance is effective

**Usage**:
```sql
EXEC sp_InitializeBankBalance '1001', 10000.00, '2024-01-01';
```

#### `sp_ImportBankTransaction_v2`
**Purpose**: Import bank transactions with transaction group categorization
**Parameters**:
- `@ActualDate` (DATE) - Transaction date
- `@Description` (NVARCHAR(255)) - Transaction description
- `@TransactionGroupID` (INT) - Category ID (1-6)
- `@AmountIn` (MONEY, Optional) - Money received
- `@AmountOut` (MONEY, Optional) - Money paid out
- `@Reference` (NVARCHAR(50), Optional) - Bank reference
- `@CreatedBy` (NVARCHAR(50)) - User importing transaction

**Usage**:
```sql
EXEC sp_ImportBankTransaction_v2
    @ActualDate = '2024-01-15',
    @Description = 'Book sales - Amazon',
    @TransactionGroupID = 5, -- Revenue
    @AmountIn = 1250.00,
    @CreatedBy = 'System';
```

#### `sp_ImportBankTransaction_Legacy`
**Purpose**: Backward-compatible import without transaction groups
**Parameters**:
- `@ActualDate` (DATE) - Transaction date
- `@Description` (NVARCHAR(255)) - Transaction description
- `@AmountIn` (MONEY, Optional) - Money received
- `@AmountOut` (MONEY, Optional) - Money paid out
- `@Reference` (NVARCHAR(50), Optional) - Bank reference
- `@CreatedBy` (NVARCHAR(50)) - User importing transaction

### Utility Procedures

#### `sp_GetTransactionGroupID`
**Purpose**: Helper function to get transaction group ID by name
**Parameters**:
- `@GroupName` (NVARCHAR(50)) - Group name ('Admin', 'Marketing', etc.)
- `@TransactionGroupID` (INT OUTPUT) - Returns the ID

**Usage**:
```sql
DECLARE @GroupID INT;
EXEC sp_GetTransactionGroupID 'Marketing', @GroupID OUTPUT;
```

#### `sp_CalculateVATReturn`
**Purpose**: Calculate VAT return figures for specified period
**Parameters**:
- `@PeriodStart` (DATE) - Start of VAT period
- `@PeriodEnd` (DATE) - End of VAT period

## View Reference

### Financial Reporting Views

#### `vw_BankRunningBalance`
**Purpose**: Bank transactions with running balance calculation
**Key Columns**:
- `TransactionID`, `TransactionDate`, `BankDate`
- `Description`, `TransactionGroup`, `BankMovement`
- `RunningBalance` - Calculated running total
- `ReconciliationStatus` - Matching status

**Usage**:
```sql
SELECT TOP 50 * FROM vw_BankRunningBalance
ORDER BY TransactionDate DESC;
```

#### `vw_TransactionSummaryByGroup`
**Purpose**: Financial summary grouped by transaction categories
**Key Columns**:
- `TransactionGroup`, `TotalIn`, `TotalOut`, `NetAmount`
- `TransactionCount`, `AverageTransaction`

#### `vw_MonthlySummary`
**Purpose**: Monthly financial performance summary
**Key Columns**:
- `Year`, `Month`, `TotalIncome`, `TotalExpenses`
- `NetProfit`, `TransactionCount`

#### `vw_BankReconciliation`
**Purpose**: Bank reconciliation workspace
**Key Columns**:
- `TransactionID`, `BankDate`, `Amount`, `ReconciliationStatus`
- `BookBalance`, `BankBalance`, `Difference`

### Standard Accounting Views

#### `TrialBalance`
**Purpose**: Standard trial balance report
**Key Columns**:
- `AccountCode`, `AccountName`, `AccountType`
- `DebitBalance`, `CreditBalance`

#### `ProfitAndLoss`
**Purpose**: Profit and Loss statement
**Key Columns**:
- `AccountType`, `AccountName`, `Amount`
- Grouped by Revenue and Expense categories

#### `BalanceSheet`
**Purpose**: Balance sheet report
**Key Columns**:
- `AccountType`, `AccountSubType`, `AccountName`, `Amount`
- Grouped by Assets, Liabilities, and Equity

### Publishing-Specific Views

#### `vw_BookProfitability`
**Purpose**: Individual book performance analysis
**Key Columns**:
- `BookID`, `Title`, `Author`, `TotalSales`
- `ProductionCosts`, `GrossProfit`, `ProfitMargin`

#### `vw_AuthorPerformance`
**Purpose**: Author performance and royalty metrics
**Key Columns**:
- `AuthorID`, `AuthorName`, `BookCount`, `TotalSales`
- `TotalRoyalties`, `AverageRoyaltyRate`

## Transaction Group Reference

### Predefined Categories

| ID | Group Name | Purpose | Typical Transactions |
|----|------------|---------|---------------------|
| 1 | Admin | Administrative expenses | Office supplies, utilities, insurance |
| 2 | Marketing | Marketing and promotion | Advertising, social media, book promotion |
| 3 | Publishing | Publishing-specific costs | Editorial services, design, printing |
| 4 | Research | R&D activities | Market research, manuscript development |
| 5 | Revenue | Income transactions | Book sales, licensing, advances |
| 6 | General | Uncategorized | Miscellaneous transactions |

### Usage Guidelines
- **Admin**: Day-to-day business operations, overheads
- **Marketing**: Customer acquisition, brand promotion
- **Publishing**: Direct publishing costs, production
- **Research**: Investment in future publications
- **Revenue**: All income sources
- **General**: Use sparingly, recategorize when possible

## Data Validation Rules

### Chart of Accounts
- `AccountCode`: Unique, 4-digit format recommended
- `AccountType`: Must be Asset, Liability, Equity, Revenue, or Expense
- `VATCode`: Must exist in VATRates table

### Transactions
- Must have at least two TransactionLines
- Debits must equal Credits (enforced by trigger)
- TransactionDate cannot be in future
- Reference field recommended for audit trail

### Authors
- Must have valid ContactID
- RoyaltyRate between 0 and 1 (0-100%)
- MinimumRoyaltyThreshold minimum £1.00

### VAT Compliance
- VATCode must be active for transaction date
- VAT calculations automatically applied
- Zero-rate VAT default for book sales

## Performance Considerations

### Indexing Strategy
- Primary keys: Clustered indexes
- Foreign keys: Non-clustered indexes
- Date columns: Consider partitioning for large datasets
- AccountCode: Unique constraint with covering index

### Query Optimization
- Use views for complex reporting queries
- Avoid SELECT * in production code
- Consider date range filtering for historical data
- Monitor execution plans for view performance

### Maintenance Tasks
- Update statistics monthly
- Rebuild indexes quarterly
- Archive old transactions annually
- Monitor transaction log growth

## Security and Compliance

### Access Control
- Use SQL Server roles for permission management
- Implement row-level security if required
- Audit sensitive table access
- Encrypt sensitive data at rest

### Audit Requirements
- All transactions logged in AuditLog table
- User identification required for all procedures
- Change tracking on critical tables
- Retention period: 7 years (UK requirement)

### Data Protection
- No personal data stored in financial tables
- Author banking details encrypted
- GDPR compliance for contact information
- Regular backup and recovery testing

## Error Handling Patterns

### Standard Error Response
All stored procedures follow this pattern:
```sql
BEGIN TRY
    BEGIN TRANSACTION;

    -- Main procedure logic here

    COMMIT TRANSACTION;
    PRINT 'Operation completed successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'Error: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
```

### Common Error Scenarios
- Duplicate transaction references
- Invalid date ranges
- Missing required relationships
- Balance calculation mismatches
- VAT rate lookup failures

## Integration Points

### Bank Import Format
Expected CSV format for bank transaction import:
```
Date,Description,AmountIn,AmountOut,Reference
2024-01-15,"Book sales - Amazon",1250.00,,REF12345
2024-01-16,"Office rent",,850.00,DD789
```

### External System APIs
- Consider REST API layer for external integrations
- JSON output format for modern applications
- Authentication via SQL Server security
- Rate limiting and error handling

### Reporting Tools
- Power BI: Direct SQL Server connection
- Excel: ODBC connection with predefined queries
- Custom applications: Use views for data access
- Management dashboards: Real-time view queries

---

**Document Version**: 1.0
**Last Updated**: September 2024
**Target Audience**: Database Administrators, Developers
**Maintenance**: Update with schema changes