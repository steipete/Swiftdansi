import Foundation
import ArgumentParser
import Swiftdansi
import Darwin

public struct SwiftdansiCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "swiftdansi", abstract: "Markdown to ANSI renderer.")

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

    @Flag(help: "Disable table cell truncation")
    public var noTableTruncate: Bool = false

    @Option(help: "Table ellipsis marker")
    public var tableEllipsis: String?

    @Flag(help: "Disable code line wrapping")
    public var noCodeWrap: Bool = false

    @Flag(help: "Disable code box drawing")
    public var noCodeBox: Bool = false

    @Flag(help: "Enable code line-number gutter")
    public var codeGutter: Bool = false

    public init() {}

    public func run() throws {
        signal(SIGPIPE, SIG_IGN)

        let inputData: Data
        if let path = `in`, path != "-" {
            inputData = try Data(contentsOf: URL(fileURLWithPath: path))
        } else {
            inputData = FileHandle.standardInput.readDataToEndOfFile()
        }

        guard let markdown = String(data: inputData, encoding: .utf8) else {
            throw ValidationError("Input is not valid UTF-8")
        }

        var opts = RenderOptions()
        opts.wrap = !noWrap
        opts.width = width
        opts.color = !noColor
        if forceLinks { opts.hyperlinks = true }
        else if noLinks { opts.hyperlinks = false }
        opts.theme = theme
        opts.listIndent = listIndent
        opts.quotePrefix = quotePrefix
        opts.tableBorder = tableBorder
        opts.tablePadding = tablePadding
        opts.tableDense = tableDense
        opts.tableTruncate = !noTableTruncate
        opts.tableEllipsis = tableEllipsis
        opts.codeWrap = !noCodeWrap
        opts.codeBox = !noCodeBox
        opts.codeGutter = codeGutter

        let output = Swiftdansi.render(markdown, options: opts)

        if let outPath = out {
            try output.write(to: URL(fileURLWithPath: outPath), atomically: true, encoding: .utf8)
        } else if let data = output.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }
}
