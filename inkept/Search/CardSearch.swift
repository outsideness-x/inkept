import Foundation

@MainActor
enum CardSearch {
    static func matches(_ card: Flashcard, query: String) -> Bool {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return false }
        let deck = card.deck?.name ?? ""
        let subject = card.deck?.subject?.name ?? ""
        return [card.frontMarkdown, card.backMarkdown, deck, subject]
            .contains { $0.localizedStandardContains(cleanQuery) }
    }
}

