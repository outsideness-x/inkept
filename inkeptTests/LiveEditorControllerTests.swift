import SwiftUI
import Testing
@testable import inkept

@MainActor
struct LiveEditorControllerTests {
    /// Stands in for the text view, which moves the cursor in the middle of an edit, before it reports the edit.
    private final class Host: LiveTextHost {
        let controller: LiveEditorController
        var hostSelectedRange = NSRange(location: 0, length: 0)
        var hostIsFocused: Bool { true }
        var hostIsComposing: Bool { false }

        init(controller: LiveEditorController) {
            self.controller = controller
        }

        func hostReplace(_ range: NSRange, with text: String) {
            controller.storage.replaceCharacters(in: range, with: text)
            hostSelectedRange = NSRange(location: min(hostSelectedRange.location, controller.storage.length), length: 0)
            controller.selectionDidChange()
            controller.textDidChange()
        }

        func hostFocus() {}
        func hostFocusHeader() {}
        func hostScrollToSelection() {}
        func hostRefreshCaret() {}
    }

    private func editor(_ text: String, cursor: Int) -> (LiveEditorController, Host) {
        let controller = LiveEditorController(font: .neucha)
        let host = Host(controller: controller)
        controller.host = host
        controller.setText(text)
        controller.focusDidChange(true)
        host.hostSelectedRange = NSRange(location: cursor, length: 0)
        return (controller, host)
    }

    @Test func endingAListKeepsTheStylerInsideTheShorterText() {
        let (controller, host) = editor("- milk\n- ", cursor: 9)
        #expect(controller.continueList())
        #expect(controller.text == "- milk\n")
        #expect(host.hostSelectedRange == NSRange(location: 7, length: 0))
    }

    @Test func shiftTabKeepsTheStylerInsideTheShorterText() {
        let (controller, host) = editor("- milk\n        - eggs\n", cursor: 21)
        #expect(controller.indentList(outdent: true))
        #expect(controller.text == "- milk\n    - eggs\n")
        #expect(host.hostSelectedRange == NSRange(location: 17, length: 0))
    }
}
