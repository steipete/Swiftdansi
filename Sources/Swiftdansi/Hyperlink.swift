import Darwin
import Foundation

struct HyperlinkSupport: Sendable {
    let environment: [String: String]
    let isTTY: Bool

    static func current(stream: FileHandle = .standardOutput) -> HyperlinkSupport {
        HyperlinkSupport(environment: ProcessInfo.processInfo.environment, isTTY: isatty(stream.fileDescriptor) != 0)
    }

    func supported() -> Bool {
        guard self.isTTY else { return false }
        if self.environment["FORCE_HYPERLINK"] == "1" { return true }
        if self.environment["NO_COLOR"] != nil { return false }
        if self.environment["WT_SESSION"] != nil { return true } // Windows Terminal
        if let prog = environment["TERM_PROGRAM"], ["iTerm.app", "WezTerm", "Hyper"].contains(prog) { return true }
        if self.environment["DOMTERM"] != nil { return true }
        if self.environment["VTE_VERSION"] != nil { return true }
        if self.environment["KONSOLE_VERSION"] != nil { return true }
        if let term = environment["TERM"]?.lowercased() {
            if term.contains("xterm-kitty") { return true }
            if term.contains("wezterm") { return true }
            if term.contains("vte"), self.environment["COLORTERM"] == "truecolor" { return true }
            if term.contains("screen"), self.environment["TERM_PROGRAM"] == "tmux" { return true }
        }
        return false
    }
}

/// Port of `supports-hyperlinks` logic (best-effort).
func hyperlinkSupported(stream: FileHandle = .standardOutput) -> Bool {
    HyperlinkSupport.current(stream: stream).supported()
}

// Testable entry.
func hyperlinkSupported(env: [String: String], isTTY: Bool) -> Bool {
    HyperlinkSupport(environment: env, isTTY: isTTY).supported()
}

func osc8(url: String, text: String) -> String {
    "\u{001B}]8;;\(url)\u{0007}\(text)\u{001B}]8;;\u{0007}"
}
