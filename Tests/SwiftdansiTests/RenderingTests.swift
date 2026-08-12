import Foundation
import SwiftdansiCLI
import Testing
@testable import Swiftdansi

struct RenderingTests {
    @Test
    func `inline formatting`() {
        let out = strip("Hello _em_ **strong** `code` ~~gone~~", options: RenderOptions(width: 80))
        #expect(out.contains("em"))
        #expect(out.contains("strong"))
        #expect(out.contains("code"))
        #expect(out.contains("gone"))
    }

    @Test
    func `wrapping paragraphs`() {
        let out = strip(
            "one two three four five six seven eight nine ten",
            options: RenderOptions(wrap: true, width: 10))
        let first = out.split(separator: "\n").first ?? ""
        #expect(first.count <= 10)
    }

    @Test
    func `soft breaks collapse to spaces`() {
        let out = strip("Hello\nworld", options: RenderOptions(wrap: true, width: 80))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello world")
    }

    @Test
    func `soft breaks trim indentation`() {
        let out = strip("Hello\n  world", options: RenderOptions(wrap: true, width: 200))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello world")
    }

    @Test
    func `hard breaks preserved`() {
        let out = strip("line one  \nline two", options: RenderOptions(wrap: true, width: 80))
        let lines = out.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count > 1)
    }

    @Test
    func `hyperlinks toggle`() {
        let rendered = render(
            "[x](https://example.com)",
            options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        #expect(rendered.contains("\u{001B}]8;;https://example.com"))
        let plain = render(
            "[x](https://example.com)",
            options: RenderOptions(wrap: false, hyperlinks: true, color: false))
        #expect(plain.contains("(https://example.com)"))
        #expect(!plain.contains("\u{001B}]8;;"))
    }

    @Test
    func `code box with label`() {
        let md = "```swift\nlet x = 1\nlet y = 2\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        #expect(out.contains("┌"))
        #expect(out.contains("[swift]"))
        #expect(out.contains("let x = 1"))
    }

    @Test
    func `table renders`() {
        let md = """
        | h1 | h2 |
        | --- | --- |
        | a | b |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 40))
        #expect(out.contains("h1"))
        #expect(out.contains("a"))
    }

    @Test
    func `long url overflows when wrapped`() {
        let url = "https://example.com/averylongpathwithoutspaces"
        let out = strip(url, options: RenderOptions(wrap: true, width: 10))
        #expect(out.contains(url))
    }

    @Test
    func `task list renders`() {
        let out = strip("- [ ] open\n- [x] done", options: RenderOptions())
        #expect(out.contains("[ ] open"))
        #expect(out.contains("[x] done"))
    }

    @Test
    func `soft breaks collapse inside list items`() {
        let md =
            "- Section IV (signature): A concluding line stating the document was \"typed on 2025-12-18 with a\n" +
            "  stubborn cursor.\""
        let out = strip(md, options: RenderOptions(wrap: true, width: 200))
        #expect(out.contains("with a stubborn cursor."))
        #expect(!out.contains("\n\n"))
    }

    @Test
    func `blockquote prefix`() {
        let out = strip("> quoted line", options: RenderOptions())
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("│ "))
    }

    @Test
    func `code gutter wraps segments`() {
        let md = "```\n0123456789ABCDEFG\n```"
        let out = render(
            md,
            options: RenderOptions(wrap: true, width: 12, color: false, codeBox: false, codeGutter: true))
        let lines = out.split(separator: "\n")
        #expect(lines.first?.hasPrefix("1") == true)
    }

    @Test
    func `table alignment and truncate`() {
        let md = """
        | l | c | r |
        | :-- | :-: | --: |
        | Supercalifragilistic | mid | tail |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 18, tableTruncate: true))
        #expect(out.contains("…"))
    }

    @Test
    func `table dense none border`() {
        let md = """
        | h1 | h2 |
        | --- | --- |
        | a | b |
        """
        let out = strip(
            md,
            options: RenderOptions(wrap: true, tableBorder: TableBorder.none, tablePadding: 0, tableDense: true))
        #expect(!out.contains("┌"))
        #expect(out.contains("h1"))
        #expect(out.contains("|"))
    }

    @Test
    func `code gutter multi digit`() {
        let body = (1...12).map { "l\($0)" }.joined(separator: "\n")
        let md = "```\n\(body)\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false, codeGutter: true))
        #expect(out.contains("12 "))
    }

    @Test
    func `boxed label width`() {
        let md = "```superlonglanguageid\nfoo\nbar\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first?.contains("[superlonglanguageid]") == true)
        #expect(lines.first?.count ?? 0 >= (lines.dropFirst().first?.count ?? 0))
    }

    @Test
    func `diff blocks do not wrap`() {
        let md = """
        ```
        --- a/foo
        +++ b/foo
        @@ -1 +1 @@
        - a very very very very long line
        + another very very very very long line
        ```
        """
        let out = render(md, options: RenderOptions(wrap: true, width: 20, color: false))
        let longLine = out.split(separator: "\n").first { $0.contains("very very very") }
        #expect((longLine?.count ?? 0) > 30)
    }

    @Test
    func `single line code no box`() {
        let md = "```\nsolo\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        #expect(!out.trimmingCharacters(in: .whitespacesAndNewlines).contains("┌"))
    }

    @Test
    func `hyperlink suffix when off`() {
        let out = strip("[link](https://example.com)", options: RenderOptions())
        #expect(out.contains("link (https://example.com)"))
    }

    @Test
    func `mailto not hyperlinked in table`() {
        let md = """
        | File | Size |
        | --- | --- |
        | icon_16x16@2x.png | 32 |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 40, tableTruncate: false))
        #expect(!out.contains("\u{001B}]8;;"))
    }

    @Test
    func `ascii border table`() {
        let md = """
        | h1 | h2 |
        | --- | --- |
        | a | b |
        """
        let out = strip(md, options: RenderOptions(wrap: true, tableBorder: .ascii, tablePadding: 2))
        #expect(out.contains("+"))
    }

    @Test
    func `table truncate disabled shows full cell`() {
        let md = """
        | col |
        | --- |
        | Supercalifragilistic |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 10, tableTruncate: false))
        #expect(out.contains("Supercalifragilistic"))
        #expect(!out.contains("…"))
    }

    @Test
    func `table truncation balances inline ANSI styling`() {
        let md = """
        | Cell |
        | --- |
        | **averylongstyledvalue** |
        """
        let out = render(
            md,
            options: RenderOptions(wrap: true, width: 14, color: true, tablePadding: 0, tableTruncate: true))
        let body = out.split(separator: "\n").first(where: { stripANSI(String($0)).contains("avery") }).map(String.init)

        #expect(body?.contains("\u{001B}[1m") == true)
        #expect(body?.contains("\u{001B}[0m") == true)
        #expect(body?.contains("…") == true)
        #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= 14 })
    }

    @Test
    func `table truncation balances OSC hyperlinks`() {
        let url = "https://example.com/nested"
        let md = """
        | Link |
        | --- |
        | [averylonglinklabelthatexceeds](\(url)) |
        """
        let out = render(
            md,
            options: RenderOptions(
                wrap: true,
                width: 24,
                hyperlinks: true,
                color: true,
                tablePadding: 0,
                tableTruncate: true))
        let open = "\u{001B}]8;;\(url)\u{0007}"
        let close = "\u{001B}]8;;\u{0007}"
        let body = out.split(separator: "\n").first(where: { stripANSI(String($0)).contains("avery") }).map(String.init)

        #expect(body?.components(separatedBy: open).count == 2)
        #expect(body?.components(separatedBy: close).count == 2)
        #expect(body?.contains("…") == true)
        #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= 24 })
    }

    @Test
    func `ANSI scanner preserves content around ST terminated hyperlinks`() {
        let open = "\u{001B}]8;;https://example.com\u{001B}\\"
        let close = "\u{001B}]8;;\u{001B}\\"
        let linked = "\(open)visible label\(close)"

        #expect(stripANSI(linked) == "visible label")
        #expect(visibleWidth(linked) == visibleWidth("visible label"))
        #expect(stripANSI("\u{001B}[2Kvalue\u{001B}[1~") == "value")
        #expect(stripANSI("\u{009B}31mred\u{009B}0m") == "red")

        let c1Open = "\u{009D}8;;https://example.com\u{009C}"
        let c1Close = "\u{009D}8;;\u{009C}"
        #expect(stripANSI("\(c1Open)C1 label\(c1Close)") == "C1 label")
    }

    @Test
    func `table truncation balances ST terminated OSC hyperlinks`() {
        let open = "\u{001B}]8;;https://example.com\u{001B}\\"
        let close = "\u{001B}]8;;\u{001B}\\"
        let md = "| Link |\n|---|\n| \(open)averylonglinklabelthatexceeds\(close) |\n"
        let out = render(
            md,
            options: RenderOptions(
                wrap: true,
                width: 24,
                hyperlinks: false,
                color: true,
                tablePadding: 0,
                tableTruncate: true))
        let body = out.split(separator: "\n").first(where: { stripANSI(String($0)).contains("avery") }).map(String.init)

        #expect(body?.components(separatedBy: open).count == 2)
        #expect(body?.components(separatedBy: close).count == 2)
        #expect(body?.contains("…") == true)
        #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= 24 })

        let plain = strip(md, options: RenderOptions(wrap: true, width: 24, tablePadding: 0))
        #expect(plain.contains("avery"))
        #expect(!plain.contains("\u{001B}"))
    }

    @Test
    func `table truncation balances C1 OSC hyperlinks`() {
        let open = "\u{009D}8;;https://example.com\u{009C}"
        let close = "\u{009D}8;;\u{009C}"
        let md = "| Link |\n|---|\n| \(open)averylonglinklabelthatexceeds\(close) |\n"
        let out = render(
            md,
            options: RenderOptions(
                wrap: true,
                width: 24,
                hyperlinks: false,
                color: true,
                tablePadding: 0,
                tableTruncate: true))
        let body = out.split(separator: "\n").first(where: { stripANSI(String($0)).contains("avery") }).map(String.init)

        #expect(body?.components(separatedBy: open).count == 2)
        #expect(body?.components(separatedBy: close).count == 2)
        #expect(body?.contains("…") == true)
        #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= 24 })
    }

    @Test
    func `table truncation measures wide ellipsis by display width`() {
        let md = """
        | ID | Text |
        | --- | --- |
        | 1 | 東京大阪京都横浜名古屋 |
        """
        let out = render(
            md,
            options: RenderOptions(
                wrap: true,
                width: 20,
                color: false,
                tablePadding: 1,
                tableTruncate: true,
                tableEllipsis: "漢字"))

        #expect(out.contains("漢字"))
        #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= 20 })
    }

    @Test
    func `table truncation preserves Unicode grapheme boundaries`() {
        let cases = [
            ("漢字漢字漢字漢字漢字漢字漢字漢字", 12),
            (String(repeating: "カﾞ", count: 8), 10),
            (String(repeating: "🇺🇸", count: 8) + " done", 12),
        ]

        for (value, width) in cases {
            let md = "| Value |\n|---|\n| \(value) |\n"
            let out = strip(
                md,
                options: RenderOptions(wrap: true, width: width, tablePadding: 0, tableTruncate: true))
            #expect(out.contains("…"))
            #expect(out.split(separator: "\n").allSatisfy { visibleWidth(String($0)) <= width })
            let beforeEllipsis = out.split(separator: "…").first.map(String.init) ?? ""
            let regionalIndicators = beforeEllipsis.unicodeScalars.count(where: { scalar in
                (0x1F1E6...0x1F1FF).contains(scalar.value)
            })
            #expect(regionalIndicators.isMultiple(of: 2))
        }
    }

    @Test
    func `table padding dense combination`() {
        let md = """
        | a | b |
        | --- | --- |
        | c | d |
        """
        let out = strip(
            md,
            options: RenderOptions(wrap: true, tableBorder: .unicode, tablePadding: 3, tableDense: true))
        #expect(out.contains("┌"))
        #expect(out.contains("│   a    │"))
    }

    @Test
    func `theme default colors`() {
        let ansi = render("`inline`\n\n```\nblock\n```\n\n# H", options: RenderOptions(wrap: false, color: true))
        #expect(ansi.contains("\u{001B}[36m")) // cyan inline code
        #expect(ansi.contains("\u{001B}[32m")) // green block code
        #expect(ansi.contains("\u{001B}[33m")) // yellow heading
    }

    @Test
    func `theme dim adds dim attribute`() {
        let ansi = render("`inline`", options: RenderOptions(wrap: false, color: true, theme: .dim))
        #expect(ansi.contains("\u{001B}[2m"))
    }

    @Test
    func `custom highlighter applied`() {
        let md = "```\ncode\n```"
        let out = render(
            md,
            options: RenderOptions(wrap: false, color: false, highlighter: { code, _ in code.uppercased() }))
        #expect(out.contains("CODE"))
    }

    @Test
    func `cli force links overrides no color`() throws {
        let cmd = try SwiftdansiCommand.parse(["--force-links", "--no-color"])
        #expect(cmd.forceLinks)
        #expect(cmd.noColor)
    }

    @Test
    func `list of code blocks collapses`() {
        let md = "- ```\n  first\n  ```\n- ```\n  second\n  ```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let boxCount = out.count(where: { $0 == "┌" })
        #expect(boxCount == 1)
        #expect(out.contains("first"))
        #expect(out.contains("second"))
    }

    @Test
    func `reference like code not boxed`() {
        let md = """
        ```
        [1]: https://example.com/icon "
            Icon Composer Notes
        "
        ```
        """
        let out = render(md, options: RenderOptions(wrap: true, color: false))
        #expect(!out.contains("┌"))
        #expect(out.contains("[1]: https://example.com/icon"))
        #expect(out.contains("Icon Composer Notes"))
    }

    @Test
    func `hr clamped to forty`() {
        let md = "----"
        let out = strip(md, options: RenderOptions(wrap: true, width: 10))
        let line = out.split(separator: "\n").first ?? ""
        #expect(line.count <= 40)
    }

    @Test
    func `inline html ignored`() {
        let out = strip("<div>ignored</div>", options: RenderOptions())
        #expect(out.isEmpty)
    }

    @Test
    func `headings and hr render`() {
        let md = "# Title\n\n---\n"
        let out = strip(md, options: RenderOptions(wrap: true, width: 80))
        #expect(out.contains("Title"))
        #expect(out.contains("—"))
    }

    @Test
    func `wrap text edge cases`() {
        #expect(wrapText("", width: 5, wrap: true) == [""])
        #expect(wrapText("abc", width: 0, wrap: true) == ["abc"])
    }

    @Test
    func `wrap avoids trailing articles when possible`() {
        let md =
            "* **Section IV (signature):** A concluding line stating the document was \"typed on 2025-12-18 " +
            "with a stubborn cursor.\""
        let out = strip(md, options: RenderOptions(wrap: true, width: 100))
        let lines = out.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 2)
        #expect(!lines[0].hasSuffix("with a"))
        #expect(lines[1].contains("with a stubborn cursor."))
    }

    @Test
    func `wrap moves trailing article to next line`() {
        #expect(wrapText("hello the world", width: 11, wrap: true) == ["hello", "the world"])
    }

    @Test
    func `wrap moves trailing preposition article to next line`() {
        #expect(wrapText("walk in the rain", width: 11, wrap: true) == ["walk", "in the rain"])
    }

    @Test
    func `wrap does not treat punctuated words as orphans`() {
        #expect(wrapText("hello the, world", width: 11, wrap: true) == ["hello the,", "world"])
    }

    @Test
    func `loose list has blank line`() {
        let out = strip("- item 1\n\n- item 2", options: RenderOptions())
        let blanks = out.split(separator: "\n", omittingEmptySubsequences: false).count(where: { $0.isEmpty })
        #expect(blanks > 0)
    }

    @Test
    func `table underscore not linkified`() {
        let md = """
        | Filename | Size |
        | --- | --- |
        | icon_16x16.png | 16 |
        | icon_16x16@2x.png | 32 |
        """
        let out = strip(md, options: RenderOptions(wrap: true, tableTruncate: false))
        #expect(!out.contains("https://"))
        #expect(out.contains("icon_16x16"))
    }

    @Test
    func `table inline link respected`() {
        let md = """
        | File | Link |
        | --- | --- |
        | icon_16x16.png | https://example.com/icon.png |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 60, tableTruncate: false))
        #expect(out.contains("icon_16x16.png"))
        #expect(out.contains("https://example.com/icon.png"))
    }

    @Test
    func `hyperlink osc emitted when color on`() {
        let out = render("[x](https://example.com)", options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        #expect(out.contains("\u{001B}]8;;https://example.com"))
    }

    @Test
    func `hyperlink disabled when color off`() {
        let out = render(
            "[x](https://example.com)",
            options: RenderOptions(wrap: false, hyperlinks: true, color: false))
        #expect(!out.contains("\u{001B}]8;;"))
        #expect(out.contains("(https://example.com)"))
    }

    @Test
    func `styler applies attributes`() {
        let styler = Styler(enableColor: true)
        let styled = styler.apply(
            "x",
            style: StyleIntent(color: "red", bgColor: "blue", bold: true, underline: true, dim: true, strike: true))
        #expect(styled.contains("\u{001B}[31m"))
        #expect(styled.contains("\u{001B}[44m"))
        #expect(styled.contains("\u{001B}[1m"))
        #expect(styled.contains("\u{001B}[9m"))
    }

    @Test
    func `styler shares exact foreground and background color parsing`() {
        let styler = Styler(enableColor: true)
        let named = styler.apply("x", style: StyleIntent(color: "gray", bgColor: "gray"))
        let hex = styler.apply("x", style: StyleIntent(color: "#2aa198", bgColor: "#2aa198"))

        #expect(named.contains("\u{001B}[90m"))
        #expect(named.contains("\u{001B}[100m"))
        #expect(hex.contains("\u{001B}[38;2;42;161;152m"))
        #expect(hex.contains("\u{001B}[48;2;42;161;152m"))
        #expect(styler.apply("x", style: StyleIntent(color: "#zzzzzz")) == "x")
    }

    @Test
    func `styler returns plain when color off`() {
        let styler = Styler(enableColor: false)
        let styled = styler.apply("plain", style: StyleIntent(color: "red"))
        #expect(styled == "plain")
    }

    @Test
    func `cli parses table flags`() throws {
        let args = [
            "--table-border",
            "ascii",
            "--table-dense",
            "--table-padding",
            "3",
            "--no-code-wrap",
            "--no-code-box",
            "--code-gutter",
        ]
        let parsed = try SwiftdansiCommand.parse(args)
        #expect(parsed.tableBorder == .ascii)
        #expect(parsed.tableDense)
        #expect(parsed.tablePadding == 3)
        #expect(parsed.noCodeWrap == true)
        #expect(parsed.noCodeBox == true)
        #expect(parsed.codeGutter == true)
    }

    @Test
    func `hyperlink detection matches env`() {
        let envTrue = ["WT_SESSION": "1"]
        #expect(hyperlinkSupported(env: envTrue, isTTY: true) == true)
        let envNoColor = ["NO_COLOR": "1"]
        #expect(hyperlinkSupported(env: envNoColor, isTTY: true) == false)
        let envForce = ["FORCE_HYPERLINK": "1"]
        #expect(hyperlinkSupported(env: envForce, isTTY: true) == true)
        let envNotty = ["WT_SESSION": "1"]
        #expect(hyperlinkSupported(env: envNotty, isTTY: false) == false)
    }

    @Test
    func `terminal context controls automatic options`() {
        let terminal = TerminalContext(
            environment: ["WT_SESSION": "1"],
            isTTY: true,
            width: 120)
        let resolved = resolve(RenderOptions(), terminal: terminal)
        #expect(resolved.width == 120)
        #expect(resolved.color)
        #expect(resolved.hyperlinks)

        let redirected = TerminalContext(environment: [:], isTTY: false, width: nil)
        let redirectedOptions = resolve(RenderOptions(), terminal: redirected)
        #expect(redirectedOptions.width == 80)
        #expect(!redirectedOptions.color)
        #expect(!redirectedOptions.hyperlinks)
    }

    @Test
    func `terminal width prefers ioctl and falls back to columns`() {
        #expect(terminalWidth(environment: ["COLUMNS": "96"], detectedWidth: 120) == 120)
        #expect(terminalWidth(environment: ["COLUMNS": "96"], detectedWidth: nil) == 96)
        #expect(terminalWidth(environment: ["COLUMNS": "invalid"], detectedWidth: nil) == nil)
        #expect(detectedTerminalWidth(fileDescriptor: -1) == nil)
    }

    @Test
    func `pipe is not a tty`() {
        let pipe = Pipe()
        #expect(HyperlinkSupport.current(stream: pipe.fileHandleForWriting).isTTY == false)
    }

    @Test
    func `definition rendering`() {
        let md = "Body line.\n[1]: https://example.com \"Title\"\nNext."
        let out = render(md, options: RenderOptions(wrap: true, color: false))
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first == "Body line.")
        #expect(lines.dropFirst().first?.isEmpty == true) // blank line before footer definition
        #expect(lines.contains("[1]: https://example.com \"Title\""))
        #expect(lines.contains("Next."))
    }

    @Test
    func `diff blocks gain label when unspecified`() {
        let md = """
        ```
        diff --git a/foo b/foo
        --- a/foo
        +++ b/foo
        ```
        """
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let top = out.split(separator: "\n").first ?? ""
        #expect(top.contains("[diff]"))
    }

    @Test
    func `code list merges with adjacent blocks`() {
        let md = """
        ```
        first
        ```

        - ```
          second
          ```
        """
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let boxCount = out.count(where: { $0 == "┌" })
        #expect(boxCount == 1)
        #expect(out.contains("first"))
        #expect(out.contains("second"))
    }

    @Test
    func `snapshot definition footer matches markdansi`() {
        let md = """
        Body line.
        [1]: https://example.com "Title"
        Next.
        """
        let expected = """
        Body line.

        [1]: https://example.com "Title"
        Next.
        """
        let out = render(md, options: RenderOptions(wrap: true, hyperlinks: false, color: false))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == expected
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test
    func `snapshot diff box matches markdansi`() {
        let md = """
        ```
        --- a/foo
        +++ b/foo
        @@ -1 +1 @@
        - a very very very very long line
        + another very very very very long line
        ```
        """
        let expected = """
        ┌ [diff]──────────────────────────────────┐
        │ --- a/foo                               │
        │ +++ b/foo                               │
        │ @@ -1 +1 @@                             │
        │ - a very very very very long line       │
        │ + another very very very very long line │
        └─────────────────────────────────────────┘

        """
        let out = render(md, options: RenderOptions(wrap: true, hyperlinks: false, color: false))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == expected
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test
    func `snapshot code list merge matches markdansi`() {
        let md = """
        ```
        first
        ```

        - ```
          second
          ```
        """
        let expected = """
        ┌ ────── ┐
        │ first  │
        │ second │
        └────────┘

        """
        let out = render(md, options: RenderOptions(wrap: true, hyperlinks: false, color: false))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == expected
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test
    func `snapshot simple table matches markdansi`() {
        let md = """
        | h1 | h2 |
        | --- | --- |
        | a | b |
        """
        let expected = """
        ┌────┬────┐
        │ h1 │ h2 │
        ├────┼────┤
        │ a  │ b  │
        └────┴────┘
        """
        let out = render(md, options: RenderOptions(wrap: true, hyperlinks: false, color: false))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == expected
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test
    func `snapshot hyperlink on off matches markdansi`() {
        let md = "[x](https://example.com)"
        let osc = render(md, options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        let plain = render(md, options: RenderOptions(wrap: false, hyperlinks: true, color: false))
        #expect(osc.contains("\u{001B}]8;;https://example.com"))
        #expect(plain.trimmingCharacters(in: .whitespacesAndNewlines) == "x (https://example.com)")
    }
}
