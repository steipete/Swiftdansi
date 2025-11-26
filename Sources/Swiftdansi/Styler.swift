import Foundation

private func ansi(for color: String?) -> String? {
    guard let color, !color.isEmpty else { return nil }
    if color.hasPrefix("#"), color.count == 7 {
        let r = Int(color.dropFirst(1).prefix(2), radix: 16) ?? 255
        let g = Int(color.dropFirst(3).prefix(2), radix: 16) ?? 255
        let b = Int(color.dropFirst(5).prefix(2), radix: 16) ?? 255
        return "\u{001B}[38;2;\(r);\(g);\(b)m"
    }
    let map: [String: Int] = [
        "black": 30, "red": 31, "green": 32, "yellow": 33, "blue": 34,
        "magenta": 35, "cyan": 36, "white": 37, "gray": 90,
    ]
    if let code = map[color.lowercased()] {
        return "\u{001B}[\(code)m"
    }
    return nil
}

private func ansiBg(for color: String?) -> String? {
    guard let color, !color.isEmpty else { return nil }
    if color.hasPrefix("#"), color.count == 7 {
        let r = Int(color.dropFirst(1).prefix(2), radix: 16) ?? 255
        let g = Int(color.dropFirst(3).prefix(2), radix: 16) ?? 255
        let b = Int(color.dropFirst(5).prefix(2), radix: 16) ?? 255
        return "\u{001B}[48;2;\(r);\(g);\(b)m"
    }
    let map: [String: Int] = [
        "black": 40, "red": 41, "green": 42, "yellow": 43, "blue": 44,
        "magenta": 45, "cyan": 46, "white": 47, "gray": 100,
    ]
    if let code = map[color.lowercased()] {
        return "\u{001B}[\(code)m"
    }
    return nil
}

public struct Styler {
    private let enableColor: Bool

    public init(enableColor: Bool) {
        self.enableColor = enableColor
    }

    public func apply(_ text: String, style: StyleIntent?) -> String {
        guard self.enableColor, let style else { return text }
        var codes: [String] = []
        if style.bold { codes.append("\u{001B}[1m") }
        if style.italic { codes.append("\u{001B}[3m") }
        if style.underline { codes.append("\u{001B}[4m") }
        if style.dim { codes.append("\u{001B}[2m") }
        if style.strike { codes.append("\u{001B}[9m") }
        if let fg = ansi(for: style.color) { codes.append(fg) }
        if let bg = ansiBg(for: style.bgColor) { codes.append(bg) }
        guard !codes.isEmpty else { return text }
        let reset = "\u{001B}[0m"
        return codes.joined() + text + reset
    }
}
