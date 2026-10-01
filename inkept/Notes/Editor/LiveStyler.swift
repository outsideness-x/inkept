import SwiftUI

/// What the styler asks the renderer for: a formula, a picture file or a Typst block.
struct LivePictureRequest: Hashable {
    var kind: LivePicture.Kind
    var source: String
    /// Which block of its kind this is, so a block being edited keeps its last picture until the new one is ready.
    var slot = 0
}

/// Where a block stands in its note: its place among all blocks, and among the code blocks and quotes.
struct LiveOrdinal {
    var block: Int
    var code: Int
    var quote: Int
}

/// Turns parsed Markdown into TextKit attributes. Away from the cursor, punctuation disappears and
/// formulas, pictures and Typst become drawings; wherever the cursor is, the Markdown comes back.
@MainActor
struct LiveStyler {
    let theme: LiveTheme
    /// Whether punctuation hides and blocks become pictures away from the cursor.
    var livePreview = true
    let picture: (LivePictureRequest) -> LivePicture

    /// `selection` is nil when the editor isn't focused: then the whole note is shown finished.
    /// `blocks` limits the work to those blocks (by index) when the rest of the note is already styled.
    func style(_ storage: NSTextStorage, markdown: LiveMarkdown, selection: NSRange?, blocks only: IndexSet? = nil) {
        let string = storage.string as NSString
        storage.beginEditing()
        if only == nil {
            storage.setAttributes(baseAttributes, range: NSRange(location: 0, length: string.length))
        }
        var codeBlocks = 0
        var quoteBlocks = 0
        var nextInline = 0
        let inlines = markdown.inlines

        for (index, block) in markdown.blocks.enumerated() {
            // Counted for every block, so a block keeps its look whether or not its neighbours are restyled.
            let ordinal = LiveOrdinal(block: index, code: codeBlocks, quote: quoteBlocks)
            switch block.kind {
            case .code: codeBlocks += 1
            case .quote: quoteBlocks += 1
            default: break
            }
            // Both lists run in text order and every inline lies inside one block.
            var own: [LiveMarkdown.Inline] = []
            while nextInline < inlines.count, inlines[nextInline].range.location < NSMaxRange(block.range) {
                own.append(inlines[nextInline])
                nextInline += 1
            }
            guard only?.contains(index) ?? true else { continue }

            if only != nil {
                storage.setAttributes(baseAttributes, range: block.range)
            }
            var hidden: [NSRange] = []
            styleBlock(block, ordinal: ordinal, in: storage, string: string, selection: selection, hidden: &hidden)
            for (position, inline) in own.enumerated() where !hidden.contains(where: { NSIntersectionRange($0, inline.range).length > 0 }) {
                styleInline(inline, seed: index &* 64 &+ position, in: storage, string: string, selection: selection)
            }
        }
        storage.endEditing()
    }

    /// Which pieces the cursor is in; restyling is only needed when this changes.
    static func activeSignature(of markdown: LiveMarkdown, selection: NSRange?, in string: NSString) -> [NSRange] {
        guard let selection else { return [] }
        var active: [NSRange] = []
        for block in markdown.blocks where touches(selection, textRange(of: block, in: string)) {
            active.append(block.range)
        }
        for inline in markdown.inlines where touches(selection, inline.range) {
            active.append(inline.range)
        }
        return active
    }

    /// An edit: `range` is what changed in the new text, `delta` how much longer the text got.
    struct Edit: Equatable {
        var range: NSRange
        var delta: Int

        /// What changed between two versions of a note, found by trimming what they share at both ends.
        init(from old: String, to new: String) {
            let before = Array(old.utf16)
            let after = Array(new.utf16)
            let shorter = min(before.count, after.count)
            var prefix = 0
            while prefix < shorter, before[prefix] == after[prefix] {
                prefix += 1
            }
            var suffix = 0
            while suffix < shorter - prefix, before[before.count - 1 - suffix] == after[after.count - 1 - suffix] {
                suffix += 1
            }
            range = NSRange(location: prefix, length: after.count - suffix - prefix)
            delta = after.count - before.count
        }

        /// Where a range of the old text ended up; a range inside the change lands on it.
        func map(_ old: NSRange) -> NSRange {
            func position(_ location: Int) -> Int {
                if location <= range.location { return location }
                if location >= NSMaxRange(range) - delta { return location + delta }
                return range.location
            }
            let start = position(old.location)
            return NSRange(location: start, length: max(0, position(NSMaxRange(old)) - start))
        }
    }

    /// The blocks whose look can differ after `edit` (if any) and with the cursor moving from `oldSelection`
    /// to `newSelection`, or nil when the note changed shape and everything needs styling again.
    static func blocksToRestyle(
        from before: LiveMarkdown,
        to after: LiveMarkdown,
        edit: Edit?,
        oldSelection: NSRange?,
        newSelection: NSRange?
    ) -> IndexSet? {
        var blocks = IndexSet()
        if let edit {
            guard before.blocks.count == after.blocks.count else { return nil }
            for (index, (old, new)) in zip(before.blocks, after.blocks).enumerated() {
                guard old.kind == new.kind else { return nil }
                if touches(edit.range, new.range) {
                    blocks.insert(index)
                    continue
                }
                // Away from the edit, a block must be the same one, moved along with the text after the edit.
                let moved = new.range.location >= NSMaxRange(edit.range) ? old.shifted(by: edit.delta) : old
                guard moved == new else { return nil }
            }
        }
        let selections = [oldSelection.map { edit?.map($0) ?? $0 }, newSelection].compactMap { $0 }
        for (index, block) in after.blocks.enumerated() where selections.contains(where: { touches($0, block.range) }) {
            blocks.insert(index)
        }
        return blocks
    }

    /// The blocks that show a drawing: formulas, pictures and Typst.
    static func blocksWithPictures(in markdown: LiveMarkdown) -> IndexSet {
        var blocks = IndexSet()
        var nextInline = 0
        for (index, block) in markdown.blocks.enumerated() {
            var drawn = false
            switch block.kind {
            case .code, .math, .image: drawn = true
            default: break
            }
            while nextInline < markdown.inlines.count, markdown.inlines[nextInline].range.location < NSMaxRange(block.range) {
                switch markdown.inlines[nextInline].kind {
                case .math, .image: drawn = true
                default: break
                }
                nextInline += 1
            }
            if drawn { blocks.insert(index) }
        }
        return blocks
    }

    static func touches(_ selection: NSRange, _ range: NSRange) -> Bool {
        selection.location <= NSMaxRange(range) && NSMaxRange(selection) >= range.location
    }

    /// A block without its last newline: a cursor at the start of the next line isn't in it.
    static func textRange(of block: LiveMarkdown.Block, in string: NSString) -> NSRange {
        NSRange(location: block.range.location, length: LiveMarkdown.lineEnd(of: block.range, in: string) - block.range.location)
    }

    // MARK: - Base

    var baseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: theme.bodyFont(),
            .foregroundColor: LiveTheme.ink,
            .paragraphStyle: theme.paragraphStyle(),
        ]
    }

    private var markerAttributes: [NSAttributedString.Key: Any] {
        [.foregroundColor: LiveTheme.graphite.withAlphaComponent(0.8)]
    }

    private func isActive(_ range: NSRange, _ selection: NSRange?) -> Bool {
        guard livePreview else { return true }
        guard let selection else { return false }
        return Self.touches(selection, range)
    }

    private func conceal(_ range: NSRange, in storage: NSTextStorage) {
        guard range.length > 0 else { return }
        storage.addAttribute(.remnConceal, value: true, range: range)
    }

    // MARK: - Blocks

    private func styleBlock(
        _ block: LiveMarkdown.Block,
        ordinal: LiveOrdinal,
        in storage: NSTextStorage,
        string: NSString,
        selection: NSRange?,
        hidden: inout [NSRange]
    ) {
        let active = isActive(Self.textRange(of: block, in: string), selection)
        let textEnd = LiveMarkdown.lineEnd(of: block.range, in: string)
        let text = NSRange(location: block.range.location, length: textEnd - block.range.location)
        // By position among the blocks, not in the text, so typing above doesn't redraw every bullet below.
        let seed = ordinal.block &* 31 &+ 7

        switch block.kind {
        case .paragraph:
            break

        case .blank:
            // Paragraphs already keep their distance; an empty line between them only adds a little.
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = theme.size * 0.5
            style.maximumLineHeight = theme.size * 0.5
            style.paragraphSpacing = 0
            storage.addAttribute(.paragraphStyle, value: style, range: block.range)

        case .heading(let level):
            let scale = LiveTheme.headingScales[level - 1]
            storage.addAttributes([
                .font: theme.bodyFont(bold: true, scale: scale),
                .paragraphStyle: theme.paragraphStyle(
                    before: theme.size * (level <= 2 ? 0.95 : 0.6),
                    after: theme.size * (level <= 2 ? 0.55 : 0.3),
                    lineSpacing: theme.size * 0.12
                ),
            ], range: block.range)
            if !theme.font.hasBoldCut {
                storage.addAttributes(fauxBold(scale: scale), range: text)
            }
            if let marker = block.marker {
                if active {
                    storage.addAttributes(markerAttributes, range: marker)
                    storage.addAttribute(.font, value: theme.markerFont, range: marker)
                    storage.removeAttribute(.strokeWidth, range: marker)
                } else {
                    conceal(marker, in: storage)
                }
                if level <= 2, NSMaxRange(marker) < textEnd {
                    let content = NSRange(location: NSMaxRange(marker), length: textEnd - NSMaxRange(marker))
                    storage.addAttribute(.remnDecoration, value: LiveDecoration(.headingSwash(level: level), seed: 4_100 + level), range: content)
                }
            }

        case .quote:
            let seed = 4_200 + ordinal.quote
            storage.addAttributes([
                .foregroundColor: LiveTheme.graphite,
                .paragraphStyle: theme.paragraphStyle(indent: 20, after: theme.size * 0.25),
                .remnDecoration: LiveDecoration(.quoteRule, seed: seed),
            ], range: block.range)
            if let marker = block.marker {
                if active {
                    storage.addAttributes(markerAttributes, range: marker)
                } else {
                    conceal(marker, in: storage)
                }
            }

        case .listItem(let ordered):
            guard let marker = block.marker else { break }
            let indent = width(of: string.substring(with: marker), font: theme.bodyFont())
            storage.addAttribute(.paragraphStyle, value: theme.paragraphStyle(indent: indent, firstLineIndent: 0, after: theme.size * 0.2), range: block.range)
            if ordered {
                storage.addAttribute(.foregroundColor, value: LiveTheme.accent, range: marker)
            } else if let bullet = bulletCharacter(in: marker, string: string) {
                storage.addAttributes([
                    .foregroundColor: PlatformColor.clear,
                    .remnDecoration: LiveDecoration(.bullet, seed: seed),
                ], range: bullet)
            }

        case .task(let checked):
            guard let marker = block.marker, let box = block.checkbox else { break }
            let indent = width(of: string.substring(with: marker), font: theme.bodyFont())
            storage.addAttribute(.paragraphStyle, value: theme.paragraphStyle(indent: indent, firstLineIndent: 0, after: theme.size * 0.2), range: block.range)
            storage.addAttribute(.foregroundColor, value: PlatformColor.clear, range: marker)
            storage.addAttribute(.remnDecoration, value: LiveDecoration(.checkbox(checked: checked), seed: seed), range: box)
            if checked, NSMaxRange(marker) < textEnd {
                let content = NSRange(location: NSMaxRange(marker), length: textEnd - NSMaxRange(marker))
                storage.addAttributes([
                    .foregroundColor: LiveTheme.graphite,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: LiveTheme.graphite,
                ], range: content)
            }

        case .rule:
            if active {
                storage.addAttributes(markerAttributes, range: text)
            } else {
                storage.addAttributes([
                    .foregroundColor: PlatformColor.clear,
                    .remnDecoration: LiveDecoration(.rule, seed: 4_500 &+ seed),
                ], range: text)
            }

        case .table:
            storage.addAttributes([
                .font: theme.codeFont,
                .paragraphStyle: theme.paragraphStyle(after: 0, lineSpacing: theme.codeSize * 0.35),
            ], range: block.range)
            highlightTablePipes(in: text, storage: storage, string: string)

        case .code(let language):
            let index = ordinal.code
            if language == "typst", !active {
                showPicture(.typst, source: block.content.map { string.substring(with: $0) } ?? "", slot: index, block: block, in: storage, string: string, hidden: &hidden)
                return
            }
            styleCode(block, language: language, index: index, active: active, in: storage, string: string, hidden: &hidden)
            if language == "typst", let content = block.content {
                addPreview(.typst, source: string.substring(with: content), slot: index, under: block, in: storage, string: string)
            }

        case .math:
            let latex = block.content.map { string.substring(with: $0) } ?? ""
            if !active {
                showPicture(.blockMath, source: latex, block: block, in: storage, string: string, hidden: &hidden)
                return
            }
            storage.addAttributes([
                .font: theme.codeFont,
                .foregroundColor: LiveTheme.accent,
                .paragraphStyle: theme.paragraphStyle(after: 0, lineSpacing: theme.codeSize * 0.3),
            ], range: block.range)
            for fence in [block.openFence, block.closeFence].compactMap({ $0 }) {
                storage.addAttributes(markerAttributes, range: fence)
            }
            addPreview(.blockMath, source: latex, under: block, in: storage, string: string)

        case .image:
            let source = imageSource(in: text, string: string)
            if !active {
                showPicture(.image, source: source, block: block, in: storage, string: string, hidden: &hidden)
                return
            }
            storage.addAttributes([.font: theme.codeFont, .foregroundColor: LiveTheme.graphite], range: text)
            addPreview(.image, source: source, under: block, in: storage, string: string)
        }
    }

    private func styleCode(
        _ block: LiveMarkdown.Block,
        language: String,
        index: Int,
        active: Bool,
        in storage: NSTextStorage,
        string: NSString,
        hidden: inout [NSRange]
    ) {
        let inset: CGFloat = 16
        let codeStyle = theme.paragraphStyle(indent: inset, after: 0, lineSpacing: theme.codeSize * 0.32)
        (codeStyle as? NSMutableParagraphStyle)?.tailIndent = -inset
        storage.addAttributes([
            .font: theme.codeFont,
            .foregroundColor: LiveTheme.ink,
            .paragraphStyle: codeStyle,
            .remnDecoration: LiveDecoration(.codeBox(label: active || language.isEmpty ? nil : language), seed: 4_300 + index),
        ], range: block.range)
        if let content = block.content, content.length > 0 {
            CodeHighlighter.highlight(string.substring(with: content), language: language, offset: content.location, storage: storage, theme: theme)
        }
        for fence in [block.openFence, block.closeFence].compactMap({ $0 }) {
            if active {
                storage.addAttributes(markerAttributes, range: fence)
            } else {
                collapse(fence, in: storage, string: string)
                hidden.append(fence)
            }
        }
        // Breathing room inside the drawn box when the fences fold away.
        if !active, let content = block.content, content.length > 0 {
            let firstLine = string.lineRange(for: NSRange(location: content.location, length: 0))
            let lastLine = string.lineRange(for: NSRange(location: max(content.location, NSMaxRange(content) - 1), length: 0))
            let first = codeStyle.mutableCopy() as! NSMutableParagraphStyle
            first.paragraphSpacingBefore = theme.size * 0.65
            storage.addAttribute(.paragraphStyle, value: first, range: firstLine)
            let last = (firstLine == lastLine ? first : codeStyle).mutableCopy() as! NSMutableParagraphStyle
            last.paragraphSpacing = theme.size * 0.95
            storage.addAttribute(.paragraphStyle, value: last, range: lastLine)
        }
    }

    /// Replaces a whole block with a picture: its first character carries the drawing, the rest fold away.
    private func showPicture(
        _ kind: LivePicture.Kind,
        source: String,
        slot: Int = 0,
        block: LiveMarkdown.Block,
        in storage: NSTextStorage,
        string: NSString,
        hidden: inout [NSRange]
    ) {
        hidden.append(block.range)
        let picture = picture(LivePictureRequest(kind: kind, source: source, slot: slot))
        let firstLine = string.lineRange(for: NSRange(location: block.range.location, length: 0))
        let firstEnd = LiveMarkdown.lineEnd(of: firstLine, in: string)
        // The line is exactly as tall as the picture plus a margin, so the picture sits evenly between paragraphs.
        let style = theme.paragraphStyle(before: theme.size * 0.3, after: theme.size * 0.3, lineSpacing: 0, alignment: .center)
            .mutableCopy() as! NSMutableParagraphStyle
        let height = min(picture.size.height, 2_000) + theme.size * 0.9
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        storage.addAttribute(.paragraphStyle, value: style, range: firstLine)
        storage.addAttribute(.remnPicture, value: picture, range: NSRange(location: block.range.location, length: 1))
        if firstEnd > block.range.location + 1 {
            conceal(NSRange(location: block.range.location + 1, length: firstEnd - block.range.location - 1), in: storage)
        }
        let rest = NSRange(location: NSMaxRange(firstLine), length: NSMaxRange(block.range) - NSMaxRange(firstLine))
        if rest.length > 0 {
            var location = rest.location
            while location < NSMaxRange(rest) {
                let line = string.lineRange(for: NSRange(location: location, length: 0))
                collapse(line, in: storage, string: string)
                location = NSMaxRange(line)
            }
        }
    }

    /// While a block's source is open, its drawing sits under it.
    private func addPreview(
        _ kind: LivePicture.Kind,
        source: String,
        slot: Int = 0,
        under block: LiveMarkdown.Block,
        in storage: NSTextStorage,
        string: NSString
    ) {
        guard livePreview, !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let picture = picture(LivePictureRequest(kind: kind, source: source, slot: slot))
        let lastLine = string.lineRange(for: NSRange(location: max(block.range.location, NSMaxRange(block.range) - 1), length: 0))
        let style = ((storage.attribute(.paragraphStyle, at: lastLine.location, effectiveRange: nil) as? NSParagraphStyle)
            ?? theme.paragraphStyle()).mutableCopy() as! NSMutableParagraphStyle
        style.paragraphSpacing = picture.size.height + theme.size * 1.4
        storage.addAttributes([.paragraphStyle: style, .remnPreview: picture], range: lastLine)
    }

    private func collapse(_ line: NSRange, in storage: NSTextStorage, string: NSString) {
        storage.addAttributes([
            .remnCollapse: true,
            .paragraphStyle: theme.collapsedParagraphStyle,
            .font: PlatformFont.systemFont(ofSize: 0.5),
        ], range: line)
        let end = LiveMarkdown.lineEnd(of: line, in: string)
        conceal(NSRange(location: line.location, length: end - line.location), in: storage)
    }

    // MARK: - Inline

    private func styleInline(_ inline: LiveMarkdown.Inline, seed: Int, in storage: NSTextStorage, string: NSString, selection: NSRange?) {
        let active = isActive(inline.range, selection)
        func hideOrDim(_ ranges: [NSRange]) {
            for range in ranges {
                if active {
                    storage.addAttributes(markerAttributes, range: range)
                } else {
                    conceal(range, in: storage)
                }
            }
        }

        switch inline.kind {
        case .strong:
            applyTraits(bold: true, italic: nil, range: inline.content, in: storage)
            hideOrDim(inline.markers)
        case .emphasis:
            applyTraits(bold: nil, italic: true, range: inline.content, in: storage)
            hideOrDim(inline.markers)
        case .strikethrough:
            storage.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: LiveTheme.graphite,
                .foregroundColor: LiveTheme.graphite,
            ], range: inline.content)
            hideOrDim(inline.markers)
        case .highlight:
            storage.addAttribute(.remnDecoration, value: LiveDecoration(.highlight, seed: seed), range: inline.content)
            hideOrDim(inline.markers)
        case .code:
            storage.addAttributes([
                .font: theme.codeFont,
                .foregroundColor: LiveTheme.ink,
                .remnDecoration: LiveDecoration(.inlineCode, seed: seed),
            ], range: inline.content)
            storage.removeAttribute(.strokeWidth, range: inline.range)
            if active {
                storage.addAttributes(markerAttributes, range: inline.range)
                storage.addAttribute(.foregroundColor, value: LiveTheme.ink, range: inline.content)
                for marker in inline.markers { storage.addAttribute(.font, value: theme.codeFont, range: marker) }
            } else {
                inline.markers.forEach { conceal($0, in: storage) }
            }
        case .math:
            let latex = string.substring(with: inline.content)
            if active {
                storage.addAttributes([.font: theme.codeFont, .foregroundColor: LiveTheme.accent], range: inline.range)
                storage.removeAttribute(.strokeWidth, range: inline.range)
            } else {
                let picture = picture(LivePictureRequest(kind: .inlineMath, source: latex))
                storage.addAttribute(.remnPicture, value: picture, range: NSRange(location: inline.range.location, length: 1))
                conceal(NSRange(location: inline.range.location + 1, length: inline.range.length - 1), in: storage)
            }
        case .link, .wikiLink:
            storage.addAttributes([
                .foregroundColor: LiveTheme.accent,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: LiveTheme.accent.withAlphaComponent(0.55),
            ], range: inline.content)
            #if os(macOS)
            // A link that shows as a link is followed with a click; the pointer says so.
            if !active { storage.addAttribute(.cursor, value: NSCursor.pointingHand, range: inline.content) }
            #endif
            hideOrDim(inline.markers.filter { NSIntersectionRange($0, inline.content).length == 0 })
        case .image(let url):
            if active {
                storage.addAttributes([.font: theme.codeFont, .foregroundColor: LiveTheme.graphite], range: inline.range)
            } else {
                let picture = picture(LivePictureRequest(kind: .image, source: url))
                storage.addAttribute(.remnPicture, value: picture, range: NSRange(location: inline.range.location, length: 1))
                conceal(NSRange(location: inline.range.location + 1, length: inline.range.length - 1), in: storage)
            }
        case .tag:
            storage.addAttribute(.foregroundColor, value: LiveTheme.accent, range: inline.range)
        }
    }

    /// Bold and italic on top of whatever size the text already has, drawn by hand for faces without the cuts.
    private func applyTraits(bold: Bool?, italic: Bool?, range: NSRange, in storage: NSTextStorage) {
        storage.enumerateAttributes(in: range) { attributes, run, _ in
            guard let font = attributes[.font] as? PlatformFont else { return }
            let isBold = bold ?? (Self.isBold(font) || attributes[.strokeWidth] != nil)
            let isItalic = italic ?? (Self.isItalic(font) || attributes[.obliqueness] != nil)
            let scale = font.pointSize / theme.size
            if theme.font.hasBoldCut {
                storage.addAttribute(.font, value: theme.bodyFont(bold: isBold, italic: isItalic, scale: scale), range: run)
            } else if isBold {
                storage.addAttributes(fauxBold(scale: scale), range: run)
            }
            if isItalic, !theme.font.hasItalicCut {
                storage.addAttribute(.obliqueness, value: 0.16, range: run)
            }
        }
    }

    private func fauxBold(scale: CGFloat) -> [NSAttributedString.Key: Any] {
        [.strokeWidth: -2.6 / max(scale, 0.8), .strokeColor: LiveTheme.ink]
    }

    private static func isBold(_ font: PlatformFont) -> Bool {
        #if canImport(UIKit)
        font.fontDescriptor.symbolicTraits.contains(.traitBold)
        #else
        font.fontDescriptor.symbolicTraits.contains(.bold)
        #endif
    }

    private static func isItalic(_ font: PlatformFont) -> Bool {
        #if canImport(UIKit)
        font.fontDescriptor.symbolicTraits.contains(.traitItalic)
        #else
        font.fontDescriptor.symbolicTraits.contains(.italic)
        #endif
    }

    // MARK: - Helpers

    private func width(of text: String, font: PlatformFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private func bulletCharacter(in marker: NSRange, string: NSString) -> NSRange? {
        for offset in 0..<marker.length {
            let character = string.character(at: marker.location + offset)
            if character == 0x2D || character == 0x2A || character == 0x2B { // - * +
                return NSRange(location: marker.location + offset, length: 1)
            }
        }
        return nil
    }

    private func imageSource(in line: NSRange, string: NSString) -> String {
        let text = string.substring(with: line)
        if let match = text.firstMatch(of: #/!\[\[([^\]|]+)/#) {
            return String(match.output.1)
        }
        guard let match = text.firstMatch(of: #/!\[[^\]]*\]\(([^)\s]+)/#) else { return "" }
        return String(match.output.1)
    }

    private func highlightTablePipes(in range: NSRange, storage: NSTextStorage, string: NSString) {
        for offset in 0..<range.length where string.character(at: range.location + offset) == 0x7C {
            storage.addAttribute(.foregroundColor, value: LiveTheme.graphite.withAlphaComponent(0.6), range: NSRange(location: range.location + offset, length: 1))
        }
    }
}

/// Code in two pens, as on the cards: keywords and numbers in red pencil, strings in blue-grey ink, comments in graphite.
enum CodeHighlighter {
    private static let keywords: Set<String> = [
        "actor", "and", "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "def",
        "default", "defer", "do", "elif", "else", "enum", "except", "export", "extension", "false", "final",
        "finally", "fn", "for", "from", "func", "function", "guard", "if", "impl", "import", "in", "init",
        "interface", "is", "let", "match", "mod", "mut", "new", "nil", "None", "not", "null", "or", "override",
        "package", "pass", "private", "protocol", "pub", "public", "raise", "return", "self", "Self", "static",
        "struct", "super", "switch", "this", "throw", "throws", "trait", "true", "True", "False", "try", "type",
        "typealias", "use", "var", "void", "where", "while", "with", "yield", "set", "show",
    ]

    private static let token = try! NSRegularExpression(
        pattern: #"(//[^\n]*|#(?![a-zA-Z_]*\()[^\n]*|/\*[\s\S]*?\*/)|("(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')|(\b\d+(?:\.\d+)?\b)|([A-Za-z_][A-Za-z0-9_]*)"#
    )

    static func highlight(_ code: String, language: String, offset: Int, storage: NSTextStorage, theme: LiveTheme) {
        let hashComments = ["python", "py", "sh", "bash", "zsh", "ruby", "rb", "r", "yaml", "toml"].contains(language)
        let nsCode = code as NSString
        for match in token.matches(in: code, range: NSRange(location: 0, length: nsCode.length)) {
            let range = NSRange(location: match.range.location + offset, length: match.range.length)
            if match.range(at: 1).location != NSNotFound {
                let text = nsCode.substring(with: match.range(at: 1))
                if text.hasPrefix("#"), !hashComments { continue }
                storage.addAttribute(.foregroundColor, value: LiveTheme.graphite, range: range)
            } else if match.range(at: 2).location != NSNotFound {
                storage.addAttribute(.foregroundColor, value: LiveTheme.emphasis, range: range)
            } else if match.range(at: 3).location != NSNotFound {
                storage.addAttribute(.foregroundColor, value: LiveTheme.accent, range: range)
            } else if keywords.contains(nsCode.substring(with: match.range(at: 4))) {
                storage.addAttributes([.foregroundColor: LiveTheme.accent, .font: theme.codeBoldFont], range: range)
            }
        }
    }
}
