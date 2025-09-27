# Asana MCP Server Integration

## Overview
Asana provides both official and third-party MCP server implementations that connect the Asana Work Graph with AI platforms, enabling natural language interaction with project management workflows through task creation, team coordination, and project tracking.

## Key Capabilities
- **Task Management**: Create, update, list, and delete tasks with detailed specifications
- **Project Operations**: Manage projects, track status, and coordinate workflows
- **Team Coordination**: Assign work, analyze workloads, and manage deadlines
- **Status Tracking**: Get task summaries based on notes, custom fields, and comments
- **Natural Language Interface**: Interact with Asana through conversational commands
- **Workload Analysis**: Monitor team capacity and project progress

## Integration Options

### 1. Official Asana MCP Server
- **Status**: Beta feature (as of 2024)
- **Authentication**: OAuth-based via Asana app integration
- **Platform**: Direct integration through Asana's official platform
- **Enterprise Controls**: App Management for Enterprise+ tiers

### 2. Third-Party Implementations
- **Primary Package**: `@roychri/mcp-server-asana`
- **Authentication**: Token-based access
- **API Integration**: Direct Asana API connectivity
- **Flexibility**: Read-only mode support available

## Claude Code Configuration

### Quick Setup Command
```bash
claude mcp add asana -e ASANA_ACCESS_TOKEN=<TOKEN> -- npx -y @roychri/mcp-server-asana
```

### Manual Configuration
Add to your `.claude.json` file:

```json
{
  "mcpServers": {
    "asana": {
      "command": "npx",
      "args": ["-y", "@roychri/mcp-server-asana"],
      "env": {
        "ASANA_ACCESS_TOKEN": "your_token_here",
        "READ_ONLY_MODE": "false"
      }
    }
  }
}
```

## Authentication Requirements
- **Asana Access Token**: Required for API access
- **Account Permissions**: Appropriate workspace and project access
- **OAuth Authorization**: For official server integration
- **Enterprise Controls**: May require approval via App Management

## Available Tools
The server provides comprehensive project management functionality:
- **Task Operations**: Create, read, update, delete tasks
- **Project Management**: Project status, milestone tracking
- **Team Collaboration**: Assignment, workload distribution
- **Comment Management**: Task discussions and updates
- **Custom Fields**: Access to custom task properties
- **Workspace Navigation**: Multi-workspace support

## Environment Variables
- **ASANA_ACCESS_TOKEN**: (Required) Your Asana personal access token
- **READ_ONLY_MODE**: (Optional) Set to 'true' for read-only operations

## Setup Process
1. **Asana Account**: Ensure access to target workspaces and projects
2. **Generate Access Token**: Create token in Asana account settings
3. **Install MCP Server**: Add to Claude Code configuration
4. **Configure Authentication**: Set up token environment variables
5. **Test Integration**: Verify connection to Asana workspace

## Example Use Cases
- "Create a new task for the Q1 marketing campaign review"
- "Show me all overdue tasks in the development project"
- "Update task status and add progress notes"
- "Analyze team workload across active projects"
- "Get summary of project milestones and deadlines"
- "Assign the database migration task to the backend team"
- "List all tasks due this week in the mobile app project"

## Security Features
- **Enterprise App Management**: Control access at organizational level
- **Approved Redirect URIs**: Allowlist system for MCP client security
- **Token-based Authentication**: Secure API access with personal tokens
- **Read-only Mode**: Limit operations to prevent accidental changes
- **Workspace Isolation**: Access controls per workspace/project

## Benefits
- **Natural Language PM**: Manage projects through conversational interface
- **Workflow Integration**: Seamless connection between AI and project data
- **Team Visibility**: Real-time access to project status and team workloads
- **Task Automation**: AI-assisted task creation and management
- **Progress Tracking**: Automated status updates and milestone monitoring

## Current Limitations
- **Beta Status**: Official server may have feature limitations
- **Enterprise Restrictions**: App Management controls may block access
- **Token Management**: Requires secure handling of access tokens
- **API Rate Limits**: Asana API usage limitations apply
- **Permissions Dependency**: Access limited by Asana workspace permissions

## Prerequisites
- Active Asana account with workspace access
- Asana personal access token with appropriate permissions
- Claude Code with MCP support
- Project/workspace access rights for target data

## Additional Resources
- **Official Documentation**: https://developers.asana.com/docs/using-asanas-mcp-server
- **Third-party Server**: https://github.com/roychri/mcp-server-asana
- **Asana API Docs**: https://developers.asana.com/docs
- **Token Generation**: Asana Developer Console

## Enterprise Considerations
- **App Management**: Enterprise+ customers can control MCP app access
- **Security Allowlist**: Approved redirect URIs for enhanced security
- **Team Permissions**: Integration respects existing Asana access controls
- **Audit Trail**: Actions performed through MCP are logged in Asana

## Notes
- Official server uses OAuth while third-party uses token authentication
- Read-only mode recommended for exploratory or reporting use cases
- Token security is crucial for production environments
- Integration quality depends on Asana workspace organization
- Multiple workspace support available through proper token configuration