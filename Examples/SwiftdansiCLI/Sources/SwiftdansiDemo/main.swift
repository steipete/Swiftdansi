import Darwin
import Foundation
import Swiftdansi

private let sampleMarkdown = """
# Swiftdansi Demo

This is a tiny CLI that uses the Swiftdansi library.

- **Bold**
- _Italic_
- [Link](https://example.com)

```swift
let greeting = "Hello"
print(greeting)
```

| Name | Value |
| --- | --- |
| Width | 80 |
| Theme | bright |

> Blockquotes render too.
"""

private func printUsage() {
    print("""
    Swiftdansi Demo (Swift 6.2)

    Usage:
      swift run SwiftdansiDemo -- [options] [path]

    Options:
      --theme <default|dim|bright|solarized|monochrome|contrast>
      --width <n>
      --plain
      -h, --help
    """)
}

private func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

var options = RenderOptions()
var plain = false
var inputPath: String?

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let arg = args[index]
    switch arg {
    case "-h", "--help":
        printUsage()
        exit(0)
    case "--plain":
        plain = true
    case "--width":
        guard index + 1 < args.count, let width = Int(args[index + 1]) else {
            printError("Missing or invalid value for --width")
            exit(64)
        }
        options.width = width
        index += 1
    case "--theme":
        guard index + 1 < args.count else {
            printError("Missing value for --theme")
            exit(64)
        }
        let value = args[index + 1]
        guard let theme = ThemeName(rawValue: value) else {
            printError("Unknown theme: \(value)")
            exit(64)
        }
        options.theme = theme
        index += 1
    case "--":
        if index + 1 < args.count {
            let remaining = args[(index + 1)...]
            if remaining.count > 1 {
                printError("Only one input path is supported")
                exit(64)
            }
            if inputPath != nil {
                printError("Only one input path is supported")
                exit(64)
            }
            inputPath = remaining.first
        }
        index = args.count
    default:
        if arg.hasPrefix("--") {
            printError("Unknown option: \(arg)")
            exit(64)
        }
        if inputPath != nil {
            printError("Only one input path is supported")
            exit(64)
        }
        inputPath = arg
    }
    index += 1
}

let input: String
if let path = inputPath {
    do {
        input = try String(contentsOfFile: path, encoding: .utf8)
    } catch {
        printError("Failed to read file: \(path)")
        exit(66)
    }
} else {
    input = sampleMarkdown
}

let output = plain ? strip(input, options: options) : render(input, options: options)
print(output)
