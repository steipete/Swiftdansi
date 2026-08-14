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
    let scalars = text.unicodeScalars
    switch scalars[start].value {
    case 0x1B:
        let introducer = scalars.index(after: start)
        guard introducer < scalars.endIndex else { return .incomplete }
        return escapeSequenceResult(in: text, from: introducer)
    case 0x9B:
        return csiSequenceResult(in: text, from: scalars.index(after: start))
    case 0x90, 0x98, 0x9D, 0x9E, 0x9F:
        return stringControlSequenceResult(
            in: text,
            from: scalars.index(after: start),
            allowsBell: scalars[start].value == 0x9D)
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
    let scalars = text.unicodeScalars
    var cursor = start
    var hasIntermediate = false
    while cursor < scalars.endIndex {
        let value = scalars[cursor].value
        let next = scalars.index(after: cursor)
        if !hasIntermediate {
            switch value {
            case 0x5B:
                return csiSequenceResult(in: text, from: next)
            case 0x5D, 0x50, 0x58, 0x5E, 0x5F:
                return stringControlSequenceResult(
                    in: text,
                    from: next,
                    allowsBell: value == 0x5D)
            default:
                break
            }
        }
        switch value {
        case 0x18, 0x1A:
            return malformedSequenceResult(in: text, recovery: next)
        case 0x1B:
            return malformedSequenceResult(in: text, recovery: cursor)
        case 0x00...0x1F, 0x7F:
            cursor = next
        case 0x20...0x2F:
            hasIntermediate = true
            cursor = next
        case 0x30...0x7E:
            return completedSequenceResult(in: text, controlEnd: next)
        default:
            return malformedSequenceResult(in: text, recovery: cursor)
        }
    }
    return .incomplete
}

private func csiSequenceResult(in text: String, from start: String.Index) -> ANSISequenceScanResult {
    let scalars = text.unicodeScalars
    var cursor = start
    var acceptsParameters = true
    while cursor < scalars.endIndex {
        let value = scalars[cursor].value
        let next = scalars.index(after: cursor)
        switch value {
        case 0x30...0x3F where acceptsParameters:
            cursor = next
        case 0x20...0x2F:
            acceptsParameters = false
            cursor = next
        case 0x40...0x7E:
            return completedSequenceResult(in: text, controlEnd: next)
        case 0x18, 0x1A:
            return malformedSequenceResult(in: text, recovery: next)
        case 0x1B:
            return malformedSequenceResult(in: text, recovery: cursor)
        case 0x00...0x1F, 0x7F:
            cursor = next
        default:
            return malformedSequenceResult(in: text, recovery: cursor)
        }
    }
    return .incomplete
}

private func stringControlSequenceResult(
    in text: String,
    from start: String.Index,
    allowsBell: Bool) -> ANSISequenceScanResult
{
    let scalars = text.unicodeScalars
    var cursor = start
    while cursor < scalars.endIndex {
        let value = scalars[cursor].value
        let next = scalars.index(after: cursor)
        if value == 0x18 || value == 0x1A {
            return malformedSequenceResult(in: text, recovery: next)
        }
        if allowsBell, value == 0x07 {
            return completedSequenceResult(in: text, controlEnd: next)
        }
        if value == 0x9C {
            return completedSequenceResult(in: text, controlEnd: next)
        }
        if value == 0x1B {
            guard next < scalars.endIndex else {
                return malformedSequenceResult(in: text, recovery: cursor)
            }
            guard scalars[next].value == 0x5C else {
                return malformedSequenceResult(in: text, recovery: cursor)
            }
            return completedSequenceResult(in: text, controlEnd: scalars.index(after: next))
        }
        if value == 0x90 || value == 0x98 || value == 0x9B || value == 0x9D || value == 0x9E || value == 0x9F {
            return malformedSequenceResult(in: text, recovery: cursor)
        }
        cursor = next
    }
    return .incomplete
}

private func completedSequenceResult(
    in text: String,
    controlEnd: String.Index) -> ANSISequenceScanResult
{
    guard controlEnd.samePosition(in: text) == nil else {
        return .complete(end: controlEnd)
    }
    let end = nextCharacterBoundary(in: text, after: controlEnd)
    let suffix = String(text.unicodeScalars[controlEnd..<end])
    return .completeWithSuffix(end: end, controlEnd: controlEnd, suffix: suffix)
}

private func malformedSequenceResult(
    in text: String,
    recovery: String.Index) -> ANSISequenceScanResult
{
    guard recovery.samePosition(in: text) == nil else {
        return .malformed(recovery: recovery)
    }
    let end = nextCharacterBoundary(in: text, after: recovery)
    let suffix = String(text.unicodeScalars[recovery..<end])
    return .recovered(end: end, suffix: suffix)
}

private func nextCharacterBoundary(in text: String, after position: String.Index) -> String.Index {
    var cursor = position
    while cursor < text.endIndex, cursor.samePosition(in: text) == nil {
        cursor = text.unicodeScalars.index(after: cursor)
    }
    return cursor
}
