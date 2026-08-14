# Changelog

All notable changes to this project will be documented in this file.

## 0.3.1 — Unreleased

### Fixed
- Parse ANSI state transitions at Unicode-scalar granularity, including combined string introducers, interrupted controls, combining-suffix ST, and embedded C0/DEL/CRLF bytes.
- Preserve recovered SGR state during table slicing and measure combining suffixes after re-clustering so truncated rows remain balanced and within width.
- Honor CAN/SUB cancellation for control strings and strip two-byte ESC/CSI finals even when Swift groups them with a trailing combining mark.
- Preserve visible suffixes after malformed bounded ESC and CSI controls while still dropping unterminated control-string payloads.
- Strip complete ESC sequences with intermediate bytes, including terminal character-set designators, without leaking their final byte into plain output or display-width calculations.
- Drop incomplete terminal controls through end of input and treat BEL as a terminator only for OSC, preventing malformed control payloads from leaking into plain output or display-width calculations.
- Preserve automatic TTY-based color detection in the CLI while keeping redirected and `--out` file output free of ANSI styling by default.
- Keep truncated tables within their display-width budget while preserving balanced ANSI styling, OSC-8 links, and wide-character ellipsis markers.
- Preserve visible content and matching BEL, ST, and C1 ST terminators for OSC-8 links, strip complete 7-bit and 8-bit CSI/OSC/DCS/SOS/PM/APC controls with one shared scanner, and keep the no-control fast path to one scan.
- Share foreground/background ANSI color parsing and ignore malformed custom hex colors instead of rendering them as white.

## 0.3.0 — 2026-08-02

### Added
- Add Ubuntu 24.04 support for the library and CLI, with Linux CI and development-container coverage. Thanks @nnabeyang.

### Changed
- Refresh the pnpm toolchain pin.

## 0.2.2 — 2026-07-15

### Changed
- Bump package metadata to 0.2.2, refresh the pnpm toolchain pin, and stabilize formatting across tool updates.

## 0.2.1 — 2026-04-28

### Changed
- Refresh SwiftPM dependency pins and package-manager metadata.
- Apply SwiftFormat to keep the package warning-free.

## 0.2.0 — 2026-01-18

### Added
- Demo CLI example for exercising rendering output.
- DocC catalog plus Swift Package Index metadata.

### Fixed
- Demo CLI example formatting.

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
