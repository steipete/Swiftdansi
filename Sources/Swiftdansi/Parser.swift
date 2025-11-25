import Foundation
import Markdown

func dedent(_ markdown: String) -> String {
    let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
    let indents = lines
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .compactMap { line -> Int? in
            let count = line.prefix { $0 == " " || $0 == "\t" }.count
            return count
        }
    guard let minIndent = indents.min(), minIndent > 0 else { return markdown }
    let trimmed = lines.map { line -> String in
        let idx = line.index(line.startIndex, offsetBy: min(minIndent, line.count))
        return String(line[idx...])
    }
    return trimmed.joined(separator: "\n")
}

func parseDocument(_ markdown: String) -> Document {
    Document(parsing: markdown, options: [.parseBlockDirectives, .parseSymbolLinks])
}
