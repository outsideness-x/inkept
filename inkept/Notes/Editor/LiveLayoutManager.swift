import SwiftUI

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// TextKit 1 layout for the live editor. The text storage always holds the note's exact Markdown;
/// this is where hidden punctuation takes no room, pictures take their size, folded lines take none,
/// and the ink around the text gets drawn.
final class LiveLayoutManager: NSLayoutManager, NSLayoutManagerDelegate {
    override init() {
        super.init()
        delegate = self
        #if canImport(UIKit)
        allowsNonContiguousLayout = true
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Glyphs

    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
        properties: UnsafePointer<NSLayoutManager.GlyphProperty>,
        characterIndexes: UnsafePointer<Int>,
        font: PlatformFont,
        forGlyphRange glyphRange: NSRange
    ) -> Int {
        guard let storage = textStorage, glyphRange.length > 0 else { return 0 }
        var changed = false
        var adjusted = [NSLayoutManager.GlyphProperty](repeating: [], count: glyphRange.length)
        for index in 0..<glyphRange.length {
            let character = characterIndexes[index]
            var property = properties[index]
            if character < storage.length {
                if storage.attribute(.inkeptPicture, at: character, effectiveRange: nil) != nil {
                    property = .controlCharacter
                    changed = true
                } else if isConcealed(character) {
                    // A control glyph that takes no room, not a null glyph: after a null glyph at the start of
                    // a wrapped line, TextKit on iOS loses track of where the line's glyphs are, and whatever is
                    // drawn from their bounds — a link's underline, a highlight — goes missing.
                    property = .controlCharacter
                    changed = true
                }
            }
            adjusted[index] = property
        }
        guard changed else { return 0 }
        adjusted.withUnsafeBufferPointer { buffer in
            layoutManager.setGlyphs(
                glyphs,
                properties: buffer.baseAddress!,
                characterIndexes: characterIndexes,
                font: font,
                forGlyphRange: glyphRange
            )
        }
        return glyphRange.length
    }

    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldUse action: NSLayoutManager.ControlCharacterAction,
        forControlCharacterAt characterIndex: Int
    ) -> NSLayoutManager.ControlCharacterAction {
        if picture(at: characterIndex) != nil { return .whitespace }
        // Hidden punctuation takes no room; a line or paragraph break stays one.
        if isConcealed(characterIndex), action.isDisjoint(with: [.lineBreak, .paragraphBreak, .containerBreak]) {
            return .zeroAdvancement
        }
        return action
    }

    func layoutManager(
        _ layoutManager: NSLayoutManager,
        boundingBoxForControlGlyphAt glyphIndex: Int,
        for textContainer: NSTextContainer,
        proposedLineFragment proposedRect: CGRect,
        glyphPosition: CGPoint,
        characterIndex: Int
    ) -> CGRect {
        guard let picture = picture(at: characterIndex) else { return .zero }
        let size = displaySize(of: picture, available: proposedRect.width - 2 * textContainer.lineFragmentPadding)
        if picture.isBlock {
            return CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        let descent = picture.descent * (size.height / max(picture.size.height, 1))
        return CGRect(x: 0, y: -descent, width: size.width, height: size.height)
    }

    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange
    ) -> Bool {
        guard let storage = textStorage, glyphRange.length > 0 else { return false }
        let character = characterIndexForGlyph(at: glyphRange.location)
        guard character < storage.length, storage.attribute(.inkeptCollapse, at: character, effectiveRange: nil) != nil else {
            return false
        }
        lineFragmentRect.pointee.size.height = 0
        lineFragmentUsedRect.pointee.size.height = 0
        baselineOffset.pointee = 0
        return true
    }

    private func isConcealed(_ characterIndex: Int) -> Bool {
        guard let storage = textStorage, characterIndex < storage.length else { return false }
        return storage.attribute(.inkeptConceal, at: characterIndex, effectiveRange: nil) != nil
    }

    private func picture(at characterIndex: Int) -> LivePicture? {
        guard let storage = textStorage, characterIndex < storage.length else { return nil }
        return storage.attribute(.inkeptPicture, at: characterIndex, effectiveRange: nil) as? LivePicture
    }

    /// Pictures never run past the page; wide ones are scaled down to fit.
    private func displaySize(of picture: LivePicture, available: CGFloat) -> CGSize {
        let limit = max(available - 2, 40)
        guard picture.size.width > limit else { return picture.size }
        let scale = limit / picture.size.width
        return CGSize(width: limit, height: (picture.size.height * scale).rounded(.up))
    }

    // MARK: - Drawing

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let context = Self.currentContext, let storage = textStorage, let container = textContainers.first else { return }
        let characters = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let whole = NSRange(location: 0, length: storage.length)
        var drawn = Set<Int>()
        storage.enumerateAttribute(.inkeptDecoration, in: characters) { value, range, _ in
            guard let decoration = value as? LiveDecoration else { return }
            var full = range
            _ = storage.attribute(.inkeptDecoration, at: range.location, longestEffectiveRange: &full, in: whole)
            guard drawn.insert(full.location).inserted else { return }
            context.saveGState()
            draw(decoration, range: full, container: container, origin: origin, in: context)
            context.restoreGState()
        }
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let context = Self.currentContext, let storage = textStorage, let container = textContainers.first else { return }
        let characters = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        storage.enumerateAttribute(.inkeptPicture, in: characters) { value, range, _ in
            guard let picture = value as? LivePicture else { return }
            let glyph = glyphIndexForCharacter(at: range.location)
            let line = lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            let used = lineFragmentUsedRect(forGlyphAt: glyph, effectiveRange: nil)
            let baseline = location(forGlyphAt: glyph)
            let size = displaySize(of: picture, available: container.size.width - 2 * container.lineFragmentPadding)
            let scale = size.height / max(picture.size.height, 1)
            var rect: CGRect
            if picture.isBlock {
                rect = CGRect(x: line.minX + baseline.x, y: used.midY - size.height / 2, width: size.width, height: size.height)
            } else {
                // Sit the formula on the line's baseline, reaching below it by its own descent.
                let bottom = line.minY + baseline.y + picture.descent * scale
                rect = CGRect(x: line.minX + baseline.x, y: bottom - size.height, width: size.width, height: size.height)
            }
            draw(picture, in: rect.offsetBy(dx: origin.x, dy: origin.y), context: context)
        }
        storage.enumerateAttribute(.inkeptPreview, in: characters) { value, range, _ in
            guard let picture = value as? LivePicture else { return }
            let glyph = glyphIndexForCharacter(at: max(range.location, NSMaxRange(range) - 1))
            let line = lineFragmentUsedRect(forGlyphAt: glyph, effectiveRange: nil).offsetBy(dx: origin.x, dy: origin.y)
            let available = container.size.width - 2 * container.lineFragmentPadding
            let size = displaySize(of: picture, available: available)
            let top = line.maxY + 16
            let rect = CGRect(
                x: origin.x + container.lineFragmentPadding + (available - size.width) / 2,
                y: top,
                width: size.width,
                height: size.height
            )
            context.saveGState()
            let frame = rect.insetBy(dx: -12, dy: -8)
            context.addPath(InkBrush.stroke(InkGeometry.roundedRectLoop(in: frame, cornerRadius: 10, seed: 4_810), pen: .hairline, seed: 4_810).cgPath)
            context.setFillColor(LiveTheme.graphite.withAlphaComponent(0.45).cgColor)
            context.fillPath()
            context.restoreGState()
            draw(picture, in: rect, context: context)
        }
    }

    private func draw(_ picture: LivePicture, in rect: CGRect, context: CGContext) {
        guard let image = picture.image else {
            context.saveGState()
            context.addPath(InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: rect.insetBy(dx: 2, dy: 2), cornerRadius: 8, seed: 4_900)).cgPath)
            context.setFillColor(LiveTheme.ink.withAlphaComponent(0.05).cgColor)
            context.fillPath()
            context.restoreGState()
            return
        }
        context.saveGState()
        context.interpolationQuality = .high
        if picture.kind == .image {
            context.addPath(InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: rect, cornerRadius: 8, seed: picture.key.inkSeed)).cgPath)
            context.clip()
        }
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
        if picture.kind == .image {
            let frame = InkBrush.stroke(InkGeometry.roundedRectLoop(in: rect, cornerRadius: 8, seed: picture.key.inkSeed), pen: .hairline, seed: picture.key.inkSeed)
            fill(frame, LiveTheme.ink.withAlphaComponent(0.55), context)
        }
    }

    private func draw(_ decoration: LiveDecoration, range: NSRange, container: NSTextContainer, origin: CGPoint, in context: CGContext) {
        let glyphs = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        guard glyphs.length > 0 else { return }
        let padding = container.lineFragmentPadding
        let width = container.size.width - 2 * padding

        switch decoration.kind {
        case .codeBox(let label):
            let block = usedRect(for: glyphs).offsetBy(dx: origin.x, dy: origin.y)
            let box = CGRect(x: origin.x + padding, y: block.minY - 8, width: width, height: block.height + 16)
            fill(InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: box, cornerRadius: 10, seed: decoration.seed ^ 0xF1)), LiveTheme.ink.withAlphaComponent(0.045), context)
            fill(InkBrush.stroke(InkGeometry.roundedRectLoop(in: box, cornerRadius: 10, seed: decoration.seed), pen: .hairline, seed: decoration.seed), LiveTheme.graphite.withAlphaComponent(0.7), context)
            if let label, !label.isEmpty {
                let text = NSAttributedString(string: label, attributes: [
                    .font: PlatformFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: LiveTheme.graphite,
                ])
                let size = text.size()
                Self.draw(text, at: CGPoint(x: box.maxX - size.width - 10, y: box.minY + 5))
            }

        case .quoteRule:
            let block = usedRect(for: glyphs).offsetBy(dx: origin.x, dy: origin.y)
            let line = CGRect(x: origin.x + padding + 4, y: block.minY + 2, width: 4, height: max(block.height - 4, 8))
            fill(InkBrush.stroke(InkGeometry.line(from: CGPoint(x: line.midX, y: line.minY), to: CGPoint(x: line.midX, y: line.maxY), seed: decoration.seed), pen: .fine, seed: decoration.seed), LiveTheme.accent.withAlphaComponent(0.8), context)

        case .headingSwash(let level):
            let first = NSRange(location: glyphs.location, length: 1)
            let glyphRect = boundingRect(forGlyphRange: first, in: container).offsetBy(dx: origin.x, dy: origin.y)
            let line = lineFragmentUsedRect(forGlyphAt: glyphs.location, effectiveRange: nil).offsetBy(dx: origin.x, dy: origin.y)
            let swash = CGRect(x: glyphRect.minX, y: line.maxY - 1, width: level == 1 ? 72 : 48, height: 8)
            fill(InkBrush.stroke(InkGeometry.underline(in: swash, seed: decoration.seed), pen: .bold, seed: decoration.seed), LiveTheme.accent, context)

        case .rule:
            let line = lineFragmentUsedRect(forGlyphAt: glyphs.location, effectiveRange: nil).offsetBy(dx: origin.x, dy: origin.y)
            let rect = CGRect(x: origin.x + padding, y: line.midY - 3, width: width, height: 6)
            fill(InkDashes(seed: decoration.seed).path(in: rect), LiveTheme.graphite.withAlphaComponent(0.7), context)

        case .bullet:
            let glyphRect = boundingRect(forGlyphRange: NSRange(location: glyphs.location, length: 1), in: container)
                .offsetBy(dx: origin.x, dy: origin.y)
            let dash = CGRect(x: glyphRect.midX - 5, y: glyphRect.midY - 2, width: 10, height: 4)
            fill(InkLine(seed: decoration.seed).path(in: dash), LiveTheme.accent, context)

        case .checkbox(let checked):
            let glyphRect = boundingRect(forGlyphRange: glyphs, in: container).offsetBy(dx: origin.x, dy: origin.y)
            let side = min(glyphRect.height * 0.62, 18)
            let box = CGRect(x: glyphRect.minX + 1, y: glyphRect.midY - side / 2, width: side, height: side)
            fill(InkRoundedRect(seed: decoration.seed, cornerRadius: 4, pen: .fine).path(in: box), checked ? LiveTheme.ink : LiveTheme.graphite, context)
            if checked {
                let tick = CGRect(x: box.minX + 2, y: box.minY - side * 0.3, width: side * 1.15, height: side * 1.1)
                fill(InkTick(seed: decoration.seed &+ 5).path(in: tick), LiveTheme.accent, context)
            }

        case .highlight:
            enumerateEnclosingRects(forGlyphRange: glyphs, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: container) { rect, _ in
                let patch = rect.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: -2, dy: rect.height * 0.12)
                self.fill(InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: patch, cornerRadius: 4, seed: decoration.seed)), LiveTheme.accent.withAlphaComponent(0.2), context)
            }

        case .inlineCode:
            enumerateEnclosingRects(forGlyphRange: glyphs, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: container) { rect, _ in
                let patch = rect.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: -3, dy: rect.height * 0.08)
                self.fill(InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: patch, cornerRadius: 5, seed: decoration.seed)), LiveTheme.ink.withAlphaComponent(0.07), context)
            }
        }
    }

    /// The union of the text a range actually occupies, ignoring the spacing between paragraphs.
    private func usedRect(for glyphs: NSRange) -> CGRect {
        var union = CGRect.null
        enumerateLineFragments(forGlyphRange: glyphs) { _, used, _, _, _ in
            union = union.union(used)
        }
        return union.isNull ? .zero : union
    }

    private func fill(_ path: Path, _ color: PlatformColor, _ context: CGContext) {
        context.addPath(path.cgPath)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    private static var currentContext: CGContext? {
        #if canImport(UIKit)
        UIGraphicsGetCurrentContext()
        #else
        NSGraphicsContext.current?.cgContext
        #endif
    }

    private static func draw(_ text: NSAttributedString, at point: CGPoint) {
        text.draw(at: point)
    }
}
