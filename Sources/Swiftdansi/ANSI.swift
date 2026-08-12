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

func ansiSequenceEnd(in text: String, from start: String.Index) -> String.Index? {
    let introducer = text.index(after: start)
    guard introducer < text.endIndex else { return nil }

    switch text[start] {
    case "\u{001B}":
        switch text[introducer] {
        case "[":
            return csiSequenceEnd(in: text, from: text.index(after: introducer))
        case "]", "P", "X", "^", "_":
            return stringControlSequenceEnd(in: text, from: text.index(after: introducer))
        default:
            return text.index(after: introducer)
        }
    case "\u{009B}":
        return csiSequenceEnd(in: text, from: introducer)
    case "\u{0090}", "\u{0098}", "\u{009D}", "\u{009E}", "\u{009F}":
        return stringControlSequenceEnd(in: text, from: introducer)
    default:
        return nil
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
        if let sequenceEnd = ansiSequenceEnd(in: text, from: cursor) {
            cursor = sequenceEnd
            continue
        }
        result.append(text[cursor])
        cursor = text.index(after: cursor)
    }
    return result
}

private func isANSIControlIntroducer(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x1B, 0x90, 0x98, 0x9B, 0x9D, 0x9E, 0x9F:
        true
    default:
        false
    }
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

private func stringControlSequenceEnd(in text: String, from start: String.Index) -> String.Index? {
    var cursor = start
    while cursor < text.endIndex {
        let character = text[cursor]
        let next = text.index(after: cursor)
        if character == "\u{0007}" {
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
