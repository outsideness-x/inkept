import SwiftUI

/// A card in a deck: the first useful line of its front, and when it's due.
struct CardRow: View {
    let card: Flashcard

    var body: some View {
        FlashcardSurface(seed: card.id.inkSeed, style: .compact) {
            VStack(alignment: .leading, spacing: 8) {
                HandwrittenText(verbatim: RemnFormatters.usefulLine(card.frontMarkdown))
                    .font(RemnTypography.display(22, relativeTo: .body))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 30)
                HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                    .font(RemnTypography.note)
                    .foregroundStyle(isDue ? Color.remnAccent : Color.remnGraphite)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var isDue: Bool {
        card.state != .new && card.due <= .now
    }
}
