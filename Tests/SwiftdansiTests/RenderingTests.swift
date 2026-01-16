import Foundation
import SwiftdansiCLI
import Testing
@testable import Swiftdansi

struct RenderingTests {
    @Test
    func inlineFormatting() {
        let out = strip("Hello _em_ **strong** `code` ~~gone~~", options: RenderOptions(width: 80))
        #expect(out.contains("em"))
        #expect(out.contains("strong"))
        #expect(out.contains("code"))
        #expect(out.contains("gone"))
    }

    @Test
    func wrappingParagraphs() {
        let out = strip(
            "one two three four five six seven eight nine ten",
            options: RenderOptions(wrap: true, width: 10))
        let first = out.split(separator: "\n").first ?? ""
        #expect(first.count <= 10)
    }

    @Test
    func softBreaksCollapseToSpaces() {
        let out = strip("Hello\nworld", options: RenderOptions(wrap: true, width: 80))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello world")
    }

    @Test
    func softBreaksTrimIndentation() {
        let out = strip("Hello\n  world", options: RenderOptions(wrap: true, width: 200))
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello world")
    }

    @Test
    func hardBreaksPreserved() {
        let out = strip("line one  \nline two", options: RenderOptions(wrap: true, width: 80))
        let lines = out.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count > 1)
    }

    @Test
    func hyperlinksToggle() {
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
    func codeBoxWithLabel() {
        let md = "```swift\nlet x = 1\nlet y = 2\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        #expect(out.contains("┌"))
        #expect(out.contains("[swift]"))
        #expect(out.contains("let x = 1"))
    }

    @Test
    func tableRenders() {
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
    func longUrlOverflowsWhenWrapped() {
        let url = "https://example.com/averylongpathwithoutspaces"
        let out = strip(url, options: RenderOptions(wrap: true, width: 10))
        #expect(out.contains(url))
    }

    @Test
    func taskListRenders() {
        let out = strip("- [ ] open\n- [x] done", options: RenderOptions())
        #expect(out.contains("[ ] open"))
        #expect(out.contains("[x] done"))
    }

    @Test
    func softBreaksCollapseInsideListItems() {
        let md =
            "- Section IV (signature): A concluding line stating the document was \"typed on 2025-12-18 with a\n" +
            "  stubborn cursor.\""
        let out = strip(md, options: RenderOptions(wrap: true, width: 200))
        #expect(out.contains("with a stubborn cursor."))
        #expect(!out.contains("\n\n"))
    }

    @Test
    func blockquotePrefix() {
        let out = strip("> quoted line", options: RenderOptions())
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("│ "))
    }

    @Test
    func codeGutterWrapsSegments() {
        let md = "```\n0123456789ABCDEFG\n```"
        let out = render(
            md,
            options: RenderOptions(wrap: true, width: 12, color: false, codeBox: false, codeGutter: true))
        let lines = out.split(separator: "\n")
        #expect(lines.first?.hasPrefix("1") == true)
    }

    @Test
    func tableAlignmentAndTruncate() {
        let md = """
        | l | c | r |
        | :-- | :-: | --: |
        | Supercalifragilistic | mid | tail |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 18, tableTruncate: true))
        #expect(out.contains("…"))
    }

    @Test
    func tableDenseNoneBorder() {
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
    func codeGutterMultiDigit() {
        let body = (1...12).map { "l\($0)" }.joined(separator: "\n")
        let md = "```\n\(body)\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false, codeGutter: true))
        #expect(out.contains("12 "))
    }

    @Test
    func boxedLabelWidth() {
        let md = "```superlonglanguageid\nfoo\nbar\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first?.contains("[superlonglanguageid]") == true)
        #expect(lines.first?.count ?? 0 >= (lines.dropFirst().first?.count ?? 0))
    }

    @Test
    func diffBlocksDoNotWrap() {
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
    func singleLineCodeNoBox() {
        let md = "```\nsolo\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        #expect(!out.trimmingCharacters(in: .whitespacesAndNewlines).contains("┌"))
    }

    @Test
    func hyperlinkSuffixWhenOff() {
        let out = strip("[link](https://example.com)", options: RenderOptions())
        #expect(out.contains("link (https://example.com)"))
    }

    @Test
    func mailtoNotHyperlinkedInTable() {
        let md = """
        | File | Size |
        | --- | --- |
        | icon_16x16@2x.png | 32 |
        """
        let out = strip(md, options: RenderOptions(wrap: true, width: 40, tableTruncate: false))
        #expect(!out.contains("\u{001B}]8;;"))
    }

    @Test
    func asciiBorderTable() {
        let md = """
        | h1 | h2 |
        | --- | --- |
        | a | b |
        """
        let out = strip(md, options: RenderOptions(wrap: true, tableBorder: .ascii, tablePadding: 2))
        #expect(out.contains("+"))
    }

    @Test
    func tableTruncateDisabledShowsFullCell() {
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
    func tablePaddingDenseCombination() {
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
    func themeDefaultColors() {
        let ansi = render("`inline`\n\n```\nblock\n```\n\n# H", options: RenderOptions(wrap: false, color: true))
        #expect(ansi.contains("\u{001B}[36m")) // cyan inline code
        #expect(ansi.contains("\u{001B}[32m")) // green block code
        #expect(ansi.contains("\u{001B}[33m")) // yellow heading
    }

    @Test
    func themeDimAddsDimAttribute() {
        let ansi = render("`inline`", options: RenderOptions(wrap: false, color: true, theme: .dim))
        #expect(ansi.contains("\u{001B}[2m"))
    }

    @Test
    func customHighlighterApplied() {
        let md = "```\ncode\n```"
        let out = render(
            md,
            options: RenderOptions(wrap: false, color: false, highlighter: { code, _ in code.uppercased() }))
        #expect(out.contains("CODE"))
    }

    @Test
    func cliForceLinksOverridesNoColor() throws {
        let cmd = try SwiftdansiCommand.parse(["--force-links", "--no-color"])
        #expect(cmd.forceLinks)
        #expect(cmd.noColor)
    }

    @Test
    func listOfCodeBlocksCollapses() {
        let md = "- ```\n  first\n  ```\n- ```\n  second\n  ```"
        let out = render(md, options: RenderOptions(wrap: false, color: false))
        let boxCount = out.count(where: { $0 == "┌" })
        #expect(boxCount == 1)
        #expect(out.contains("first"))
        #expect(out.contains("second"))
    }

    @Test
    func referenceLikeCodeNotBoxed() {
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
    func hrClampedToForty() {
        let md = "----"
        let out = strip(md, options: RenderOptions(wrap: true, width: 10))
        let line = out.split(separator: "\n").first ?? ""
        #expect(line.count <= 40)
    }

    @Test
    func inlineHtmlIgnored() {
        let out = strip("<div>ignored</div>", options: RenderOptions())
        #expect(out.isEmpty)
    }

    @Test
    func headingsAndHrRender() {
        let md = "# Title\n\n---\n"
        let out = strip(md, options: RenderOptions(wrap: true, width: 80))
        #expect(out.contains("Title"))
        #expect(out.contains("—"))
    }

    @Test
    func wrapTextEdgeCases() {
        #expect(wrapText("", width: 5, wrap: true) == [""])
        #expect(wrapText("abc", width: 0, wrap: true) == ["abc"])
    }

    @Test
    func wrapAvoidsTrailingArticlesWhenPossible() {
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
    func wrapMovesTrailingArticleToNextLine() {
        #expect(wrapText("hello the world", width: 11, wrap: true) == ["hello", "the world"])
    }

    @Test
    func wrapMovesTrailingPrepositionArticleToNextLine() {
        #expect(wrapText("walk in the rain", width: 11, wrap: true) == ["walk", "in the rain"])
    }

    @Test
    func wrapDoesNotTreatPunctuatedWordsAsOrphans() {
        #expect(wrapText("hello the, world", width: 11, wrap: true) == ["hello the,", "world"])
    }

    @Test
    func looseListHasBlankLine() {
        let out = strip("- item 1\n\n- item 2", options: RenderOptions())
        let blanks = out.split(separator: "\n", omittingEmptySubsequences: false).count(where: { $0.isEmpty })
        #expect(blanks > 0)
    }

    @Test
    func tableUnderscoreNotLinkified() {
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
    func tableInlineLinkRespected() {
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
    func hyperlinkOscEmittedWhenColorOn() {
        let out = render("[x](https://example.com)", options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        #expect(out.contains("\u{001B}]8;;https://example.com"))
    }

    @Test
    func hyperlinkDisabledWhenColorOff() {
        let out = render(
            "[x](https://example.com)",
            options: RenderOptions(wrap: false, hyperlinks: true, color: false))
        #expect(!out.contains("\u{001B}]8;;"))
        #expect(out.contains("(https://example.com)"))
    }

    @Test
    func stylerAppliesAttributes() {
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
    func stylerReturnsPlainWhenColorOff() {
        let styler = Styler(enableColor: false)
        let styled = styler.apply("plain", style: StyleIntent(color: "red"))
        #expect(styled == "plain")
    }

    @Test
    func cliParsesTableFlags() throws {
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
    func hyperlinkDetectionMatchesEnv() {
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
    func definitionRendering() {
        let md = "Body line.\n[1]: https://example.com \"Title\"\nNext."
        let out = render(md, options: RenderOptions(wrap: true, color: false))
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first == "Body line.")
        #expect(lines.dropFirst().first?.isEmpty == true) // blank line before footer definition
        #expect(lines.contains("[1]: https://example.com \"Title\""))
        #expect(lines.contains("Next."))
    }

    @Test
    func diffBlocksGainLabelWhenUnspecified() {
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
    func codeListMergesWithAdjacentBlocks() {
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
    func snapshotDefinitionFooterMatchesMarkdansi() {
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
    func snapshotDiffBoxMatchesMarkdansi() {
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
    func snapshotCodeListMergeMatchesMarkdansi() {
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
    func snapshotSimpleTableMatchesMarkdansi() {
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
    func snapshotHyperlinkOnOffMatchesMarkdansi() {
        let md = "[x](https://example.com)"
        let osc = render(md, options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        let plain = render(md, options: RenderOptions(wrap: false, hyperlinks: true, color: false))
        #expect(osc.contains("\u{001B}]8;;https://example.com"))
        #expect(plain.trimmingCharacters(in: .whitespacesAndNewlines) == "x (https://example.com)")
    }
}
