import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

struct TerminalContext {
    let environment: [String: String]
    let isTTY: Bool
    let width: Int?

    static func current(stream: FileHandle = .standardOutput) -> TerminalContext {
        let environment = ProcessInfo.processInfo.environment
        let fileDescriptor = stream.fileDescriptor
        return TerminalContext(
            environment: environment,
            isTTY: isatty(fileDescriptor) != 0,
            width: terminalWidth(
                environment: environment,
                detectedWidth: detectedTerminalWidth(fileDescriptor: fileDescriptor)))
    }
}

struct ResolvedOptions {
    var wrap: Bool
    var width: Int?
    var color: Bool
    var hyperlinks: Bool
    var theme: Theme
    var highlighter: Highlighter?
    var listIndent: Int
    var listMarker: String
    var quotePrefix: String
    var tableBorder: TableBorder
    var tablePadding: Int
    var tableDense: Bool
    var tableTruncate: Bool
    var tableEllipsis: String
    var codeBox: Bool
    var codeGutter: Bool
    var codeWrap: Bool
}

func resolve(_ user: RenderOptions, terminal: TerminalContext = .current()) -> ResolvedOptions {
    let wrap = user.wrap ?? true
    let autoWidth = wrap ? terminal.width ?? 80 : nil
    let width = user.width ?? autoWidth
    let color = user.color ?? terminal.isTTY
    let hyperlinks = color ? (user.hyperlinks ?? hyperlinkSupported(
        env: terminal.environment,
        isTTY: terminal.isTTY)) : false
    let baseTheme = user.customTheme ?? (user.theme.map { Themes.named($0) } ?? Themes.default)
    let listIndent = user.listIndent ?? 2
    let listMarker = user.listMarker ?? "-"
    let quotePrefix = user.quotePrefix ?? "│ "
    let tableBorder = user.tableBorder ?? .unicode
    let tablePadding = user.tablePadding ?? 1
    let tableDense = user.tableDense ?? false
    let tableTruncate = user.tableTruncate ?? true
    let tableEllipsis = user.tableEllipsis ?? "…"
    let codeBox = user.codeBox ?? true
    let codeGutter = user.codeGutter ?? false
    let codeWrap = user.codeWrap ?? true

    return ResolvedOptions(
        wrap: wrap,
        width: width,
        color: color,
        hyperlinks: hyperlinks,
        theme: baseTheme,
        highlighter: user.highlighter,
        listIndent: listIndent,
        listMarker: listMarker,
        quotePrefix: quotePrefix,
        tableBorder: tableBorder,
        tablePadding: tablePadding,
        tableDense: tableDense,
        tableTruncate: tableTruncate,
        tableEllipsis: tableEllipsis,
        codeBox: codeBox,
        codeGutter: codeGutter,
        codeWrap: codeWrap)
}

func terminalWidth(environment: [String: String], detectedWidth: Int?) -> Int? {
    if let detectedWidth {
        return detectedWidth
    }
    if let columns = environment["COLUMNS"], let value = Int(columns) {
        return value
    }
    return nil
}

func detectedTerminalWidth(fileDescriptor: Int32 = STDOUT_FILENO) -> Int? {
    var terminalSize = winsize()
    #if canImport(Darwin)
    let result = ioctl(fileDescriptor, TIOCGWINSZ, &terminalSize)
    #elseif canImport(Glibc)
    let result = ioctl(fileDescriptor, UInt(TIOCGWINSZ), &terminalSize)
    #endif
    #if canImport(Darwin) || canImport(Glibc)
    if result == 0, terminalSize.ws_col > 0 {
        return Int(terminalSize.ws_col)
    }
    #endif
    return nil
}
