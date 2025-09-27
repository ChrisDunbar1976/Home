# Puppeteer MCP Server

A Model Context Protocol (MCP) server that provides browser automation capabilities using Puppeteer. This server allows AI assistants to interact with web pages, take screenshots, extract content, and perform browser automation tasks.

## Features

- **Page Navigation** - Navigate to any URL
- **Screenshots** - Capture full page or viewport screenshots
- **Content Extraction** - Get text content from pages or specific elements
- **User Interactions** - Click elements, type text, wait for elements
- **JavaScript Execution** - Run custom JavaScript in the page context
- **Page Information** - Get page title, URL, and viewport details

## Installation

```bash
# Install dependencies
npm install

# Install MCP SDK (required)
npm install @modelcontextprotocol/sdk
```

## Usage

### Start the MCP Server

```bash
npm start
```

The server runs as a stdio-based MCP server and communicates via standard input/output.

### Available Tools

#### `navigate`
Navigate to a URL
```json
{
  "url": "https://example.com"
}
```

#### `screenshot`
Take a screenshot of the current page
```json
{
  "path": "./screenshot.png",  // Optional: save to file
  "fullPage": true            // Optional: full page screenshot
}
```

#### `get_content`
Get text content from the page
```json
{
  "selector": ".main-content"  // Optional: CSS selector for specific element
}
```

#### `click`
Click on an element
```json
{
  "selector": "button.submit"
}
```

#### `type`
Type text into an input field
```json
{
  "selector": "input[name='email']",
  "text": "user@example.com"
}
```

#### `wait_for_selector`
Wait for an element to appear
```json
{
  "selector": ".loading-complete",
  "timeout": 30000  // Optional: timeout in milliseconds
}
```

#### `evaluate`
Execute JavaScript in the page context
```json
{
  "script": "document.title"
}
```

#### `get_page_info`
Get basic page information
```json
{}
```

## Browser Configuration

The server launches Puppeteer with the following default settings:
- Headless mode enabled
- Viewport: 1280x800
- No sandbox mode (for compatibility)

## MCP Integration

To use this server with an MCP client, configure it in your MCP settings:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "node",
      "args": ["/path/to/puppeteer-mcp/index.js"]
    }
  }
}
```

## Development

The server is built using:
- **@modelcontextprotocol/sdk** - MCP protocol implementation
- **puppeteer** - Browser automation library

### Architecture

- `PuppeteerMCPServer` class manages the MCP server and browser lifecycle
- Each tool maps to a specific Puppeteer operation
- Browser and page instances are created on-demand and reused
- Proper cleanup on process termination

### Error Handling

All tools include error handling that returns descriptive error messages to the client. The browser automatically handles common issues like:
- Network timeouts
- Element not found
- JavaScript execution errors

## Security Considerations

This server provides powerful browser automation capabilities. When deployed:
- Run in a sandboxed environment
- Limit network access appropriately
- Monitor resource usage
- Consider rate limiting for production use

## License

ISC