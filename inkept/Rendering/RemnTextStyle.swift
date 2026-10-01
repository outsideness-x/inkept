import SwiftUI
import Textual

/// Markdown on a card, written in the same hand as the rest of remn: ruled headings,
/// pencilled quotes and code set in a drawn box.
struct RemnTextStyle: StructuredText.Style {
    let inlineStyle = InlineStyle()
        .code(.monospaced, .fontScale(0.82))
        .strong(.foregroundColor(.remnStrong))
        .emphasis(.foregroundColor(.remnEmphasis))
        .link(.foregroundColor(.remnStrong), .underlineStyle(.single))
    let headingStyle = RemnHeadingStyle()
    let paragraphStyle = RemnParagraphStyle()
    let blockQuoteStyle = RemnBlockQuoteStyle()
    let codeBlockStyle = RemnCodeBlockStyle()
    let listItemStyle: StructuredText.DefaultListItemStyle = .default(markerSpacing: .fontScaled(0.45))
    let unorderedListMarker = RemnListMarker()
    let orderedListMarker: StructuredText.DecimalListMarker = .decimal
    let tableStyle: StructuredText.DefaultTableStyle = .default
    let tableCellStyle: StructuredText.DefaultTableCellStyle = .default
    let thematicBreakStyle = RemnThematicBreakStyle()
}

struct RemnHeadingStyle: StructuredText.HeadingStyle {
    private static let scales: [CGFloat] = [1.45, 1.25, 1.1, 1, 1, 1]

    func makeBody(configuration: Configuration) -> some View {
        let level = min(max(configuration.headingLevel, 1), 6)
        VStack(alignment: .leading, spacing: 0) {
            configuration.label
                .textual.fontScale(Self.scales[level - 1])
                .textual.lineSpacing(.fontScaled(0.1))
            if level <= 2 {
                TitleSwash(seed: 4_100 + level, width: level == 1 ? 64 : 44)
            }
        }
        .textual.blockSpacing(.fontScaled(top: 0.7, bottom: 0.45))
    }
}

struct RemnParagraphStyle: StructuredText.ParagraphStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textual.lineSpacing(.fontScaled(0.16))
            .textual.blockSpacing(.fontScaled(top: 0, bottom: 0.6))
    }
}

struct RemnBlockQuoteStyle: StructuredText.BlockQuoteStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            InkLine(seed: 4_200 + configuration.indentationLevel, pen: .fine, vertical: true)
                .fill(Color.remnAccent.opacity(0.8))
                .frame(width: 6)
            configuration.label
                .foregroundStyle(Color.remnGraphite)
        }
        .fixedSize(horizontal: false, vertical: true)
        .textual.blockSpacing(.fontScaled(top: 0, bottom: 0.6))
    }
}

struct RemnCodeBlockStyle: StructuredText.CodeBlockStyle {
    func makeBody(configuration: Configuration) -> some View {
        Overflow {
            configuration.label
                .textual.lineSpacing(.fontScaled(0.2))
                .textual.fontScale(0.68)
                .fixedSize(horizontal: false, vertical: true)
                .monospaced()
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
        }
        .textRenderer(InkTextRenderer(wobble: 0))
        .background {
            InkBox(
                seed: 4_300 + configuration.indentationLevel,
                cornerRadius: 10,
                fill: .remnInk.opacity(0.045),
                outline: .remnGraphite.opacity(0.7),
                pen: .hairline,
                registration: .zero
            )
        }
        .textual.blockSpacing(.fontScaled(top: 0.1, bottom: 0.7))
    }
}

struct RemnListMarker: StructuredText.UnorderedListMarker {
    func makeBody(configuration: Configuration) -> some View {
        InkLine(seed: 4_400 + configuration.indentationLevel, pen: .fine)
            .fill(Color.remnAccent)
            .frame(width: 9, height: 5)
            .textual.frame(minWidth: .fontScaled(1.1), alignment: .trailing)
    }
}

struct RemnThematicBreakStyle: StructuredText.ThematicBreakStyle {
    func makeBody(configuration _: Configuration) -> some View {
        InkDashes(seed: 4_500)
            .fill(Color.remnGraphite.opacity(0.7))
            .frame(height: 6)
            .textual.blockSpacing(.fontScaled(top: 0.6, bottom: 0.9))
    }
}

extension StructuredText.HighlighterTheme {
    /// Code in two pens: keywords and literals in red pencil, comments in graphite, the rest in ink.
    static let remn = Self(
        foregroundColor: .remnCodeInk,
        backgroundColor: DynamicColor(.clear),
        tokenProperties: [
            .keyword: AnyTextProperty(.foregroundColor(.remnStrong)),
            .builtin: AnyTextProperty(.foregroundColor(.remnStrong)),
            .literal: AnyTextProperty(.foregroundColor(.remnStrong)),
            .boolean: AnyTextProperty(.foregroundColor(.remnStrong)),
            .number: AnyTextProperty(.foregroundColor(.remnStrong)),
            .string: AnyTextProperty(.foregroundColor(.remnEmphasis)),
            .char: AnyTextProperty(.foregroundColor(.remnEmphasis)),
            .regex: AnyTextProperty(.foregroundColor(.remnEmphasis)),
            .url: AnyTextProperty(.foregroundColor(.remnEmphasis)),
            .comment: AnyTextProperty(.foregroundColor(.remnComment)),
            .blockComment: AnyTextProperty(.foregroundColor(.remnComment)),
            .docComment: AnyTextProperty(.foregroundColor(.remnComment)),
            .preprocessor: AnyTextProperty(.foregroundColor(.remnComment)),
            .attribute: AnyTextProperty(.foregroundColor(.remnComment)),
            .inserted: AnyTextProperty(.foregroundColor(.remnEmphasis)),
            .deleted: AnyTextProperty(.foregroundColor(.remnStrong)),
        ]
    )
}

extension DynamicColor {
    static let remnCodeInk = DynamicColor(
        light: Color(red: 0.114, green: 0.106, blue: 0.098),
        dark: Color(red: 0.937, green: 0.918, blue: 0.875)
    )
    /// The red pencil: bold text, keywords, links.
    static let remnStrong = DynamicColor(
        light: Color(red: 0.745, green: 0.231, blue: 0.173),
        dark: Color(red: 0.941, green: 0.404, blue: 0.306)
    )
    /// A softer ink for emphasis and strings.
    static let remnEmphasis = DynamicColor(
        light: Color(red: 0.231, green: 0.345, blue: 0.451),
        dark: Color(red: 0.580, green: 0.702, blue: 0.808)
    )
    static let remnComment = DynamicColor(
        light: Color(red: 0.369, green: 0.349, blue: 0.322),
        dark: Color(red: 0.639, green: 0.620, blue: 0.584)
    )
}
