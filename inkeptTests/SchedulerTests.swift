import SwiftData
import XCTest
@testable import inkept

final class SchedulerTests: XCTestCase {
    private let scheduler = FSRSSchedulerService()
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testNewCardProducesFourDistinctCandidates() throws {
        let candidates = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )

        XCTAssertEqual(candidates.count, 4)
        XCTAssertNotEqual(candidates[.again]?.schedule.due, candidates[.hard]?.schedule.due)
        XCTAssertNotEqual(candidates[.good]?.schedule.due, candidates[.easy]?.schedule.due)
        XCTAssertEqual(candidates[.again]?.schedule.state, .learning)
        XCTAssertEqual(candidates[.hard]?.schedule.lapses, 0)
        for rating in StudyRating.allCases {
            XCTAssertGreaterThan(candidates[rating]!.schedule.due, now)
        }
    }

    func testRepeatedSameDayLearningReviewAdvancesRealStep() throws {
        let first = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )[.again]!
        XCTAssertEqual(first.schedule.state, .learning)
        XCTAssertLessThan(first.schedule.due.timeIntervalSince(now), 86_400)

        let secondTime = first.schedule.due
        let second = try scheduler.candidates(
            for: first.schedule,
            at: secondTime,
            desiredRetention: 0.90
        )[.good]!
        XCTAssertGreaterThan(second.schedule.due, secondTime)
        XCTAssertGreaterThan(second.schedule.repetitions, first.schedule.repetitions)
    }

    func testHardOnReviewIsRecallAndAgainIsLapse() throws {
        let first = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )[.easy]!
        XCTAssertEqual(first.schedule.state, .review)
        let later = first.schedule.due.addingTimeInterval(86_400 * 3)
        let next = try scheduler.candidates(
            for: first.schedule,
            at: later,
            desiredRetention: 0.90
        )

        XCTAssertEqual(next[.hard]?.schedule.lapses, first.schedule.lapses)
        XCTAssertEqual(next[.again]?.schedule.lapses, first.schedule.lapses + 1)
        XCTAssertEqual(next[.hard]?.schedule.state, .review)
        XCTAssertEqual(next[.again]?.schedule.state, .relearning)
    }

    func testDesiredRetentionChangesSubsequentInterval() throws {
        let review = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )[.easy]!.schedule
        let reviewDate = review.due.addingTimeInterval(86_400)
        let low = try scheduler.candidates(for: review, at: reviewDate, desiredRetention: 0.70)[.good]!
        let high = try scheduler.candidates(for: review, at: reviewDate, desiredRetention: 0.97)[.good]!

        XCTAssertGreaterThan(low.schedule.due, high.schedule.due)
    }

    func testOverdueReviewSchedulesFromActualReviewTime() throws {
        let review = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )[.easy]!.schedule
        let overdueDate = review.due.addingTimeInterval(86_400 * 20)
        let candidate = try scheduler.candidates(
            for: review,
            at: overdueDate,
            desiredRetention: 0.90
        )[.good]!
        XCTAssertGreaterThan(candidate.schedule.due, overdueDate)
        XCTAssertGreaterThan(candidate.elapsedDays, review.scheduledDays)
    }

    @MainActor
    func testApplyLogUndoAndReset() throws {
        let container = try TestStore.makeContainer()
        let context = ModelContext(container)
        let (subject, deck, card) = TestStore.makeCard(createdAt: now)
        context.insert(subject)
        context.insert(deck)
        context.insert(card)
        let session = StudySessionRecord(
            subjectIDs: [subject.id],
            deckID: deck.id,
            admittedCardIDs: [card.id],
            initialNewCount: 1
        )
        context.insert(session)
        try context.save()

        let old = card.scheduleSnapshot
        let service = ReviewService(scheduler: scheduler)
        let candidate = try service.candidates(for: card, at: now, desiredRetention: 0.90)[.good]!
        let log = try service.apply(
            .good,
            candidate: candidate,
            to: card,
            in: session,
            context: context,
            at: now
        )

        XCTAssertEqual(log.rating, .good)
        XCTAssertEqual(session.reviewedCount, 1)
        XCTAssertNotEqual(card.scheduleSnapshot, old)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ReviewLogEntry>()), 1)

        try service.undoLastReview(in: session, context: context)
        XCTAssertEqual(card.scheduleSnapshot, old)
        XCTAssertEqual(session.queueCardIDs, [card.id])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ReviewLogEntry>()), 0)

        card.scheduleSnapshot = candidate.schedule
        try service.reset(card, context: context, at: now)
        XCTAssertEqual(card.state, .new)
        XCTAssertEqual(card.repetitions, 0)
        XCTAssertNil(card.lastReview)
    }
}
