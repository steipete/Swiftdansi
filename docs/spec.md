# Swiftdansi – Design Spec

Goal: Swift 6.2 Markdown → ANSI renderer and CLI, mirroring Markdansi behavior with no runtime dependencies beyond `swift-markdown` and accurate width handling via `swift-displaywidth`.

## Core Dependencies
- `swift-markdown` for GFM-compatible parsing (tables, task lists, strikethrough, autolink literals).
- `swift-displaywidth` for grapheme/emoji-aware width calculations.
- `swift-argument-parser` for the CLI.

## Surface Area
### Library
- `render(_ markdown: String, options: RenderOptions = .init()) -> String`
- `createRenderer(options:) -> (String) -> String`
- `strip(_ markdown: String, options:) -> String` (forces `color=false`, `hyperlinks=false`, preserves wrap flag).

`RenderOptions` fields match Markdansi:
- `wrap` (default `true`), `width` (default TTY cols or 80 when wrapping).
- `hyperlinks` (default: auto when color enabled), `color` (default: TTY).
- `theme` / `customTheme`, built-ins: `default | dim | bright | solarized | monochrome | contrast`.
- `listIndent` (default 2), `quotePrefix` (default `│ `).
- Table: `tableBorder unicode|ascii|none`, `tablePadding`, `tableDense`, `tableTruncate`, `tableEllipsis`.
- Code: `codeBox`, `codeGutter`, `codeWrap`.
- `highlighter` closure `(code, lang?) -> String` applied to fenced code lines.

### CLI
`swiftdansi [--in FILE] [--out FILE] [--width N] [--no-wrap] [--no-color] [--no-links] [--force-links] [--theme ...] [--list-indent N] [--quote-prefix STR] [--table-border ascii|unicode|none] [--table-padding N] [--table-dense] [--table-truncate] [--table-ellipsis STR] [--code-wrap] [--code-box] [--code-gutter]`
- Input: stdin when `--in` missing or `-`.
- Output: stdout unless `--out` provided.
- Handles SIGPIPE for filter-style use.

## Behavior & Rules
- Uses swift-markdown AST; ignores inline HTML; treats `mailto:` links as plain text.
- Hyperlinks: OSC‑8 when enabled and color is on; otherwise falls back to underlined label plus `(url)` suffix.
- Wrapping: word-wrap on spaces using display width; soft breaks collapse to spaces (indent trimmed) unless adjacent to definitions; preserves hard breaks; width ignored when `wrap=false`. Wrap tries to avoid orphaned trailing articles/prepositions when possible.
- Code blocks: optional box with label, optional line-number gutter; wraps lines when `codeWrap=true` except for diff-like blocks; single-line blocks omit the box.
- Tables: unicode/ascii/none borders, padding, alignment from GFM markers, optional truncation with ellipsis; width balancing shrinks widest columns until fit.
- Lists: supports ordered/unordered and task checkboxes; tight rendering by default.
- Blockquotes: wraps with styled prefix (`│ `).
- Thematic breaks: 40-character em-dash line, clamped by width when wrapping.

## Platforms & Toolchain
- Platforms: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+.
- Swift 6.2 language mode. Build/test with SwiftPM + Swift Testing.

## Testing
- Swift Testing suite covering inline formatting, wrapping, hyperlinks on/off, code boxes, and table rendering; more cases can be added mirroring Markdansi vitest fixtures.

## Non-goals (v1)
- Syntax highlighting bundle (only hook provided).
- Image/HTML passthrough, math, footnotes.
