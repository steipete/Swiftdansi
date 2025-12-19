# Changelog

All notable changes to this project will be documented in this file.

## 0.1.1 — 2025-12-19

### Added
- Soft line breaks now collapse to spaces (with indentation trimmed) while hard breaks remain, mirroring Markdansi rendering rules.
- Wrapping avoids orphaned trailing articles/prepositions when possible for cleaner line breaks.

### Changed
- Wrap logic now trims trailing whitespace when emitting lines and aligns orphan-handling behavior with Markdansi.
- Added regression tests for soft-break normalization and orphan-aware wrapping.

## 0.1.0 — 2025-11-26

### Added
- Swift 6.2 Markdown → ANSI renderer with OSC‑8 hyperlinks, theme support (default/dim/bright/solarized/monochrome/contrast), Unicode‑aware width + wrapping, and code/table/blockquote/list rendering tuned for terminals.
- CLI parity with the Markdansi flags: `--no-wrap`, `--width`, `--no-color`, `--no-links`, `--force-links`, theme selection, table border/padding/dense/truncate/ellipsis toggles, and code box/gutter/wrap controls.
- New `listMarker` option mirrors Markdansi defaults for unordered items; renderer honors custom markers while keeping ordered numbering intact.
- Footer-style link definitions now keep a blank line before the footer and normalize curly quotes, matching Markdansi output.
- Diff detection auto-labels boxed code blocks even when the language isn’t specified, improving parity with upstream snapshots.
- Adjacent code blocks (including those inside single-item lists) now merge into one box to reduce visual noise; trailing blank lines inside merged code are trimmed.
- README hero banner (`swiftdansi.png`) plus platform badges for macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, and visionOS 2+; added contributor guide (`AGENTS.md`).

### Changed
- Reference-like code blocks strip indentation with Swift regex literals (`replacing(/^[ \\t>]+/gm, with: \" \")`) for faster, clearer normalization.
- Renderer tests expanded to cover diff labeling, definition footer spacing, table snapshots, and code-list merging to lock behavior against Markdansi snapshots.

### Fixed
- Reference definition continuations no longer duplicate whitespace; newline trimming ensures merged code sections keep box borders tight.
- Diff code blocks avoid wrapping while still respecting width constraints for other languages, preventing clipped gutters in snapshot tests.
