import Swiftdansi
import Testing

struct ANSISequenceTests {
    @Test
    func `scanner preserves content around ST terminated hyperlinks`() {
        let open = "\u{001B}]8;;https://example.com\u{001B}\\"
        let close = "\u{001B}]8;;\u{001B}\\"
        let linked = "\(open)visible label\(close)"

        #expect(stripANSI(linked) == "visible label")
        #expect(visibleWidth(linked) == visibleWidth("visible label"))
        #expect(stripANSI("\u{001B}[2Kvalue\u{001B}[1~") == "value")
        #expect(stripANSI("\u{009B}31mred\u{009B}0m") == "red")

        let c1Open = "\u{009D}8;;https://example.com\u{009C}"
        let c1Close = "\u{009D}8;;\u{009C}"
        #expect(stripANSI("\(c1Open)C1 label\(c1Close)") == "C1 label")
    }

    @Test
    func `scanner strips seven and eight bit string controls`() {
        let sevenBitIntroducers = ["P", "X", "^", "_"]
        for introducer in sevenBitIntroducers {
            let value = "\u{001B}\(introducer)metadata\u{001B}\\visible"
            #expect(stripANSI(value) == "visible")
            #expect(visibleWidth(value) == visibleWidth("visible"))
        }

        let eightBitIntroducers = ["\u{0090}", "\u{0098}", "\u{009E}", "\u{009F}"]
        for introducer in eightBitIntroducers {
            let value = "\(introducer)metadata\u{009C}visible"
            #expect(stripANSI(value) == "visible")
            #expect(visibleWidth(value) == visibleWidth("visible"))
        }
    }

    @Test
    func `scanner strips ESC sequences with intermediate bytes`() {
        let sequences = [
            "\u{001B}(B", // Select ASCII character set.
            "\u{001B}(0", // Select DEC line-drawing character set.
            "\u{001B}#8", // DEC screen alignment test.
            "\u{001B}%G", // Select UTF-8 character set.
            "\u{001B} !B", // Multiple intermediate bytes are valid.
        ]

        for sequence in sequences {
            let value = "before\(sequence)after"
            #expect(stripANSI(value) == "beforeafter")
            #expect(visibleWidth(value) == visibleWidth("beforeafter"))
        }

        #expect(stripANSI("before\u{001B}( ") == "before")
    }

    @Test
    func `scanner preserves visible suffixes after malformed bounded controls`() {
        let values = [
            "before\u{001B}(💥after",
            "before\u{001B} !💥after",
            "before\u{001B}[31💥after",
            "before\u{009B}31💥after",
        ]

        for value in values {
            #expect(stripANSI(value) == "before💥after")
            #expect(visibleWidth(value) == visibleWidth("before💥after"))
        }

        #expect(stripANSI("before\u{001B}[1 2after") == "before2after")
    }

    @Test
    func `scanner drops incomplete controls through end of input`() {
        let controls = [
            "\u{001B}]metadata",
            "\u{001B}Pmetadata",
            "\u{001B}Xmetadata",
            "\u{001B}^metadata",
            "\u{001B}_metadata",
            "\u{001B}[31",
            "\u{0090}metadata",
            "\u{0098}metadata",
            "\u{009D}metadata",
            "\u{009E}metadata",
            "\u{009F}metadata",
            "\u{009B}31",
            "\u{001B}",
            "\u{001B}\u{001B}]metadata",
            "\u{001B}\u{009D}metadata",
        ]

        for control in controls {
            let value = "visible\(control)"
            #expect(stripANSI(value) == "visible")
            #expect(visibleWidth(value) == visibleWidth("visible"))
        }

        let interruptedCSI = "before\u{001B}\u{001B}[31mred\u{001B}[0m"
        #expect(stripANSI(interruptedCSI) == "beforered")
    }

    @Test
    func `BEL terminates OSC but remains payload for other string controls`() {
        #expect(stripANSI("before\u{001B}]metadata\u{0007}after") == "beforeafter")
        #expect(stripANSI("before\u{009D}metadata\u{0007}after") == "beforeafter")

        let sevenBitIntroducers = ["P", "X", "^", "_"]
        for introducer in sevenBitIntroducers {
            let complete = "before\u{001B}\(introducer)metadata\u{0007}private\u{001B}\\after"
            let incomplete = "before\u{001B}\(introducer)metadata\u{0007}private"
            #expect(stripANSI(complete) == "beforeafter")
            #expect(stripANSI(incomplete) == "before")
        }

        let eightBitIntroducers = ["\u{0090}", "\u{0098}", "\u{009E}", "\u{009F}"]
        for introducer in eightBitIntroducers {
            let complete = "before\(introducer)metadata\u{0007}private\u{009C}after"
            let incomplete = "before\(introducer)metadata\u{0007}private"
            #expect(stripANSI(complete) == "beforeafter")
            #expect(stripANSI(incomplete) == "before")
        }
    }

    @Test
    func `colored renderer degrades malformed control output to a plain safe prefix`() {
        let controls = [
            "\u{001B}]private",
            "\u{001B}Pprivate\u{0007}still-private",
            "\u{009D}private",
            "\u{0090}private\u{0007}still-private",
        ]

        for control in controls {
            let output = render("visible\(control)", options: RenderOptions(color: true))
            #expect(output == "visible")
            #expect(!output.unicodeScalars.contains("\u{001B}"))
        }

        let malformedEscape = render(
            "before\u{001B}(💥after",
            options: RenderOptions(color: true))
        #expect(malformedEscape == "before💥after\n")
        #expect(!malformedEscape.unicodeScalars.contains("\u{001B}"))
    }
}
