import Foundation
import SwiftData

/// The first schema ready for iCloud, as shipped: no unique constraints, a default for every value,
/// optional relationships, and a link from a card back to the note it came from. Kept exactly as it
/// was so libraries made with it can be migrated.
enum RemnSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            SubjectModel.self,
            Deck.self,
            Flashcard.self,
            ReviewLogEntry.self,
            StudySessionRecord.self
        ]
    }

    @Model
    final class SubjectModel: Identifiable {
        var id: UUID = UUID()
        var name: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var manualSortOrder: Int = 0

        @Relationship(deleteRule: .cascade, inverse: \Deck.subject)
        var decks: [Deck]? = []

        init(
            id: UUID = UUID(),
            name: String,
            createdAt: Date = .now,
            updatedAt: Date = .now,
            manualSortOrder: Int = 0
        ) {
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.manualSortOrder = manualSortOrder
        }
    }

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
    }

    @Model
    final class Flashcard: Identifiable {
        var id: UUID = UUID()
        var frontMarkdown: String = ""
        var backMarkdown: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var deck: Deck?
        var sourceNotePath: String?

        var stateRaw: Int = 0
        var due: Date = Date.now
        var lastReview: Date?
        var stability: Double = 0
        var difficulty: Double = 0
        var elapsedDays: Double = 0
        var scheduledDays: Double = 0
        var learningStep: Int = 0
        var repetitions: Int = 0
        var lapses: Int = 0

        @Relationship(deleteRule: .cascade, inverse: \ReviewLogEntry.card)
        var reviewLogs: [ReviewLogEntry]? = []

        init(
            id: UUID = UUID(),
            deck: Deck,
            frontMarkdown: String,
            backMarkdown: String,
            createdAt: Date = .now,
            updatedAt: Date = .now,
            sourceNotePath: String? = nil
        ) {
            self.id = id
            self.deck = deck
            self.frontMarkdown = frontMarkdown
            self.backMarkdown = backMarkdown
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.sourceNotePath = sourceNotePath
            self.stateRaw = ScheduleState.new.rawValue
            self.due = createdAt
        }
    }

    @Model
    final class ReviewLogEntry: Identifiable {
        var id: UUID = UUID()
        var card: Flashcard?
        var timestamp: Date = Date.now
        var ratingRaw: Int = 0
        var elapsedInterval: Double = 0
        var scheduledInterval: Double = 0

        var previousStateRaw: Int = 0
        var previousDue: Date = Date.now
        var previousLastReview: Date?
        var previousStability: Double = 0
        var previousDifficulty: Double = 0
        var previousElapsedDays: Double = 0
        var previousScheduledDays: Double = 0
        var previousLearningStep: Int = 0
        var previousRepetitions: Int = 0
        var previousLapses: Int = 0

        var resultingStateRaw: Int = 0
        var resultingDue: Date = Date.now
        var resultingLastReview: Date?
        var resultingStability: Double = 0
        var resultingDifficulty: Double = 0
        var resultingElapsedDays: Double = 0
        var resultingScheduledDays: Double = 0
        var resultingLearningStep: Int = 0
        var resultingRepetitions: Int = 0
        var resultingLapses: Int = 0

        init(id: UUID = UUID(), card: Flashcard, timestamp: Date) {
            self.id = id
            self.card = card
            self.timestamp = timestamp
        }
    }

    @Model
    final class StudySessionRecord: Identifiable {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isActive: Bool = true
        var subjectIDs: [UUID] = []
        var deckID: UUID?
        var admittedCardIDs: [UUID] = []
        var queueCardIDs: [UUID] = []
        var lastReviewLogID: UUID?
        var reviewedCount: Int = 0
        var initialNewCount: Int = 0

        init(id: UUID = UUID(), createdAt: Date = .now) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }
}
