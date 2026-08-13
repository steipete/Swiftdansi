enum ANSIOSCTerminator {
    case bell
    case stringTerminator
    case c1StringTerminator

    var hyperlinkClose: String {
        switch self {
        case .bell:
            "\u{001B}]8;;\u{0007}"
        case .stringTerminator:
            "\u{001B}]8;;\u{001B}\\"
        case .c1StringTerminator:
            "\u{009D}8;;\u{009C}"
        }
    }
}

enum ANSISequenceScanResult {
    case notControl
    case complete(end: String.Index)
    case incomplete
}

func scanANSISequence(in text: String, from start: String.Index) -> ANSISequenceScanResult {
    switch text[start] {
    case "\u{001B}":
        let introducer = text.index(after: start)
        guard introducer < text.endIndex else { return .incomplete }
        switch text[introducer] {
        case "[":
            return scanResult(csiSequenceEnd(in: text, from: text.index(after: introducer)))
        case "]", "P", "X", "^", "_":
            return scanResult(stringControlSequenceEnd(
                in: text,
                from: text.index(after: introducer),
                allowsBell: text[introducer] == "]"))
        default:
            if text[introducer].unicodeScalars.contains(where: isANSIControlIntroducer) {
                return .complete(end: introducer)
            }
            return scanResult(escapeSequenceEnd(in: text, from: introducer))
        }
    case "\u{009B}":
        return scanResult(csiSequenceEnd(in: text, from: text.index(after: start)))
    case "\u{0090}", "\u{0098}", "\u{009D}", "\u{009E}", "\u{009F}":
        return scanResult(stringControlSequenceEnd(
            in: text,
            from: text.index(after: start),
            allowsBell: text[start] == "\u{009D}"))
    default:
        return .notControl
    }
}

private func scanResult(_ end: String.Index?) -> ANSISequenceScanResult {
    end.map { .complete(end: $0) } ?? .incomplete
}

func ansiOSCTerminator(in sequence: Substring) -> ANSIOSCTerminator? {
    if sequence.hasSuffix("\u{0007}") {
        return .bell
    }
    if sequence.hasSuffix("\u{001B}\\") {
        return .stringTerminator
    }
    if sequence.hasSuffix("\u{009C}") {
        return .c1StringTerminator
    }
    return nil
}

func strippingANSISequences(_ text: String) -> String {
    guard text.unicodeScalars.contains(where: isANSIControlIntroducer) else {
        return text
    }

    var result = ""
    result.reserveCapacity(text.utf8.count)
    var cursor = text.startIndex
    while cursor < text.endIndex {
        switch scanANSISequence(in: text, from: cursor) {
        case let .complete(sequenceEnd):
            cursor = sequenceEnd
        case .incomplete:
            return result
        case .notControl:
            result.append(text[cursor])
            cursor = text.index(after: cursor)
        }
    }
    return result
}

func preservingCompleteANSISequences(_ text: String) -> String {
    guard text.unicodeScalars.contains(where: isANSIControlIntroducer) else {
        return text
    }

    var cursor = text.startIndex
    while cursor < text.endIndex {
        switch scanANSISequence(in: text, from: cursor) {
        case let .complete(sequenceEnd):
            cursor = sequenceEnd
        case .incomplete:
            // A terminal treats the remaining bytes as private control payload. Degrade the
            // entire safe prefix to plain text so generated styles cannot remain open.
            return strippingANSISequences(text)
        case .notControl:
            cursor = text.index(after: cursor)
        }
    }
    return text
}

private func isANSIControlIntroducer(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x1B, 0x90, 0x98, 0x9B, 0x9D, 0x9E, 0x9F:
        true
    default:
        false
    }
}

private func escapeSequenceEnd(in text: String, from start: String.Index) -> String.Index? {
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        guard character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.value
        else {
            return nil
        }

        switch value {
        case 0x20...0x2F:
            cursor = next
        case 0x30...0x7E:
            return next
        default:
            return nil
        }
    }
    return nil
}

private func csiSequenceEnd(in text: String, from start: String.Index) -> String.Index? {
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        if character.unicodeScalars.count == 1,
           let value = character.unicodeScalars.first?.value,
           (0x40...0x7E).contains(value)
        {
            return next
        }
        cursor = next
    }
    return nil
}

private func stringControlSequenceEnd(
    in text: String,
    from start: String.Index,
    allowsBell: Bool) -> String.Index?
{
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        if allowsBell, character == "\u{0007}" {
            return next
        }
        if character == "\u{009C}" {
            return next
        }
        if character == "\u{001B}", next < text.endIndex, text[next] == "\\" {
            return text.index(after: next)
        }
        cursor = next
    }
    return nil
}
