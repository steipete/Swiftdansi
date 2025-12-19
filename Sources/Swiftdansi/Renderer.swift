import Foundation
import Markdown

private let hrWidth = 40
private let maxTableColWidth = 40
private let hardBreakMarker: Character = "\u{000B}"

public func render(_ markdown: String, options: RenderOptions = RenderOptions()) -> String {
    let resolved = resolve(options)
    return renderResolved(markdown: markdown, options: resolved)
}

public func createRenderer(options: RenderOptions = RenderOptions()) -> (String) -> String {
    let resolved = resolve(options)
    return { md in renderResolved(markdown: md, options: resolved) }
}

public func strip(_ markdown: String, options: RenderOptions = RenderOptions()) -> String {
    var opts = options
    opts.color = false
    opts.hyperlinks = false
    if opts.wrap == nil { opts.wrap = true }
    let resolved = resolve(opts)
    return renderResolved(markdown: markdown, options: resolved)
}

private func renderResolved(markdown: String, options: ResolvedOptions) -> String {
    let styler = Styler(enableColor: options.color)
    let doc = parseDocument(dedent(markdown))
    let normalized = normalizeBlocks(Array(doc.blockChildren))
    let body = renderBlocks(
        normalized,
        ctx: RenderContext(options: options, styler: styler),
        indentLevel: 0,
        isTightList: false).joined()
    return options.color ? body : stripANSI(body)
}

private struct RenderContext {
    let options: ResolvedOptions
    let styler: Styler
}

// MARK: - Block Rendering

private func renderBlocks(
    _ blocks: [BlockMarkup],
    ctx: RenderContext,
    indentLevel: Int,
    isTightList: Bool) -> [String]
{
    var out: [String] = []
    for block in blocks {
        if let para = block as? Paragraph {
            out.append(contentsOf: renderParagraph(para, ctx: ctx, indentLevel: indentLevel))
        } else if let heading = block as? Heading {
            out.append(contentsOf: renderHeading(heading, ctx: ctx))
        } else if block is ThematicBreak {
            out.append(contentsOf: renderHr(ctx: ctx))
        } else if let quote = block as? BlockQuote {
            out.append(contentsOf: renderBlockQuote(quote, ctx: ctx, indentLevel: indentLevel))
        } else if let list = block as? UnorderedList {
            out.append(contentsOf: renderList(list, ordered: false, ctx: ctx, indentLevel: indentLevel))
        } else if let list = block as? OrderedList {
            out.append(contentsOf: renderList(list, ordered: true, ctx: ctx, indentLevel: indentLevel))
        } else if let code = block as? CodeBlock {
            if isReferenceLikeCode(code) {
                out.append(contentsOf: renderReferenceLikeCode(code, ctx: ctx))
            } else {
                out.append(contentsOf: renderCodeBlock(code, ctx: ctx))
            }
        } else if let table = block as? Table {
            out.append(contentsOf: renderTable(table, ctx: ctx))
        }
    }
    return out
}

private func normalizeBlocks(_ blocks: [BlockMarkup]) -> [BlockMarkup] {
    let mergedRefs = mergeReferenceContinuations(blocks)
    let labelled = applyLabelParagraphs(mergedRefs)
    let mergedCodes = mergeAdjacentCodeBlocks(labelled)
    return mergedCodes
}

private func renderParagraph(_ para: Paragraph, ctx: RenderContext, indentLevel: Int) -> [String] {
    let text = normalizeParagraphInlineText(renderInline(children: Array(para.inlineChildren), ctx: ctx))
    let prefix = String(repeating: " ", count: ctx.options.listIndent * indentLevel)
    let rawLines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let defRegex = /^\[[^\]]+]:\s+\S/
    var normalized: [String] = []
    var inDefinitions = false
    for line in rawLines {
        var s = line
        if s.firstMatch(of: defRegex) != nil {
            s = s.replacingOccurrences(of: "“", with: "\"").replacingOccurrences(of: "”", with: "\"")
            if let last = normalized.last, !last.isEmpty {
                normalized.append("") // blank line before footer-style definitions
            }
            normalized.append(s)
            inDefinitions = true
            continue
        }
        if inDefinitions, s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            continue // drop stray blank lines inside definitions footer block
        }
        inDefinitions = false
        normalized.append(s)
    }

    var wrapped = normalized.flatMap { line -> [String] in
        wrapWithPrefix(line, width: ctx.options.width ?? 80, wrap: ctx.options.wrap, prefix: prefix)
    }
    if let first = normalized.first(where: { !$0.isEmpty }), first.firstMatch(of: defRegex) != nil {
        wrapped.insert(prefix + "", at: 0) // ensure a blank line before footer definitions
    }
    return wrapped.map { $0 + "\n" }
}

private func normalizeParagraphInlineText(_ text: String) -> String {
    guard text.contains("\n") || text.contains(String(hardBreakMarker)) else { return text }
    enum BreakKind { case soft, hard }
    struct Segment { var text: String; var breakAfter: BreakKind? }
    var segments: [Segment] = []
    var current = ""
    for ch in text {
        if ch == "\n" || ch == hardBreakMarker {
            segments.append(Segment(text: current, breakAfter: ch == hardBreakMarker ? .hard : .soft))
            current = ""
            continue
        }
        current.append(ch)
    }
    segments.append(Segment(text: current, breakAfter: nil))
    let defRegex = /^\[[^\]]+]:\s+\S/
    var out = segments.first?.text ?? ""
    guard segments.count > 1 else { return out }
    for i in 0..<(segments.count - 1) {
        let kind = segments[i].breakAfter ?? .soft
        let left = segments[i].text
        let right = segments[i + 1].text
        if kind == .hard {
            out.append("\n")
            out.append(right)
            continue
        }
        let leftTrim = trimLeadingWhitespace(left)
        let rightTrim = trimLeadingWhitespace(right)
        let keepNewline = left.isEmpty
            || right.isEmpty
            || leftTrim.firstMatch(of: defRegex) != nil
            || rightTrim.firstMatch(of: defRegex) != nil
        out.append(keepNewline ? "\n" : " ")
        out.append(rightTrim)
    }
    return out
}

private func trimLeadingWhitespace(_ text: String) -> String {
    String(text.drop(while: { $0.isWhitespace }))
}

private func renderHeading(_ heading: Heading, ctx: RenderContext) -> [String] {
    let text = renderInline(children: Array(heading.inlineChildren), ctx: ctx)
    let styled = ctx.styler.apply(text, style: ctx.options.theme.heading ?? .init(bold: true))
    return ["\n\(styled)\n"]
}

private func renderHr(ctx: RenderContext) -> [String] {
    let width = ctx.options.wrap ? min(ctx.options.width ?? hrWidth, hrWidth) : hrWidth
    let line = String(repeating: "—", count: width)
    return [ctx.styler.apply(line, style: ctx.options.theme.hr) + "\n"]
}

private func renderBlockQuote(_ quote: BlockQuote, ctx: RenderContext, indentLevel: Int) -> [String] {
    let inner = renderBlocks(Array(quote.blockChildren), ctx: ctx, indentLevel: indentLevel, isTightList: false)
        .joined().trimmingCharacters(in: .whitespacesAndNewlines)
    let prefixRaw = ctx.options.quotePrefix
    let prefix = ctx.styler.apply(prefixRaw, style: ctx.options.theme.quote)
    let wrapped = wrapWithPrefix(inner, width: ctx.options.width ?? 80, wrap: ctx.options.wrap, prefix: prefix)
    return wrapped.map { $0 + "\n" }
}

private func renderList(_ list: ListItemContainer, ordered: Bool, ctx: RenderContext, indentLevel: Int) -> [String] {
    let items = list.listItems
    let tight = listHasTightSpacing(list) ?? true
    let start = (list as? OrderedList)?.startIndex ?? 1
    if let flattened = flattenCodeList(list) {
        return renderCodeBlock(flattened, ctx: ctx)
    }
    var out: [String] = []
    for (idx, item) in items.enumerated() {
        out.append(contentsOf: renderListItem(
            item,
            ctx: ctx,
            indentLevel: indentLevel,
            tight: tight,
            ordered: ordered,
            start: Int(start),
            idx: idx))
    }
    return out
}

// swiftlint:disable function_parameter_count
private func renderListItem(
    _ item: ListItem,
    ctx: RenderContext,
    indentLevel: Int,
    tight: Bool,
    ordered: Bool,
    start: Int,
    idx: Int) -> [String]
{
    let marker = ordered ? "\(start + idx)." : ctx.options.listMarker
    let markerStyled = ctx.styler.apply(marker, style: ctx.options.theme.listMarker)
    let taskBox: String? = {
        guard let checkbox = item.checkbox else { return nil }
        switch checkbox {
        case .checked: return "[x]"
        case .unchecked: return "[ ]"
        }
    }()

    let markerWidth = visibleWidth(taskBox ?? marker) + 1
    let content = renderBlocks(Array(item.blockChildren), ctx: ctx, indentLevel: indentLevel + 1, isTightList: tight)
        .joined().trimmingCharacters(in: .whitespacesAndNewlines).split(
            separator: "\n",
            omittingEmptySubsequences: false).map(String.init)
    // drop leading blank lines
    var lines = content
    while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
        lines.removeFirst()
    }
    var rendered: [String] = []
    for (i, line) in lines.enumerated() {
        let clean = line.replacing(/^[ \t]+/, with: "")
        let prefix = if i == 0 {
            if let box = taskBox {
                String(repeating: " ", count: ctx.options.listIndent * indentLevel) + ctx.styler.apply(
                    box,
                    style: ctx.options.theme.listMarker) + " "
            } else {
                String(repeating: " ", count: ctx.options.listIndent * indentLevel) + markerStyled + " "
            }
        } else {
            String(repeating: " ", count: ctx.options.listIndent * indentLevel + markerWidth)
        }
        rendered.append(prefix + clean)
    }
    if !tight { rendered.append("") }
    return rendered.map { $0 + "\n" }
}

// swiftlint:enable function_parameter_count

private func renderCodeBlock(_ code: CodeBlock, ctx: RenderContext) -> [String] {
    var lang = code.language
    var lines = code.code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    while lines.last?.isEmpty == true {
        lines.removeLast()
    }
    if lines.isEmpty { lines = [""] }
    if lang == nil, looksLikeDiff(code.code) {
        lang = "diff"
    }
    let isDiff = lang?.lowercased() == "diff"
    let gutterWidth = ctx.options.codeGutter ? String(lines.count).count + 2 : 0
    let shouldWrap = !isDiff && ctx.options.codeWrap
    let useBox = ctx.options.codeBox && lines.count > 1
    let paddingForBox = useBox ? 4 : 0
    let wrapLimit: Int? = {
        guard shouldWrap, ctx.options.wrap, let width = ctx.options.width else { return nil }
        return max(1, width - paddingForBox - gutterWidth)
    }()
    let bodyLines: [String] = lines.enumerated().flatMap { idx, line in
        let wrapped = wrapCodeLine(line, width: wrapLimit)
        return wrapped.enumerated().map { segIdx, segment in
            let highlighted = ctx.options.highlighter?(segment, lang) ?? ctx.styler.apply(
                segment,
                style: ctx.options.theme.blockCode ?? ctx.options.theme.code ?? ctx.options.theme.inlineCode)
            guard ctx.options.codeGutter else { return highlighted }
            let num = segIdx == 0 ? String(idx + 1).padding(
                toLength: max(1, gutterWidth - 2),
                withPad: " ",
                startingAt: 0) : String(repeating: " ", count: max(1, gutterWidth - 2))
            let numStyled = ctx.styler.apply(num, style: StyleIntent(dim: true))
            return "\(numStyled) \(highlighted)"
        }
    }

    guard useBox else { return [bodyLines.joined(separator: "\n") + "\n\n"] }

    let innerWidth = max(bodyLines.map { visibleWidth($0) }.max() ?? 0, lang.map { $0.count + 2 } ?? 0)
    let labelRaw = lang.map { "[\($0)]" } ?? ""
    let labelStyled = labelRaw.isEmpty ? "" : ctx.styler.apply(labelRaw, style: StyleIntent(dim: true))
    let headerPad = max(0, innerWidth - labelRaw.count + 1)
    let top: String = if labelRaw.isEmpty {
        ctx.styler.apply("┌ " + String(repeating: "─", count: innerWidth) + " ┐", style: StyleIntent(dim: true))
    } else {
        ctx.styler.apply(
            "┌ \(labelStyled)" + String(repeating: "─", count: headerPad) + "┐",
            style: StyleIntent(dim: true))
    }
    let bottom = ctx.styler.apply(
        "└" + String(repeating: "─", count: innerWidth + 2) + "┘",
        style: StyleIntent(dim: true))
    let middle = bodyLines.map { line in
        let pad = max(0, innerWidth - visibleWidth(line))
        let left = ctx.styler.apply("│ ", style: StyleIntent(dim: true))
        let right = ctx.styler.apply(" │", style: StyleIntent(dim: true))
        return left + line + String(repeating: " ", count: pad) + right
    }.joined(separator: "\n")
    return ["\(top)\n\(middle)\n\(bottom)\n\n"]
}

private func renderTable(_ table: Table, ctx: RenderContext) -> [String] {
    guard !table.isEmpty else { return [] }
    let headCells = Array(table.head.cells)
    let rowBlocks = Array(table.body.rows)
    let alignments = table.columnAlignments
    let cells: [[String]] = ([headCells] + rowBlocks.map { Array($0.cells) }).map { row in
        row.map { cell in renderInline(children: Array(cell.inlineChildren), ctx: ctx) }
    }
    let colCount = cells.map(\.count).max() ?? 0
    var widths = Array(repeating: 1, count: colCount)
    let pad = ctx.options.tablePadding
    let minContent = max(1, ctx.options.tableEllipsis.count + 1)
    let minColWidth = max(1, pad * 2 + minContent)

    for row in cells {
        for (idx, cell) in row.enumerated() {
            widths[idx] = max(widths[idx], min(maxTableColWidth, visibleWidth(cell)))
        }
    }

    let totalWidth = widths.reduce(0, +) + 3 * colCount + 1
    if ctx.options.wrap, let target = ctx.options.width, totalWidth > target {
        var over = totalWidth - target
        while over > 0 {
            if let i = widths.firstIndex(of: widths.max() ?? 0), widths[i] > minColWidth {
                widths[i] -= 1
                over -= 1
            } else { break }
        }
    }
    for i in widths.indices where widths[i] < minColWidth {
        widths[i] = minColWidth
    }

    func renderRow(_ row: [String], header: Bool) -> [[String]] {
        let colLines: [[String]] = row.enumerated().map { idx, cell in
            let target = max(minContent, widths[idx] - pad * 2)
            let truncated: String = if ctx.options.tableTruncate, visibleWidth(cell) > target {
                truncateCell(cell, width: target, ellipsis: ctx.options.tableEllipsis)
            } else {
                cell
            }
            let wrapped = wrapText(truncated, width: ctx.options.wrap ? target : Int.max / 2, wrap: ctx.options.wrap)
            return wrapped.map { line in
                padCell(line, width: widths[idx], align: alignments[safe: idx] ?? .left, padding: pad)
            }
        }
        let height = colLines.map(\.count).max() ?? 1
        var lines: [[String]] = []
        for i in 0..<height {
            let parts = colLines.enumerated().map { idx, column -> String in
                let content = column[safe: i] ?? padCell(
                    "",
                    width: widths[idx],
                    align: alignments[safe: idx] ?? .left,
                    padding: pad)
                return header ? ctx.styler.apply(content, style: ctx.options.theme.tableHeader) : ctx.styler.apply(
                    content,
                    style: ctx.options.theme.tableCell)
            }
            lines.append(parts)
        }
        return lines
    }

    let headLines = renderRow(cells.first ?? [], header: true)
    let bodyLines = cells.dropFirst().flatMap { renderRow($0, header: false) }

    if ctx.options.tableBorder == .none {
        let lines = (headLines + bodyLines).map { $0.joined(separator: " | ") }.joined(separator: "\n")
        return [lines + "\n\n"]
    }

    let box = ctx.options.tableBorder == .ascii ? asciiBox : unicodeBox
    func hLine(_ sepMid: String, _ sepLeft: String, _ sepRight: String) -> String {
        sepLeft + widths.map { String(repeating: box.hSep, count: $0) }.joined(separator: sepMid) + sepRight + "\n"
    }
    let top = hLine(box.tSep, box.topLeft, box.topRight)
    let mid = hLine(box.mSep, box.mLeft, box.mRight)
    let bottom = hLine(box.bSep, box.bottomLeft, box.bottomRight)

    func renderFlat(_ rows: [[String]]) -> String {
        rows.map { row in box.vSep + row.joined(separator: box.vSep) + box.vSep + "\n" }.joined()
    }

    let dense = ctx.options.tableDense
    let out = top + renderFlat(headLines) + (dense ? "" : mid) + renderFlat(bodyLines) + bottom + "\n"
    return [out]
}

// MARK: - Inline

private func renderInline(children: [Markup], ctx: RenderContext) -> String {
    var out = ""
    for child in children {
        if let text = child as? Text {
            out += text.string
        } else if let emphasis = child as? Emphasis {
            out += ctx.styler.apply(
                renderInline(children: Array(emphasis.inlineChildren), ctx: ctx),
                style: ctx.options.theme.emph)
        } else if let strong = child as? Strong {
            out += ctx.styler.apply(
                renderInline(children: Array(strong.inlineChildren), ctx: ctx),
                style: ctx.options.theme.strong)
        } else if let del = child as? Strikethrough {
            out += ctx.styler.apply(
                renderInline(children: Array(del.inlineChildren), ctx: ctx),
                style: StyleIntent(strike: true))
        } else if let code = child as? InlineCode {
            let theme = ctx.options.theme.inlineCode ?? ctx.options.theme.blockCode ?? ctx.options.theme.code
            out += ctx.styler.apply(code.code, style: theme)
        } else if let link = child as? Link {
            out += renderLink(link, ctx: ctx)
        } else if child is SoftBreak {
            out += "\n"
        } else if child is LineBreak {
            out += String(hardBreakMarker)
        } else if child is InlineHTML {
            // ignore inline html
        } else {
            out += String(describing: child)
        }
    }
    return out
}

private func renderLink(_ link: Link, ctx: RenderContext) -> String {
    let label = renderInline(children: Array(link.inlineChildren), ctx: ctx)
    let url = link.destination ?? ""
    if url.starts(with: "mailto:") { return label }
    if ctx.options.hyperlinks, !url.isEmpty {
        return osc8(url: url, text: label)
    }
    if !url.isEmpty, label != url {
        let suffix = ctx.styler.apply(" (\(url))", style: StyleIntent(dim: true))
        return ctx.styler.apply(label, style: ctx.options.theme.link) + suffix
    }
    return ctx.styler.apply(label, style: ctx.options.theme.link)
}

// MARK: - Helpers

private func wrapCodeLine(_ text: String, width: Int?) -> [String] {
    guard let width, width > 0 else { return [text] }
    var current = ""
    var out: [String] = []
    for ch in text {
        let chWidth = visibleWidth(String(ch))
        if visibleWidth(current) + chWidth > width {
            out.append(current)
            current = String(ch)
        } else {
            current.append(ch)
        }
    }
    if !current.isEmpty { out.append(current) }
    return out.isEmpty ? [""] : out
}

private func truncateCell(_ text: String, width: Int, ellipsis: String) -> String {
    if visibleWidth(text) <= width { return text }
    if width <= ellipsis.count { return String(ellipsis.prefix(width)) }
    let target = width - ellipsis.count
    var result = ""
    for ch in text {
        if visibleWidth(result + String(ch)) > target { break }
        result.append(ch)
    }
    return result + ellipsis
}

private func padCell(_ text: String, width: Int, align: Table.ColumnAlignment?, padding: Int) -> String {
    let padded = String(repeating: " ", count: padding) + text + String(repeating: " ", count: padding)
    let padNeeded = max(0, width - visibleWidth(stripANSI(padded)))
    switch align ?? .left {
    case .left:
        return padded + String(repeating: " ", count: padNeeded)
    case .right:
        return String(repeating: " ", count: padNeeded) + padded
    case .center:
        let left = padNeeded / 2
        let right = padNeeded - left
        return String(repeating: " ", count: left) + padded + String(repeating: " ", count: right)
    }
}

private func looksLikeDiff(_ text: String) -> Bool {
    let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
    if lines
        .contains(where: {
            $0.hasPrefix("diff --git") || $0.hasPrefix("--- a/") || $0.hasPrefix("+++ b/") || $0.hasPrefix("@@ ")
        })
    {
        return true
    }
    let nonEmpty = lines.filter { !$0.isEmpty }
    guard nonEmpty.count >= 3 else { return false }
    let markers = nonEmpty.count(where: { ["+", "-", "@"].contains($0.prefix(1)) })
    return markers >= max(3, Int(Double(nonEmpty.count) * 0.6))
}

private func isReferenceLikeCode(_ code: CodeBlock) -> Bool {
    guard code.language == nil else { return false }
    let stripped = code.code.replacingOccurrences(
        of: #"^[ \t>]+"#,
        with: "",
        options: .regularExpression)
    return stripped.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") && stripped.contains("]:")
}

private func renderReferenceLikeCode(_ code: CodeBlock, ctx: RenderContext) -> [String] {
    let text = code.code
        .replacingOccurrences(
            of: #"^[ \t>]+"#,
            with: "",
            options: .regularExpression)
        .replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let line = text
    var out: [String] = []
    out.append(line + "\n")
    return out
}

private func listHasTightSpacing(_ list: ListItemContainer) -> Bool? {
    for item in list.listItems {
        let children = Array(item.blockChildren)
        if children.count > 1 { return false } // likely loose
        if let para = children.first as? Paragraph {
            let text = paragraphPlainText(para).trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { return false }
        }
    }
    return true
}

private func applyLabelParagraphs(_ blocks: [BlockMarkup]) -> [BlockMarkup] {
    var out: [BlockMarkup] = []
    var i = 0
    while i < blocks.count {
        let block = blocks[i]
        if let para = block as? Paragraph {
            let inline = Array(para.inlineChildren)
            if inline.count == 1, let text = inline.first as? Text {
                let trimmed = text.string.trimmingCharacters(in: .whitespacesAndNewlines)
                let match = trimmed.wholeMatch(of: /^\[([^\]]+)\]$/)
                if let langSub = match?.output.1,
                   i + 1 < blocks.count,
                   var code = blocks[i + 1] as? CodeBlock,
                   code.language == nil
                {
                    code.language = String(langSub)
                    out.append(code)
                    i += 2
                    continue
                }
            }
        }
        out.append(block)
        i += 1
    }
    return out
}

private func mergeAdjacentCodeBlocks(_ blocks: [BlockMarkup]) -> [BlockMarkup] {
    var out: [BlockMarkup] = []
    var pending: CodeBlock?
    func flush() {
        if let p = pending { out.append(p); pending = nil }
    }
    for block in blocks {
        if let code = block as? CodeBlock {
            if var p = pending, (p.language ?? "") == (code.language ?? "") {
                let merged = trimTrailingNewlines(p.code) + "\n" + trimTrailingNewlines(code.code)
                p.code = merged
                pending = p
            } else {
                flush()
                pending = code
            }
            continue
        }
        if let list = block as? ListItemContainer, let flattened = flattenCodeList(list) {
            if var p = pending, (p.language ?? "") == (flattened.language ?? "") {
                let merged = trimTrailingNewlines(p.code) + "\n" + trimTrailingNewlines(flattened.code)
                p.code = merged
                pending = p
            } else {
                flush()
                pending = flattened
            }
            continue
        }
        flush()
        out.append(block)
    }
    flush()
    return out
}

private func mergeReferenceContinuations(_ blocks: [BlockMarkup]) -> [BlockMarkup] {
    var out: [BlockMarkup] = []
    var i = 0
    while i < blocks.count {
        let block = blocks[i]
        if let para = block as? Paragraph {
            let text = paragraphPlainText(para)
            let defPattern = /^\[(\d+|\w+)]:\s+\S.*"\s*$/
            if text.firstMatch(of: defPattern) != nil,
               i + 1 < blocks.count,
               let code = blocks[i + 1] as? CodeBlock,
               code.language == nil
            {
                let continuation = code.code
                    .replacingOccurrences(
                        of: #"^[ \t>]+"#,
                        with: " ",
                        options: .regularExpression)
                    .replacingOccurrences(
                        of: #"\s+"#,
                        with: " ",
                        options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                var head = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if head.hasSuffix("\"") { head.removeLast() }
                let merged = "\(head) \(continuation)".trimmingCharacters(in: .whitespaces)
                let mergedPara = Paragraph([Text(merged)])
                out.append(mergedPara)
                i += 2
                continue
            }
        }
        out.append(block)
        i += 1
    }
    return out
}

private func flattenCodeList(_ list: ListItemContainer) -> CodeBlock? {
    let items = Array(list.listItems)
    guard !items.isEmpty else { return nil }
    let codes: [CodeBlock] = items.compactMap { item in
        let children = Array(item.blockChildren)
        guard children.count == 1, let code = children.first as? CodeBlock else { return nil }
        return code
    }
    guard codes.count == items.count else { return nil }
    let sameLang = Set(codes.map { $0.language ?? "" }).count == 1
    let lang = sameLang ? codes.first?.language : nil
    let merged = codes.map(\.code).joined(separator: "\n")
    let new = CodeBlock(language: lang, merged)
    return new
}

private func trimTrailingNewlines(_ text: String) -> String {
    text.replacingOccurrences(of: "\n+$", with: "", options: .regularExpression)
}

private struct TableBox {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let hSep: String
    let vSep: String
    let tSep: String
    let mSep: String
    let bSep: String
    let mLeft: String
    let mRight: String
}

private let unicodeBox = TableBox(
    topLeft: "┌",
    topRight: "┐",
    bottomLeft: "└",
    bottomRight: "┘",
    hSep: "─",
    vSep: "│",
    tSep: "┬",
    mSep: "┼",
    bSep: "┴",
    mLeft: "├",
    mRight: "┤")
private let asciiBox = TableBox(
    topLeft: "+",
    topRight: "+",
    bottomLeft: "+",
    bottomRight: "+",
    hSep: "-",
    vSep: "|",
    tSep: "+",
    mSep: "+",
    bSep: "+",
    mLeft: "+",
    mRight: "+")

extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private func paragraphPlainText(_ para: Paragraph) -> String {
    var out = ""
    for inline in para.inlineChildren {
        switch inline {
        case let t as Text:
            out += t.string
        case let code as InlineCode:
            out += code.code
        case let strong as Strong:
            out += paragraphPlainText(Paragraph(strong.inlineChildren))
        case let emph as Emphasis:
            out += paragraphPlainText(Paragraph(emph.inlineChildren))
        case let del as Strikethrough:
            out += paragraphPlainText(Paragraph(del.inlineChildren))
        default:
            break
        }
    }
    return out
}
