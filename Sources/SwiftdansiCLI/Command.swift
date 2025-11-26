import ArgumentParser
import Darwin
import Foundation
import Swiftdansi

public struct SwiftdansiCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "swiftdansi",
        abstract: "Markdown to ANSI renderer.")

    @Option(help: "Input file (default: stdin). Use - for stdin explicitly.")
    public var `in`: String?

    @Option(help: "Output file (default: stdout)")
    public var out: String?

    @Option(help: "Wrap width (default: TTY cols or 80)")
    public var width: Int?

    @Flag(help: "Disable hard wrapping")
    public var noWrap: Bool = false

    @Flag(help: "Disable ANSI/OSC output")
    public var noColor: Bool = false

    @Flag(help: "Disable OSC-8 hyperlinks")
    public var noLinks: Bool = false

    @Flag(help: "Force-enable OSC-8 hyperlinks (overrides auto-detect)")
    public var forceLinks: Bool = false

    @Option(help: "Theme (default|dim|bright|solarized|monochrome|contrast)")
    public var theme: ThemeName?

    @Option(help: "Spaces per list nesting level (default: 2)")
    public var listIndent: Int?

    @Option(help: "Prefix for blockquotes (default: \"│ \" )")
    public var quotePrefix: String?

    @Option(help: "Table border style: unicode|ascii|none")
    public var tableBorder: TableBorder?

    @Option(help: "Spaces around table cell content")
    public var tablePadding: Int?

    @Flag(help: "Reduce separator rows in tables")
    public var tableDense: Bool = false

    @Option(help: "Table truncation toggle (true/false)")
    public var tableTruncate: Bool?

    @Flag(help: "Disable table cell truncation")
    public var noTableTruncate: Bool = false

    @Option(help: "Table ellipsis marker")
    public var tableEllipsis: String?

    @Option(help: "Code wrap toggle (true/false)")
    public var codeWrap: Bool?

    @Flag(help: "Disable code line wrapping")
    public var noCodeWrap: Bool = false

    @Option(help: "Code box toggle (true/false)")
    public var codeBox: Bool?

    @Flag(help: "Disable code box drawing")
    public var noCodeBox: Bool = false

    @Flag(help: "Enable code line-number gutter")
    public var codeGutter: Bool = false

    public init() {}

    public func run() throws {
        signal(SIGPIPE, SIG_IGN)

        let inputData: Data = if let path = `in`, path != "-" {
            try Data(contentsOf: URL(fileURLWithPath: path))
        } else {
            FileHandle.standardInput.readDataToEndOfFile()
        }

        guard let markdown = String(data: inputData, encoding: .utf8) else {
            throw ValidationError("Input is not valid UTF-8")
        }

        var opts = RenderOptions()
        opts.wrap = !self.noWrap
        opts.width = self.width
        opts.color = !self.noColor
        if self.forceLinks { opts.hyperlinks = true } else if self.noLinks { opts.hyperlinks = false }
        opts.theme = self.theme
        opts.listIndent = self.listIndent
        opts.quotePrefix = self.quotePrefix
        opts.tableBorder = self.tableBorder
        opts.tablePadding = self.tablePadding
        opts.tableDense = self.tableDense
        if let t = tableTruncate { opts.tableTruncate = t } else { opts.tableTruncate = !self.noTableTruncate }
        opts.tableEllipsis = self.tableEllipsis
        if let cw = codeWrap { opts.codeWrap = cw } else { opts.codeWrap = !self.noCodeWrap }
        if let cb = codeBox { opts.codeBox = cb } else { opts.codeBox = !self.noCodeBox }
        opts.codeGutter = self.codeGutter

        let output = Swiftdansi.render(markdown, options: opts)

        if let outPath = out {
            try output.write(to: URL(fileURLWithPath: outPath), atomically: true, encoding: .utf8)
        } else if let data = output.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }
}
