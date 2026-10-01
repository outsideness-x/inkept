import Foundation
import Testing
@testable import inkept

@MainActor
struct LivePerformanceTests {
    @Test func longNotesRestyleQuickly() {
        let section = """
        ## Section

        Some **bold** text with *emphasis*, `code`, a [link](https://example.com) and $x^2 + y^2$.

        - item one
        - item two with ==highlight==
        - [ ] a task

        > a quote

        ```swift
        let value = 42 // answer
        ```

        """
        let text = String(repeating: section, count: 120)
        let controller = LiveEditorController(font: .neucha)
        let started = Date()
        controller.setText(text)
        let first = Date().timeIntervalSince(started)
        let again = Date()
        controller.restyle(force: true)
        let second = Date().timeIntervalSince(again)
        let parseStart = Date()
        _ = LiveMarkdown(text)
        let parse = Date().timeIntervalSince(parseStart)
        // A letter typed in the middle: only its paragraph is styled again.
        let typeStart = Date()
        let middle = (text as NSString).range(of: "Some ", range: NSRange(location: text.utf16.count / 2, length: text.utf16.count / 2))
        controller.storage.replaceCharacters(in: NSRange(location: NSMaxRange(middle), length: 0), with: "x")
        controller.textDidChange(notify: false)
        let typing = Date().timeIntervalSince(typeStart)
        print("restyle \(text.utf16.count) chars: first \(Int(first * 1000)) ms, again \(Int(second * 1000)) ms, parse \(Int(parse * 1000)) ms, typing \(Int(typing * 1000)) ms")
        #expect(second < 1.0)
        #expect(typing < second)
    }
}
