import Foundation
import SwiftData
@testable import inkept

@MainActor
enum TestStore {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: InkeptSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(
            for: schema,
            migrationPlan: InkeptMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeCard(
        subjectName: String = "Mathematics",
        deckName: String = "Linear Algebra",
        front: String = "What is a vector?",
        back: String = "An element of a vector space.",
        createdAt: Date = .now
    ) -> (SubjectModel, Deck, Flashcard) {
        let subject = SubjectModel(name: subjectName, createdAt: createdAt, updatedAt: createdAt)
        let deck = Deck(subject: subject, name: deckName, createdAt: createdAt, updatedAt: createdAt)
        let card = Flashcard(
            deck: deck,
            frontMarkdown: front,
            backMarkdown: back,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        return (subject, deck, card)
    }
}
