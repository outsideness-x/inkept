import Foundation
import SwiftData

@MainActor
enum SessionService {
    static func start(
        cards: [Flashcard],
        subjectIDs: Set<UUID>,
        deckID: UUID?,
        targetCount: Int?,
        context: ModelContext,
        now: Date = .now
    ) throws -> StudySessionRecord? {
        let selected = StudyQueueBuilder.select(
            from: cards,
            subjectIDs: subjectIDs,
            deckID: deckID,
            targetCount: targetCount,
            now: now
        )
        guard !selected.isEmpty else { return nil }

        let existing = try context.fetch(FetchDescriptor<StudySessionRecord>())
        for session in existing where session.isActive {
            session.isActive = false
        }
        let session = StudySessionRecord(
            subjectIDs: Array(subjectIDs),
            deckID: deckID,
            admittedCardIDs: selected.map(\.id),
            initialNewCount: selected.count { $0.state == .new }
        )
        context.insert(session)
        try context.save()
        return session
    }

    static func refreshQueue(
        _ session: StudySessionRecord,
        cards: [Flashcard],
        now: Date = .now
    ) {
        let admitted = Set(session.admittedCardIDs)
        let queued = Set(session.queueCardIDs)
        let dueAgain = cards
            .filter { admitted.contains($0.id) && !queued.contains($0.id) && $0.due <= now }
            .sorted { $0.due < $1.due }
            .map(\.id)
        session.queueCardIDs.append(contentsOf: dueAgain)
        if session.queueCardIDs.isEmpty {
            session.isActive = false
        }
        session.updatedAt = now
    }
}

