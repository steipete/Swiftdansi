# 🎨 Swiftdansi: Wraps, colors, links—no baggage.

<p align="center">
  <img src="./swiftdansi.png" alt="Swiftdansi README header" width="1100">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-1f6feb?style=flat-square" alt="License MIT"></a>
  <a href="https://www.swift.org"><img src="https://img.shields.io/badge/Swift-6.2-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 6.2"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-0078d7?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+"></a>
  <a href="https://www.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-17%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="iOS 17+"></a>
  <a href="https://www.apple.com/tvos/"><img src="https://img.shields.io/badge/tvOS-17%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="tvOS 17+"></a>
  <a href="https://www.apple.com/watchos/"><img src="https://img.shields.io/badge/watchOS-10%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="watchOS 10+"></a>
  <a href="https://www.apple.com/visionos/"><img src="https://img.shields.io/badge/visionOS-1%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="visionOS 1+"></a>
  <a href="https://www.swift.org/install/linux/"><img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu 24.04"></a>
</p>

Swift 6.2 Markdown → ANSI renderer and CLI, modeled on [Markdansi](https://github.com/steipete/Markdansi) but built with `swift-markdown` + `swift-displaywidth`. Fast, zero runtime deps, and available on macOS 14+, iOS 17+, tvOS 17+, watchOS 10+, visionOS 1+, and Ubuntu 24.04.

## Features
- GFM blocks & inline: headings, lists/tasks, blockquotes, code (boxed/labels/gutter), tables (align/pad/dense/truncate/ellipsis), HR, strike, links/autolinks, inline code, emphasis/strong.
- OSC‑8 hyperlinks with auto-detect + force/disable flags; plain suffix fallback when color off.
- Unicode-aware width/wrapping (emoji, CJK) using swift-displaywidth.
- Themes: default, dim, bright, solarized, monochrome, contrast; custom theme support.
- Highlighter hook: inject your own ANSI coloring for fenced code.
- CLI parity with Markdansi flags, plus `--force-links`.

## Install
SwiftPM package:
```swift
.package(url: "https://github.com/steipete/Swiftdansi.git", from: "0.2.1")
```
Targets: `Swiftdansi` (library), `swiftdansi` (CLI binary).

## Library usage
```swift
import Swiftdansi

// One-off render
let ansi = render("# Hello **world**", options: RenderOptions(width: 60))

// Reusable renderer
let renderNoWrap = createRenderer(options: RenderOptions(wrap: false))
let out = renderNoWrap("A very long line without wrapping")

// Plain text (no ANSI/OSC)
let plain = strip("link to [x](https://example.com)")

// Custom theme & highlighter
let custom = createRenderer(options: RenderOptions(
    theme: .bright,
    highlighter: { code, _ in code.uppercased() }
))
```

### Options (RenderOptions)
- `wrap` (default `true`), `width` (TTY cols or 80 when wrapping).
- `color` (default TTY), `hyperlinks` (auto when color on), `force-links` / `no-links` via CLI.
- `theme`: `.default | .dim | .bright | .solarized | .monochrome | .contrast` or `customTheme`.
- Lists: `listIndent` (default 2), `listMarker` (default `-`, set to `"•"` for dotted lists like Markdansi).
- Quotes: `quotePrefix` (default `│ `).
- Tables: `tableBorder unicode|ascii|none`, `tablePadding`, `tableDense`, `tableTruncate`, `tableEllipsis`.
- Code: `codeBox`, `codeGutter`, `codeWrap`.
- `highlighter` `(code, lang?) -> String`.

## CLI
```
swiftdansi [--in FILE] [--out FILE] [--width N] [--no-wrap] [--no-color] [--no-links] [--force-links]
          [--theme default|dim|bright|solarized|monochrome|contrast]
          [--list-indent N] [--quote-prefix STR]
          [--table-border unicode|ascii|none] [--table-padding N] [--table-dense]
          [--table-truncate[=true|false]] [--table-ellipsis STR]
          [--code-wrap[=true|false]] [--code-box[=true|false]] [--code-gutter]
```
- Input: stdin if `--in` missing or `-`; output: stdout unless `--out`.
- Hyperlinks: auto-detect when color on; override with `--force-links` or `--no-links`.
- Handles SIGPIPE for pipelines.

## Example CLI (macOS and Linux)
Tiny demo CLI that uses the Swiftdansi library (Swift 6.2):

```
cd Examples/SwiftdansiCLI
swift run SwiftdansiDemo --
swift run SwiftdansiDemo -- ../../README.md --theme bright --width 72
```

## Development
- Build: `swift build` (or `pnpm build`)
- Test: `swift test` (or `pnpm test`)
- Lint: `pnpm lint` (SwiftLint, config in `.swiftlint.yml`)
- Format: `pnpm format` (SwiftFormat, config in `.swiftformat`)

### Linux development container
Open this repository in VS Code and select **Dev Containers: Reopen in Container** to use the
Swift 6.3.2 Ubuntu development environment. The container mounts the workspace and Git directory
at their host paths, so it also works with Git worktrees.

Build and test the package inside the container with:

```sh
swift --version
swift build
swift test
```

## Testing & CI
- Tests (Swift-Testing): `swift test`
- CI: `.github/workflows/ci.yml` builds and tests on macOS and Ubuntu 24.04.

## License
MIT

## Inspiration
Built as a Swift port of [Markdansi](https://github.com/steipete/Markdansi); see that project for the original TypeScript implementation and behavior notes.
