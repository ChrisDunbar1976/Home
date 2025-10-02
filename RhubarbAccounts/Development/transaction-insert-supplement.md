# Supplemental Bank Transaction Inserts Attempt

- **Timestamp:** 2025-10-01 18:37:55 BST
- **Target:** Azure SQL `rhubarbpressdb`
- **Procedure:** `sp_ImportBankTransaction`
- **Commands Attempted:**
  1. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-26', @BankDate='2025-09-26', @Description='Author Podcast Sponsorship', @Category='Marketing', @AmountIn=0, @AmountOut=450.00, @CreatedBy='Test Data Supplement';`
  2. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-27', @BankDate='2025-09-27', @Description='Bulk Paper Stock Replenishment', @Category='Production', @AmountIn=0, @AmountOut=612.75, @CreatedBy='Test Data Supplement';`
  3. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-28', @BankDate='2025-09-28', @Description='Regional Courier Distribution', @Category='Distribution', @AmountIn=0, @AmountOut=248.40, @CreatedBy='Test Data Supplement';`
  4. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-29', @BankDate='2025-09-29', @Description='Direct Fair Sales Receipts', @Category='Publishing', @AmountIn=1320.00, @AmountOut=0, @CreatedBy='Test Data Supplement';`
  5. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-30', @BankDate='2025-09-30', @Description='Audiobook Licensing Advance', @Category='Royalties', @AmountIn=980.00, @AmountOut=0, @CreatedBy='Test Data Supplement';`
- **Outcome:** Each execution returned `The EXECUTE permission was denied on the object 'sp_ImportBankTransaction', database 'rhubarbpressdb', schema 'dbo'.` No data was inserted.
- **Next Steps:** Grant `EXECUTE` permissions on `dbo.sp_ImportBankTransaction` to `mcp_user` (e.g., `GRANT EXECUTE ON OBJECT::dbo.sp_ImportBankTransaction TO mcp_user;`) or run the commands via a privileged account.

---

- **Timestamp:** 2025-10-01 18:40:22 BST
- **Permission Update:** `GRANT EXECUTE ON OBJECT::dbo.sp_ImportBankTransaction TO mcp_user;`
- **Commands Executed Successfully:** (returned transaction + reference ids)
  1. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-26', @BankDate='2025-09-26', @Description='Author Podcast Sponsorship', @Category='Marketing', @AmountIn=0, @AmountOut=450.00, @CreatedBy='Test Data Supplement';` -> TransactionID 6 (BANK-20250926-821)
  2. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-27', @BankDate='2025-09-27', @Description='Bulk Paper Stock Replenishment', @Category='Production', @AmountIn=0, @AmountOut=612.75, @CreatedBy='Test Data Supplement';` -> TransactionID 7 (BANK-20250927-823)
  3. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-28', @BankDate='2025-09-28', @Description='Regional Courier Distribution', @Category='Distribution', @AmountIn=0, @AmountOut=248.40, @CreatedBy='Test Data Supplement';` -> TransactionID 8 (BANK-20250928-240)
  4. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-29', @BankDate='2025-09-29', @Description='Direct Fair Sales Receipts', @Category='Publishing', @AmountIn=1320.00, @AmountOut=0, @CreatedBy='Test Data Supplement';` -> TransactionID 9 (BANK-20250929-289)
  5. `EXEC sp_ImportBankTransaction @ActualDate='2025-09-30', @BankDate='2025-09-30', @Description='Audiobook Licensing Advance', @Category="Royalties", @AmountIn=980.00, @AmountOut=0, @CreatedBy='Test Data Supplement';` -> TransactionID 10 (BANK-20250930-224)
- **Verification Query:** `SELECT TransactionID, TransactionDate, Description, TotalAmount, TransactionType, CreatedBy FROM Transactions WHERE CreatedBy = 'Test Data Supplement';`
