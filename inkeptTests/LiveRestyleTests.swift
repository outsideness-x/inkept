import SwiftUI
import Testing
@testable import inkept

/// Restyling only the blocks an edit or a cursor move touches must leave the note looking exactly
/// as if all of it had been styled again.
@MainActor
struct LiveRestyleTests {
    private let sample = """
    # Конспект 📚

    Some **bold** text with *emphasis*, `code`, a [link](https://example.com) and $x^2 + y^2$.
    Ещё ==важное== и ~~старое~~ #тег

    - item one
    - item two with `inline code`
    - [ ] a task
    - [x] done
    1. first
    2. second

    > a quote
    > with two lines

    ```swift
    let value = 42 // answer
    ```

    $$
    \\int_0^1 x\\,dx
    $$

    ```typst
    #rect[hi]
    ```

    | a | b |
    | --- | --- |

    ![cell](attachments/cell.png)

    ---
    The end, with [[Wiki link]] and **more *nested* text**.
    """

    private let theme = LiveTheme(font: .neucha)
    private let pictures = PictureStub()

    private func styler() -> LiveStyler {
        LiveStyler(theme: theme) { [pictures] request in pictures.picture(for: request) }
    }

    private func fullyStyled(_ text: String, selection: NSRange?) -> NSTextStorage {
        let storage = NSTextStorage(string: text)
        styler().style(storage, markdown: LiveMarkdown(text), selection: selection)
        return storage
    }

    /// Where two styled notes first differ, for a readable failure.
    private func firstDifference(_ a: NSAttributedString, _ b: NSAttributedString) -> String? {
        guard a.string == b.string else { return "text differs" }
        var location = 0
        while location < a.length {
            var rangeA = NSRange()
            var rangeB = NSRange()
            let attributesA = a.attributes(at: location, effectiveRange: &rangeA) as NSDictionary
            let attributesB = b.attributes(at: location, effectiveRange: &rangeB) as NSDictionary
            if attributesA != attributesB {
                let line = (a.string as NSString).lineRange(for: NSRange(location: location, length: 0))
                return "at \(location) in \((a.string as NSString).substring(with: line).debugDescription): \(attributesA) vs \(attributesB)"
            }
            location = min(NSMaxRange(rangeA), NSMaxRange(rangeB))
        }
        return nil
    }

    /// Styles `text`, makes the edit the way typing does, restyles only what it touched, and compares.
    private func check(_ text: String, from oldSelection: NSRange?, replacing range: NSRange, with replacement: String, cursorAfter: Bool = true) -> String? {
        let storage = fullyStyled(text, selection: oldSelection)
        let before = LiveMarkdown(text)
        let typing = range.location > 0 ? storage.attributes(at: range.location - 1, effectiveRange: nil) : styler().baseAttributes
        storage.replaceCharacters(in: range, with: NSAttributedString(string: replacement, attributes: typing))
        let after = storage.string
        let newSelection = oldSelection.map { _ in
            NSRange(location: range.location + (cursorAfter ? (replacement as NSString).length : 0), length: 0)
        }
        let markdown = LiveMarkdown(after)
        let blocks = LiveStyler.blocksToRestyle(
            from: before, to: markdown, edit: LiveStyler.Edit(from: text, to: after),
            oldSelection: oldSelection, newSelection: newSelection
        )
        styler().style(storage, markdown: markdown, selection: newSelection, blocks: blocks)
        return firstDifference(storage, fullyStyled(after, selection: newSelection))
    }

    @Test func editsFindTheirChange() {
        let edit = LiveStyler.Edit(from: "abc def", to: "abc XYZ def")
        #expect(edit.range == NSRange(location: 4, length: 4))
        #expect(edit.delta == 4)
        #expect(edit.map(NSRange(location: 6, length: 1)) == NSRange(location: 10, length: 1))
        #expect(edit.map(NSRange(location: 1, length: 2)) == NSRange(location: 1, length: 2))
        let deletion = LiveStyler.Edit(from: "hello world", to: "hello")
        #expect(deletion.range == NSRange(location: 5, length: 0))
        #expect(deletion.delta == -6)
    }

    @Test func typingAnywhereMatchesAFullRestyle() {
        let length = (sample as NSString).length
        var failures: [String] = []
        for location in stride(from: 0, through: length, by: 3) {
            let cursor = NSRange(location: location, length: 0)
            for replacement in ["x", "я", "\n", "*", "`", "$", "=", " ", "- ", "#"] {
                if let difference = check(sample, from: cursor, replacing: cursor, with: replacement) {
                    failures.append("typing \(replacement.debugDescription) at \(location): \(difference)")
                }
            }
            if location < length, let difference = check(sample, from: cursor, replacing: NSRange(location: location, length: 1), with: "") {
                failures.append("deleting at \(location): \(difference)")
            }
            // Edits made while the editor isn't focused, like a change coming in from iCloud.
            if let difference = check(sample, from: nil, replacing: cursor, with: "q") {
                failures.append("unfocused edit at \(location): \(difference)")
            }
        }
        #expect(failures.isEmpty, "\(failures.count) differences, first: \(failures.first ?? "")")
    }

    @Test func pastingOverASelectionMatchesAFullRestyle() {
        let length = (sample as NSString).length
        var failures: [String] = []
        for location in stride(from: 0, to: length - 12, by: 11) {
            for span in [2, 12] {
                let range = NSRange(location: location, length: span)
                for replacement in ["ok", "**bold**", "line\nbreak"] {
                    if let difference = check(sample, from: range, replacing: range, with: replacement) {
                        failures.append("replacing \(range) with \(replacement.debugDescription): \(difference)")
                    }
                }
            }
        }
        #expect(failures.isEmpty, "\(failures.count) differences, first: \(failures.first ?? "")")
    }

    @Test func movingTheCursorMatchesAFullRestyle() {
        let length = (sample as NSString).length
        let markdown = LiveMarkdown(sample)
        var failures: [String] = []
        var generator = SystemRandomNumberGenerator()
        var positions = (0..<120).map { _ in Int.random(in: 0...length, using: &generator) }
        positions.append(contentsOf: [0, length])
        for (from, to) in zip(positions, positions.dropFirst()) {
            let old = NSRange(location: from, length: 0)
            let new = NSRange(location: to, length: 0)
            let storage = fullyStyled(sample, selection: old)
            let blocks = LiveStyler.blocksToRestyle(from: markdown, to: markdown, edit: nil, oldSelection: old, newSelection: new)
            styler().style(storage, markdown: markdown, selection: new, blocks: blocks)
            if let difference = firstDifference(storage, fullyStyled(sample, selection: new)) {
                failures.append("cursor \(from) → \(to): \(difference)")
            }
        }
        #expect(failures.isEmpty, "\(failures.count) differences, first: \(failures.first ?? "")")
    }
}

/// Pictures without drawing anything, the same object for the same request.
@MainActor
private final class PictureStub {
    private var cache: [LivePictureRequest: LivePicture] = [:]

    func picture(for request: LivePictureRequest) -> LivePicture {
        if let picture = cache[request] { return picture }
        let picture = LivePicture(kind: request.kind, key: request.source, size: CGSize(width: 40, height: 20), image: nil)
        cache[request] = picture
        return picture
    }
}
