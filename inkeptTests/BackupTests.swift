import SwiftData
import XCTest
@testable import inkept

@MainActor
final class BackupTests: XCTestCase {
    func testBackupRoundTripPreservesTechnicalContentAndSchedule() throws {
        let sourceContainer = try TestStore.makeContainer()
        let source = ModelContext(sourceContainer)
        let front = #"Gradient: $\nabla_\theta \mathcal{L}$"#
        let back = """
        ```swift
        let path = "C:\\\\tmp"
        print("quoted")
        ```
        """
        let (subject, deck, card) = TestStore.makeCard(front: front, back: back)
        subject.icon = "atom"
        source.insert(subject)
        source.insert(deck)
        source.insert(card)
        let scheduler = FSRSSchedulerService()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        card.scheduleSnapshot = try scheduler.candidates(
            for: scheduler.reset(at: now),
            at: now,
            desiredRetention: 0.90
        )[.easy]!.schedule
        source.insert(
            ReviewLogEntry(
                card: card,
                timestamp: now,
                rating: .easy,
                previous: scheduler.reset(at: now),
                resulting: card.scheduleSnapshot,
                elapsedInterval: 0,
                scheduledInterval: card.scheduledDays
            )
        )
        try source.save()

        let data = try BackupService.export(
            context: source,
            settings: BackupSettings(desiredRetention: 0.91, appearanceMode: "dark")
        )
        let archive = try BackupService.decode(data)
        let destinationContainer = try TestStore.makeContainer()
        let destination = ModelContext(destinationContainer)
        let settings = try BackupService.importArchive(archive, context: destination)

        let restored = try XCTUnwrap(destination.fetch(FetchDescriptor<Flashcard>()).first)
        XCTAssertEqual(restored.frontMarkdown, front)
        XCTAssertEqual(restored.backMarkdown, back)
        XCTAssertEqual(restored.scheduleSnapshot, card.scheduleSnapshot)
        XCTAssertEqual(restored.deck?.subject?.icon, "atom")
        XCTAssertEqual(try destination.fetchCount(FetchDescriptor<ReviewLogEntry>()), 1)
        XCTAssertEqual(settings.desiredRetention, 0.91)
        XCTAssertEqual(settings.appearanceMode, "dark")

        // A backup from before subjects had icons still reads.
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["subjects"] = (json["subjects"] as? [[String: Any]])?.map { $0.filter { $0.key != "icon" } }
        let older = try BackupService.decode(JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(older.subjects.count, 1)
        XCTAssertNil(older.subjects.first?.icon)
    }

    func testInvalidRelationshipsDoNotMutateStore() throws {
        let container = try TestStore.makeContainer()
        let context = ModelContext(container)
        let archive = BackupArchive(
            schema: BackupArchive.currentSchema,
            exportedAt: .now,
            settings: BackupSettings(desiredRetention: 0.90, appearanceMode: "system"),
            subjects: [],
            decks: [
                BackupDeck(
                    id: UUID(),
                    subjectID: UUID(),
                    name: "orphan",
                    createdAt: .now,
                    updatedAt: .now,
                    manualSortOrder: 0
                )
            ],
            cards: [],
            reviewLogs: []
        )
        XCTAssertThrowsError(try BackupService.importArchive(archive, context: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Deck>()), 0)
    }
}

