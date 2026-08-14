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
    case completeWithSuffix(end: String.Index, controlEnd: String.Index, suffix: String)
    case recovered(end: String.Index, suffix: String)
    case malformed(recovery: String.Index)
    case incomplete
}

func scanANSISequence(in text: String, from start: String.Index) -> ANSISequenceScanResult {
    switch text[start] {
    case "\u{001B}":
        let introducer = text.index(after: start)
        guard introducer < text.endIndex else { return .incomplete }
        switch text[introducer] {
        case "[":
            return csiSequenceResult(in: text, from: text.index(after: introducer))
        case "]", "P", "X", "^", "_":
            return stringControlSequenceResult(
                in: text,
                from: text.index(after: introducer),
                allowsBell: text[introducer] == "]")
        default:
            if text[introducer].unicodeScalars.contains(where: isANSIControlIntroducer) {
                return .complete(end: introducer)
            }
            return escapeSequenceResult(in: text, from: introducer)
        }
    case "\u{009B}":
        return csiSequenceResult(in: text, from: text.index(after: start))
    case "\u{0090}", "\u{0098}", "\u{009D}", "\u{009E}", "\u{009F}":
        return stringControlSequenceResult(
            in: text,
            from: text.index(after: start),
            allowsBell: text[start] == "\u{009D}")
    default:
        return .notControl
    }
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
        case let .completeWithSuffix(sequenceEnd, _, suffix):
            result.append(contentsOf: suffix)
            cursor = sequenceEnd
        case let .recovered(sequenceEnd, suffix):
            result.append(contentsOf: suffix)
            cursor = sequenceEnd
        case let .malformed(recovery):
            cursor = recovery
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
        case let .completeWithSuffix(sequenceEnd, _, _):
            cursor = sequenceEnd
        case .recovered, .malformed, .incomplete:
            // Rebuild plain output for malformed or incomplete controls so generated styles
            // cannot remain open.
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

private func escapeSequenceResult(in text: String, from start: String.Index) -> ANSISequenceScanResult {
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        guard character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.value
        else {
            guard let value = character.unicodeScalars.first?.value else {
                return .malformed(recovery: cursor)
            }
            let suffix = String(character.unicodeScalars.dropFirst())
            switch value {
            case 0x20...0x2F:
                return .recovered(end: next, suffix: suffix)
            case 0x30...0x7E:
                let controlEnd = text.unicodeScalars.index(after: cursor)
                return .completeWithSuffix(end: next, controlEnd: controlEnd, suffix: suffix)
            default:
                return .malformed(recovery: cursor)
            }
        }

        switch value {
        case 0x20...0x2F:
            cursor = next
        case 0x30...0x7E:
            return .complete(end: next)
        default:
            return .malformed(recovery: cursor)
        }
    }
    return .incomplete
}

private func csiSequenceResult(in text: String, from start: String.Index) -> ANSISequenceScanResult {
    var cursor = start
    var acceptsParameters = true
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        guard character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.value
        else {
            guard let value = character.unicodeScalars.first?.value else {
                return .malformed(recovery: cursor)
            }
            let suffix = String(character.unicodeScalars.dropFirst())
            switch value {
            case 0x30...0x3F where acceptsParameters,
                 0x20...0x2F,
                 0x00...0x1F,
                 0x7F:
                return .recovered(end: next, suffix: suffix)
            case 0x40...0x7E:
                let controlEnd = text.unicodeScalars.index(after: cursor)
                return .completeWithSuffix(end: next, controlEnd: controlEnd, suffix: suffix)
            default:
                return .malformed(recovery: cursor)
            }
        }

        switch value {
        case 0x30...0x3F where acceptsParameters:
            cursor = next
        case 0x20...0x2F:
            acceptsParameters = false
            cursor = next
        case 0x40...0x7E:
            return .complete(end: next)
        case 0x18, 0x1A:
            return .malformed(recovery: next)
        case 0x1B:
            return .malformed(recovery: cursor)
        case 0x00...0x1F, 0x7F:
            cursor = next
        default:
            return .malformed(recovery: cursor)
        }
    }
    return .incomplete
}

private func stringControlSequenceResult(
    in text: String,
    from start: String.Index,
    allowsBell: Bool) -> ANSISequenceScanResult
{
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        if character == "\u{0018}" || character == "\u{001A}" {
            return .malformed(recovery: next)
        }
        if allowsBell, character == "\u{0007}" {
            return .complete(end: next)
        }
        if character == "\u{009C}" {
            return .complete(end: next)
        }
        if character == "\u{001B}", next < text.endIndex, text[next] == "\\" {
            return .complete(end: text.index(after: next))
        }
        cursor = next
    }
    return .incomplete
}
