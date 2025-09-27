# Codex Installation

## Overview
This conversation documents the installation and setup of OpenAI Codex CLI on Windows.

## Installation Process

### Initial Attempt
- First tried installing with `npm install -g @openai/codex-cli` but this package was not found
- The package was deprecated as OpenAI moved Codex functionality into other tools

### Correct Installation
Used Context7 MCP to find the proper installation method:

```bash
npm install -g @openai/codex
```

### Verification
Confirmed installation with:
```bash
codex --version
# Output: codex-cli 0.39.0
```

## Authentication
- Used existing ChatGPT login credentials
- Ran `codex login` which opened browser authentication
- Successfully authenticated with OpenAI account

## PowerShell Issue
- Codex CLI has execution policy issues in PowerShell
- Error: "running scripts is disabled on this system"
- Current execution policy: Restricted

### Solution
To use in PowerShell, run as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Alternative: Use Command Prompt (cmd) where it works without policy changes.

## Usage
- `codex` - Start interactive coding session
- `codex "your prompt here"` - Run with specific prompt
- `codex --help` - See all available options

## Key Commands Available
- `codex exec` - Run non-interactively
- `codex login/logout` - Manage authentication
- `codex mcp` - Manage MCP servers
- `codex resume` - Resume previous session
- `codex apply` - Apply latest diff to working tree

## Notes
- Codex CLI is a local coding agent that helps read, modify, and run code
- Works with ChatGPT authentication
- Supports various AI providers through configuration
- Can be configured via `~/.codex/config.toml`