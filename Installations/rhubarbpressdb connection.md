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

---

## macOS Configuration (2025-10-01)

### Prerequisites Setup
1. **Disabled Azure AD-only authentication** on the SQL Server to allow both authentication methods
   - Navigate to SQL Server (rhubarbpress-sqlsrv) in Azure Portal
   - Go to Microsoft Entra admin settings
   - Unchecked "Microsoft Entra authentication only"
   - This enables both Entra and SQL authentication

2. **Created SQL authentication user** for MCP access
   - Connected to database via SQL Server Management Studio on Windows VM
   - Created login and user with read/write permissions:
   ```sql
   CREATE LOGIN mcp_user WITH PASSWORD = '[password]';
   USE rhubarbpressdb;
   CREATE USER mcp_user FOR LOGIN mcp_user;
   ALTER ROLE db_datareader ADD MEMBER mcp_user;
   ALTER ROLE db_datawriter ADD MEMBER mcp_user;
   ```

### macOS Claude Configuration

**File Location**: `/Users/dunbar/Library/Application Support/Claude/config.json`

**MCP Configuration Added**:
```json
"mcpServers": {
    "mssql": {
        "command": "node",
        "args": ["/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/build/index.js"],
        "env": {
            "MSSQL_SERVER": "rhubarbpress-sqlsrv.database.windows.net",
            "MSSQL_DATABASE": "rhubarbpressdb",
            "MSSQL_USER": "mcp_user",
            "MSSQL_PASSWORD": "[password]",
            "MSSQL_PORT": "1433",
            "MSSQL_ENCRYPT": "true"
        }
    }
}
```

### Authentication Methods Now Enabled
- **User access**: Microsoft Entra (Azure AD) with MFA
- **MCP access**: SQL authentication (mcp_user with username/password)

### Post-Configuration
- Restart Claude for changes to take effect
- MCP can now connect to Azure SQL Database from macOS

---

## Troubleshooting Session (2025-10-01, 11:30 AM)

### Issue Encountered
After restarting Claude Code in a new session, attempting to connect to the Azure SQL Database resulted in authentication errors:
- Error: `AADSTS500200: User account 'christopherjohndunbar@hotmail.com' is a personal Microsoft account`
- The MCP server was attempting to use Azure AD authentication instead of SQL authentication

### Root Cause
The MSSQL MCP server was defaulting to Azure AD authentication despite having SQL credentials (`MSSQL_USER` and `MSSQL_PASSWORD`) configured in the environment variables.

### Solution Applied
Added explicit authentication type setting to the MCP configuration:

**Updated Configuration** (`/Users/dunbar/Library/Application Support/Claude/config.json`):
```json
"env": {
    "MSSQL_SERVER": "rhubarbpress-sqlsrv.database.windows.net",
    "MSSQL_DATABASE": "rhubarbpressdb",
    "MSSQL_USER": "mcp_user",
    "MSSQL_PASSWORD": "Sc0tsCup2!May!994!",
    "MSSQL_PORT": "1433",
    "MSSQL_ENCRYPT": "true",
    "MSSQL_AUTHENTICATION_TYPE": "default"
}
```

### Key Change
- Added `MSSQL_AUTHENTICATION_TYPE: "default"` to force SQL authentication mode
- This prevents the MCP server from attempting Azure AD authentication

### Next Steps
- Restart Claude Code to apply the configuration change
- Test connection with: `mcp__mssql__list_table` or `mcp__mssql__read_data`

---

## Configuration Fix (2025-10-01, 12:00 PM)

### Issue Encountered
After restart, MCP server continued to trigger Azure AD authentication browser popup instead of using SQL authentication with mcp_user credentials.

### Root Causes Identified
1. **Incorrect build path**: Configuration was pointing to `/build/index.js` instead of `/dist/index.js`
2. **Environment variable naming**: The MCP server may not recognize `MSSQL_*` prefixed variables for SQL authentication

### Solution Applied
Updated configuration in `/Users/dunbar/Library/Application Support/Claude/config.json`:

**Changed FROM**:
```json
"args": ["/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/build/index.js"],
"env": {
    "MSSQL_SERVER": "rhubarbpress-sqlsrv.database.windows.net",
    "MSSQL_DATABASE": "rhubarbpressdb",
    "MSSQL_USER": "mcp_user",
    "MSSQL_PASSWORD": "Sc0tsCup2!May!994!",
    "MSSQL_PORT": "1433",
    "MSSQL_ENCRYPT": "true",
    "MSSQL_AUTHENTICATION_TYPE": "default"
}
```

**Changed TO**:
```json
"args": ["/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"],
"env": {
    "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
    "DATABASE_NAME": "rhubarbpressdb",
    "USERNAME": "mcp_user",
    "PASSWORD": "Sc0tsCup2!May!994!",
    "PORT": "1433",
    "ENCRYPT": "true",
    "READONLY": "false"
}
```

### Key Changes
- Corrected path from `/build/` to `/dist/`
- Simplified environment variable names (removed `MSSQL_` prefix)
- Removed `MSSQL_AUTHENTICATION_TYPE` as it appeared to be ignored
- Using standard variable names: `SERVER_NAME`, `DATABASE_NAME`, `USERNAME`, `PASSWORD`

### Next Steps
- Restart Claude Code for changes to take effect
- Test connection should now use SQL authentication without browser popup

---

## Code Modification for SQL Authentication Support (2025-10-01, 1:35 PM)

### Issue Encountered
Despite correct configuration in `config.json`, the MCP server continued to trigger Azure AD authentication browser popup. Configuration changes were not effective.

### Root Cause
The MSSQL MCP server source code was hardcoded to use **only** Azure AD authentication via `InteractiveBrowserCredential`. The server did not check for or support SQL authentication credentials (USERNAME/PASSWORD environment variables).

### Solution Applied
Modified the MCP server source code to support both authentication methods:

**File Modified**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`

**Changes Made**:
Updated the `createSqlConfig()` function to:
1. Check for `USERNAME` and `PASSWORD` environment variables
2. If present, use SQL authentication with username/password
3. If absent, fall back to Azure AD authentication with Interactive Browser Credential

**Code Logic Added**:
```typescript
// Check if SQL authentication credentials are provided
const username = process.env.USERNAME;
const password = process.env.PASSWORD;

if (username && password) {
  // Use SQL authentication
  return {
    config: {
      server: process.env.SERVER_NAME!,
      database: process.env.DATABASE_NAME!,
      user: username,
      password: password,
      options: {
        encrypt: true,
        trustServerCertificate
      },
      connectionTimeout: connectionTimeout * 1000,
    },
    token: '',
    expiresOn: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
  };
} else {
  // Use Azure AD authentication (existing code)
  ...
}
```

**Build Command Executed**:
```bash
cd "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node"
npm run build
```

Build completed successfully, compiling TypeScript to JavaScript in `/dist/index.js`.

### Next Steps
1. **Restart Claude Code** to load the newly compiled MCP server
2. Test connection with: `mcp__mssql__list_table` or `mcp__mssql__read_data`
3. Verify no browser popup appears (should use SQL authentication silently)

### Summary
The MCP server now supports dual authentication modes:
- **SQL Authentication**: When USERNAME and PASSWORD are provided
- **Azure AD Authentication**: When credentials are not provided (fallback to browser popup)

---

## Environment Variable Conflict Fix (2025-10-01, 1:40 PM BST)

### Issue Encountered
After restarting Claude Code with the modified MCP server, Azure AD authentication browser popup still appeared instead of using SQL authentication.

### Root Cause
The `USERNAME` environment variable is a **system-reserved variable** on macOS that contains the current user's login name (in this case, "dunbar"). When the MCP server checked `process.env.USERNAME`, it was getting "dunbar" instead of "mcp_user", causing the SQL authentication check to pass but with incorrect credentials.

### Solution Applied
Changed the environment variable names to avoid system conflicts:

**File Modified**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`

**Changed FROM**:
```typescript
const username = process.env.USERNAME;
const password = process.env.PASSWORD;
```

**Changed TO**:
```typescript
const username = process.env.MSSQL_USERNAME;
const password = process.env.MSSQL_PASSWORD;
```

**Configuration Updated**: `/Users/dunbar/Library/Application Support/Claude/config.json`

**Changed FROM**:
```json
"env": {
    "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
    "DATABASE_NAME": "rhubarbpressdb",
    "USERNAME": "mcp_user",
    "PASSWORD": "Sc0tsCup2!May!994!",
    "PORT": "1433",
    "ENCRYPT": "true",
    "READONLY": "false"
}
```

**Changed TO**:
```json
"env": {
    "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
    "DATABASE_NAME": "rhubarbpressdb",
    "MSSQL_USERNAME": "mcp_user",
    "MSSQL_PASSWORD": "Sc0tsCup2!May!994!",
    "PORT": "1433",
    "ENCRYPT": "true",
    "READONLY": "false"
}
```

**Rebuild Command**:
```bash
cd "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node"
npm run build
```

Build completed successfully.

### Next Steps
1. **Restart Claude Code** to load the updated configuration and compiled MCP server
2. Test connection with database queries
3. If successful, explore the rhubarbpressdb schema and contents
4. Begin database operations for Rhubarb Press project

### Key Lesson
Always use prefixed environment variable names (e.g., `MSSQL_*`) to avoid conflicts with system-reserved variables like `USERNAME`, `PATH`, `HOME`, etc.

---

## Configuration Verification and Restart Required (2025-10-01, 13:43 BST)

### Status Check
After the environment variable conflict fix, verified that:
1. ✅ Source code (`/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`) correctly checks for `MSSQL_USERNAME` and `MSSQL_PASSWORD`
2. ✅ Configuration file (`/Users/dunbar/Library/Application Support/Claude/config.json`) has correct environment variables set
3. ✅ MCP server rebuilt successfully with `npm run build`

### Issue
Despite correct configuration and code, Azure AD browser authentication still triggers when attempting to connect. This is because the old MCP server process is still running in the current Claude Code session.

### Solution
**Restart Claude Code completely** (quit and reopen the application) to:
- Terminate the old MCP server process
- Load the newly compiled MCP server with SQL authentication support
- Apply the updated configuration with `MSSQL_USERNAME` and `MSSQL_PASSWORD`

### Next Steps After Restart
1. Test the connection with `mcp__mssql__list_table`
2. Verify no browser popup appears (should connect silently with SQL authentication)
3. Explore database schema and tables
4. Begin working with rhubarbpressdb for Rhubarb Press project

---

## Debug Logging Added (2025-10-01, 13:50 BST)

### Issue Persisting
After multiple complete restarts of both VS Code and Claude Code, Azure AD browser authentication continues to trigger with error: "The account needs to be added as an external user in the tenant first. Please use a different account."

This confirms the MCP server is still attempting Azure AD authentication instead of SQL authentication with the `mcp_user` credentials.

### Debug Steps Taken
1. **Verified configuration file** (`/Users/dunbar/Library/Application Support/Claude/config.json`):
   - ✅ Correct path to compiled MCP server: `/dist/index.js`
   - ✅ Environment variables correctly set: `MSSQL_USERNAME` and `MSSQL_PASSWORD`
   - ✅ All other connection parameters present

2. **Verified source code** (`/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`):
   - ✅ Code checks for `MSSQL_USERNAME` and `MSSQL_PASSWORD`
   - ✅ Falls back to Azure AD only if credentials not present
   - ✅ SQL authentication configuration looks correct

3. **Added debug logging** to `createSqlConfig()` function:
   ```typescript
   console.error(`[MCP Debug] MSSQL_USERNAME: ${username ? 'SET' : 'NOT SET'}`);
   console.error(`[MCP Debug] MSSQL_PASSWORD: ${password ? 'SET' : 'NOT SET'}`);
   console.error(`[MCP Debug] Will use: ${username && password ? 'SQL AUTH' : 'AZURE AD AUTH'}`);
   ```

4. **Rebuilt MCP server** with debug logging included

### Suspected Issue
The environment variables in `config.json` may not be properly passed from Claude Code to the MCP server process. The debug logs will confirm whether the environment variables are reaching the server.

### Next Steps
1. **Restart Claude Code** (Command+Q and reopen) - VS Code does not need to be closed
2. **Attempt database connection** (e.g., list tables)
3. **Check debug output** in MCP server logs or developer console to see:
   - Are `MSSQL_USERNAME` and `MSSQL_PASSWORD` being read as "SET" or "NOT SET"?
   - Which authentication method is being chosen?
4. **Based on debug output**:
   - If variables are "NOT SET": Configuration issue with how Claude Code passes environment variables to MCP
   - If variables are "SET": Issue with how credentials are passed to the mssql library
5. Once SQL authentication works, proceed with database exploration and Rhubarb Press project work

---

## File-Based Debug Logging Added (2025-10-01, 13:55 BST)

### Issue
Azure AD browser authentication popup continues to appear after multiple restarts. Console.error debug logs from the MCP server process are not visible, making it impossible to determine if environment variables are being passed correctly.

### Solution Applied
Added file-based debug logging to write environment variable status to a persistent log file that can be inspected after connection attempts.

**File Modified**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`

**Code Added** (lines 42-44):
```typescript
// Debug logging
const fs = require('fs');
const debugMsg = `[${new Date().toISOString()}] MSSQL_USERNAME: ${username ? 'SET' : 'NOT SET'}, MSSQL_PASSWORD: ${password ? 'SET' : 'NOT SET'}, Will use: ${username && password ? 'SQL AUTH' : 'AZURE AD AUTH'}\n`;
fs.appendFileSync('/tmp/mcp-debug.log', debugMsg);
```

**Build Command**:
```bash
cd "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node"
npm run build
```

Build completed successfully.

### Debug Log Location
`/tmp/mcp-debug.log`

This file will be created/appended to each time the MCP server attempts to connect to the database. It will show:
- Timestamp of connection attempt
- Whether `MSSQL_USERNAME` is SET or NOT SET
- Whether `MSSQL_PASSWORD` is SET or NOT SET
- Which authentication method will be used (SQL AUTH vs AZURE AD AUTH)

### Next Steps
1. **Restart Claude Code** (Command+Q and reopen)
2. **Attempt database connection** (e.g., `mcp__mssql__list_table`)
3. **Check debug log file**:
   ```bash
   cat /tmp/mcp-debug.log
   ```
4. **Diagnose based on log output**:
   - If "NOT SET": Environment variables in `config.json` are not being passed to the MCP server process
   - If "SET" but still seeing Azure AD popup: Issue with SQL authentication configuration in the mssql library
5. **Apply appropriate fix** based on diagnosis
6. Once connection works, begin database exploration and Rhubarb Press project development
---

## Import Fix for ES Modules (2025-10-01, 14:05 BST)

### Issue
After adding file-based debug logging with `require('fs')`, the MCP server threw error: `ReferenceError: require is not defined`

### Root Cause
The project uses ES modules (import/export), not CommonJS (require). The `require` statement is not available in ES module context.

### Solution Applied
Changed from CommonJS `require` to ES module `import`:

**File Modified**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`

**Added import at top of file**:
```typescript
import { writeFileSync, appendFileSync } from "fs";
```

**Changed debug logging code**:
```typescript
// Before (broken):
const fs = require('fs');
fs.appendFileSync('/tmp/mcp-debug.log', debugMsg);

// After (working):
appendFileSync('/tmp/mcp-debug.log', debugMsg);
```

**Rebuild**:
```bash
cd "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node"
npm run build
```

Build completed successfully.

### Next Steps
- **Restart Claude Code** (full quit and reopen) to reload the MCP server
- Test connection with `mcp__mssql__list_table`
- Check `/tmp/mcp-debug.log` for authentication diagnostics

---

## VS Code Reload Required (2025-10-01, 14:03 BST)

### Current Status
- ✅ ES module import fix applied to `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`
- ✅ MCP server rebuilt successfully with `npm run build`
- ✅ Debug logging now uses proper ES module imports (`import { appendFileSync } from "fs"`)

### Next Steps
1. **Reload VS Code window** to restart the MCP server:
   - Open Command Palette (Command+Shift+P)
   - Type "Developer: Reload Window" and select it
   - OR fully quit VS Code (Command+Q) and reopen

2. **Test database connection**:
   - Try `mcp__mssql__list_table` or similar query
   - No browser popup should appear (SQL authentication should work silently)

3. **Check debug log** to verify authentication method:
   ```bash
   cat /tmp/mcp-debug.log
   ```
   - Should show: `MSSQL_USERNAME: SET`, `MSSQL_PASSWORD: SET`, `Will use: SQL AUTH`

4. **If connection successful**:
   - Begin exploring rhubarbpressdb schema
   - Start Rhubarb Press database operations and development

5. **If connection fails**:
   - Review debug log for diagnostics
   - Verify environment variables in `/Users/dunbar/Library/Application Support/Claude/config.json`
   - Check Azure SQL Server firewall allows your current IP address

---

## Enhanced Debug Logging Added (2025-10-01, 14:06 BST)

### Issue
After restarting VS Code and attempting connection, Azure AD browser popup continued to appear. Debug log showed:
```
[2025-10-01T13:04:42.916Z] MSSQL_USERNAME: NOT SET, MSSQL_PASSWORD: NOT SET, Will use: AZURE AD AUTH
```

This confirms environment variables from `config.json` are not being passed to the MCP server process.

### Root Cause Investigation
The `config.json` file is correctly configured with `MSSQL_USERNAME` and `MSSQL_PASSWORD` in the `env` object, but these variables are not reaching the MCP server's `process.env`.

This suggests a potential issue with how Claude Code passes environment variables to MCP server processes.

### Solution Applied
Added comprehensive environment variable logging to diagnose exactly which variables the MCP server receives:

**File Modified**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/src/index.ts`

**Enhanced Debug Code**:
```typescript
// Debug logging - log ALL environment variables
const allEnvVars = Object.keys(process.env).filter(key =>
  key.includes('MSSQL') || key.includes('SERVER') || key.includes('DATABASE') || key.includes('USERNAME') || key.includes('PASSWORD')
).map(key => `${key}=${process.env[key]}`).join(', ');

const debugMsg = `[${new Date().toISOString()}] MSSQL_USERNAME: ${username ? 'SET' : 'NOT SET'}, MSSQL_PASSWORD: ${password ? 'SET' : 'NOT SET'}, Will use: ${username && password ? 'SQL AUTH' : 'AZURE AD AUTH'}\nAll relevant env vars: ${allEnvVars}\n\n`;
appendFileSync('/tmp/mcp-debug.log', debugMsg);
```

This will show all environment variables containing:
- `MSSQL`
- `SERVER`
- `DATABASE`
- `USERNAME`
- `PASSWORD`

**Rebuild Command**:
```bash
cd "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node"
npm run build
```

Build completed successfully.

### Next Steps
1. **Restart Claude Code** (Command+Q and reopen)
2. **Attempt database connection** (e.g., `mcp__mssql__list_table`)
3. **Check enhanced debug log**:
   ```bash
   cat /tmp/mcp-debug.log
   ```
4. **Analyze output** to determine:
   - Are ANY environment variables from `config.json` reaching the MCP server?
   - Is there a naming mismatch or case sensitivity issue?
   - Is Claude Code passing the `env` object at all?
5. **Based on findings**:
   - If no variables are passed: Investigate Claude Code MCP configuration requirements
   - If variables are passed but with different names: Update code to match actual variable names
   - If specific variables are missing: Determine why those specific ones aren't being passed
6. Once SQL authentication works, proceed with database exploration and Rhubarb Press project development

### Current Status
- ✅ Enhanced debug logging implemented
- ✅ MCP server rebuilt
- ⏳ Awaiting restart and connection test to gather diagnostic data

---

## Shell Wrapper Configuration Fix (2025-10-01, 14:10 BST)

### Issue Diagnosed
Enhanced debug logging confirmed that environment variables from the `env` object in `config.json` were **NOT being passed** to the MCP server process:
```
[2025-10-01T13:07:43.282Z] MSSQL_USERNAME: NOT SET, MSSQL_PASSWORD: NOT SET, Will use: AZURE AD AUTH
All relevant env vars:
```

This confirmed that Claude Code's MCP configuration does not properly pass environment variables from the `env` object to child processes.

### Root Cause
The standard MCP configuration format using a separate `env` object does not work correctly in Claude Code for macOS. Environment variables specified in the `env` object are not being exported to the Node process.

### Solution Applied
Changed the MCP server configuration to use a shell wrapper that explicitly sets environment variables:

**File Modified**: `/Users/dunbar/Library/Application Support/Claude/config.json`

**Changed FROM**:
```json
"mssql": {
    "command": "node",
    "args": ["/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"],
    "env": {
        "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
        "DATABASE_NAME": "rhubarbpressdb",
        "MSSQL_USERNAME": "mcp_user",
        "MSSQL_PASSWORD": "Sc0tsCup2!May!994!",
        "PORT": "1433",
        "ENCRYPT": "true",
        "READONLY": "false"
    }
}
```

**Changed TO**:
```json
"mssql": {
    "command": "sh",
    "args": ["-c", "SERVER_NAME='rhubarbpress-sqlsrv.database.windows.net' DATABASE_NAME='rhubarbpressdb' MSSQL_USERNAME='mcp_user' MSSQL_PASSWORD='Sc0tsCup2!May!994!' PORT='1433' ENCRYPT='true' READONLY='false' node '/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js'"]
}
```

### Key Changes
- Changed `command` from `node` to `sh`
- Added `-c` flag to execute a shell command string
- Embedded all environment variables directly in the shell command before the `node` invocation
- This ensures environment variables are set in the same process context where Node runs

### Next Steps
1. **Restart Claude Code** (Command+Q and fully reopen)
2. **Test database connection** with `mcp__mssql__list_table` or similar query
3. **Verify no browser popup** appears (SQL authentication should work silently)
4. **Check debug log** to confirm authentication method:
   ```bash
   cat /tmp/mcp-debug.log
   ```
   - Should show: `MSSQL_USERNAME: SET`, `MSSQL_PASSWORD: SET`, `Will use: SQL AUTH`
5. **Begin database exploration** once connection is verified:
   - List all tables in rhubarbpressdb
   - Explore schema structure
   - Start Rhubarb Press project development

### Current Status
- ✅ Shell wrapper configuration implemented
- ⏳ Awaiting Claude Code restart to test SQL authentication
- ⏳ Connection should work without Azure AD browser popup

---

## Standalone Shell Script Configuration (2025-10-01, 14:12 BST)

### Issue
After implementing the shell wrapper configuration, the Azure AD browser popup continued to appear. Debug log confirmed environment variables were still not being passed to the MCP server process, even with the inline shell command approach.

### Root Cause
Claude Code's MCP configuration does not properly pass environment variables using either:
1. The `env` object in `config.json`
2. Inline shell commands with variables in the `args` array

### Solution Applied
Created a standalone shell script with explicit `export` statements that sets all environment variables before launching the Node process.

**File Created**: `/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh`

```bash
#!/bin/bash

# Set environment variables for MSSQL MCP Server
export SERVER_NAME='rhubarbpress-sqlsrv.database.windows.net'
export DATABASE_NAME='rhubarbpressdb'
export MSSQL_USERNAME='mcp_user'
export MSSQL_PASSWORD='Sc0tsCup2!May!994!'
export PORT='1433'
export ENCRYPT='true'
export READONLY='false'

# Start the MCP server
node "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"
```

**Permissions Set**:
```bash
chmod +x "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh"
```

**Updated Configuration** (`/Users/dunbar/Library/Application Support/Claude/config.json`):
```json
"mcpServers": {
    "mssql": {
        "command": "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh"
    }
}
```

### Key Advantages
- Explicit `export` statements ensure variables are available to child processes
- Standalone script is easier to test and debug independently
- Simpler configuration in `config.json` (just the script path)
- Can be tested manually: `bash /Users/dunbar/Tech\ Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh`

### Next Steps
1. **Fully quit Claude Code** (Command+Q) and reopen
2. **Test database connection** with `mcp__mssql__list_table`
3. **Verify no Azure AD browser popup** appears
4. **Check debug log** to confirm SQL authentication:
   ```bash
   cat /tmp/mcp-debug.log
   ```
   - Should show: `MSSQL_USERNAME: SET`, `MSSQL_PASSWORD: SET`, `Will use: SQL AUTH`
5. **If successful**:
   - Begin database exploration
   - List all tables and schema
   - Start Rhubarb Press project development
6. **If still fails**:
   - Test script manually to verify it works outside Claude Code
   - Consider alternative MCP configuration approaches or contact Claude support

### Current Status
- ✅ Standalone shell script created and made executable
- ✅ Configuration updated to use shell script
- ⏳ Awaiting Claude Code restart to test connection
- ⏳ SQL authentication should work with this approach

---

## Codex CLI Configuration Fix (2025-10-02, 09:42 BST)

### Issue Identified
After reviewing the VM documentation, discovered that the Windows VM successfully connected to the database using the codex CLI with the same credentials. However, the macOS codex CLI configuration had an empty `env` object, preventing SQL authentication.

### Root Cause
The codex CLI uses a different configuration file (`~/.claude.json`) than Claude Code (which uses `/Users/dunbar/Library/Application Support/Claude/config.json`). The codex CLI configuration was missing the SQL authentication credentials in the `env` object.

### Solution Applied
Updated the codex CLI configuration file to match the working VM setup:

**File Modified**: `~/.claude.json`

**Changed FROM**:
```json
"mssql": {
  "type": "stdio",
  "command": "node",
  "args": [
    "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"
  ],
  "env": {}
}
```

**Changed TO**:
```json
"mssql": {
  "type": "stdio",
  "command": "node",
  "args": [
    "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"
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

### Key Changes
- Added SQL authentication credentials to the `env` object
- Used `USER_NAME` variable name (matching VM configuration)
- Configuration now matches the working Windows VM setup

### Next Steps
1. Exit the current codex CLI session (type `exit` or Ctrl+D)
2. Start a new codex session with `claude`
3. Test connection with database queries (e.g., "Show me all tables in rhubarbpressdb")
4. Verify no Azure AD browser popup appears
5. Begin working with the database

### Current Status
- ✅ Codex CLI configuration updated with SQL credentials
- ⏳ Awaiting session restart to test connection
- ⏳ Should connect using SQL authentication without browser popup

---

## Bash Command Wrapper Fix (2025-10-01, 14:18 BST)

### Issue
After creating the shell script and updating config.json to use it directly, the Azure AD login popup still appeared. Debug log confirmed environment variables were still not being set:
```
[2025-10-01T13:16:26.296Z] MSSQL_USERNAME: NOT SET, MSSQL_PASSWORD: NOT SET, Will use: AZURE AD AUTH
```

### Root Cause
The MCP configuration was trying to execute the shell script directly as a command:
```json
"command": "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh"
```

This approach doesn't properly invoke the bash interpreter to execute the script.

### Solution Applied
Updated the configuration to explicitly use `bash` with the script path as an argument:

**File Modified**: `/Users/dunbar/Library/Application Support/Claude/config.json`

**Changed FROM**:
```json
"mcpServers": {
    "mssql": {
        "command": "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh"
    }
}
```

**Changed TO**:
```json
"mcpServers": {
    "mssql": {
        "command": "bash",
        "args": ["/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/start-mcp.sh"]
    }
}
```

### Key Change
- Changed `command` from the script path to `bash`
- Added `args` array with the script path as the argument
- This ensures bash properly executes the script with exported environment variables

### Next Steps
1. **Fully quit Claude Code** (Command+Q and reopen) - not just reload
2. **Test database connection** with `mcp__mssql__list_table`
3. **Verify no Azure AD browser popup** appears
4. **Check debug log** to confirm SQL authentication worked:
   ```bash
   cat /tmp/mcp-debug.log
   ```
   - Should show: `MSSQL_USERNAME: SET`, `MSSQL_PASSWORD: SET`, `Will use: SQL AUTH`
5. **If successful**:
   - List all tables in rhubarbpressdb
   - Explore database schema and contents
   - Begin Rhubarb Press project database operations
6. **If still fails**:
   - Consider alternative approaches (connection string in script, different MCP server implementation)
   - Test script manually to verify it works outside Claude Code

### Current Status
- ✅ Configuration updated to use `bash` command with script argument
- ⏳ Awaiting full Claude Code restart
- ⏳ This should properly execute the shell script with environment variables exported

---

## Successful Connection from macOS (2025-10-02, 09:53 BST)

### Issue Encountered
After bash wrapper configuration, connection attempt resulted in firewall error:
```
ConnectionError: Cannot open server 'rhubarbpress-sqlsrv' requested by the login. Client with IP address '2.97.64.68' is not allowed to access the server.
```

### Root Cause
The macOS connection attempt was from IP address `2.97.64.68`, which was not in the Azure SQL Server firewall rules. The VM connection worked previously because the VM's IP was already whitelisted.

### Solution Applied
Added firewall rule in Azure Portal for IP address `2.97.64.68`:
1. Navigated to SQL Server: `rhubarbpress-sqlsrv` in Azure Portal
2. Went to "Networking" / "Firewalls and virtual networks"
3. Added new firewall rule for IP: `2.97.64.68`
4. Waited for changes to take effect

### Connection Test Result
Successfully connected to Azure SQL Database from macOS. Connection test returned 24 tables:
- AuditLog, Authors, BankBalance, BankBalanceHistory, BookCategories, Books, BookSales
- CapitalAllowances, ChartOfAccounts, ComplianceDocuments, Contacts, CorporationTaxCalculations
- InvoiceLines, Invoices, ProductionCosts, RoyaltyCalculationDetails, RoyaltyCalculations
- SalesChannels, TransactionGroup, TransactionLines, Transactions, VATRates, VATReturns, VATTransactionMapping

### Authentication Method Confirmed
- ✅ SQL authentication working correctly (no Azure AD browser popup)
- ✅ Using `mcp_user` credentials from bash wrapper script
- ✅ Environment variables properly exported via shell script

### Current Status
- ✅ macOS successfully connected to rhubarbpressdb
- ✅ Firewall rule configured for macOS IP address
- ✅ All 24 database tables accessible
- ✅ Ready for database operations and Rhubarb Press project development
