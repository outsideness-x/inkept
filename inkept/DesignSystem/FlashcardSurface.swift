import SwiftUI

enum FlashcardSurfaceStyle {
    case compact
    case regular
    case study
    case export

    var padding: EdgeInsets {
        switch self {
        case .compact: EdgeInsets(top: 14, leading: 18, bottom: 16, trailing: 18)
        case .regular: EdgeInsets(top: 20, leading: 22, bottom: 24, trailing: 22)
        case .study: EdgeInsets(top: 24, leading: 26, bottom: 28, trailing: 26)
        case .export: EdgeInsets(top: 26, leading: 28, bottom: 30, trailing: 28)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: 12
        case .regular, .study, .export: 16
        }
    }

    var pen: InkPen {
        switch self {
        case .compact: .fine
        case .regular, .study, .export: .pen
        }
    }

    /// Where the card underneath peeks out.
    var underneath: CGSize {
        switch self {
        case .compact: CGSize(width: 3.5, height: 5)
        case .regular: CGSize(width: 4, height: 6)
        case .study, .export: CGSize(width: 5, height: 8)
        }
    }
}

/// An index card: paper, a pen outline, and a hatched card underneath.
struct FlashcardSurface<Content: View>: View {
    let seed: Int
    let style: FlashcardSurfaceStyle
    private let content: Content

    init(
        seed: Int,
        style: FlashcardSurfaceStyle = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.seed = seed
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(style.padding)
            .background {
                ZStack {
                    InkHatch(seed: seed ^ 0x3C1, spacing: style == .compact ? 4 : 4.6)
                        .fill(Color.remnAccent.opacity(style == .compact ? 0.55 : 0.45))
                        .clipShape(InkPatch(seed: seed ^ 0x3C2, cornerRadius: style.cornerRadius))
                        .offset(style.underneath)
                    InkBox(
                        seed: seed,
                        cornerRadius: style.cornerRadius,
                        fill: .remnCardPaper,
                        outline: .remnInk,
                        pen: style.pen,
                        registration: CGSize(width: 0.8, height: 1.1)
                    )
                }
            }
            .padding(.trailing, style.underneath.width)
            .padding(.bottom, style.underneath.height)
    }
}

/// The small pencil label in the corner of a card.
struct FlashcardSideLabel: View {
    let title: LocalizedStringKey

    var body: some View {
        HandwrittenText(title)
            .font(RemnTypography.note)
            .foregroundStyle(Color.remnGraphite)
    }
}
