import Foundation

struct ScheduleCandidate: Equatable, Sendable {
    let rating: StudyRating
    let schedule: ScheduleSnapshot
    let elapsedDays: Double
    let scheduledDays: Double
}

protocol SpacedRepetitionScheduling: Sendable {
    func candidates(
        for schedule: ScheduleSnapshot,
        at date: Date,
        desiredRetention: Double
    ) throws -> [StudyRating: ScheduleCandidate]

    func reset(at date: Date) -> ScheduleSnapshot
}

