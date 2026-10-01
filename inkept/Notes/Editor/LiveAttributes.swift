import SwiftUI

extension NSAttributedString.Key {
    /// The character takes no room and isn't drawn: Markdown punctuation away from the cursor.
    static let remnConceal = NSAttributedString.Key("remnConceal")
    /// The first character of something drawn as a picture (a formula, an image, a Typst block).
    static let remnPicture = NSAttributedString.Key("remnPicture")
    /// A line that folds away completely while the picture above it stands in for it.
    static let remnCollapse = NSAttributedString.Key("remnCollapse")
    /// Something drawn in ink around or behind the text: a code box, a quote rule, a heading swash.
    static let remnDecoration = NSAttributedString.Key("remnDecoration")
    /// A picture drawn under the source while the source is being edited.
    static let remnPreview = NSAttributedString.Key("remnPreview")
}

/// A picture that stands in for Markdown source.
final class LivePicture: NSObject {
    enum Kind: Hashable {
        case inlineMath
        case blockMath
        case image
        case typst
    }

    let kind: Kind
    let key: String
    /// The picture's size in points; block pictures are centred in the line.
    let size: CGSize
    /// How far the picture reaches below the baseline, for formulas set in a line of text.
    let descent: CGFloat
    let image: CGImage?

    init(kind: Kind, key: String, size: CGSize, descent: CGFloat = 0, image: CGImage?) {
        self.kind = kind
        self.key = key
        self.size = size
        self.descent = descent
        self.image = image
    }

    var isBlock: Bool { kind != .inlineMath }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LivePicture else { return false }
        return kind == other.kind && key == other.key && size == other.size && (image == nil) == (other.image == nil)
    }

    override var hash: Int { key.hashValue }
}

/// Ink drawn by the layout manager, behind or beside the text it belongs to.
final class LiveDecoration: NSObject {
    enum Kind: Equatable {
        /// A hand-drawn box behind a fenced code block; `label` is the language, shown when the fences are hidden.
        case codeBox(label: String?)
        /// The red pencil rule down the side of a quote.
        case quoteRule
        /// The red swash under a large heading.
        case headingSwash(level: Int)
        /// A dashed pencil line across the page.
        case rule
        /// A short red pencil dash for a bullet.
        case bullet
        /// A drawn box, ticked when done.
        case checkbox(checked: Bool)
        /// A highlighter stroke behind text.
        case highlight
        /// A faint patch behind inline code.
        case inlineCode
    }

    let kind: Kind
    /// Keeps each drawing's wobble the same from one frame to the next.
    let seed: Int

    init(_ kind: Kind, seed: Int) {
        self.kind = kind
        self.seed = seed
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LiveDecoration else { return false }
        return kind == other.kind && seed == other.seed
    }

    override var hash: Int { seed }
}

/// Type and colour for one note.
struct LiveTheme {
    var font: NoteFont
    var size: CGFloat

    init(font: NoteFont) {
        self.font = font
        self.size = font.bodySize
    }

    static let ink = PlatformColor.remnDynamic(light: 0x1D1B19, dark: 0xEFEADF)
    static let graphite = PlatformColor.remnDynamic(light: 0x5E5952, dark: 0xA39E95)
    static let accent = PlatformColor.remnDynamic(light: 0xBE3B2C, dark: 0xF0674E)
    static let emphasis = PlatformColor.remnDynamic(light: 0x3B5873, dark: 0x94B3CE)
    static let paper = PlatformColor.remnDynamic(light: 0xFBF8F1, dark: 0x1F1D1A)

    var codeSize: CGFloat { (size * (font == .neucha ? 0.74 : 0.86)).rounded() }

    func bodyFont(bold: Bool = false, italic: Bool = false, scale: CGFloat = 1) -> PlatformFont {
        font.platformFont(size: size * scale, bold: bold, italic: italic)
    }

    var codeFont: PlatformFont { .monospacedSystemFont(ofSize: codeSize, weight: .regular) }
    var codeBoldFont: PlatformFont { .monospacedSystemFont(ofSize: codeSize, weight: .semibold) }
    var markerFont: PlatformFont { .monospacedSystemFont(ofSize: codeSize * 0.92, weight: .regular) }

    static let headingScales: [CGFloat] = [1.55, 1.3, 1.14, 1.04, 1, 1]

    func paragraphStyle(
        indent: CGFloat = 0,
        firstLineIndent: CGFloat? = nil,
        before: CGFloat = 0,
        after: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        alignment: NSTextAlignment = .natural
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing ?? size * font.leading
        style.paragraphSpacing = after ?? size * 0.45
        style.paragraphSpacingBefore = before
        style.headIndent = indent
        style.firstLineHeadIndent = firstLineIndent ?? indent
        style.alignment = alignment
        return style
    }

    /// For lines that fold away.
    var collapsedParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.minimumLineHeight = 0.01
        style.maximumLineHeight = 0.01
        return style
    }
}
