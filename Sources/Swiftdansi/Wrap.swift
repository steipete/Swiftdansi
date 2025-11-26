import DisplayWidth
import Foundation

/// Visible width ignoring ANSI escape sequences.
public func visibleWidth(_ text: String) -> Int {
    let stripped = stripANSI(text)
    return DisplayWidth()(stripped)
}

/// Strip ANSI escape sequences.
public func stripANSI(_ text: String) -> String {
    // Quick regex for CSI/OSC; not exhaustive but sufficient for renderer output.
    let pattern = #"\u001B\[[0-9;]*[A-Za-z]|\u001B\][^\u0007]*\u0007"#
    return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
}

/// Wrap a paragraph string on spaces to the given width. Words longer than width overflow.
public func wrapText(_ text: String, width: Int, wrap: Bool) -> [String] {
    guard wrap, width > 0 else { return [text] }
    var lines: [String] = []
    var current = ""
    var currentWidth = 0
    let regex = /(\s+|\S+)/
    for match in text.matches(of: regex) {
        let token = String(match.0)
        let isSpace = token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let w = visibleWidth(token)
        if !isSpace, !current.isEmpty, currentWidth + w > width {
            lines.append(current)
            current = token
            currentWidth = w
            continue
        }
        if isSpace, currentWidth + w > width {
            lines.append(current)
            current = ""
            currentWidth = 0
            continue
        }
        current += token
        currentWidth += w
    }
    if !current.isEmpty { lines.append(current) }
    if lines.isEmpty { lines.append("") }
    return lines
}

/// Wrap text accounting for a prefix width (e.g., quote marker).
public func wrapWithPrefix(_ text: String, width: Int, wrap: Bool, prefix: String = "") -> [String] {
    guard wrap else { return text.split(separator: "\n", omittingEmptySubsequences: false).map { prefix + $0 } }
    let available = max(1, width - visibleWidth(prefix))
    var out: [String] = []
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
        for chunk in wrapText(String(line), width: available, wrap: wrap) {
            out.append(prefix + chunk)
        }
    }
    return out
}
