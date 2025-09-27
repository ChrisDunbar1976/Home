# Figma MCP Server Integration

## Overview
Figma provides an official Dev Mode MCP server that brings design context directly into AI coding workflows, enabling seamless design-to-code translation with access to design tokens, variables, and structured component data.

## Key Capabilities
- **Design-to-Code Generation**: Convert Figma selections to React + Tailwind code structures
- **Design Token Access**: Extract and reference Figma variables (colors, spacing, typography)
- **Component Analysis**: Understand design structure at a semantic level vs visual inspection
- **Variable Integration**: Direct access to design system tokens in generated code
- **Framework Flexibility**: Generated code serves as starting point for any framework

## Integration Options

### 1. Official Dev Mode MCP Server
- **Status**: Open beta (as of 2024)
- **Platform**: Figma's official implementation
- **Access**: Through Figma Dev Mode
- **Authentication**: Figma access tokens required

### 2. Community Implementations
- Multiple GitHub repositories available
- Various approaches to Figma API integration
- Third-party MCP server implementations
- Custom integrations for specific workflows

## Claude Code Configuration

Add to your `.claude.json` file:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@figma/dev-mode-mcp"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "figd_..."
      }
    }
  }
}
```

## Authentication Requirements
- **Figma Access Token**: Required for API access
- **Project Permissions**: Read access to Figma files
- **Dev Mode Access**: May require Figma Professional/Organization plan
- **File Sharing**: Proper sharing permissions for target files

## Available Tools
The server provides key functions for design analysis:
- **get_code**: Provides structured React + Tailwind representation
- **get_variable_defs**: Extracts design variables and styles
- **Component inspection**: Access to Figma component properties
- **Design system integration**: Token and variable extraction

## Compatible Tools
- **Claude Code**: Full integration support
- **VS Code + Copilot**: GitHub Copilot integration
- **Cursor**: AI-powered code editor support
- **Windsurf**: Development environment integration
- **Other AI Coding Tools**: Various assistant compatibility

## Setup Process
1. **Figma Account**: Ensure access to target design files
2. **Generate Access Token**: Create token in Figma account settings
3. **Install MCP Server**: Add to Claude Code configuration
4. **Configure Authentication**: Set up token environment variables
5. **Test Integration**: Verify connection to Figma files

## Example Use Cases
- "Generate React component from this Figma selection"
- "Extract all design tokens used in this component"
- "Convert this design to Tailwind CSS classes"
- "Show me the spacing variables used in this layout"
- "Generate TypeScript types from this design system"

## Benefits
- **Structural Understanding**: AI understands design intent vs just visual appearance
- **Design System Consistency**: Maintains token usage in generated code
- **Framework Agnostic**: Starting point works for any tech stack
- **Variable Preservation**: Direct reference to design system tokens
- **Workflow Integration**: Seamless designer-developer handoff

## Current Limitations
- **Beta Status**: Some functions may be unavailable or unstable
- **Component Updates**: Better at new component generation than surgical edits
- **Authentication Complexity**: Requires proper token management
- **Access Requirements**: May need paid Figma plan for full Dev Mode access
- **File Permissions**: Requires appropriate sharing/access rights

## Prerequisites
- Figma account with file access
- Figma access token with appropriate permissions
- Claude Code with MCP support
- Target design files accessible via Figma API

## Additional Resources
- **Official Documentation**: Figma Dev Mode MCP documentation
- **Community Servers**: GitHub repositories with alternative implementations
- **Figma API Docs**: https://www.figma.com/developers/api
- **Design Tokens**: Figma variables and design system documentation

## Notes
- Dev Mode access may require Figma Professional plan
- Community implementations may have different feature sets
- Token security is crucial for production use
- Design file organization affects extraction quality
- Integration works best with well-structured design systems