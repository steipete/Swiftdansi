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
    let tokens = text.matches(of: /(\s+|\S+)/).map { String($0.0) }
    var lines: [String] = []
    var current = ""
    var currentWidth = 0

    func trimEndSpaces(_ value: String) -> String {
        value.replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression)
    }

    func orphanPhraseTail(_ value: String) -> String? {
        let trimmed = trimEndSpaces(value)
        if let range = trimmed.range(
            of: #"\b(with|in|on|of|to|for)\s+(a|an|the)$"#,
            options: [.regularExpression, .caseInsensitive])
        {
            return String(trimmed[range])
        }
        if let range = trimmed.range(
            of: #"\b(a|an|the|to|of|with|and|or|in|on|for)$"#,
            options: [.regularExpression, .caseInsensitive])
        {
            return String(trimmed[range])
        }
        return nil
    }

    for token in tokens {
        let w = visibleWidth(token)
        let isSpace = token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !current.isEmpty, currentWidth + w > width, !isSpace {
            let nextWord = token.replacingOccurrences(of: #"^\s+"#, with: "", options: .regularExpression)
            let currentNoTrail = trimEndSpaces(current)
            if let tail = orphanPhraseTail(currentNoTrail), currentNoTrail.count > tail.count {
                let base = trimEndSpaces(String(currentNoTrail.dropLast(tail.count)))
                if !base.isEmpty {
                    lines.append(base)
                    current = "\(tail) \(nextWord)"
                    currentWidth = visibleWidth(current)
                    continue
                }
            }
            lines.append(currentNoTrail)
            current = nextWord
            currentWidth = visibleWidth(current)
            continue
        }
        current += token
        currentWidth = visibleWidth(current)
    }
    if !current.isEmpty { lines.append(trimEndSpaces(current)) }
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
