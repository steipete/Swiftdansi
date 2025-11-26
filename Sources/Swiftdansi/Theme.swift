import Foundation

public enum ThemeName: String, Sendable {
    case `default`
    case dim
    case bright
    case solarized
    case monochrome
    case contrast
}

public struct StyleIntent: Sendable, Hashable {
    public var color: String?
    public var bgColor: String?
    public var bold: Bool = false
    public var italic: Bool = false
    public var underline: Bool = false
    public var dim: Bool = false
    public var strike: Bool = false

    public init(
        color: String? = nil,
        bgColor: String? = nil,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        dim: Bool = false,
        strike: Bool = false)
    {
        self.color = color
        self.bgColor = bgColor
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.dim = dim
        self.strike = strike
    }
}

public struct Theme: Sendable {
    public var heading: StyleIntent?
    public var strong: StyleIntent?
    public var emph: StyleIntent?
    public var inlineCode: StyleIntent?
    public var blockCode: StyleIntent?
    public var code: StyleIntent?
    public var link: StyleIntent?
    public var quote: StyleIntent?
    public var hr: StyleIntent?
    public var listMarker: StyleIntent?
    public var tableHeader: StyleIntent?
    public var tableCell: StyleIntent?

    public init(
        heading: StyleIntent? = nil,
        strong: StyleIntent? = nil,
        emph: StyleIntent? = nil,
        inlineCode: StyleIntent? = nil,
        blockCode: StyleIntent? = nil,
        code: StyleIntent? = nil,
        link: StyleIntent? = nil,
        quote: StyleIntent? = nil,
        hr: StyleIntent? = nil,
        listMarker: StyleIntent? = nil,
        tableHeader: StyleIntent? = nil,
        tableCell: StyleIntent? = nil)
    {
        self.heading = heading
        self.strong = strong
        self.emph = emph
        self.inlineCode = inlineCode
        self.blockCode = blockCode
        self.code = code
        self.link = link
        self.quote = quote
        self.hr = hr
        self.listMarker = listMarker
        self.tableHeader = tableHeader
        self.tableCell = tableCell
    }
}

public enum Themes {
    public static let `default` = Theme(
        heading: .init(color: "yellow", bold: true),
        strong: .init(bold: true),
        emph: .init(italic: true),
        inlineCode: .init(color: "cyan"),
        blockCode: .init(color: "green"),
        link: .init(color: "blue", underline: true),
        quote: .init(dim: true),
        hr: .init(dim: true),
        listMarker: .init(color: "cyan"),
        tableHeader: .init(color: "yellow", bold: true),
        tableCell: .init())

    public static let dim = Theme(
        heading: .init(color: "white", bold: true, dim: true),
        strong: .init(bold: true),
        emph: .init(italic: true),
        inlineCode: .init(color: "cyan", dim: true),
        blockCode: .init(color: "green", dim: true),
        link: .init(color: "blue", underline: true, dim: true),
        quote: .init(dim: true),
        hr: .init(dim: true),
        listMarker: .init(color: "cyan", dim: true),
        tableHeader: .init(color: "yellow", bold: true, dim: true),
        tableCell: .init(dim: true))

    public static let bright = Theme(
        heading: .init(color: "magenta", bold: true),
        strong: .init(bold: true),
        emph: .init(italic: true),
        inlineCode: .init(color: "green"),
        blockCode: .init(color: "green"),
        link: .init(color: "cyan", underline: true),
        quote: .init(dim: true),
        hr: .init(dim: true),
        listMarker: .init(color: "yellow"),
        tableHeader: .init(color: "yellow", bold: true),
        tableCell: .init())

    public static let solarized = Theme(
        heading: .init(color: "yellow", bold: true),
        strong: .init(bold: true),
        emph: .init(italic: true),
        inlineCode: .init(color: "cyan"),
        blockCode: .init(color: "#2aa198"),
        link: .init(color: "blue", underline: true),
        quote: .init(color: "white", dim: true),
        hr: .init(color: "white", dim: true),
        listMarker: .init(color: "cyan"),
        tableHeader: .init(color: "yellow", bold: true),
        tableCell: .init())

    public static let monochrome = Theme(
        heading: .init(bold: true),
        strong: .init(bold: true),
        emph: .init(italic: true),
        inlineCode: .init(dim: true),
        blockCode: .init(dim: true),
        link: .init(underline: true),
        quote: .init(dim: true),
        hr: .init(dim: true),
        listMarker: .init(dim: true),
        tableHeader: .init(bold: true),
        tableCell: .init())

    public static let contrast = Theme(
        heading: .init(color: "magenta", bold: true),
        strong: .init(color: "white", bold: true),
        emph: .init(color: "white", italic: true),
        inlineCode: .init(color: "cyan", bold: true),
        blockCode: .init(color: "green", bold: true),
        link: .init(color: "blue", underline: true),
        quote: .init(color: "white", dim: true),
        hr: .init(color: "white", dim: true),
        listMarker: .init(color: "yellow", bold: true),
        tableHeader: .init(color: "yellow", bold: true),
        tableCell: .init(color: "white"))

    public static func named(_ name: ThemeName) -> Theme {
        switch name {
        case .default: Themes.default
        case .dim: Themes.dim
        case .bright: Themes.bright
        case .solarized: Themes.solarized
        case .monochrome: Themes.monochrome
        case .contrast: Themes.contrast
        }
    }
}
