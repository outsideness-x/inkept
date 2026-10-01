import SwiftData

/// The schema in use: version 2 with an icon for each subject.
enum InkeptSchemaV3: VersionedSchema {
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

enum InkeptMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [InkeptSchemaV1.self, InkeptSchemaV2.self, InkeptSchemaV3.self] }
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: InkeptSchemaV1.self, toVersion: InkeptSchemaV2.self),
            .lightweight(fromVersion: InkeptSchemaV2.self, toVersion: InkeptSchemaV3.self),
        ]
    }
}
