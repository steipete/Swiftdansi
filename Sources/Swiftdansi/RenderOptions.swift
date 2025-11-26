import Foundation

public typealias Highlighter = @Sendable (_ code: String, _ lang: String?) -> String

public struct RenderOptions: Sendable {
    public var wrap: Bool?
    public var width: Int?
    public var hyperlinks: Bool?
    public var color: Bool?
    public var theme: ThemeName?
    public var customTheme: Theme?
    public var listIndent: Int?
    public var listMarker: String?
    public var quotePrefix: String?
    public var tableBorder: TableBorder?
    public var tablePadding: Int?
    public var tableDense: Bool?
    public var tableTruncate: Bool?
    public var tableEllipsis: String?
    public var codeBox: Bool?
    public var codeGutter: Bool?
    public var codeWrap: Bool?
    public var highlighter: Highlighter?

    public init(
        wrap: Bool? = nil,
        width: Int? = nil,
        hyperlinks: Bool? = nil,
        color: Bool? = nil,
        theme: ThemeName? = nil,
        customTheme: Theme? = nil,
        listIndent: Int? = nil,
        listMarker: String? = nil,
        quotePrefix: String? = nil,
        tableBorder: TableBorder? = nil,
        tablePadding: Int? = nil,
        tableDense: Bool? = nil,
        tableTruncate: Bool? = nil,
        tableEllipsis: String? = nil,
        codeBox: Bool? = nil,
        codeGutter: Bool? = nil,
        codeWrap: Bool? = nil,
        highlighter: Highlighter? = nil)
    {
        self.wrap = wrap
        self.width = width
        self.hyperlinks = hyperlinks
        self.color = color
        self.theme = theme
        self.customTheme = customTheme
        self.listIndent = listIndent
        self.listMarker = listMarker
        self.quotePrefix = quotePrefix
        self.tableBorder = tableBorder
        self.tablePadding = tablePadding
        self.tableDense = tableDense
        self.tableTruncate = tableTruncate
        self.tableEllipsis = tableEllipsis
        self.codeBox = codeBox
        self.codeGutter = codeGutter
        self.codeWrap = codeWrap
        self.highlighter = highlighter
    }
}

public enum TableBorder: String, Sendable {
    case unicode
    case ascii
    case none
}
