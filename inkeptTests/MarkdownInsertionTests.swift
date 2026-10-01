import Testing
@testable import inkept

struct MarkdownInsertionTests {
    @Test func boldWrapsTheSelection() {
        var text = "hello world"
        let selected = MarkdownInsertion.bold.apply(to: &text, selecting: 6..<11)
        #expect(text == "hello **world**")
        #expect(selected == 8..<13)
    }

    @Test func emptySelectionInsertsAPlaceholderToTypeOver() {
        var text = ""
        let selected = MarkdownInsertion.inlineMath.apply(to: &text, selecting: nil)
        #expect(text == "$x$")
        #expect(selected == 1..<2)
    }

    @Test func blocksStartOnTheirOwnLine() {
        var text = "Swift actors"
        let selected = MarkdownInsertion.codeBlock.apply(to: &text, selecting: nil)
        #expect(text == "Swift actors\n```\ncode\n```")
        #expect(String(Array(text)[selected]) == "code")
    }

    @Test func blocksAtALineStartDontAddABlankLine() {
        var text = "list:\n"
        _ = MarkdownInsertion.bullets.apply(to: &text, selecting: nil)
        #expect(text == "list:\n- item")
    }

    @Test func outOfRangeSelectionsAreClamped() {
        var text = "abc"
        let selected = MarkdownInsertion.inlineCode.apply(to: &text, selecting: 2..<40)
        #expect(text == "ab`c`")
        #expect(selected == 3..<4)
    }
}
