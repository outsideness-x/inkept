import SwiftData
import SwiftUI

struct SearchView: View {
    @Query private var cards: [Flashcard]
    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: String(localized: "library"))
            HStack(spacing: 12) {
                InkIcon(kind: .search, color: .remnGraphite, size: 21)
                TextField("search.placeholder", text: $query)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .font(RemnTypography.display(24, relativeTo: .title3))
                    .foregroundStyle(Color.remnInk)
                    .tint(.remnAccent)
                    .focused($focused)
                if !query.isEmpty {
                    InkIconButton(kind: .close, label: "search.clear", color: .remnGraphite, size: 15) {
                        query = ""
                    }
                    .padding(.trailing, -12)
                }
            }
            .frame(minHeight: 44)
            .padding(.vertical, 4)
            .overlay(alignment: .bottom) {
                InkLine(seed: 64, pen: .fine)
                    .fill(Color.remnInk.opacity(0.55))
                    .frame(height: 6)
                    .offset(y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .remnReadableWidth()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HandwrittenText("search.prompt")
                            .font(RemnTypography.body)
                            .foregroundStyle(Color.remnGraphite)
                            .padding(.top, 22)
                    } else if results.isEmpty {
                        VStack(spacing: 18) {
                            StackedCardsDoodle(width: 70)
                            HandwrittenText("search.empty")
                                .font(RemnTypography.sectionTitle)
                                .foregroundStyle(Color.remnGraphite)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 56)
                    } else {
                        HandwrittenText("count.cards \(results.count)")
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                            .padding(.top, 16)
                        ForEach(results, id: \.id) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                SearchResultRow(card: card)
                            }
                            .buttonStyle(InkRowStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .remnReadableWidth()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .paperBackground()
        .remnHidesSystemBar()
        .onAppear { focused = query.isEmpty }
    }

    private var results: [Flashcard] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return cards
            .filter { CardSearch.matches($0, query: query) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

private struct SearchResultRow: View {
    let card: Flashcard

    var body: some View {
        FlashcardSurface(seed: card.id.inkSeed, style: .compact) {
            VStack(alignment: .leading, spacing: 8) {
                HandwrittenText(verbatim: context)
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
                    .lineLimit(1)
                HandwrittenText(verbatim: RemnFormatters.usefulLine(card.frontMarkdown))
                    .font(RemnTypography.display(22, relativeTo: .body))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                    .font(RemnTypography.note)
                    .foregroundStyle(card.state != .new && card.due <= .now ? Color.remnAccent : Color.remnGraphite)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var context: String {
        let subject = card.deck?.subject?.name ?? String(localized: "subject.unknown")
        let deck = card.deck?.name ?? String(localized: "deck.unknown")
        return "\(subject) / \(deck)"
    }
}
