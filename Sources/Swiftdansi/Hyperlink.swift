import Foundation
import Darwin

/// Port of `supports-hyperlinks` logic (best-effort).
func hyperlinkSupported(stream: FileHandle = .standardOutput) -> Bool {
    let fd = stream.fileDescriptor
    if isatty(fd) == 0 { return false }
    let env = ProcessInfo.processInfo.environment
    if env["FORCE_HYPERLINK"] == "1" { return true }
    if env["NO_COLOR"] != nil { return false }
    if env["WT_SESSION"] != nil { return true } // Windows Terminal
    if let prog = env["TERM_PROGRAM"], ["iTerm.app", "WezTerm", "Hyper"].contains(prog) { return true }
    if env["DOMTERM"] != nil { return true }
    if env["VTE_VERSION"] != nil { return true }
    if env["KONSOLE_VERSION"] != nil { return true }
    if let term = env["TERM"]?.lowercased() {
        if term.contains("xterm-kitty") { return true }
        if term.contains("wezterm") { return true }
        if term.contains("vte") && env["COLORTERM"] == "truecolor" { return true }
        if term.contains("screen") && env["TERM_PROGRAM"] == "tmux" { return true }
    }
    return false
}

func osc8(url: String, text: String) -> String {
    "\u{001B}]8;;\(url)\u{0007}\(text)\u{001B}]8;;\u{0007}"
}
