import Foundation
import SwiftData

/// The first schema, as shipped: kept exactly as it was so existing libraries can be migrated.
enum RemnSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
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
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var updatedAt: Date
        var manualSortOrder: Int

        @Relationship(deleteRule: .cascade, inverse: \Deck.subject)
        var decks: [Deck] = []

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
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var updatedAt: Date
        var manualSortOrder: Int
        var subject: SubjectModel?

        @Relationship(deleteRule: .cascade, inverse: \Flashcard.deck)
        var cards: [Flashcard] = []

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
        @Attribute(.unique) var id: UUID
        var frontMarkdown: String
        var backMarkdown: String
        var createdAt: Date
        var updatedAt: Date
        var deck: Deck?

        var stateRaw: Int
        var due: Date
        var lastReview: Date?
        var stability: Double
        var difficulty: Double
        var elapsedDays: Double
        var scheduledDays: Double
        var learningStep: Int
        var repetitions: Int
        var lapses: Int

        @Relationship(deleteRule: .cascade, inverse: \ReviewLogEntry.card)
        var reviewLogs: [ReviewLogEntry] = []

        init(
            id: UUID = UUID(),
            deck: Deck,
            frontMarkdown: String,
            backMarkdown: String,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.deck = deck
            self.frontMarkdown = frontMarkdown
            self.backMarkdown = backMarkdown
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.stateRaw = ScheduleState.new.rawValue
            self.due = createdAt
            self.stability = 0
            self.difficulty = 0
            self.elapsedDays = 0
            self.scheduledDays = 0
            self.learningStep = 0
            self.repetitions = 0
            self.lapses = 0
        }
    }

    @Model
    final class ReviewLogEntry: Identifiable {
        @Attribute(.unique) var id: UUID
        var card: Flashcard?
        var timestamp: Date
        var ratingRaw: Int
        var elapsedInterval: Double
        var scheduledInterval: Double

        var previousStateRaw: Int
        var previousDue: Date
        var previousLastReview: Date?
        var previousStability: Double
        var previousDifficulty: Double
        var previousElapsedDays: Double
        var previousScheduledDays: Double
        var previousLearningStep: Int
        var previousRepetitions: Int
        var previousLapses: Int

        var resultingStateRaw: Int
        var resultingDue: Date
        var resultingLastReview: Date?
        var resultingStability: Double
        var resultingDifficulty: Double
        var resultingElapsedDays: Double
        var resultingScheduledDays: Double
        var resultingLearningStep: Int
        var resultingRepetitions: Int
        var resultingLapses: Int

        init(
            id: UUID = UUID(),
            card: Flashcard,
            timestamp: Date,
            rating: StudyRating,
            previous: ScheduleSnapshot,
            resulting: ScheduleSnapshot,
            elapsedInterval: Double,
            scheduledInterval: Double
        ) {
            self.id = id
            self.card = card
            self.timestamp = timestamp
            self.ratingRaw = rating.rawValue
            self.elapsedInterval = elapsedInterval
            self.scheduledInterval = scheduledInterval
            self.previousStateRaw = previous.stateRaw
            self.previousDue = previous.due
            self.previousLastReview = previous.lastReview
            self.previousStability = previous.stability
            self.previousDifficulty = previous.difficulty
            self.previousElapsedDays = previous.elapsedDays
            self.previousScheduledDays = previous.scheduledDays
            self.previousLearningStep = previous.learningStep
            self.previousRepetitions = previous.repetitions
            self.previousLapses = previous.lapses
            self.resultingStateRaw = resulting.stateRaw
            self.resultingDue = resulting.due
            self.resultingLastReview = resulting.lastReview
            self.resultingStability = resulting.stability
            self.resultingDifficulty = resulting.difficulty
            self.resultingElapsedDays = resulting.elapsedDays
            self.resultingScheduledDays = resulting.scheduledDays
            self.resultingLearningStep = resulting.learningStep
            self.resultingRepetitions = resulting.repetitions
            self.resultingLapses = resulting.lapses
        }
    }

    @Model
    final class StudySessionRecord: Identifiable {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var updatedAt: Date
        var isActive: Bool
        var subjectIDs: [UUID]
        var deckID: UUID?
        var admittedCardIDs: [UUID]
        var queueCardIDs: [UUID]
        var lastReviewLogID: UUID?
        var reviewedCount: Int
        var initialNewCount: Int

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            subjectIDs: [UUID],
            deckID: UUID?,
            admittedCardIDs: [UUID],
            initialNewCount: Int
        ) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = createdAt
            self.isActive = true
            self.subjectIDs = subjectIDs
            self.deckID = deckID
            self.admittedCardIDs = admittedCardIDs
            self.queueCardIDs = admittedCardIDs
            self.reviewedCount = 0
            self.initialNewCount = initialNewCount
        }
    }
}
