import Foundation

struct StudyAvailability: Equatable {
    let availableNow: Int
    let scheduledLater: Int
}

@MainActor
enum StudyQueueBuilder {
    static func select(
        from cards: [Flashcard],
        subjectIDs: Set<UUID>,
        deckID: UUID? = nil,
        targetCount: Int?,
        now: Date = .now
    ) -> [Flashcard] {
        let scoped = scopedCards(from: cards, subjectIDs: subjectIDs, deckID: deckID)

        let due = scoped
            .filter { $0.state != .new && $0.due <= now }
            .sorted {
                if $0.due == $1.due { return $0.createdAt < $1.createdAt }
                return $0.due < $1.due
            }

        guard let targetCount else { return due }
        guard targetCount > 0 else { return [] }
        if due.count >= targetCount { return Array(due.prefix(targetCount)) }

        let newCards = scoped
            .filter { $0.state == .new }
            .sorted { $0.createdAt < $1.createdAt }
        return due + newCards.prefix(targetCount - due.count)
    }

    static func availability(
        from cards: [Flashcard],
        subjectIDs: Set<UUID>,
        deckID: UUID? = nil,
        now: Date = .now
    ) -> StudyAvailability {
        let scoped = scopedCards(from: cards, subjectIDs: subjectIDs, deckID: deckID)
        return StudyAvailability(
            availableNow: scoped.count { $0.state == .new || $0.due <= now },
            scheduledLater: scoped.count { $0.state != .new && $0.due > now }
        )
    }

    private static func scopedCards(
        from cards: [Flashcard],
        subjectIDs: Set<UUID>,
        deckID: UUID?
    ) -> [Flashcard] {
        cards.filter { card in
            guard let deck = card.deck, let subject = deck.subject else { return false }
            let matchesSubject = subjectIDs.isEmpty || subjectIDs.contains(subject.id)
            let matchesDeck = deckID == nil || deck.id == deckID
            return matchesSubject && matchesDeck
        }
    }
}
