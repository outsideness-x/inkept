import SwiftUI

/// A card in a deck: the first useful line of its front, and when it's due.
struct CardRow: View {
    let card: Flashcard

    var body: some View {
        FlashcardSurface(seed: card.id.inkSeed, style: .compact) {
            VStack(alignment: .leading, spacing: 8) {
                HandwrittenText(verbatim: InkeptFormatters.usefulLine(card.frontMarkdown))
                    .font(InkeptTypography.display(22, relativeTo: .body))
                    .foregroundStyle(Color.inkeptInk)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 30)
                HandwrittenText(verbatim: InkeptFormatters.dueStatus(for: card))
                    .font(InkeptTypography.note)
                    .foregroundStyle(isDue ? Color.inkeptAccent : Color.inkeptGraphite)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var isDue: Bool {
        card.state != .new && card.due <= .now
    }
}
