# RhubarbPressDB Connection - Windows Setup

**Date:** Thu, Oct 2, 2025 2:53 PM BST

## Overview
Configuration of MSSQL MCP server to connect to local SQL Server instance on Windows machine.

## Connection Details
- **Server Name:** DESKTOP-6O4GMJP
- **Database:** master
- **Authentication:** Windows Authentication (Trusted Connection)

## Configuration Steps

### 1. Located Claude Desktop Config File
Path: `C:\Users\Chris Dunbar\AppData\Roaming\Claude\claude_desktop_config.json`

### 2. Added MSSQL MCP Server Configuration
Updated the `mcpServers` section in `claude_desktop_config.json`:

```json
"MSSQL-MCP": {
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-mssql"
  ],
  "env": {
    "MSSQL_SERVER": "DESKTOP-6O4GMJP",
    "MSSQL_DATABASE": "master",
    "MSSQL_TRUSTED_CONNECTION": "true"
  }
}
```

### 3. Restart Required
Claude Code must be restarted for the configuration changes to take effect.

## Next Steps

1. **Restart Claude Code** - Close and reopen the application to load the new configuration
2. **Test Connection** - Use `mcp__MSSQL-MCP__list_table` to verify connection to DESKTOP-6O4GMJP
3. **Switch to RhubarbPressDB** - Once connected, update the configuration to use the RhubarbPressDB database instead of master
4. **Verify Access** - Test querying tables in the RhubarbPressDB database
5. **Set Permissions** - Configure any necessary tool permissions in Claude Code settings if prompted

## Notes
- The configuration file is located in AppData and is **not** part of any Git repository
- Uses Windows Authentication (no username/password required)
- The MCP server is installed via npx, so no local installation is needed
- Available MCP tools after configuration:
  - `mcp__MSSQL-MCP__list_table` - List tables in the database
  - `mcp__MSSQL-MCP__read_data` - Execute SELECT queries
  - `mcp__MSSQL-MCP__describe_table` - Describe table schema
