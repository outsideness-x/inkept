import Foundation
import SwiftData

/// Where the cards live on this device: one SwiftData store, kept in step with the `.inkept`
/// folder inside the notes folder by `LibraryFolder`. The folder is what syncs, not the store.
enum LibraryStore {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: InkeptSchemaV3.self)
        let configuration = ModelConfiguration("inkept", schema: schema, cloudKitDatabase: .none)
        return try ModelContainer(
            for: schema,
            migrationPlan: InkeptMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
