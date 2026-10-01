import Observation
import SwiftUI

/// The text view a live editor lives in, on either platform.
@MainActor
protocol LiveTextHost: AnyObject {
    var hostSelectedRange: NSRange { get set }
    var hostIsFocused: Bool { get }
    /// A character is still being put together, like a Japanese word or an accented letter.
    var hostIsComposing: Bool { get }
    func hostReplace(_ range: NSRange, with text: String)
    func hostFocus()
    /// Puts the cursor in the field at the top of the page, the note's title.
    func hostFocusHeader()
    func hostScrollToSelection()
    /// The layout under the cursor changed without an edit; redraw the cursor at its new size.
    func hostRefreshCaret()
}

/// Everything about a note's live editor that isn't tied to UIKit or AppKit: the TextKit stack,
/// parsing, styling, pictures, and the edits the toolbar makes.
@MainActor
@Observable
final class LiveEditorController: NSObject {
    @ObservationIgnored let storage = NSTextStorage()
    @ObservationIgnored let layoutManager = LiveLayoutManager()
    @ObservationIgnored let container = NSTextContainer(size: CGSize(width: 600, height: CGFloat.greatestFiniteMagnitude))
    @ObservationIgnored let renderer: LiveRenderer
    @ObservationIgnored weak var host: LiveTextHost?

    @ObservationIgnored private(set) var markdown = LiveMarkdown("")
    @ObservationIgnored private var activeSignature: [NSRange] = []
    @ObservationIgnored private var isStyling = false
    @ObservationIgnored private var parsedText: String?
    @ObservationIgnored private var parsedLength = 0
    /// The cursor the note was last styled for, when it was styled at all.
    @ObservationIgnored private var styledSelection: NSRange??

    /// Called with the note's Markdown after every edit.
    @ObservationIgnored var onTextChange: (String) -> Void = { _ in }
    /// Called with the selected Markdown when someone asks to make a card from it.
    @ObservationIgnored var onMakeCard: (String) -> Void = { _ in }
    /// Called with a picture pasted or dropped into the note.
    @ObservationIgnored var onPasteImage: (Data) -> Void = { _ in }
    /// Called with a link that was clicked.
    @ObservationIgnored var onOpenLink: (LinkTarget) -> Void = { _ in }

    /// Where a link in a note leads: a web page, or another note by its `[[name]]`.
    enum LinkTarget: Equatable {
        case web(URL)
        case note(String)
    }

    private(set) var hasSelection = false
    private(set) var isFocused = false

    var font: NoteFont {
        didSet {
            guard font != oldValue else { return }
            renderer.theme = LiveTheme(font: font)
            renderer.invalidate()
            restyle(force: true)
        }
    }

    var livePreview = true {
        didSet { restyle(force: true) }
    }

    init(font: NoteFont) {
        self.font = font
        renderer = LiveRenderer(theme: LiveTheme(font: font))
        super.init()
        container.widthTracksTextView = true
        container.lineFragmentPadding = 0
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        renderer.onPictureReady = { [weak self] in self?.restyle(.pictures) }
    }

    var text: String { storage.string }

    /// Puts a whole note into the editor, as when it's first opened or changed elsewhere.
    func setText(_ text: String) {
        guard text != storage.string else { return }
        let selection = host?.hostSelectedRange
        storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
        textDidChange(notify: false)
        if let selection, NSMaxRange(selection) <= storage.length {
            host?.hostSelectedRange = selection
        }
    }

    // MARK: - Events from the text view

    func textDidChange(notify: Bool = true) {
        // Restyling half-typed text would undo the keyboard's own marking; wait until it's committed.
        if host?.hostIsComposing == true { return }
        let current = storage.string
        guard current != parsedText else { return }
        let previous = (text: parsedText, markdown: markdown)
        parsedText = current
        markdown = LiveMarkdown(current)
        parsedLength = storage.length
        if let text = previous.text {
            restyle(.edit(LiveStyler.Edit(from: text, to: current), before: previous.markdown))
        } else {
            restyle(.everything)
        }
        if notify { onTextChange(storage.string) }
    }

    func selectionDidChange() {
        hasSelection = (host?.hostSelectedRange.length ?? 0) > 0
        if restyle(force: false) { host?.hostRefreshCaret() }
    }

    func focusDidChange(_ focused: Bool) {
        isFocused = focused
        if restyle(force: true) { host?.hostRefreshCaret() }
    }

    func appearanceDidChange(isDark: Bool, scale: CGFloat) {
        guard renderer.isDark != isDark || renderer.displayScale != scale else { return }
        renderer.isDark = isDark
        renderer.displayScale = scale
        renderer.invalidate()
        restyle(force: true)
    }

    func pageWidthDidChange(_ width: CGFloat) {
        guard abs(renderer.pageWidth - width) > 1 else { return }
        renderer.pageWidth = width
        renderer.invalidate()
        restyle(force: true)
    }

    private var selectionForStyling: NSRange? {
        guard isFocused, let host else { return nil }
        return host.hostSelectedRange
    }

    /// Styles the note again; returns whether anything was restyled.
    @discardableResult
    func restyle(force: Bool) -> Bool {
        restyle(force ? .everything : .cursor)
    }

    private enum Restyle {
        /// Something that touches every line changed, like the font or the page width.
        case everything
        /// Only the cursor moved.
        case cursor
        /// The text changed.
        case edit(LiveStyler.Edit, before: LiveMarkdown)
        /// A formula, picture or Typst block finished drawing.
        case pictures
    }

    @discardableResult
    private func restyle(_ reason: Restyle) -> Bool {
        // The parse is from before the half-typed text; it's styled once the keyboard commits it. And while an
        // edit is being made the text view already moves the cursor, before it reports the edit: the old parse
        // would reach past the end of the shorter text. The edit's own restyle comes straight after.
        guard !isStyling, host?.hostIsComposing != true, storage.length == parsedLength else { return false }
        let selection = selectionForStyling
        let signature = LiveStyler.activeSignature(of: markdown, selection: selection, in: storage.string as NSString)
            + (selection == nil ? [] : [NSRange(location: -1, length: 0)])
        if case .cursor = reason, signature == activeSignature { return false }
        activeSignature = signature

        // Long notes stay quick to type in: only the blocks that can look different are styled again.
        var blocks: IndexSet?
        if let styled = styledSelection {
            switch reason {
            case .everything:
                blocks = nil
            case .cursor:
                blocks = LiveStyler.blocksToRestyle(from: markdown, to: markdown, edit: nil, oldSelection: styled, newSelection: selection)
            case .edit(let edit, let before):
                blocks = LiveStyler.blocksToRestyle(from: before, to: markdown, edit: edit, oldSelection: styled, newSelection: selection)
            case .pictures:
                blocks = LiveStyler.blocksToRestyle(from: markdown, to: markdown, edit: nil, oldSelection: styled, newSelection: selection)?
                    .union(LiveStyler.blocksWithPictures(in: markdown))
            }
        }
        styledSelection = .some(selection)

        isStyling = true
        defer { isStyling = false }
        let styler = LiveStyler(theme: renderer.theme, livePreview: livePreview) { [renderer] request in
            renderer.picture(for: request)
        }
        styler.style(storage, markdown: markdown, selection: selection, blocks: blocks)
        return true
    }

    var typingAttributes: [NSAttributedString.Key: Any] {
        LiveStyler(theme: renderer.theme) { _ in LivePicture(kind: .image, key: "", size: .zero, image: nil) }.baseAttributes
    }

    // MARK: - Selection

    var selectedText: String {
        guard let range = host?.hostSelectedRange, range.length > 0, NSMaxRange(range) <= storage.length else { return "" }
        return (storage.string as NSString).substring(with: range)
    }

    func makeCardFromSelection() {
        let text = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onMakeCard(text)
    }

    // MARK: - Links

    /// A click on a link that shows as a link follows it. `selection` is the cursor from before the click,
    /// nil when the note wasn't being edited; a link the cursor is in shows its Markdown, and is edited instead.
    func openLink(at index: Int, selection: NSRange?) -> Bool {
        guard livePreview,
              let inline = markdown.inlines.first(where: { NSLocationInRange(index, $0.content) }),
              selection.map({ !LiveStyler.touches($0, inline.range) }) ?? true
        else { return false }
        switch inline.kind {
        case .wikiLink(let target):
            onOpenLink(.note(target))
        case .link(let address):
            if let url = URL(string: address), url.scheme != nil {
                onOpenLink(.web(url))
            } else {
                // `[text](Other note.md)`: a note in the folder.
                onOpenLink(.note(address.removingPercentEncoding ?? address))
            }
        default:
            return false
        }
        return true
    }

    // MARK: - Edits

    /// Makes a toolbar edit. With `cursorAfter`, the cursor lands after what was put in instead of selecting inside it.
    func apply(_ insertion: NoteInsertion, cursorAfter: Bool = false) {
        guard let host else { return }
        let string = storage.string as NSString
        let edit = insertion.edit(in: string, selection: host.hostSelectedRange)
        host.hostReplace(edit.range, with: edit.replacement)
        host.hostSelectedRange = cursorAfter
            ? NSRange(location: edit.range.location + (edit.replacement as NSString).length, length: 0)
            : edit.selection
        host.hostFocus()
        host.hostScrollToSelection()
    }

    /// Puts text where the cursor is, on a line of its own when it's a block.
    func insert(_ text: String, asBlock: Bool = false) {
        guard let host else { return }
        let string = storage.string as NSString
        var range = host.hostSelectedRange
        if range.location > string.length { range = NSRange(location: string.length, length: 0) }
        var insertion = text
        if asBlock {
            if range.location > 0, string.character(at: range.location - 1) != 10 { insertion = "\n" + insertion }
            if NSMaxRange(range) < string.length, string.character(at: NSMaxRange(range)) != 10 { insertion += "\n" }
        }
        host.hostReplace(range, with: insertion)
        host.hostSelectedRange = NSRange(location: range.location + (insertion as NSString).length, length: 0)
        host.hostFocus()
        host.hostScrollToSelection()
    }

    /// Tab and Shift-Tab on list items. Returns false off a list, so the key does what it usually does.
    func indentList(outdent: Bool) -> Bool {
        guard let host else { return false }
        let string = storage.string as NSString
        guard let edit = ListIndent.edit(in: string, selection: host.hostSelectedRange, outdent: outdent) else { return false }
        if edit.replacement != string.substring(with: edit.range) {
            host.hostReplace(edit.range, with: edit.replacement)
        }
        host.hostSelectedRange = edit.selection
        return true
    }

    /// Return in a list: carries the list on, or ends it on an empty item. Returns false for a plain newline.
    func continueList() -> Bool {
        guard let host, host.hostSelectedRange.length == 0,
              let edit = ListContinuation.edit(in: storage.string as NSString, at: host.hostSelectedRange.location)
        else { return false }
        host.hostReplace(edit.range, with: edit.replacement)
        host.hostSelectedRange = edit.selection
        host.hostScrollToSelection()
        return true
    }

    /// Ticks or unticks a task when its drawn box is tapped.
    func toggleTask(at characterIndex: Int) -> Bool {
        guard let block = markdown.blocks.first(where: { block in
            guard case .task = block.kind, let box = block.checkbox else { return false }
            return NSLocationInRange(characterIndex, NSRange(location: box.location - 2, length: box.length + 3))
        }), case .task(let checked) = block.kind, let box = block.checkbox, let host else { return false }
        let selection = host.hostSelectedRange
        host.hostReplace(NSRange(location: box.location + 1, length: 1), with: checked ? " " : "x")
        host.hostSelectedRange = selection
        return true
    }
}
