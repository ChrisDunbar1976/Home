# Claude Code Uninstall

**Date**: 2025-09-29

## Actions
- Removed the `anthropic.claude-code-1.0.127` extension folder from `C:/Users/cdunbar/.vscode/extensions` and pruned its entry from `extensions.json`.
- Cleared cached installers at `C:/Users/cdunbar/AppData/Roaming/Code/CachedExtensionVSIXs`.
- Deleted Anthropic application data directories: `C:/Users/cdunbar/AppData/Local/AnthropicClaude` and `C:/Users/cdunbar/AppData/Local/claude-cli-nodejs`.
- Removed user-level config files `C:/Users/cdunbar/.claude.json` and `.claude.json.backup`.
- Purged Anthropic/Claude references from relevant `HKCU` registry keys (ApplicationAssociationToasts, Explorer FeatureUsage, AppCompatFlags Store, MuiCache).

## Verification
- `Get-ChildItem C:/Users/cdunbar/.vscode/extensions` shows no Anthropic folders.
- `reg query HKCU /f Claude /s` and `/f Anthropic /s` report zero matches.
- `Get-ChildItem $env:LOCALAPPDATA -Directory` returns no Claude-related directories.
