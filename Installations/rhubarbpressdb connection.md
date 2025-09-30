# Azure SQL Database Connection Configuration

## Overview
This document describes the successful configuration of the MSSQL MCP server to connect to the Azure SQL Database for the Rhubarb Press project.

## Database Details
- **Server Name**: `rhubarbpress-sqlsrv.database.windows.net`
- **Database Name**: `rhubarbpressdb`
- **Username**: `christopherjohndunbar@hotmail.com` (Azure AD authentication)
- **Authentication Method**: Azure AD / Windows Authentication

## Configuration Update

### File Location
`C:\Users\cdunbar\.claude.json`

### Configuration Applied
```json
"mssql": {
  "type": "stdio",
  "command": "node",
  "args": [
    "C:\\Users\\cdunbar\\Documents\\Projects\\SQL-AI-samples\\MssqlMcp\\Node\\dist\\index.js"
  ],
  "env": {
    "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
    "DATABASE_NAME": "rhubarbpressdb",
    "READONLY": "false"
  }
}
```

### Settings Explanation
- **SERVER_NAME**: Full Azure SQL Server endpoint
- **DATABASE_NAME**: Target database name
- **READONLY**: Set to `"false"` to allow INSERT, UPDATE, DELETE operations

## Next Steps

### 1. Restart Claude Code
For the configuration changes to take effect, restart Claude Code.

### 2. Test Connection
Try these example queries:
- "Show me all tables in rhubarbpressdb"
- "Describe the structure of the database"
- "How many records are in each table?"
- "List all stored procedures"

### 3. Authentication
The MCP server will use Azure AD authentication automatically when you're logged into Azure on this machine with the account `christopherjohndunbar@hotmail.com`.

## Firewall Configuration
Ensure that:
- Azure SQL Server firewall rules allow connections from your current IP address
- You can test connectivity using Azure Data Studio or SSMS before using the MCP server

## Security Considerations
- **READONLY mode**: Currently set to `false` (allows writes)
- To enable read-only mode for safer exploration, change `READONLY` to `"true"`
- Database operations are logged and can be audited through Azure SQL audit logs

## Related Tags (from Azure DB Server)
- **Cost Centre**: Accounting
- **Environment**: Production
- **Owner**: Chris
- **Project**: RhubarbPress

## Troubleshooting

### Connection Issues
1. Verify Azure SQL firewall rules include your IP
2. Confirm you're logged into Azure with correct credentials
3. Test connection using Azure Data Studio first
4. Check that the server name and database name are correct

### Authentication Issues
- Ensure Azure AD authentication is enabled on the SQL Server
- Verify your Microsoft account has appropriate database permissions
- Check if Multi-Factor Authentication (MFA) is required

## Additional Information
For complete MSSQL MCP installation and usage details, see:
- `MCPs\mssql-info.md` - Full MCP server documentation
- GitHub: https://github.com/Azure-Samples/SQL-AI-samples
- Microsoft Blog: https://devblogs.microsoft.com/azure-sql/introducing-mssql-mcp-server/

## Configuration Date
2025-09-30