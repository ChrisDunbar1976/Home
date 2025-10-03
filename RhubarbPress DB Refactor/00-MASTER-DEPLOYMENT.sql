-- =============================================
-- RhubarbPress DB - MASTER DEPLOYMENT SCRIPT
-- Complete database rebuild from scratch
-- =============================================
-- Target: Azure SQL Database (rhubarbpressdb)
-- Version: 1.0
-- Date: 2025-01-03
--
-- INSTRUCTIONS:
-- 1. Connect to rhubarbpressdb in Azure Data Studio or SSMS
-- 2. Execute this entire script
-- 3. Deployment takes approximately 2-3 minutes
-- =============================================

USE rhubarbpressdb;
GO

PRINT '';
PRINT '==========================================================';
PRINT 'RhubarbPress DB - Master Deployment Script';
PRINT 'Version: 1.0';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '==========================================================';
PRINT '';
GO

-- =============================================
-- STEP 1: DROP ALL EXISTING OBJECTS
-- =============================================
PRINT 'STEP 1: Dropping all existing objects...';
PRINT '';
GO

-- Drop Views
PRINT 'Dropping views...';
GO

IF OBJECT_ID('vw_CashFlowSummary', 'V') IS NOT NULL DROP VIEW vw_CashFlowSummary;
IF OBJECT_ID('vw_TransactionGroupAnalysis', 'V') IS NOT NULL DROP VIEW vw_TransactionGroupAnalysis;
IF OBJECT_ID('vw_TransactionDetails', 'V') IS NOT NULL DROP VIEW vw_TransactionDetails;
IF OBJECT_ID('vw_TransactionSummaryByGroup', 'V') IS NOT NULL DROP VIEW vw_TransactionSummaryByGroup;
IF OBJECT_ID('vw_BankReconciliation', 'V') IS NOT NULL DROP VIEW vw_BankReconciliation;
IF OBJECT_ID('vw_MonthlySummary', 'V') IS NOT NULL DROP VIEW vw_MonthlySummary;
IF OBJECT_ID('vw_BankRunningBalance', 'V') IS NOT NULL DROP VIEW vw_BankRunningBalance;
IF OBJECT_ID('vw_CurrentBankBalances', 'V') IS NOT NULL DROP VIEW vw_CurrentBankBalances;
IF OBJECT_ID('vw_BankBalanceAuditTrail', 'V') IS NOT NULL DROP VIEW vw_BankBalanceAuditTrail;
IF OBJECT_ID('vw_TrialBalance', 'V') IS NOT NULL DROP VIEW vw_TrialBalance;
IF OBJECT_ID('vw_AccountBalances', 'V') IS NOT NULL DROP VIEW vw_AccountBalances;
IF OBJECT_ID('vw_AuthorPerformance', 'V') IS NOT NULL DROP VIEW vw_AuthorPerformance;
IF OBJECT_ID('vw_BookProfitability', 'V') IS NOT NULL DROP VIEW vw_BookProfitability;
IF OBJECT_ID('BalanceSheet', 'V') IS NOT NULL DROP VIEW BalanceSheet;
IF OBJECT_ID('ProfitAndLoss', 'V') IS NOT NULL DROP VIEW ProfitAndLoss;
IF OBJECT_ID('TrialBalance', 'V') IS NOT NULL DROP VIEW TrialBalance;
GO

PRINT 'Views dropped.';
GO

-- Drop Stored Procedures
PRINT 'Dropping stored procedures...';
GO

IF OBJECT_ID('sp_BulkImportBankTransactions', 'P') IS NOT NULL DROP PROCEDURE sp_BulkImportBankTransactions;
IF OBJECT_ID('sp_SetupBankImportAccounts', 'P') IS NOT NULL DROP PROCEDURE sp_SetupBankImportAccounts;
IF OBJECT_ID('sp_DashboardSummary', 'P') IS NOT NULL DROP PROCEDURE sp_DashboardSummary;
IF OBJECT_ID('sp_GenerateTrialBalance', 'P') IS NOT NULL DROP PROCEDURE sp_GenerateTrialBalance;
IF OBJECT_ID('sp_BookProfitabilityReport', 'P') IS NOT NULL DROP PROCEDURE sp_BookProfitabilityReport;
IF OBJECT_ID('sp_CalculateAuthorRoyalties', 'P') IS NOT NULL DROP PROCEDURE sp_CalculateAuthorRoyalties;
IF OBJECT_ID('sp_ProcessBookSales', 'P') IS NOT NULL DROP PROCEDURE sp_ProcessBookSales;
IF OBJECT_ID('sp_CreateInvoice', 'P') IS NOT NULL DROP PROCEDURE sp_CreateInvoice;
IF OBJECT_ID('sp_CreateJournalEntry', 'P') IS NOT NULL DROP PROCEDURE sp_CreateJournalEntry;
IF OBJECT_ID('sp_ImportBankTransaction_v2', 'P') IS NOT NULL DROP PROCEDURE sp_ImportBankTransaction_v2;
IF OBJECT_ID('sp_ImportBankTransaction_Legacy', 'P') IS NOT NULL DROP PROCEDURE sp_ImportBankTransaction_Legacy;
IF OBJECT_ID('sp_ImportBankTransaction', 'P') IS NOT NULL DROP PROCEDURE sp_ImportBankTransaction;
IF OBJECT_ID('sp_GetTransactionGroupID', 'P') IS NOT NULL DROP PROCEDURE sp_GetTransactionGroupID;
IF OBJECT_ID('sp_UpdateBankBalance', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateBankBalance;
IF OBJECT_ID('sp_InitializeBankBalance', 'P') IS NOT NULL DROP PROCEDURE sp_InitializeBankBalance;
IF OBJECT_ID('sp_CalculateVATReturn', 'P') IS NOT NULL DROP PROCEDURE sp_CalculateVATReturn;
GO

PRINT 'Stored procedures dropped.';
GO

-- Drop Triggers
PRINT 'Dropping triggers...';
GO

IF OBJECT_ID('tr_TransactionLines_UpdateBankBalance', 'TR') IS NOT NULL DROP TRIGGER tr_TransactionLines_UpdateBankBalance;
IF OBJECT_ID('TR_Transactions_Audit', 'TR') IS NOT NULL DROP TRIGGER TR_Transactions_Audit;
GO

PRINT 'Triggers dropped.';
GO

-- Drop Tables (in correct order due to foreign keys)
PRINT 'Dropping tables...';
GO

IF OBJECT_ID('VATTransactionMapping', 'U') IS NOT NULL DROP TABLE VATTransactionMapping;
IF OBJECT_ID('ComplianceDocuments', 'U') IS NOT NULL DROP TABLE ComplianceDocuments;
IF OBJECT_ID('CapitalAllowances', 'U') IS NOT NULL DROP TABLE CapitalAllowances;
IF OBJECT_ID('CorporationTaxCalculations', 'U') IS NOT NULL DROP TABLE CorporationTaxCalculations;
IF OBJECT_ID('VATReturns', 'U') IS NOT NULL DROP TABLE VATReturns;
IF OBJECT_ID('VATRates', 'U') IS NOT NULL DROP TABLE VATRates;
IF OBJECT_ID('BankBalanceHistory', 'U') IS NOT NULL DROP TABLE BankBalanceHistory;
IF OBJECT_ID('BankBalance', 'U') IS NOT NULL DROP TABLE BankBalance;
IF OBJECT_ID('RoyaltyCalculationDetails', 'U') IS NOT NULL DROP TABLE RoyaltyCalculationDetails;
IF OBJECT_ID('RoyaltyCalculations', 'U') IS NOT NULL DROP TABLE RoyaltyCalculations;
IF OBJECT_ID('ProductionCosts', 'U') IS NOT NULL DROP TABLE ProductionCosts;
IF OBJECT_ID('BookSales', 'U') IS NOT NULL DROP TABLE BookSales;
IF OBJECT_ID('SalesChannels', 'U') IS NOT NULL DROP TABLE SalesChannels;
IF OBJECT_ID('Books', 'U') IS NOT NULL DROP TABLE Books;
IF OBJECT_ID('BookCategories', 'U') IS NOT NULL DROP TABLE BookCategories;
IF OBJECT_ID('Authors', 'U') IS NOT NULL DROP TABLE Authors;
IF OBJECT_ID('InvoiceLines', 'U') IS NOT NULL DROP TABLE InvoiceLines;
IF OBJECT_ID('Invoices', 'U') IS NOT NULL DROP TABLE Invoices;
IF OBJECT_ID('TransactionLines', 'U') IS NOT NULL DROP TABLE TransactionLines;
IF OBJECT_ID('TransactionGroup', 'U') IS NOT NULL DROP TABLE TransactionGroup;
IF OBJECT_ID('Transactions', 'U') IS NOT NULL DROP TABLE Transactions;
IF OBJECT_ID('AuditLog', 'U') IS NOT NULL DROP TABLE AuditLog;
IF OBJECT_ID('Contacts', 'U') IS NOT NULL DROP TABLE Contacts;
IF OBJECT_ID('ChartOfAccounts', 'U') IS NOT NULL DROP TABLE ChartOfAccounts;
GO

PRINT 'Tables dropped.';
GO

PRINT '';
PRINT 'STEP 1 COMPLETE: All existing objects dropped successfully.';
PRINT '';
PRINT 'IMPORTANT: The following scripts will now be executed in sequence:';
PRINT '  01-Core-Schema.sql';
PRINT '  02-Publishing-Schema.sql';
PRINT '  03-UK-Compliance.sql';
PRINT '  04-Initial-Data-Setup.sql';
PRINT '  05-Bank-Balance-System.sql';
PRINT '  06-Transaction-Groups-System.sql';
PRINT '  07-Enhanced-Views.sql';
PRINT '  08-Publishing-Business-Procedures.sql';
PRINT '  09-Test-Transaction-Data.sql';
PRINT '';
PRINT 'Please execute each script manually in sequence, OR';
PRINT 'Concatenate all scripts and execute them after this master script.';
PRINT '';
PRINT '==========================================================';
GO
