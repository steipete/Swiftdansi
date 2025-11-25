import Foundation

/// Basic OSC-8 hyperlink support detection.
func hyperlinkSupported() -> Bool {
    // Heuristic similar to supports-hyperlinks
    let env = ProcessInfo.processInfo.environment
    if env["DOMTERM"] != nil { return true }
    if env["WT_SESSION"] != nil { return true } // Windows Terminal
    if let prog = env["TERM_PROGRAM"] {
        if prog == "iTerm.app" || prog == "WezTerm" || prog == "Hyper" { return true }
    }
    if let term = env["TERM"]?.lowercased() {
        if term.contains("xterm-kitty") || term.contains("wezterm") { return true }
        if term.contains("vte") && env["COLORTERM"] == "truecolor" { return true }
    }
    if env["VTE_VERSION"] != nil { return true }
    return false
}

func osc8(url: String, text: String) -> String {
    "\u{001B}]8;;\(url)\u{0007}\(text)\u{001B}]8;;\u{0007}"
}
