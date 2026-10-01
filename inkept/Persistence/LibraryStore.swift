import Foundation
import SwiftData

/// Where the cards live: one SwiftData store on the device, mirrored to the person's private iCloud database.
enum LibraryStore {
    static let cloudContainerIdentifier = "iCloud.com.chemical-pink.inkept"

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: RemnSchemaV3.self)
        do {
            return try makeContainer(schema: schema, cloud: .private(cloudContainerIdentifier))
        } catch {
            // Without iCloud the library still works; it just stays on this device.
            return try makeContainer(schema: schema, cloud: .none)
        }
    }

    private static func makeContainer(
        schema: Schema,
        cloud: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration("inkept", schema: schema, cloudKitDatabase: cloud)
        return try ModelContainer(
            for: schema,
            migrationPlan: RemnMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
