# rhubarbpressdb VM Connection Validation

**Completed:** 2025-10-03 15:46 (+00:00)

## Setup
- Tool: `C:\Program Files\SqlCmd\sqlcmd.exe` invoked via PowerShell.
- Connection: `tcp:rhubarbpress-sqlsrv.database.windows.net,1433` targeting `rhubarbpressdb` with SQL auth user `mcp_user`.
- Network: harness escalated once for outbound SQL traffic.

## Validation Query
```sql
SELECT TOP (5) name FROM sys.tables ORDER BY name;
```
- Result: AuditLog, Authors, BankBalance, BankBalanceHistory, BookCategories (5 rows).

## Notes
- Confirms credentials now accepted and TLS negotiation succeeds.
- Ready for further scripted validation or deployments from this VM using `sqlcmd`.
