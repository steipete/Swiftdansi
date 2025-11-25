# Swiftdansi

Swift 6.2 Markdown → ANSI renderer and CLI, inspired by [Markdansi](../Markdansi). Targets Apple platforms (macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+) and ships a zero-dependency runtime (`swift-markdown` + `swift-displaywidth`).

## Library

```swift
import Swiftdansi

let ansi = render("# Hello **world**", options: RenderOptions(width: 60))

let renderNoWrap = createRenderer(options: RenderOptions(wrap: false))
let out = renderNoWrap("A very long line without wrapping")

let plain = strip("link to [x](https://example.com)")
```

### Options
- `wrap` (default `true`), `width` (TTY columns or 80 when wrapping).
- `color` (default TTY), `hyperlinks` (auto when color is on).
- `theme`: `default | dim | bright | solarized | monochrome | contrast` or pass a `customTheme`.
- Lists: `listIndent` (default 2).
- Quotes: `quotePrefix` (default `│ `).
- Tables: `tableBorder unicode|ascii|none`, `tablePadding`, `tableDense`, `tableTruncate`, `tableEllipsis`.
- Code: `codeBox`, `codeGutter`, `codeWrap`.
- `highlighter` hook `(code, lang?) -> String` lets you inject ANSI-colored code.

## CLI

```
swiftdansi [--in FILE] [--out FILE] [--width N] [--no-wrap] [--no-color] [--no-links]
          [--theme default|dim|bright|solarized|monochrome|contrast]
          [--list-indent N] [--quote-prefix STR]
          [--table-border unicode|ascii|none] [--table-padding N] [--table-dense]
          [--table-truncate] [--table-ellipsis STR]
          [--code-wrap] [--code-box] [--code-gutter]
```

- Input: stdin if `--in` missing or `-`.
- Output: stdout unless `--out` given.
- Handles SIGPIPE gracefully for pipelines.

## Development
- Build: `swift build`
- Test (Swift Testing): `swift test`

See `docs/spec.md` for detailed behavior notes and parity expectations with Markdansi.
