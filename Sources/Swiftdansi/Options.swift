import Foundation
#if canImport(Darwin)
import Darwin
#endif

struct ResolvedOptions: Sendable {
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

func resolve(_ user: RenderOptions) -> ResolvedOptions {
    let wrap = user.wrap ?? true
    let autoWidth = wrap ? terminalWidth() ?? 80 : nil
    let width = user.width ?? autoWidth
    let colorDefault = isatty(fileno(stdout)) != 0
    let color = user.color ?? colorDefault
    let hyperlinks = color ? (user.hyperlinks ?? hyperlinkSupported()) : false
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

private func terminalWidth() -> Int? {
    #if canImport(Darwin)
    var w = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0, w.ws_col > 0 {
        return Int(w.ws_col)
    }
    #endif
    if let cols = ProcessInfo.processInfo.environment["COLUMNS"], let val = Int(cols) {
        return val
    }
    return nil
}
