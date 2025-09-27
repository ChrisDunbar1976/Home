# GitHub Repository Configuration

## Issue
User noticed an unfamiliar GitHub repository showing in VS Code's Source Control panel and wanted to identify and change it.

## Investigation
- Current working directory: `C:\Users\Chris Dunbar\Tech Projects`
- Found git repository in `SQL-AI-samples` subdirectory
- Repository was connected to: `https://github.com/Azure-Samples/SQL-AI-samples.git`

## Solution
Changed the remote repository to user's personal GitHub repository:

1. **Removed existing remote:**
   ```bash
   cd SQL-AI-samples
   git remote remove origin
   ```

2. **Added new remote:**
   ```bash
   git remote add origin https://github.com/ChrisDunbar1976/Home.git
   ```

3. **Verified change:**
   ```bash
   git remote -v
   ```
   Result: Now points to `https://github.com/ChrisDunbar1976/Home.git`

## Next Steps
User needs to refresh VS Code to see the updated repository:
- Option 1: Reload Window (`Ctrl+Shift+P` → "Developer: Reload Window")
- Option 2: Close and reopen folder
- Option 3: Refresh Source Control panel

## Status
Git repository successfully reconfigured. VS Code refresh pending.