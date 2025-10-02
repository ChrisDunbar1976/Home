# Azure SQL Database MCP Connection Configuration (VM)

## Overview
This document describes the configuration of the MSSQL MCP server to connect to the Azure SQL Database for the Rhubarb Press project from the Windows VM.

## Date
2025-10-01

## Database Details
- **Server Name**: `rhubarbpress-sqlsrv.database.windows.net`
- **Database Name**: `rhubarbpressdb`
- **Username**: `mcp_user`
- **Authentication Method**: SQL Server Authentication

## Configuration File Location
`C:\Users\cdunbar\.claude.json`

## Configuration Applied

The following configuration was added to the `mcpServers` section:

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
    "USER_NAME": "mcp_user",
    "PASSWORD": "Sc0tsCup2!May!994!",
    "READONLY": "false"
  }
}
```

## Configuration Settings Explanation

- **SERVER_NAME**: Full Azure SQL Server endpoint
- **DATABASE_NAME**: Target database name
- **USER_NAME**: SQL authentication username (mcp_user)
- **PASSWORD**: SQL authentication password
- **READONLY**: Set to `"false"` to allow INSERT, UPDATE, DELETE operations

## Next Steps

### 1. Restart Claude Code
For the configuration changes to take effect:
- Exit current Claude Code session (type `exit` or press Ctrl+D)
- Start new session with `claude`
- Note: VS Code does not need to be restarted

### 2. Test Connection
After restarting, try these test queries:
- "Show me all tables in rhubarbpressdb"
- "Describe the structure of the database"
- "List all tables with their row counts"

## Security Considerations

- **Password Storage**: Password is stored in plain text in `.claude.json`
- Ensure `.claude.json` has appropriate file permissions
- Do not commit `.claude.json` to version control
- **READONLY Mode**: Currently set to `false` (allows writes)
- To enable read-only mode for safer exploration, change `READONLY` to `"true"`

## Firewall Configuration

Ensure that:
- Azure SQL Server firewall rules allow connections from the VM's IP address
- You can test connectivity using Azure Data Studio or SSMS before using the MCP server

## Troubleshooting

### Connection Issues
1. Verify Azure SQL firewall rules include the VM's IP address
2. Test connection using Azure Data Studio or SSMS first
3. Confirm server name and database name are correct
4. Verify mcp_user has appropriate permissions on the database

### Authentication Issues
- Ensure mcp_user account is created and active
- Verify password is correct
- Check that SQL Server authentication is enabled on Azure SQL Server
- Confirm user has CONNECT permission to the database

## Related Documentation
- Previous configuration: `Installations/rhubarbpressdb connection.md` (uses Azure AD authentication)
- MSSQL MCP Documentation: `MCPs/mssql-info.md`
- GitHub: https://github.com/Azure-Samples/SQL-AI-samples
- Microsoft Blog: https://devblogs.microsoft.com/azure-sql/introducing-mssql-mcp-server/
