import Foundation
import Testing
@testable import inkept

struct LiveMarkdownTests {
    private func kinds(_ text: String) -> [LiveMarkdown.Block.Kind] {
        LiveMarkdown(text).blocks.map(\.kind)
    }

    private func text(_ source: String, _ range: NSRange?) -> String? {
        range.map { (source as NSString).substring(with: $0) }
    }

    @Test func readsBlocksLineByLine() {
        let source = """
        # Title
        plain text
        > quoted
        - item
        3. third
        - [x] done
        ---
        | a | b |
        ![cell](attachments/cell.png)

        """
        #expect(kinds(source) == [
            .heading(level: 1), .paragraph, .quote, .listItem(ordered: false), .listItem(ordered: true),
            .task(checked: true), .rule, .table, .image, .blank,
        ])
        let blocks = LiveMarkdown(source).blocks
        #expect(text(source, blocks[0].marker) == "# ")
        #expect(text(source, blocks[5].checkbox) == "[x]")
        #expect(text(source, blocks[5].marker) == "- [x] ")
    }

    @Test func fencedCodeAndMathSpanTheirLines() {
        let source = "before\n```swift\nlet x = \"$y$\"\n```\n$$\n\\int_0^1 x\\,dx\n$$\nafter"
        let blocks = LiveMarkdown(source).blocks
        #expect(blocks.map(\.kind) == [.paragraph, .code(language: "swift"), .math, .paragraph])
        #expect(text(source, blocks[1].content) == "let x = \"$y$\"\n")
        #expect(text(source, blocks[2].content)?.trimmingCharacters(in: .whitespacesAndNewlines) == "\\int_0^1 x\\,dx")
        // Nothing inside code is read as Markdown.
        #expect(LiveMarkdown(source).inlines.allSatisfy { $0.range.location < blocks[1].range.location || $0.range.location >= NSMaxRange(blocks[1].range) })
    }

    @Test func singleLineDisplayMathIsOneBlock() {
        let source = "$$E = mc^2$$"
        let block = LiveMarkdown(source).blocks[0]
        #expect(block.kind == .math)
        #expect(text(source, block.content) == "E = mc^2")
    }

    @Test func typstBlocksAreDrawnAsPictures() {
        let block = LiveMarkdown("```typst\n#circle()\n```").blocks[0]
        #expect(block.kind == .code(language: "typst"))
        #expect(block.rendersAsPicture)
    }

    @Test func unclosedFenceRunsToTheEnd() {
        let source = "```\ncode\nmore"
        let block = LiveMarkdown(source).blocks[0]
        #expect(block.closeFence == nil)
        #expect(text(source, block.content) == "code\nmore")
    }

    @Test func inlineMarkupHidesOnlyItsPunctuation() {
        let source = "**bold** and *soft* with `code`, $x^2$, [link](https://a.b) and #tag"
        let inlines = LiveMarkdown(source).inlines
        let found = inlines.map { ($0.kind, text(source, $0.content) ?? "") }
        #expect(found.contains { $0.0 == .strong && $0.1 == "bold" })
        #expect(found.contains { $0.0 == .emphasis && $0.1 == "soft" })
        #expect(found.contains { $0.0 == .code && $0.1 == "code" })
        #expect(found.contains { $0.0 == .math && $0.1 == "x^2" })
        #expect(found.contains { $0.0 == .link(url: "https://a.b") && $0.1 == "link" })
        #expect(found.contains { $0.0 == .tag && $0.1 == "#tag" })
        let strong = inlines.first { $0.kind == .strong }!
        #expect(strong.markers.map { text(source, $0) } == ["**", "**"])
    }

    @Test func dollarsInProseAreNotMath() {
        let inlines = LiveMarkdown("it costs $5 and $10 today").inlines
        #expect(!inlines.contains { $0.kind == .math })
    }

    @Test func mathAndCodeProtectTheirInsides() {
        let source = "`**not bold**` and $a*b*c$"
        let inlines = LiveMarkdown(source).inlines
        #expect(!inlines.contains { $0.kind == .strong || $0.kind == .emphasis })
    }
}

struct NoteInsertionTests {
    private func apply(_ insertion: NoteInsertion, to text: String, selecting range: NSRange) -> (String, String) {
        let edit = insertion.edit(in: text as NSString, selection: range)
        let result = (text as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
        return (result, (result as NSString).substring(with: edit.selection))
    }

    @Test func boldWrapsAndUnwraps() {
        let (wrapped, selected) = apply(.bold, to: "a word here", selecting: NSRange(location: 2, length: 4))
        #expect(wrapped == "a **word** here")
        #expect(selected == "word")
        let (unwrapped, _) = apply(.bold, to: wrapped, selecting: NSRange(location: 4, length: 4))
        #expect(unwrapped == "a word here")
    }

    @Test func emptySelectionGetsAPlaceholder() {
        let (text, selected) = apply(.inlineMath, to: "", selecting: NSRange(location: 0, length: 0))
        #expect(text == "$x^2$")
        #expect(selected == "x^2")
    }

    @Test func headingsCycle() {
        var text = "Topic"
        for expected in ["# Topic", "## Topic", "### Topic", "Topic"] {
            text = apply(.heading, to: text, selecting: NSRange(location: 0, length: 0)).0
            #expect(text == expected)
        }
    }

    @Test func listsToggleAndReplaceEachOther() {
        let source = "one\ntwo"
        let (bulleted, _) = apply(.bullets, to: source, selecting: NSRange(location: 0, length: 7))
        #expect(bulleted == "- one\n- two")
        let (numbered, _) = apply(.numbers, to: bulleted, selecting: NSRange(location: 0, length: 11))
        #expect(numbered == "1. one\n2. two")
        let (plain, _) = apply(.numbers, to: numbered, selecting: NSRange(location: 0, length: 13))
        #expect(plain == "one\ntwo")
    }

    @Test func blocksGoOnTheirOwnLines() {
        let (text, selected) = apply(.mathBlock, to: "before", selecting: NSRange(location: 6, length: 0))
        #expect(text.hasPrefix("before\n\n$$\n"))
        #expect(text.hasSuffix("\n$$\n"))
        #expect(selected.contains("\\int"))
    }
}

struct ListContinuationTests {
    private func pressReturn(_ text: String) -> String? {
        let source = text as NSString
        guard let edit = ListContinuation.edit(in: source, at: source.length) else { return nil }
        return source.replacingCharacters(in: edit.range, with: edit.replacement)
    }

    @Test func listsCarryOn() {
        #expect(pressReturn("- milk") == "- milk\n- ")
        #expect(pressReturn("  * eggs") == "  * eggs\n  * ")
        #expect(pressReturn("9. nine") == "9. nine\n10. ")
        #expect(pressReturn("- [x] done") == "- [x] done\n- [ ] ")
        #expect(pressReturn("> quoted") == "> quoted\n> ")
    }

    @Test func anEmptyItemEndsTheList() {
        #expect(pressReturn("- milk\n- ") == "- milk\n")
        #expect(pressReturn("- [ ] ") == "")
    }

    @Test func anEmptyNestedItemStepsOutFirst() {
        #expect(pressReturn("- milk\n    - ") == "- milk\n- ")
        #expect(pressReturn("1. one\n\t- [ ] ") == "1. one\n- [ ] ")
    }

    @Test func plainTextAndCodeAreLeftAlone() {
        #expect(pressReturn("just words") == nil)
        #expect(pressReturn("```\n- not a list") == nil)
    }
}

struct ListIndentTests {
    private func press(_ text: String, _ selection: NSRange, outdent: Bool = false) -> (text: String, selection: NSRange)? {
        let source = text as NSString
        guard let edit = ListIndent.edit(in: source, selection: selection, outdent: outdent) else { return nil }
        return (source.replacingCharacters(in: edit.range, with: edit.replacement), edit.selection)
    }

    @Test func tabTucksAnItemUnderTheOneAbove() {
        let result = press("- milk\n- eggs", NSRange(location: 13, length: 0))
        #expect(result?.text == "- milk\n    - eggs")
        #expect(result?.selection == NSRange(location: 17, length: 0))
    }

    @Test func shiftTabBringsItBackOut() {
        let result = press("- milk\n    - eggs", NSRange(location: 17, length: 0), outdent: true)
        #expect(result?.text == "- milk\n- eggs")
        #expect(result?.selection == NSRange(location: 13, length: 0))
        // A cursor inside the indentation that goes lands at the start of the line.
        #expect(press("  - x", NSRange(location: 1, length: 0), outdent: true)?.selection == NSRange(location: 0, length: 0))
        // Already at the top: the key is still taken, and nothing changes.
        #expect(press("- milk", NSRange(location: 3, length: 0), outdent: true)?.text == "- milk")
    }

    @Test func aSelectionMovesEveryItemInIt() {
        let result = press("1. one\n2. two\nplain", NSRange(location: 0, length: 13))
        #expect(result?.text == "    1. one\n    2. two\nplain")
        #expect(result?.selection == NSRange(location: 4, length: 17))
    }

    @Test func offAListTabIsLeftAlone() {
        #expect(press("just words", NSRange(location: 4, length: 0)) == nil)
        #expect(press("```\n- code", NSRange(location: 8, length: 0)) == nil)
    }
}

