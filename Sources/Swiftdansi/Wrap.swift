import DisplayWidth
import Foundation

/// Visible width ignoring ANSI escape sequences.
public func visibleWidth(_ text: String) -> Int {
    let stripped = stripANSI(text)
    return DisplayWidth()(stripped)
}

/// Strip ANSI escape sequences.
public func stripANSI(_ text: String) -> String {
    strippingANSISequences(text)
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
        currentWidth += w
    }
    if !current.isEmpty { lines.append(trimEndSpaces(current)) }
    if lines.isEmpty { lines.append("") }
    return balanceWrappedSGR(lines)
}

private func balanceWrappedSGR(_ lines: [String]) -> [String] {
    var carry = ""
    var balanced: [String] = []
    balanced.reserveCapacity(lines.count)
    for line in lines {
        let opened = carry.isEmpty ? line : carry + line
        let next = sgrCarry(in: opened)
        if next.isEmpty {
            balanced.append(opened)
        } else {
            balanced.append(opened + "\u{001B}[0m")
        }
        carry = next
    }
    return balanced
}

private func sgrCarry(in text: String) -> String {
    var carry = ""
    for match in text.matches(of: /\u{001B}\[[0-9;]*m/) {
        let sequence = String(match.output)
        if sgrResetsAll(sequence) {
            carry = ""
        } else {
            carry += sequence
        }
    }
    return carry
}

private func sgrResetsAll(_ sequence: String) -> Bool {
    guard sequence.hasPrefix("\u{001B}["), sequence.hasSuffix("m") else { return false }
    let parameters = sequence.dropFirst(2).dropLast()
    if parameters.isEmpty { return true }
    let parts = parameters.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
    var index = 0
    var active = false
    var sawReset = false
    while index < parts.count {
        let parameter = parts[index]
        if parameter.isEmpty || parameter == "0" {
            active = false
            sawReset = true
            index += 1
            continue
        }
        if parameter == "38" || parameter == "48" || parameter == "58" {
            active = true
            index += 1
            guard index < parts.count else { break }
            let mode = parts[index]
            index += 1
            let skip = mode == "2" ? 3 : mode == "5" ? 1 : 0
            index += min(skip, max(0, parts.count - index))
            continue
        }
        active = true
        index += 1
    }
    return sawReset && !active
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
