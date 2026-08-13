/// Port of `supports-hyperlinks` logic (best-effort).
func hyperlinkSupported(environment: [String: String], isTTY: Bool) -> Bool {
    guard isTTY else { return false }
    if environment["FORCE_HYPERLINK"] == "1" { return true }
    if environment["NO_COLOR"] != nil { return false }
    if environment["WT_SESSION"] != nil { return true } // Windows Terminal
    if let program = environment["TERM_PROGRAM"], ["iTerm.app", "WezTerm", "Hyper"].contains(program) { return true }
    if environment["DOMTERM"] != nil { return true }
    if environment["VTE_VERSION"] != nil { return true }
    if environment["KONSOLE_VERSION"] != nil { return true }
    if let term = environment["TERM"]?.lowercased() {
        if term.contains("xterm-kitty") { return true }
        if term.contains("wezterm") { return true }
        if term.contains("vte"), environment["COLORTERM"] == "truecolor" { return true }
        if term.contains("screen"), environment["TERM_PROGRAM"] == "tmux" { return true }
    }
    return false
}

func osc8(url: String, text: String) -> String {
    "\u{001B}]8;;\(url)\u{0007}\(text)\u{001B}]8;;\u{0007}"
}
