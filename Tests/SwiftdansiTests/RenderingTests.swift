import Testing
@testable import Swiftdansi
import SwiftdansiCLI

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
        let out = strip("one two three four five six seven eight nine ten", options: RenderOptions(wrap: true, width: 10))
        let first = out.split(separator: "\n").first ?? ""
        #expect(first.count <= 10)
    }

    @Test
    func hyperlinksToggle() {
        let rendered = render("[x](https://example.com)", options: RenderOptions(wrap: false, hyperlinks: true, color: true))
        #expect(rendered.contains("\u{001B}]8;;https://example.com"))
        let plain = render("[x](https://example.com)", options: RenderOptions(wrap: false, hyperlinks: true, color: false))
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
    func blockquotePrefix() {
        let out = strip("> quoted line", options: RenderOptions())
        #expect(out.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("│ "))
    }

    @Test
    func codeGutterWrapsSegments() {
        let md = "```\n0123456789ABCDEFG\n```"
        let out = render(md, options: RenderOptions(wrap: true, width: 12, color: false, codeBox: false, codeGutter: true))
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
        let out = strip(md, options: RenderOptions(wrap: true, tableBorder: TableBorder.none, tablePadding: 0, tableDense: true))
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
        let out = strip(md, options: RenderOptions(wrap: true, tableBorder: .unicode, tablePadding: 3, tableDense: true))
        #expect(out.contains("┌"))
        #expect(out.contains("a      "))
    }

    @Test
    func themeDefaultColors() {
        let ansi = render("`inline`\n\n```\nblock\n```\n\n# H", options: RenderOptions(wrap: false, color: true))
        #expect(ansi.contains("\u{001B}[36m")) // cyan inline code
        #expect(ansi.contains("\u{001B}[32m")) // green block code
        #expect(ansi.contains("\u{001B}[33m")) // yellow heading
    }

    @Test
    func customHighlighterApplied() {
        let md = "```\ncode\n```"
        let out = render(md, options: RenderOptions(wrap: false, color: false, highlighter: { code, _ in code.uppercased() }))
        #expect(out.contains("CODE"))
    }

    @Test
    func cliForceLinksOverridesNoColor() throws {
        let cmd = try SwiftdansiCommand.parse(["--force-links", "--no-color"])
        #expect(cmd.forceLinks)
        #expect(cmd.noColor)
    }

    @Test
    func definitionRendering() {
        let md = "Body line.\n[1]: https://example.com \"Title\"\nNext."
        let out = render(md, options: RenderOptions(wrap: true, color: false))
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.contains("[1]: https://example.com \"Title\""))
    }
}
