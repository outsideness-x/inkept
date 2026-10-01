import Foundation

/// Where the notes folder is. Each device remembers its own choice.
struct VaultLocation: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        /// `iCloud Drive/remn`, shared by every device signed in to the same iCloud.
        case iCloud
        /// The app's own folder on this device (`On My iPhone/remn` in Files).
        case device
        /// A folder the person picked, remembered with a security-scoped bookmark.
        case folder
    }

    var kind: Kind
    var bookmark: Data?

    static let iCloud = VaultLocation(kind: .iCloud)
    static let device = VaultLocation(kind: .device)

    static func folder(_ url: URL) throws -> VaultLocation {
        VaultLocation(kind: .folder, bookmark: try url.bookmarkData(options: bookmarkCreationOptions))
    }

    // MARK: - Remembering the choice

    private static let defaultsKey = "notesVaultLocation"

    static var saved: VaultLocation? {
        get {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
            return try? JSONDecoder().decode(VaultLocation.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: defaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            }
        }
    }

    // MARK: - Finding the folder

    enum ResolveError: LocalizedError {
        case iCloudUnavailable
        case folderUnavailable

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable: String(localized: "notes.error.icloud")
            case .folderUnavailable: String(localized: "notes.error.folder")
            }
        }
    }

    /// The folder on disk. Reaching iCloud can take a moment the first time, so call this off the main actor.
    nonisolated func resolve() throws -> URL {
        switch kind {
        case .iCloud:
            guard let container = FileManager.default.url(
                forUbiquityContainerIdentifier: LibraryStore.cloudContainerIdentifier
            ) else { throw ResolveError.iCloudUnavailable }
            let documents = container.appendingPathComponent("Documents", isDirectory: true)
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            return documents
        case .device:
            let documents = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            #if os(macOS)
            let folder = documents.appendingPathComponent("Notes", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder
            #else
            return documents
            #endif
        case .folder:
            guard let bookmark else { throw ResolveError.folderUnavailable }
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: Self.bookmarkResolutionOptions,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) else { throw ResolveError.folderUnavailable }
            return url
        }
    }

    var usesSecurityScope: Bool { kind == .folder }

    private static var bookmarkCreationOptions: URL.BookmarkCreationOptions {
        #if os(macOS)
        [.withSecurityScope]
        #else
        []
        #endif
    }

    private static var bookmarkResolutionOptions: URL.BookmarkResolutionOptions {
        #if os(macOS)
        [.withSecurityScope]
        #else
        []
        #endif
    }

    static var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
