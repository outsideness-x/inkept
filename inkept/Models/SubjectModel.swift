import Foundation
import SwiftData

@Model
final class SubjectModel: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var manualSortOrder: Int = 0
    /// The id of the `SubjectIcon` drawn before the subject's name.
    var icon: String?

    @Relationship(deleteRule: .cascade, inverse: \Deck.subject)
    var decks: [Deck]? = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        manualSortOrder: Int = 0,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.manualSortOrder = manualSortOrder
        self.icon = icon
    }

    var allDecks: [Deck] { decks ?? [] }

    var orderedDecks: [Deck] {
        allDecks.sorted {
            if $0.manualSortOrder == $1.manualSortOrder { return $0.createdAt < $1.createdAt }
            return $0.manualSortOrder < $1.manualSortOrder
        }
    }

    var cards: [Flashcard] { allDecks.flatMap(\.allCards) }
}
