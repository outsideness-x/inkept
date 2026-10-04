import SwiftUI

/// A card laid on paper for saving as an image; always in the light kit, so it prints the same everywhere.
struct CardExportView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HandwrittenText(verbatim: card.deckContext)
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
            FlashcardSurface(seed: card.id.inkSeed, style: .export) {
                VStack(alignment: .leading, spacing: 0) {
                    FlashcardSideLabel(title: "card.front")
                    IndexRule(seed: card.id.inkSeed ^ 0x11)
                        .padding(.top, 4)
                        .padding(.bottom, 14)
                    CardContentView(markdown: card.frontMarkdown, context: .export)
                    InkDashes(seed: card.id.inkSeed ^ 0x22)
                        .fill(Color.inkeptGraphite.opacity(0.6))
                        .allowsHitTesting(false)
                        .frame(height: 6)
                        .padding(.vertical, 18)
                    FlashcardSideLabel(title: "card.back")
                        .padding(.bottom, 10)
                    CardContentView(markdown: card.backMarkdown, context: .export)
                }
            }
            HStack(spacing: 8) {
                Spacer()
                ForgetMeNot(colors: .inkept, size: 40, lineWeight: 2.2)
                HandwrittenText("inkept", weight: 0.8)
                    .font(InkeptTypography.display(22, relativeTo: .body))
                    .foregroundStyle(Color.inkeptInk)
            }
        }
        .padding(30)
        .frame(width: 540, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.inkeptPaper)
        .environment(\.colorScheme, .light)
    }
}
