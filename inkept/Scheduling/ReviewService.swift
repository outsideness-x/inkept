import Foundation
import SwiftData

@MainActor
struct ReviewService {
    let scheduler: any SpacedRepetitionScheduling

    init(scheduler: any SpacedRepetitionScheduling = FSRSSchedulerService()) {
        self.scheduler = scheduler
    }

    func candidates(
        for card: Flashcard,
        at date: Date,
        desiredRetention: Double
    ) throws -> [StudyRating: ScheduleCandidate] {
        try scheduler.candidates(
            for: card.scheduleSnapshot,
            at: date,
            desiredRetention: desiredRetention
        )
    }

    @discardableResult
    func apply(
        _ rating: StudyRating,
        candidate: ScheduleCandidate,
        to card: Flashcard,
        in session: StudySessionRecord,
        context: ModelContext,
        at date: Date
    ) throws -> ReviewLogEntry {
        let previous = card.scheduleSnapshot
        card.scheduleSnapshot = candidate.schedule
        let log = ReviewLogEntry(
            card: card,
            timestamp: date,
            rating: rating,
            previous: previous,
            resulting: candidate.schedule,
            elapsedInterval: candidate.elapsedDays,
            scheduledInterval: candidate.scheduledDays
        )
        context.insert(log)
        session.queueCardIDs.removeAll { $0 == card.id }
        session.lastReviewLogID = log.id
        session.reviewedCount += 1
        session.updatedAt = date
        try context.save()
        return log
    }

    func undoLastReview(in session: StudySessionRecord, context: ModelContext) throws {
        guard let logID = session.lastReviewLogID else { return }
        let descriptor = FetchDescriptor<ReviewLogEntry>(
            predicate: #Predicate { $0.id == logID }
        )
        guard let log = try context.fetch(descriptor).first, let card = log.card else { return }

        card.scheduleSnapshot = log.previousSnapshot
        if !session.queueCardIDs.contains(card.id) {
            session.queueCardIDs.insert(card.id, at: 0)
        }
        session.reviewedCount = max(0, session.reviewedCount - 1)
        session.lastReviewLogID = nil
        session.isActive = true
        session.updatedAt = .now
        context.delete(log)
        try context.save()
    }

    func reset(_ card: Flashcard, context: ModelContext, at date: Date = .now) throws {
        card.scheduleSnapshot = scheduler.reset(at: date)
        try context.save()
    }
}

