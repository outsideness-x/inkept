import Foundation
import FSRS

struct FSRSSchedulerService: SpacedRepetitionScheduling {
    func candidates(
        for schedule: ScheduleSnapshot,
        at date: Date,
        desiredRetention: Double
    ) throws -> [StudyRating: ScheduleCandidate] {
        let parameters = FSRSParameters(
            requestRetention: min(max(desiredRetention, 0.70), 0.97),
            maximumInterval: 36_500,
            w: FSRSDefaults.defaultWv6,
            enableFuzz: false,
            enableShortTerm: true,
            learningSteps: FSRSDefaults.defaultLearningSteps,
            relearningSteps: FSRSDefaults.defaultRelearningSteps
        )
        let scheduler = FSRS(parameters: parameters)
        let source = makeFSRSCard(from: schedule)

        return try Dictionary(uniqueKeysWithValues: StudyRating.allCases.map { rating in
            let item = try scheduler.next(card: source, now: date, grade: rating.fsrsRating)
            return (
                rating,
                ScheduleCandidate(
                    rating: rating,
                    schedule: makeSnapshot(from: item.card),
                    elapsedDays: item.log.elapsedDays,
                    scheduledDays: item.log.scheduledDays
                )
            )
        })
    }

    func reset(at date: Date) -> ScheduleSnapshot {
        ScheduleSnapshot(
            stateRaw: ScheduleState.new.rawValue,
            due: date,
            lastReview: nil,
            stability: 0,
            difficulty: 0,
            elapsedDays: 0,
            scheduledDays: 0,
            learningStep: 0,
            repetitions: 0,
            lapses: 0
        )
    }

    private func makeFSRSCard(from value: ScheduleSnapshot) -> Card {
        Card(
            due: value.due,
            stability: value.stability,
            difficulty: value.difficulty,
            elapsedDays: value.elapsedDays,
            scheduledDays: value.scheduledDays,
            learningSteps: value.learningStep,
            reps: value.repetitions,
            lapses: value.lapses,
            state: CardState(rawValue: value.stateRaw) ?? .new,
            lastReview: value.lastReview
        )
    }

    private func makeSnapshot(from value: Card) -> ScheduleSnapshot {
        ScheduleSnapshot(
            stateRaw: value.state.rawValue,
            due: value.due,
            lastReview: value.lastReview,
            stability: value.stability,
            difficulty: value.difficulty,
            elapsedDays: value.elapsedDays,
            scheduledDays: value.scheduledDays,
            learningStep: value.learningSteps,
            repetitions: value.reps,
            lapses: value.lapses
        )
    }
}

private extension StudyRating {
    var fsrsRating: Rating {
        switch self {
        case .again: .again
        case .hard: .hard
        case .good: .good
        case .easy: .easy
        }
    }
}
