# Context7 MCP Server Integration

## Overview
Context7 is an MCP server developed by Upstash that provides up-to-date, version-specific documentation and code examples directly into your AI assistant's context window. It eliminates tab-switching, prevents hallucinated APIs, and ensures current code generation by fetching official documentation in real-time.

## Key Capabilities
- **Real-time Documentation**: Fetches current official docs and code examples on demand
- **Version-Specific Content**: Returns documentation matching specific library/framework versions
- **Source Integration**: Pulls information directly from official sources
- **Context Window Integration**: Seamlessly adds documentation to AI prompts
- **Multi-Language Support**: Works across various programming languages and frameworks
- **No Manual Lookup**: Eliminates need to switch between editor and documentation

## Integration Options

### 1. Remote Server (Hosted by Upstash)
- **Endpoint**: https://mcp.context7.com/mcp
- **Authentication**: Optional API key via header
- **Benefits**: No local installation, managed infrastructure
- **Rate Limits**: Higher limits with API key

### 2. Local Server (NPX)
- **Package**: `@upstash/context7-mcp`
- **Execution**: Runs via npx on-demand
- **Benefits**: Full control, works offline after initial fetch
- **Authentication**: Optional API key via command argument

## Claude Code Configuration

### Installation Commands

**Local server (without API key):**
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

**Local server (with API key):**
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

**Remote server (with API key):**
```bash
claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: YOUR_API_KEY"
```

### Manual Configuration
Add to your `.claude.json` file:

**Local server:**
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**Remote server:**
```json
{
  "mcpServers": {
    "context7": {
      "transport": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

## Authentication Requirements
- **API Key**: Optional but recommended for higher rate limits
- **Account Creation**: Sign up at https://context7.com/dashboard
- **Free Tier**: Available without API key (lower rate limits)
- **No Credentials**: Works immediately without authentication

## Available Tools
The server provides documentation retrieval functionality:
- **fetch_documentation**: Retrieves current docs for specified libraries/frameworks
- **get_code_examples**: Fetches real-world code samples
- **version_lookup**: Gets version-specific API documentation
- **framework_reference**: Accesses framework-specific guides and references

## Usage in Prompts
To activate Context7, include keywords in your prompts:
- "use context7 to..."
- "fetch documentation for..."
- "get the latest API docs for..."

### Example Use Cases
- "Use context7 to get the latest React hooks documentation"
- "Fetch Next.js 14 App Router documentation with context7"
- "Get TypeScript 5.0 utility types documentation"
- "Show me the latest FastAPI dependency injection examples"
- "Use context7 for the current Tailwind CSS configuration options"
- "Get documentation for PostgreSQL connection pooling"

## Benefits
- **Always Current**: Documentation stays up-to-date automatically
- **No Hallucinations**: Uses real, verified API references
- **Faster Development**: No context switching to browser
- **Version Accuracy**: Matches your specific library versions
- **Comprehensive Examples**: Real code samples from official sources
- **Multi-Framework**: Works across Python, JavaScript, Rust, Go, etc.

## Current Limitations
- **Rate Limits**: Free tier has lower request limits
- **Network Dependency**: Requires internet connection for real-time fetch
- **API Coverage**: Limited to publicly documented APIs
- **Version Availability**: Depends on official documentation availability
- **Cache Behavior**: May serve cached results for performance

## Prerequisites
- Claude Code with MCP support
- Internet connection for documentation retrieval
- (Optional) Context7 account for higher rate limits

## Additional Resources
- **GitHub Repository**: https://github.com/upstash/context7
- **Official Blog**: https://upstash.com/blog/context7-mcp
- **Dashboard**: https://context7.com/dashboard
- **MCP Documentation**: Uses Anthropic's Model Context Protocol

## Community Variants
- **context7-http**: HTTP SSE streaming variant by lrstanley
- **zed-mcp-server-context7**: Zed editor integration
- **Various editor plugins**: Community adaptations for different IDEs

## Notes
- Works best when explicitly invoked with "use context7" in prompts
- Combines well with other MCP servers for comprehensive development support
- API key improves reliability for heavy documentation lookup workflows
- Consider local server for consistent performance; remote for simplicity
- Documentation quality depends on upstream source maintenance