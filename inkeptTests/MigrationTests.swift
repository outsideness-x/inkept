import SwiftData
import XCTest
@testable import inkept

@MainActor
final class MigrationTests: XCTestCase {
    func testFirstSchemaLibraryOpensInTheCurrentSchema() throws {
        let url = try storeURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let cardID = UUID()

        do {
            let schema = Schema(versionedSchema: InkeptSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let subject = InkeptSchemaV1.SubjectModel(name: "Mathematics")
            let deck = InkeptSchemaV1.Deck(subject: subject, name: "Linear Algebra")
            let card = InkeptSchemaV1.Flashcard(id: cardID, deck: deck, frontMarkdown: "front", backMarkdown: "back")
            card.stateRaw = ScheduleState.review.rawValue
            card.stability = 12.5
            context.insert(subject)
            context.insert(deck)
            context.insert(card)
            try context.save()
        }

        let context = ModelContext(try currentContainer(at: url))
        let card = try XCTUnwrap(context.fetch(FetchDescriptor<Flashcard>()).first)
        XCTAssertEqual(card.id, cardID)
        XCTAssertEqual(card.frontMarkdown, "front")
        XCTAssertEqual(card.state, .review)
        XCTAssertEqual(card.stability, 12.5)
        XCTAssertEqual(card.deck?.subject?.name, "Mathematics")
        XCTAssertNil(card.deck?.subject?.icon)
        XCTAssertNil(card.sourceNotePath)
        XCTAssertEqual(card.deck?.subject?.allDecks.count, 1)
    }

    func testCloudReadyLibraryGainsSubjectIcons() throws {
        let url = try storeURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let subjectID = UUID()

        do {
            let schema = Schema(versionedSchema: InkeptSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let subject = InkeptSchemaV2.SubjectModel(id: subjectID, name: "Physics", manualSortOrder: 3)
            let deck = InkeptSchemaV2.Deck(subject: subject, name: "Optics")
            let card = InkeptSchemaV2.Flashcard(deck: deck, frontMarkdown: "front", backMarkdown: "back", sourceNotePath: "Physics/Lenses.md")
            context.insert(subject)
            context.insert(deck)
            context.insert(card)
            try context.save()
        }

        do {
            let context = ModelContext(try currentContainer(at: url))
            let subject = try XCTUnwrap(context.fetch(FetchDescriptor<SubjectModel>()).first)
            XCTAssertEqual(subject.id, subjectID)
            XCTAssertEqual(subject.name, "Physics")
            XCTAssertEqual(subject.manualSortOrder, 3)
            XCTAssertNil(subject.icon)
            XCTAssertEqual(subject.cards.first?.sourceNotePath, "Physics/Lenses.md")
            subject.icon = "atom"
            try context.save()
        }

        let context = ModelContext(try currentContainer(at: url))
        XCTAssertEqual(try context.fetch(FetchDescriptor<SubjectModel>()).first?.icon, "atom")
    }

    private func storeURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("inkept-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("inkept.store")
    }

    private func currentContainer(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: InkeptSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: InkeptMigrationPlan.self, configurations: [configuration])
    }
}
