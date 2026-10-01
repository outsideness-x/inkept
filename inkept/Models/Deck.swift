import Foundation
import SwiftData

@Model
final class Deck: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var manualSortOrder: Int = 0
    var subject: SubjectModel?

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.deck)
    var cards: [Flashcard]? = []

    init(
        id: UUID = UUID(),
        subject: SubjectModel,
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        manualSortOrder: Int = 0
    ) {
        self.id = id
        self.subject = subject
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.manualSortOrder = manualSortOrder
    }

    var allCards: [Flashcard] { cards ?? [] }

    var orderedCards: [Flashcard] {
        allCards.sorted { $0.createdAt < $1.createdAt }
    }
}
