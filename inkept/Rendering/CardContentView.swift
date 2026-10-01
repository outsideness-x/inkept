import SwiftUI
import SwiftUIMath
import Textual

enum CardRenderingContext {
    case study
    case detail
    case preview
    case export
}

/// The Markdown on one side of a card, set in remn's hand.
struct CardContentView: View {
    let markdown: String
    var context: CardRenderingContext = .detail
    @ScaledMetric(relativeTo: .body) private var baseMathSize = 22

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 10) {
            ForEach(Array(MarkdownRenderSource.blocks(in: markdown).enumerated()), id: \.offset) { _, block in
                switch block {
                case .markdown(let markdown):
                    structuredText(markdown)
                case .displayMath(let latex):
                    displayMath(latex)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .accessibilityElement(children: .contain)
    }

    /// A single short line on a study card sits in the middle, like a word written on an index card.
    private var centered: Bool {
        guard context == .study else { return false }
        let text = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count <= 90, !text.contains("\n"), !text.contains("$$") else { return false }
        return !["```", "~~~", "- ", "* ", "+ ", "#", ">", "|", "1."].contains { text.hasPrefix($0) }
    }

    private func structuredText(_ markdown: String) -> some View {
        StructuredText(
            markdown: markdown,
            patternOptions: .init(mathExpressions: true)
        )
        .textual.structuredTextStyle(RemnTextStyle())
        .textual.highlighterTheme(.remn)
        .textual.mathProperties(.init(fontScale: mathScale, textAlignment: .center))
        .textual.imageAttachmentLoader(OfflineAttachmentLoader())
        .textual.emojiAttachmentLoader(OfflineAttachmentLoader())
        .textual.overflowMode(.scroll)
        .textual.textSelection(.enabled)
        .font(contentFont)
        .foregroundStyle(Color.remnInk)
        .tint(.remnAccent)
        .multilineTextAlignment(centered ? .center : .leading)
        .textRenderer(InkTextRenderer(wobble: 0.6))
        .environment(\.openURL, OpenURLAction { _ in .discarded })
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .accessibilityLabel(Text(markdown))
    }

    private func displayMath(_ latex: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                math(latex)
                Spacer(minLength: 0)
            }
            ScrollView(.horizontal, showsIndicators: true) {
                math(latex)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .accessibilityLabel(Text(verbatim: latex))
    }

    private func math(_ latex: String) -> some View {
        Math(latex)
            .mathFont(.init(name: .latinModern, size: mathFontSize))
            .mathTypesettingStyle(.display)
            .mathRenderingMode(.monochrome)
            .foregroundStyle(Color.remnInk)
    }

    private var mathFontSize: CGFloat {
        switch context {
        case .study: baseMathSize * 1.18
        case .detail, .preview, .export: baseMathSize
        }
    }

    private var mathScale: CGFloat {
        switch context {
        case .study: 1.26
        case .detail, .preview, .export: 1.2
        }
    }

    private var contentFont: Font {
        switch context {
        case .study: RemnTypography.studyText
        case .detail, .preview, .export: RemnTypography.cardText
        }
    }
}
