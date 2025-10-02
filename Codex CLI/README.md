# Codex CLI Quick Reference

## Session Launch
- `codex` - default workspace-write sandbox with `on-failure` approvals; commands run sandboxed and prompt only after a blocked action.
- `codex --full-auto` - shortcut for `--ask-for-approval on-failure --sandbox workspace-write`.
- `codex --ask-for-approval on-request --sandbox workspace-write` - decide upfront which commands run with elevated access.
- `codex --ask-for-approval never --sandbox workspace-write` - skip approval prompts; commands that need escalation will fail instead.
- `codex --ask-for-approval untrusted` - require approval for almost every command; safest when exploring unfamiliar repos.
- `codex --sandbox read-only` - block writes entirely; expect approval prompts whenever a command needs broader access.
- `codex --sandbox danger-full-access` - lift filesystem restrictions (only combine with a trusted environment).
- Combine flags as needed, e.g. `codex --ask-for-approval on-failure --sandbox danger-full-access` for fewer prompts and unrestricted filesystem access.

## Handy Prompts
- `Show me the active sandbox, approval, and network settings.` - quick environment check.
- `List the files I changed in this session.` - helpful before committing.
- `Summarise the differences between <file A> and <file B>.` - rapid diff explanation.
- `Draft a remediation plan for [issue], then apply it.` - enforces plan/execute pattern.
- `Generate test cases for the changes you just made.` - encourages verification steps.

## Workflow Tips
- Prefix shell commands with `bash -lc` (or stay in PowerShell) so scripts run reliably.
- Use `rg` for fast searches (`rg "pattern" -g "*.js"`).
- Keep documentation in the relevant project folder; mirror any database work with a short note.
- When raising privileges, note the reason in the session log for future audits.
- Restore restrictive settings once high-risk work is complete to avoid accidental destructive commands.
