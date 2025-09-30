# Puppeteer MCP Server Integration

## Overview
Puppeteer MCP is an official Model Context Protocol server that provides browser automation capabilities using Google's Puppeteer library. It enables AI assistants to interact with web pages, take screenshots, execute JavaScript in a real browser environment, and perform web scraping tasks programmatically.

## Key Capabilities
- **Browser Automation**: Control headless or headed Chrome/Chromium browsers
- **Web Page Interaction**: Navigate, click, type, and interact with web elements
- **Screenshot Capture**: Take full-page or element-specific screenshots
- **JavaScript Execution**: Run custom JavaScript code in browser context
- **Web Scraping**: Extract content, data, and metadata from web pages
- **Form Automation**: Fill forms, submit data, handle authentication flows
- **PDF Generation**: Convert web pages to PDF documents
- **Network Monitoring**: Intercept and analyze network requests/responses

## Integration Options

### Official MCP Server
- **Package**: `@modelcontextprotocol/server-puppeteer`
- **Execution**: Runs via npx on-demand
- **Browser**: Uses Chrome/Chromium (downloads automatically if needed)
- **Mode**: Headless by default (can be configured for headed mode)

### Community Variants
Multiple community implementations offer specialized features:
- **merajmehrabi/puppeteer-mcp-server**: Enhanced automation with existing Chrome support
- **djannot/puppeteer-vision-mcp**: Vision-enhanced scraping with markdown conversion
- **jatidevelopments/MCP-Puppeteer-Advanced**: Advanced features with image extraction
- **hushaudio/PuppeteerMCP**: Screenshot-focused tools with console log capture

## Claude Code Configuration

### Installation Command

**Standard installation:**
```bash
claude mcp add puppeteer -- npx -y @modelcontextprotocol/server-puppeteer
```

### Manual Configuration
Add to your `.claude.json` file:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

### Advanced Configuration Options
```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
      "env": {
        "PUPPETEER_HEADLESS": "true",
        "PUPPETEER_EXECUTABLE_PATH": "/path/to/chrome"
      }
    }
  }
}
```

## Available Tools
The server provides comprehensive browser automation functionality:
- **puppeteer_navigate**: Navigate to URLs and wait for page load
- **puppeteer_screenshot**: Capture screenshots of entire pages or specific elements
- **puppeteer_click**: Click on elements using CSS selectors
- **puppeteer_fill**: Fill form inputs and text fields
- **puppeteer_evaluate**: Execute JavaScript code in browser context
- **puppeteer_content**: Extract page HTML content
- **puppeteer_pdf**: Generate PDF from web pages
- **puppeteer_cookies**: Manage browser cookies
- **puppeteer_select**: Interact with dropdown menus

## Environment Variables
- **PUPPETEER_HEADLESS**: Set to 'false' to show browser window (default: true)
- **PUPPETEER_EXECUTABLE_PATH**: Custom Chrome/Chromium binary path
- **PUPPETEER_ARGS**: Additional browser launch arguments
- **PUPPETEER_TIMEOUT**: Default navigation timeout in milliseconds

## Example Use Cases
- "Navigate to example.com and take a screenshot"
- "Scrape the product prices from this e-commerce page"
- "Fill out the contact form and submit it"
- "Take a screenshot of the login modal dialog"
- "Extract all links from the navigation menu"
- "Convert this documentation page to PDF"
- "Monitor network requests while loading the dashboard"
- "Test if the search functionality returns correct results"
- "Automate login flow and capture session cookies"
- "Extract structured data from a table on the page"

## Benefits
- **Real Browser Environment**: Tests/scrapes as users see it
- **JavaScript Support**: Handles SPAs and dynamic content
- **Visual Verification**: Screenshots for debugging and validation
- **Flexible Automation**: Programmatic control over browser actions
- **Network Control**: Intercept/modify requests and responses
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **No Manual Setup**: Auto-downloads compatible browser version

## Current Limitations
- **Resource Intensive**: Browser automation requires significant memory/CPU
- **Speed**: Slower than lightweight HTTP clients for simple requests
- **Stability**: Browser crashes can affect automation reliability
- **Anti-Bot Measures**: Some sites detect and block Puppeteer
- **Windows Environment**: May require additional setup on Windows
- **Archived Status**: Official server moved to archived repository (community maintained)

## Prerequisites
- Node.js installed (for npx execution)
- Claude Code with MCP support
- Sufficient disk space for Chromium download (~170MB)
- Internet connection for initial browser download
- Adequate system resources (RAM: 512MB+ per browser instance)

## Security Considerations
- **Untrusted Sites**: Exercise caution when automating untrusted websites
- **Credentials**: Avoid hardcoding passwords in automation scripts
- **Network Isolation**: Consider sandbox/VM for untrusted automation
- **Data Privacy**: Be aware of data sent to/from automated sites
- **CAPTCHA/Bot Detection**: Respect site terms of service

## Additional Resources
- **Official Puppeteer Docs**: https://pptr.dev/
- **MCP Repository**: https://github.com/modelcontextprotocol/servers
- **Claude MCP Servers**: https://www.claudemcp.com/servers/puppeteer
- **Community Implementations**: Various GitHub repositories with enhanced features

## Troubleshooting
- **Browser Download Fails**: Check internet connection and firewall settings
- **Execution Permission**: Ensure Chrome binary has execute permissions
- **Memory Issues**: Reduce concurrent browser instances
- **Timeout Errors**: Increase PUPPETEER_TIMEOUT for slow-loading pages
- **Windows Specific**: May need to install Visual C++ Redistributable

## Notes
- Puppeteer automatically downloads a compatible Chromium version on first run
- Headless mode is recommended for server environments
- Screenshot quality can be controlled via tool parameters
- Browser instances are cleaned up automatically after use
- Consider using stealth plugins for sites with bot detection
- Community variants may offer additional features beyond official server