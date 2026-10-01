import SwiftUI

/// A card laid on paper for saving as an image; always in the light kit, so it prints the same everywhere.
struct CardExportView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HandwrittenText(verbatim: card.deckContext)
                .font(RemnTypography.note)
                .foregroundStyle(Color.remnGraphite)
            FlashcardSurface(seed: card.id.inkSeed, style: .export) {
                VStack(alignment: .leading, spacing: 0) {
                    FlashcardSideLabel(title: "card.front")
                    IndexRule(seed: card.id.inkSeed ^ 0x11)
                        .padding(.top, 4)
                        .padding(.bottom, 14)
                    CardContentView(markdown: card.frontMarkdown, context: .export)
                    InkDashes(seed: card.id.inkSeed ^ 0x22)
                        .fill(Color.remnGraphite.opacity(0.6))
                        .frame(height: 6)
                        .padding(.vertical, 18)
                    FlashcardSideLabel(title: "card.back")
                        .padding(.bottom, 10)
                    CardContentView(markdown: card.backMarkdown, context: .export)
                }
            }
            HStack(spacing: 8) {
                Spacer()
                StackedCardsDoodle(width: 30)
                HandwrittenText("remn", weight: 0.8)
                    .font(RemnTypography.display(22, relativeTo: .body))
                    .foregroundStyle(Color.remnInk)
            }
        }
        .padding(30)
        .frame(width: 540, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.remnPaper)
        .environment(\.colorScheme, .light)
    }
}
