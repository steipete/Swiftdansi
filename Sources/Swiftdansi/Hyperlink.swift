import Foundation

/// Basic OSC-8 hyperlink support detection.
func hyperlinkSupported() -> Bool {
    // Common modern terminals set one of these; keep conservative.
    let env = ProcessInfo.processInfo.environment
    if env["WT_SESSION"] != nil || env["TERM_PROGRAM"] == "iTerm.app" || env["TERM_PROGRAM"] == "WezTerm" {
        return true
    }
    if let term = env["TERM"], term.contains("xterm-kitty") || term.contains("wezterm") || term.contains("vte") {
        return true
    }
    return false
}

func osc8(url: String, text: String) -> String {
    "\u{001B}]8;;\(url)\u{0007}\(text)\u{001B}]8;;\u{0007}"
}
