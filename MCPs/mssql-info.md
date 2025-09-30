# MSSQL MCP Server Integration

## Overview
MSSQL MCP is Microsoft's official Model Context Protocol server for SQL Server and Azure SQL Database. It enables natural language interaction with SQL databases, allowing AI assistants to explore schemas, execute queries, analyze data, and perform database operations through conversational commands.

## Key Capabilities
- **Schema Discovery**: List tables, views, columns, and database objects
- **Natural Language Queries**: Convert conversational requests to SQL
- **Data Analysis**: Aggregate, filter, and analyze database content
- **Query Execution**: Run SELECT statements and stored procedures
- **Data Manipulation**: INSERT, UPDATE, DELETE operations (if not read-only)
- **Database Documentation**: Auto-generate schema documentation
- **Performance Analysis**: Query optimization suggestions
- **Relationship Mapping**: Understand foreign keys and table relationships

## Supported Databases
- **Azure SQL Database**: Cloud-based SQL Server
- **SQL Server (On-Premises)**: Local installations
- **Microsoft Fabric**: Data warehouse integration
- **Any SQL Server**: Via connection string

## Installation Process

### Prerequisites
- Node.js installed
- Git installed
- Azure SQL Database or SQL Server instance
- Database connection credentials

### Step 1: Clone Repository
```bash
git clone https://github.com/Azure-Samples/SQL-AI-samples.git
```

### Step 2: Navigate to MCP Server
```bash
cd SQL-AI-samples/MssqlMcp/Node
```

### Step 3: Install Dependencies
```bash
npm install
```
This will:
- Install 180+ npm packages
- Build TypeScript to JavaScript (via `npm run build`)
- Create `dist/index.js` executable

### Step 4: Add to Claude Code Configuration
```bash
claude mcp add mssql -e SERVER_NAME=your-server.database.windows.net -e DATABASE_NAME=your-database-name -e READONLY=false -- node "C:\Users\cdunbar\Documents\Projects\SQL-AI-samples\MssqlMcp\Node\dist\index.js"
```

**Note**: Adjust the path based on your installation location.

## Configuration

### Update .claude.json
After installation, manually edit `C:\Users\cdunbar\.claude.json` to update the connection details:

```json
{
  "mcpServers": {
    "mssql": {
      "type": "stdio",
      "command": "node",
      "args": [
        "C:\\Users\\cdunbar\\Documents\\Projects\\SQL-AI-samples\\MssqlMcp\\Node\\dist\\index.js"
      ],
      "env": {
        "SERVER_NAME": "your-server.database.windows.net",
        "DATABASE_NAME": "your-database-name",
        "READONLY": "false"
      }
    }
  }
}
```

### Required Configuration Updates

**SERVER_NAME**: Replace with your Azure SQL server name
- Format: `servername.database.windows.net`
- Example: `rhubarbpress-sql.database.windows.net`

**DATABASE_NAME**: Replace with your database name
- Example: `RhubarbAccounts`

**READONLY**: Set to `"true"` or `"false"`
- `"true"`: Only SELECT queries allowed (safe for exploration)
- `"false"`: Allows INSERT, UPDATE, DELETE operations

### Authentication
The MCP server uses Windows Authentication or SQL Server Authentication based on your system configuration. Ensure your credentials have appropriate database access.

## Available Tools
The server provides comprehensive database interaction functionality:
- **list_tables**: Get all tables in the database
- **describe_table**: Show table schema and columns
- **execute_query**: Run SQL SELECT statements
- **get_relationships**: Show foreign key relationships
- **list_stored_procedures**: View available stored procedures
- **execute_procedure**: Run stored procedures
- **table_data_sample**: Get sample rows from tables
- **schema_documentation**: Generate database documentation
- **query_optimization**: Analyze and suggest query improvements

## Environment Variables
- **SERVER_NAME**: (Required) SQL Server hostname or Azure SQL endpoint
- **DATABASE_NAME**: (Required) Target database name
- **READONLY**: (Optional) Set to "true" to prevent write operations (default: "false")

## Example Use Cases
- "Show me all tables in the database"
- "Describe the structure of the Users table"
- "How many orders were placed last month?"
- "Find customers who haven't ordered in 90 days"
- "What's the relationship between Orders and Products tables?"
- "Show me the top 10 products by revenue"
- "Generate documentation for the database schema"
- "Analyze the performance of this query: SELECT * FROM..."
- "Insert a new customer record with name 'John Doe'"
- "Update order status to 'shipped' for order ID 12345"

## Benefits
- **Natural Language Interface**: Query databases without writing SQL
- **Rapid Exploration**: Understand database structure quickly
- **Ad-Hoc Analysis**: Get insights without BI tools
- **Code Generation**: AI-generated SQL queries and procedures
- **Documentation**: Auto-generate schema documentation
- **Azure Integration**: Direct connection to Azure SQL Database
- **Security**: Read-only mode prevents accidental data changes

## Current Limitations
- **Preview Status**: Official Microsoft implementation in preview
- **Manual Setup**: Requires cloning full sample repository
- **Large Repository**: Downloads many unrelated AI/SQL samples
- **Authentication**: May require additional Azure AD configuration
- **Performance**: Complex queries may timeout
- **Connection Pooling**: Limited concurrent connection support

## Prerequisites
- Active Azure SQL Database or SQL Server instance
- Database access credentials with appropriate permissions
- Node.js runtime (v14 or higher recommended)
- Adequate network connectivity to database server
- Firewall rules allowing connection from your IP

## Security Considerations
- **Read-Only Mode**: Use `READONLY=true` for safe exploration
- **Credentials**: Avoid hardcoding passwords in configuration
- **Least Privilege**: Use database accounts with minimal required permissions
- **Audit Logging**: Enable database audit logs for compliance
- **Network Security**: Ensure proper firewall and network rules
- **Connection Strings**: Protect sensitive connection information

## Troubleshooting

### Connection Issues
- Verify server name and database name are correct
- Check Azure SQL firewall rules allow your IP address
- Confirm database credentials have proper permissions
- Test connection using Azure Data Studio or SSMS first

### Build Errors
- Ensure Node.js is installed and up to date
- Run `npm install` again if dependencies failed
- Check for TypeScript compilation errors in console

### Authentication Failures
- Verify SQL Server authentication mode
- Check if Windows Authentication is configured correctly
- For Azure SQL, ensure Azure AD authentication is set up

### Performance Issues
- Enable read-only mode to prevent accidental expensive operations
- Use specific queries rather than SELECT * from large tables
- Consider indexing frequently queried columns

## Additional Resources
- **Official Blog**: https://devblogs.microsoft.com/azure-sql/introducing-mssql-mcp-server/
- **GitHub Repository**: https://github.com/Azure-Samples/SQL-AI-samples
- **MCP Documentation**: https://modelcontextprotocol.io/
- **Azure SQL Docs**: https://docs.microsoft.com/azure/azure-sql/

## Installation Location
- **Repository**: `C:\Users\cdunbar\Documents\Projects\SQL-AI-samples`
- **MCP Server**: `SQL-AI-samples\MssqlMcp\Node`
- **Executable**: `SQL-AI-samples\MssqlMcp\Node\dist\index.js`

## Notes
- Repository contains multiple Azure SQL + AI samples beyond just the MCP server
- First run may take time as Node.js loads and connects to database
- Consider using read-only mode initially to explore safely
- MCP server supports both integrated and SQL Server authentication
- Works with both Azure SQL Database and on-premises SQL Server
- Connection is established on first tool invocation, not at startup