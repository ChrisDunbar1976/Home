Given your Claude Code experience and database background, creating your own accounting software for Rhubarb Press is definitely feasible and could be a smart business decision. Here's what would be involved:
Core Requirements for UK Publishing
Essential Features:

Double-entry bookkeeping system
VAT calculations and MTD (Making Tax Digital) compliance
Corporation Tax calculations
Author royalty tracking and payments
Invoice generation and tracking
Expense categorization (editing, printing, marketing, etc.)
Bank reconciliation
Profit & Loss and Balance Sheet generation

Technical Architecture
Database Design:
- accounts (chart of accounts)
- transactions (double-entry records)
- contacts (authors, suppliers, customers)
- invoices/bills
- vat_rates
- royalty_schemes
- book_sales_tracking
Technology Stack Options:

Backend: Node.js/Express, Python/Django, or .NET Core
Database: PostgreSQL (excellent for financial data integrity)
Frontend: React/Next.js or Vue.js
API Integration: Open Banking APIs for bank feeds
PDF Generation: For invoices, royalty statements, reports

UK-Specific Compliance Requirements
Making Tax Digital (MTD):

HMRC API integration for VAT submissions
Digital record keeping requirements
Audit trail maintenance

Corporation Tax:

CT600 form data preparation
Capital allowances calculations
R&D tax relief tracking (potentially relevant for publishing)

Development Scope Estimate
MVP (3-4 weeks with Claude Code):

Basic double-entry system
Invoice generation
Expense tracking
Simple reporting
Bank import (CSV)

Full System (8-12 weeks):

MTD compliance
Advanced reporting
Author royalty automation
Open Banking integration
Multi-company support

Advantages for Your Publishing Business
Financial Benefits:

No ongoing subscription fees (£240-360/year saved)
Tailor-made for publishing workflows
Author royalty automation
Book-specific profit tracking

Business Intelligence:

Track profitability per book/author
Genre performance analysis
Seasonal sales patterns
Marketing ROI tracking

Competitive Advantage:

Could become a product to sell to other small publishers
Deep integration with your publishing workflow
Custom reporting for industry needs

Key Challenges
Compliance Complexity:

HMRC regulations change frequently
VAT rules can be complex
Audit requirements
Data backup and security obligations

Time Investment:

Initial development time
Ongoing maintenance
Testing and validation
Documentation

Recommended Approach
Phase 1 (Immediate):
Use existing software (FreeAgent/Xero) to get started and understand your exact requirements
Phase 2 (Month 6-12):
Build custom system with these priorities:

Author royalty automation
Book profitability tracking
Publishing-specific expense categories
Custom reporting for your industry

Phase 3 (Year 2+):
Add advanced features and potentially package as SaaS for other indie publishers
ROI Analysis
Development Cost: ~40-60 hours @ your rate
Annual Savings: £240-360 in subscription fees
Business Value: Proprietary system that grows with your business
Potential Revenue: Could license to other small publishers
Given your technical skills and the publishing industry's specific needs (author royalties, book profitability, industry-specific reporting), this could be an excellent project that pays for itself quickly while giving you a competitive advantage.
Would you like me to elaborate on any specific technical aspects or help you plan the development phases?RetryCDI would use Microsoft SQL Server.EditExcellent choice! SQL Server is perfect for financial applications with its strong ACID compliance, excellent transaction handling, and robust security features. Here's how to approach building your publishing accounting system:
SQL Server Advantages for Accounting
Financial Data Integrity:

Native support for MONEY and DECIMAL data types
Row-level locking for concurrent transactions
Built-in backup and point-in-time recovery
Transparent Data Encryption (TDE) for compliance

Business Intelligence:

SQL Server Reporting Services (SSRS) for financial reports
Integration Services (SSIS) for bank file imports
Analysis Services (SSAS) for business intelligence
Power BI integration for dashboards

Core Database Schema Design
Chart of Accounts:
sqlCREATE TABLE ChartOfAccounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountCode NVARCHAR(20) NOT NULL UNIQUE,
    AccountName NVARCHAR(100) NOT NULL,
    AccountType NVARCHAR(20) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    ParentAccountID INT NULL,
    IsActive BIT DEFAULT 1,
    VATCode NVARCHAR(10) NULL
);
Double-Entry Transactions:
sqlCREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionDate DATE NOT NULL,
    Reference NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NOT NULL,
    TotalAmount MONEY NOT NULL,
    VATAmount MONEY DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) NOT NULL
);

CREATE TABLE TransactionLines (
    LineID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT NOT NULL,
    AccountID INT NOT NULL,
    DebitAmount MONEY DEFAULT 0,
    CreditAmount MONEY DEFAULT 0,
    Description NVARCHAR(255) NULL,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
    FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID),
    CONSTRAINT CK_DebitOrCredit CHECK ((DebitAmount > 0 AND CreditAmount = 0) OR (CreditAmount > 0 AND DebitAmount = 0))
);
Publishing-Specific Tables:
sqlCREATE TABLE Authors (
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    AuthorName NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(100),
    RoyaltyRate DECIMAL(5,4) NOT NULL, -- e.g., 0.4000 for 40%
    PaymentTerms NVARCHAR(50),
    TaxStatus NVARCHAR(20) -- Employee, Self-Employed, Company
);

CREATE TABLE Books (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    ISBN NVARCHAR(17) NOT NULL UNIQUE,
    Title NVARCHAR(255) NOT NULL,
    AuthorID INT NOT NULL,
    PublicationDate DATE,
    ProductionCosts MONEY DEFAULT 0,
    MarketingSpend MONEY DEFAULT 0,
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);

CREATE TABLE BookSales (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Channel NVARCHAR(50) NOT NULL, -- Amazon, Waterstones, Direct, etc.
    QuantitySold INT NOT NULL,
    GrossRevenue MONEY NOT NULL,
    NetRevenue MONEY NOT NULL,
    RoyaltyDue MONEY NOT NULL,
    TransactionID INT NULL, -- Link to accounting transaction
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);
UK-Specific Compliance Features
VAT Handling:
sqlCREATE TABLE VATRates (
    VATRateID INT IDENTITY(1,1) PRIMARY KEY,
    VATCode NVARCHAR(10) NOT NULL UNIQUE,
    Rate DECIMAL(5,4) NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE NULL
);

-- Books are typically zero-rated in UK
INSERT INTO VATRates (VATCode, Rate, Description, EffectiveFrom)
VALUES ('ZR', 0.0000, 'Zero Rate (Books)', '2023-01-01'),
       ('ST', 0.2000, 'Standard Rate', '2023-01-01');
MTD Compliance:
sqlCREATE TABLE VATReturns (
    ReturnID INT IDENTITY(1,1) PRIMARY KEY,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    Box1_VATDue MONEY NOT NULL,
    Box2_VATDueAcquisitions MONEY NOT NULL,
    Box3_TotalVATDue MONEY NOT NULL,
    Box4_VATReclaimed MONEY NOT NULL,
    Box5_NetVATDue MONEY NOT NULL,
    Box6_NetSales MONEY NOT NULL,
    Box7_NetPurchases MONEY NOT NULL,
    Box8_GoodsSuppliedEU MONEY NOT NULL,
    Box9_GoodsAcquiredEU MONEY NOT NULL,
    SubmittedDate DATETIME2 NULL,
    HMRCReference NVARCHAR(50) NULL
);
Business Intelligence Views
Book Profitability:
sqlCREATE VIEW BookProfitability AS
SELECT 
    b.BookID,
    b.Title,
    a.AuthorName,
    SUM(bs.NetRevenue) as TotalRevenue,
    SUM(bs.RoyaltyDue) as TotalRoyalties,
    b.ProductionCosts,
    b.MarketingSpend,
    SUM(bs.NetRevenue) - SUM(bs.RoyaltyDue) - b.ProductionCosts - b.MarketingSpend as NetProfit
FROM Books b
INNER JOIN Authors a ON b.AuthorID = a.AuthorID
LEFT JOIN BookSales bs ON b.BookID = bs.BookID
GROUP BY b.BookID, b.Title, a.AuthorName, b.ProductionCosts, b.MarketingSpend;
Development Stack Recommendations
Backend Options:

ASP.NET Core (native SQL Server integration)
Node.js with mssql package (if you prefer JavaScript)
Python with pyodbc/SQLAlchemy (excellent for data processing)

Key SQL Server Features to Leverage:

Stored Procedures for complex financial calculations
Triggers for audit trails and business rule enforcement
SQL Server Agent for automated royalty calculations
Filestream for storing receipt images
Full-Text Search for transaction searching

Financial Controls & Audit Trail
Audit Table Pattern:
sqlCREATE TABLE TransactionAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT NOT NULL,
    Action NVARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(50) NOT NULL,
    ChangedDate DATETIME2 DEFAULT GETDATE()
);
Recommended Development Phases
Phase 1 (Core Accounting):

Chart of accounts setup
Basic transaction entry
Trial balance generation
Simple P&L and Balance Sheet

Phase 2 (Publishing Features):

Author and book management
Royalty calculations
Sales tracking and reporting
Book profitability analysis

Phase 3 (Compliance):

VAT return preparation
Corporation Tax calculations
MTD API integration
Advanced reporting

Phase 4 (Automation):

Bank feed integration
Automated royalty processing
Email notifications
Dashboard and KPIs

SQL Server Licensing Considerations
For a small publishing business:

SQL Server Express (free, up to 10GB) might suffice initially
SQL Server Standard if you need advanced features
Azure SQL Database for cloud hosting and automatic backups

This approach gives you a robust, scalable system that can grow with Rhubarb Press and potentially become a product for other indie publishers. The strong typing and transaction support in SQL Server makes it ideal for financial applications.
Would you like me to detail any specific aspect, such as the royalty calculation procedures or MTD integration?