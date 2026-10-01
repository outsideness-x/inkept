import Foundation
import SwiftData

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

    var rating: StudyRating? { StudyRating(rawValue: ratingRaw) }

    var previousSnapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            stateRaw: previousStateRaw,
            due: previousDue,
            lastReview: previousLastReview,
            stability: previousStability,
            difficulty: previousDifficulty,
            elapsedDays: previousElapsedDays,
            scheduledDays: previousScheduledDays,
            learningStep: previousLearningStep,
            repetitions: previousRepetitions,
            lapses: previousLapses
        )
    }
}
