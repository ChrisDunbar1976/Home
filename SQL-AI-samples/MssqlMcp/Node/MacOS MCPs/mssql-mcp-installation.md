# Microsoft SQL Server MCP Installation

## Overview
The official Microsoft SQL Server Model Context Protocol (MCP) server enables secure database interactions through AI assistants.

## Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Azure-Samples/SQL-AI-samples.git
   ```

2. **Navigate to the Node Project**
   ```bash
   cd SQL-AI-samples/MssqlMcp/Node
   ```

3. **Install Dependencies**
   ```bash
   npm install
   ```

4. **Add to Claude MCP Configuration**
   ```bash
   claude mcp add mssql node "/Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node/dist/index.js"
   ```

5. **Restart Claude Code** for changes to take effect

## Repository Information
- **GitHub**: https://github.com/Azure-Samples/SQL-AI-samples/tree/main/MssqlMcp
- **Location**: /Users/dunbar/Tech Projects/SQL-AI-samples/MssqlMcp/Node
- **Version**: 1.0.0

## Features
- Secure database interactions
- Support for SQL Server, Azure SQL Database, and SQL Database in Microsoft Fabric
- Both .NET and Node.js implementations available
- Query execution and schema exploration

## Configuration
Connection details are typically configured through environment variables or MCP settings when ready to use.

## Installation Date
October 1, 2025
