import SwiftData

/// The schema in use: version 2 with an icon for each subject.
enum RemnSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            SubjectModel.self,
            Deck.self,
            Flashcard.self,
            ReviewLogEntry.self,
            StudySessionRecord.self
        ]
    }
}

enum RemnMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RemnSchemaV1.self, RemnSchemaV2.self, RemnSchemaV3.self] }
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: RemnSchemaV1.self, toVersion: RemnSchemaV2.self),
            .lightweight(fromVersion: RemnSchemaV2.self, toVersion: RemnSchemaV3.self),
        ]
    }
}
