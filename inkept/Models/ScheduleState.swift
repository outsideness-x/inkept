import Foundation

enum ScheduleState: Int, Codable, CaseIterable, Sendable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3
}

enum StudyRating: Int, Codable, CaseIterable, Identifiable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .again: "rating.again"
        case .hard: "rating.hard"
        case .good: "rating.good"
        case .easy: "rating.easy"
        }
    }
}

struct ScheduleSnapshot: Codable, Equatable, Sendable {
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

    var state: ScheduleState {
        ScheduleState(rawValue: stateRaw) ?? .new
    }
}

