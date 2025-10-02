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
