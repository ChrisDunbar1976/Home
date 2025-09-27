# MCP Servers Discussion - SQL Server Setup

## Context
Discussion about available MCP servers for Claude Code, with focus on SQL Server connectivity and Microsoft's official MSSQL MCP Server.

## Key Topics Covered

### Available MCP Categories
- Development & Testing (Sentry, Linear)
- Databases & Data Management (Airtable, SQL Server)
- Payments & Commerce (Stripe)
- Design & Media (Figma)
- Project Management (Asana)
- Infrastructure & DevOps

### SQL Server MCP Servers
Found several options:
1. **Microsoft's Official MSSQL MCP Server (Preview)** - Chosen option
2. Multi-database MCP servers (SQL Server, MySQL, PostgreSQL, SQLite)
3. Python-based implementations using pymssql

### Installation Steps Completed
1. Cloned Microsoft's SQL AI samples repository
2. Installed dependencies in `SQL-AI-samples/MssqlMcp/Node`
3. Added MSSQL-MCP server to Claude Code configuration
4. Configured connection to:
   - **Server**: DESKTOP-6O4GMJP
   - **Database**: AdventureWorks2022
   - **Mode**: Read-only
   - **Authentication**: Entra (Windows) authentication

### Other Databases Available
- AdventureWorksDW2022
- SSIS

### Key Features of SQL Server MCP
- Natural language queries to database
- Read-only by default for safety
- Local credential storage
- Support for on-premises, Azure SQL Database, SQL Database in Microsoft Fabric

## Next Steps
- Restart Claude Code for configuration to take effect
- Test connection and natural language queries
- Can switch databases by updating DATABASE_NAME in config

## Design & Media - Figma MCP Servers

### Official Figma Dev Mode MCP Server
- **Status**: Open beta (as of 2024)
- **Purpose**: Brings Figma design context directly into AI coding workflows
- **Key Features**:
  - `get_code`: Provides structured React + Tailwind representation of Figma selections
  - `get_variable_defs`: Extracts variables and styles (color, spacing, typography, etc.)
  - Direct integration with design tokens and variables

### Integration Benefits
- **Design-to-Code**: AI tools can understand Figma designs at structural level vs just visual inspection
- **Context Preservation**: Maintains design system consistency in generated code
- **Variable Access**: Direct reference to Figma tokens in generated code
- **Framework Flexibility**: Starting point can be translated to any framework/style

### Compatible Tools
- Claude Code
- VS Code with Copilot
- Cursor
- Windsurf
- Other AI coding assistants

### Community Implementations
Multiple community-built servers available on GitHub providing various approaches to Figma API integration.

### Current Limitations
- Beta status - some functions may be unavailable
- Better at generating new components than surgical updates to existing code
- Requires proper Figma access tokens and permissions

## Project Management - Asana MCP Servers

### Official Asana MCP Server
- **Status**: Beta feature (as of 2024)
- **Purpose**: Connects Asana Work Graph with external AI platforms and LLMs
- **Authentication**: Requires Asana account authorization via app integration

### Key Features
- **Task Management**: Create, update, list, and delete tasks
- **Project Operations**: Manage projects, track status, coordinate workflows
- **Team Coordination**: Assign work, analyze workloads, manage deadlines
- **Natural Language Interface**: Interact with Asana through conversational commands
- **Status Tracking**: Get task summaries based on notes, custom fields, and comments

### Integration Options

#### 1. Official Asana MCP Server
- Direct integration through Asana's platform
- OAuth-based authentication
- Enterprise+ tier controls via App Management
- Allowlist of approved MCP client redirect URIs for security

#### 2. Third-Party Implementations
- `@roychri/mcp-server-asana` - Community-built server
- Direct Asana API integration
- Token-based authentication
- Read-only mode support

### Claude Code Configuration
```bash
claude mcp add asana -e ASANA_ACCESS_TOKEN=<TOKEN> -- npx -y @roychri/mcp-server-asana
```

### Environment Variables
- `ASANA_ACCESS_TOKEN`: Required Asana access token
- `READ_ONLY_MODE`: Optional - set to 'true' for read-only operations

### Example Use Cases
- "Create a new task for the Q1 marketing campaign review"
- "Show me all overdue tasks in the development project"
- "Update task status and add progress notes"
- "Analyze team workload across active projects"
- "Get summary of project milestones and deadlines"

### Security Considerations
- Enterprise+ App Management controls
- Approved redirect URI allowlist
- Token-based authentication for third-party servers
- Read-only mode available for limited access

## Infrastructure & DevOps - MCP Servers

### Cloud Infrastructure
- **AWS MCP Servers**: Official AWS implementation providing access to documentation, API references, and architectural guidance
- **Azure DevOps MCP**: Query agent status, manage build queues, troubleshoot build farm issues
- **Multi-Cloud Support**: Various community implementations for different cloud providers

### Container & Orchestration
- **Docker MCP Servers**: Container management and operations through natural language
- **Kubernetes MCP**: Multiple implementations available:
  - `kubectl-mcp-server`: Natural language Kubernetes cluster interaction
  - `k8m`: Multi-cluster management with 50+ built-in DevOps tools
  - Read-only monitoring and diagnostics for pods, deployments, services

### Key DevOps Capabilities
- **Infrastructure Management**: Server configuration, monitoring setup (Nagios, Docker containers)
- **Remote System Access**: SSHFS-mounted directories, SSH command execution
- **Build Pipeline Management**: Azure DevOps build agent status and queue management
- **Code Sandbox**: Secure code execution within Docker containers
- **Cluster Operations**: Pod management, deployment monitoring, service discovery

### Claude Code Integration Examples
```bash
# AWS infrastructure
claude mcp add aws -e AWS_ACCESS_KEY_ID=xxx -e AWS_SECRET_ACCESS_KEY=xxx -- npx -y aws-mcp-server

# Azure DevOps
claude mcp add azure-devops \
  -e ADO_ORGANIZATION="https://dev.azure.com/your-org" \
  -e ADO_PROJECT="your-project" \
  -e ADO_PAT="your-token" \
  -- npx -y @rxreyn3/azure-devops-mcp@latest

# Docker management
claude mcp add docker -- npx -y docker-mcp-server
```

### Benefits for DevOps Teams
- **Infrastructure-Aware Development**: AI understands your deployment environment
- **Natural Language Operations**: Manage complex infrastructure through conversation
- **Expert System Admin**: Like having a senior sysadmin available 24/7
- **Cross-Platform Management**: Handle multiple cloud providers and tools
- **Secure Sandboxing**: Safe code execution and testing environments

## Files Created
- Repository cloned to: `C:\Users\Chris Dunbar\Tech Projects\SQL-AI-samples\`
- Configuration updated in: `C:\Users\Chris Dunbar\.claude.json`