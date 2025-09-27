# Repository Guidelines

## Project Structure & Module Organization
- Top-level projects: `Agents/` (docs), `MCPs/` (docs), `prompt-enhancer/` (Node CLI), `puppeteer-mcp/` (Node MCP server), `Cosy Crime Website/` and `RhubarbPress Website/` (static sites), plus various notes (e.g., `CLAUDE.md`).
- Node packages: source in `src/` (e.g., `prompt-enhancer/src`), entry points like `index.js`, tests in `tests/`.
- Static sites: HTML at the directory root (e.g., `index.html`, `about.html`) with assets in subfolders like `Photos/`.

## Build, Test, and Development Commands
- Node projects (run inside each project directory):
  - `npm ci` — install dependencies exactly.
  - `npm start` — run the app (e.g., `puppeteer-mcp` server, CLI entry).
  - `npm run dev` — interactive/dev mode if provided (see `prompt-enhancer`).
  - `npm test` — run package tests (e.g., `prompt-enhancer/tests/test.js`).
  - `npm run build` — build step if defined.
- Static sites:
  - Open `index.html` in a browser, or serve locally: `python3 -m http.server` (from the site folder).

## Coding Style & Naming Conventions
- JavaScript (Node >= 16): CommonJS modules (`require`, `module.exports`), semicolons required, 2-space indentation, single quotes preferred.
- Filenames: lower-case with hyphens where needed; directories use kebab-case (e.g., `puppeteer-mcp`, `prompt-enhancer`).
- Keep functions small and single-purpose; prefer explicit names (`get_page_info`, `wait_for_selector`).

## Testing Guidelines
- Frameworks are minimal; tests are plain Node scripts in `tests/` (e.g., `tests/test.js`).
- Add new tests as `tests/*.test.js`. Keep tests deterministic; avoid network unless mocked.
- Run tests per package via `npm test` in that package directory.

## Commit & Pull Request Guidelines
- Use Conventional Commits style where practical: `feat:`, `fix:`, `docs:`, `chore:`, `test:`.
- Commits should be scoped to one subproject; include paths in the body if touching multiple (e.g., `prompt-enhancer: ...`).
- PRs: clear description, affected folders, run commands used, and screenshots for site changes. Link issues where applicable.

## Security & Configuration Tips
- Do not commit secrets; prefer `.env` (not present by default) and document required vars in package README.
- For automation or scraping, respect robots and legal terms; avoid hardcoding credentials.

## Agent-Specific Instructions
- Scope changes to the relevant subfolder; avoid cross-project edits unless necessary.
- Prefer `rg` for fast code search and check per-package `package.json` before adding tooling.
- Keep patches minimal and consistent with existing style; add tests when introducing behavior.

