# Repository Guidelines

## Start Here
- Load shared guardrails first: skim `~/Projects/agent-scripts/AGENTS.md` (and `TOOLS.md` if present) before coding.
- Re-run any repo helpers that surface docs/rules (e.g., `pnpm mcp:docs:list`) when you suspect instructions changed.

## Project Structure & Modules
- Sources live in `Sources/Swiftdansi` (renderer, options, styler); CLI entry points under `Sources/swiftdansi`.
- Tests: `Tests/SwiftdansiTests` (Swift‑Testing). Keep new cases near the behavior they cover.
- Docs & marketing: `README.md`, images in repo root (e.g., `swiftdansi.png`).

## Build, Test & Dev Commands
- `swift build` — debug build for all targets.  
- `swift test` — run Swift‑Testing suite (default gate).  
- `pnpm build` / `pnpm test` — wrappers to run the same build/test via workspace scripts.  
- `pnpm lint` / `pnpm format` — SwiftLint and SwiftFormat; run before commits when source changes.

## Coding Style & Naming
- Swift 6.2, 4‑space indent; explicit `self` required (SwiftFormat enforces).
- Prefer small, focused extensions over sprawling files; keep functions short and typed (`Sendable` where appropriate).
- Avoid `Any`; favor concrete types and enums for option sets. Keep public concurrency annotations accurate.
- Match existing renderer patterns; update canonical files instead of creating suffixed copies.

## Testing Guidelines
- Use Swift‑Testing (`@Test`) with descriptive function names (e.g., `snapshotDiffBoxMatchesMarkdansi`).
- When fixing a bug, add or extend a test that fails before your change and passes after.
- Keep snapshots inline as string literals; trim trailing whitespace to reduce diff noise.

## Commit & PR Guidelines
- Conventional Commits: `feat|fix|chore|docs|test|refactor|build|ci|style|perf` (scope optional).
- Stage/commit via the usual git workflow; group related file changes per commit.
- PRs: summarize intent, list build/test commands run, note doc/asset updates, include screenshots when user‑visible output changes (e.g., README banner).

## Security & Configuration Tips
- No bundled secrets; environment/config comes from developer machine. Do not check in keys or tokens.
- Treat generated artifacts as derived—regenerate from sources instead of editing output directly.

## Troubleshooting
- If builds stall, clear SwiftPM caches (`swift package reset`) and rerun `swift build`.
- When formatter/lint disagree, run `pnpm format` then `pnpm lint` to see remaining violations.
