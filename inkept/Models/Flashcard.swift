import Foundation
import SwiftData

@Model
final class Flashcard: Identifiable {
    var id: UUID = UUID()
    var frontMarkdown: String = ""
    var backMarkdown: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var deck: Deck?
    /// The note this card was made from, as a path inside the notes folder.
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
        self.stability = 0
        self.difficulty = 0
        self.elapsedDays = 0
        self.scheduledDays = 0
        self.learningStep = 0
        self.repetitions = 0
        self.lapses = 0
    }

    var allReviewLogs: [ReviewLogEntry] { reviewLogs ?? [] }

    var state: ScheduleState {
        get { ScheduleState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    var scheduleSnapshot: ScheduleSnapshot {
        get {
            ScheduleSnapshot(
                stateRaw: stateRaw,
                due: due,
                lastReview: lastReview,
                stability: stability,
                difficulty: difficulty,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                learningStep: learningStep,
                repetitions: repetitions,
                lapses: lapses
            )
        }
        set {
            stateRaw = newValue.stateRaw
            due = newValue.due
            lastReview = newValue.lastReview
            stability = newValue.stability
            difficulty = newValue.difficulty
            elapsedDays = newValue.elapsedDays
            scheduledDays = newValue.scheduledDays
            learningStep = newValue.learningStep
            repetitions = newValue.repetitions
            lapses = newValue.lapses
        }
    }
}
