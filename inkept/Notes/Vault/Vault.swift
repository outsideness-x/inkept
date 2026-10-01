import Foundation
import Observation

/// The notes folder: plain Markdown files in folders, readable by any other app.
@MainActor
@Observable
final class Vault {
    enum Status: Equatable {
        /// No folder chosen yet on this device.
        case unconfigured
        case opening
        case ready
        case failed(String)
    }

    private(set) var status: Status = .unconfigured
    private(set) var location: VaultLocation?
    private(set) var root = VaultFolder(path: "", name: "", folders: [], notes: [])
    private(set) var rootURL: URL?
    /// Bumped whenever the files change on disk, so open notes can check whether they were edited elsewhere.
    private(set) var revision = 0

    @ObservationIgnored private var presenter: VaultPresenter?
    #if os(macOS)
    @ObservationIgnored private var watcher: FolderWatcher?
    #endif
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var accessingSecurityScope = false

    init(location: VaultLocation? = VaultLocation.saved) {
        self.location = location
        if location != nil { open() }
    }

    /// For tests, previews and the demo library: a folder that's already on disk. With `watches`,
    /// changes made to it from outside come in the way they do for a real notes folder.
    init(rootURL: URL, watches: Bool = false) {
        location = .device
        self.rootURL = rootURL
        status = .ready
        root = VaultScanner.scan(root: rootURL, reusing: [:])
        if watches { watch(rootURL) }
    }

    // MARK: - Choosing and opening

    func choose(_ location: VaultLocation) {
        close()
        self.location = location
        VaultLocation.saved = location
        open()
    }

    func open() {
        guard let location else {
            status = .unconfigured
            return
        }
        status = .opening
        Task {
            let result = await Task.detached { Result { try location.resolve() } }.value
            switch result {
            case .success(let url):
                attach(to: url, location: location)
            case .failure(let error):
                status = .failed(error.localizedDescription)
            }
        }
    }

    private func attach(to url: URL, location: VaultLocation) {
        if location.usesSecurityScope {
            accessingSecurityScope = url.startAccessingSecurityScopedResource()
        }
        rootURL = url
        root = VaultFolder(path: "", name: url.lastPathComponent, folders: [], notes: [])
        watch(url)
        status = .ready
        refresh()
    }

    /// Reads the folder again whenever something changes it: another app, or a sync from another device.
    private func watch(_ url: URL) {
        let presenter = VaultPresenter(url: url) { [weak self] in
            Task { @MainActor in self?.scheduleRefresh() }
        }
        NSFileCoordinator.addFilePresenter(presenter)
        self.presenter = presenter
        #if os(macOS)
        watcher = FolderWatcher(url: url) { [weak self] in
            Task { @MainActor in self?.scheduleRefresh() }
        }
        #endif
    }

    private func close() {
        refreshTask?.cancel()
        if let presenter { NSFileCoordinator.removeFilePresenter(presenter) }
        presenter = nil
        #if os(macOS)
        watcher = nil
        #endif
        if accessingSecurityScope, let rootURL {
            rootURL.stopAccessingSecurityScopedResource()
        }
        accessingSecurityScope = false
        rootURL = nil
        root = VaultFolder(path: "", name: "", folders: [], notes: [])
    }

    // MARK: - Reading the tree

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { await reload() }
    }

    /// Reads the folder again and waits until the tree is up to date.
    func reload() async {
        guard let rootURL else { return }
        let previous = Dictionary(root.allNotes.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
        let tree = await Task.detached(priority: .userInitiated) {
            VaultScanner.scan(root: rootURL, reusing: previous)
        }.value
        guard !Task.isCancelled else { return }
        root = tree
        revision += 1
    }

    func scheduleRefresh() {
        guard rootURL != nil else { return }
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            refresh()
        }
    }

    func url(for path: String) -> URL? {
        guard let rootURL else { return nil }
        return path.isEmpty ? rootURL : rootURL.appendingPathComponent(path)
    }

    /// Every tag in the folder, most used first.
    var tags: [(tag: String, count: Int)] {
        var counts: [String: (display: String, count: Int)] = [:]
        for note in root.allNotes {
            for tag in note.tags {
                let key = tag.lowercased()
                counts[key, default: (tag, 0)].count += 1
            }
        }
        return counts.values
            .map { (tag: $0.display, count: $0.count) }
            .sorted { $0.count == $1.count ? $0.tag.localizedStandardCompare($1.tag) == .orderedAscending : $0.count > $1.count }
    }

    // MARK: - Folders

    @discardableResult
    func createFolder(named name: String, in parent: String, icon: String? = nil) async throws -> String {
        let folderURL = try requireURL(parent)
        let clean = VaultPath.sanitized(name).nilIfEmpty ?? String(localized: "notes.folder.untitled")
        let url = VaultFiles.availableURL(named: clean, extension: nil, in: folderURL)
        try await Task.detached {
            try VaultFiles.createFolder(url)
            if let icon { try VaultFolderInfo.setIcon(icon, in: url) }
        }.value
        refresh()
        return VaultPath.join(parent, url.lastPathComponent)
    }

    /// Puts `icon` in front of a folder's name, or takes it away.
    func setIcon(_ icon: String?, forFolder path: String) async throws {
        guard !path.isEmpty else { return }
        let url = try requireURL(path)
        try await Task.detached { try VaultFolderInfo.setIcon(icon, in: url) }.value
        // Show it at once; the next read of the folder confirms it.
        root = root.settingIcon(icon, at: path)
        refresh()
    }

    @discardableResult
    func renameFolder(_ path: String, to name: String) async throws -> String {
        let source = try requireURL(path)
        let parent = VaultPath.parent(of: path)
        let clean = VaultPath.sanitized(name)
        guard !clean.isEmpty, clean != VaultPath.name(of: path) else { return path }
        let destination = VaultFiles.availableURL(named: clean, extension: nil, in: try requireURL(parent))
        try await Task.detached { try VaultFiles.move(source, to: destination) }.value
        refresh()
        return VaultPath.join(parent, destination.lastPathComponent)
    }

    func deleteFolder(_ path: String) async throws {
        guard !path.isEmpty else { return }
        let url = try requireURL(path)
        try await Task.detached { try VaultFiles.delete(url) }.value
        refresh()
    }

    // MARK: - Notes

    /// Makes an empty note and returns its path.
    func createNote(in folder: String, title: String? = nil, body: String = "") async throws -> String {
        let folderURL = try requireURL(folder)
        let clean = title.map(VaultPath.sanitized)?.nilIfEmpty ?? String(localized: "notes.note.untitled")
        let url = VaultFiles.availableURL(named: clean, extension: "md", in: folderURL)
        let document = NoteDocument(body: body)
        try await Task.detached { try VaultFiles.write(document.text, to: url) }.value
        refresh()
        return VaultPath.join(folder, url.lastPathComponent)
    }

    func load(_ path: String) async throws -> NoteDocument {
        let url = try requireURL(path)
        let text = try await Task.detached { try VaultFiles.read(url) }.value
        return NoteDocument(text: text)
    }

    func save(_ document: NoteDocument, to path: String) async throws {
        let url = try requireURL(path)
        let text = document.text
        try await Task.detached { try VaultFiles.write(text, to: url) }.value
        scheduleRefresh()
    }

    /// Renames the file behind a note; the title of a note is its file name.
    @discardableResult
    func renameNote(_ path: String, to title: String) async throws -> String {
        let clean = VaultPath.sanitized(title)
        guard !clean.isEmpty, clean != VaultPath.title(ofNoteNamed: VaultPath.name(of: path)) else { return path }
        let source = try requireURL(path)
        let folder = VaultPath.parent(of: path)
        let ext = (path as NSString).pathExtension.nilIfEmpty ?? "md"
        let destination = VaultFiles.availableURL(named: clean, extension: ext, in: try requireURL(folder))
        try await Task.detached { try VaultFiles.move(source, to: destination) }.value
        refresh()
        return VaultPath.join(folder, destination.lastPathComponent)
    }

    @discardableResult
    func moveNote(_ path: String, toFolder folder: String) async throws -> String {
        guard VaultPath.parent(of: path) != folder else { return path }
        let source = try requireURL(path)
        let name = VaultPath.name(of: path)
        let destination = VaultFiles.availableURL(
            named: VaultPath.title(ofNoteNamed: name),
            extension: (name as NSString).pathExtension.nilIfEmpty ?? "md",
            in: try requireURL(folder)
        )
        try await Task.detached { try VaultFiles.move(source, to: destination) }.value
        refresh()
        return VaultPath.join(folder, destination.lastPathComponent)
    }

    func deleteNote(_ path: String) async throws {
        let url = try requireURL(path)
        try await Task.detached { try VaultFiles.delete(url) }.value
        refresh()
    }

    // MARK: - Attachments

    /// Saves a picture into `attachments/` beside the note and returns the link to put in the note.
    func saveAttachment(_ data: Data, fileExtension: String, forNoteAt notePath: String) async throws -> String {
        let folder = VaultPath.parent(of: notePath)
        let folderURL = try requireURL(folder).appendingPathComponent(VaultPath.attachmentsFolder, isDirectory: true)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = VaultFiles.availableURL(named: "image-\(formatter.string(from: .now))", extension: fileExtension, in: folderURL)
        try await Task.detached {
            try VaultFiles.createFolder(folderURL)
            try VaultFiles.write(data, to: url)
        }.value
        let name = url.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? url.lastPathComponent
        return "\(VaultPath.attachmentsFolder)/\(name)"
    }

    /// Where a link written in a note points on disk, if it points inside the notes folder.
    func resolveLink(_ link: String, fromNoteAt notePath: String) -> URL? {
        guard let rootURL else { return nil }
        let decoded = link.removingPercentEncoding ?? link
        guard !decoded.contains("://") else { return nil }
        let base = decoded.hasPrefix("/")
            ? rootURL
            : (url(for: VaultPath.parent(of: notePath)) ?? rootURL)
        let resolved = base.appendingPathComponent(decoded.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            .standardizedFileURL
        guard resolved.path.hasPrefix(rootURL.standardizedFileURL.path) else { return nil }
        if FileManager.default.fileExists(atPath: resolved.path) || decoded.contains("/") {
            return resolved
        }
        // Obsidian-style `![[name.png]]`: look beside the note, in its attachments, then anywhere in the folder.
        let name = VaultPath.name(of: decoded)
        let candidates = [
            base.appendingPathComponent(name),
            base.appendingPathComponent(VaultPath.attachmentsFolder).appendingPathComponent(name),
            rootURL.appendingPathComponent(name),
            rootURL.appendingPathComponent(VaultPath.attachmentsFolder).appendingPathComponent(name),
        ]
        if let found = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return found
        }
        let enumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        while let url = enumerator?.nextObject() as? URL {
            if url.lastPathComponent == name { return url }
        }
        return resolved
    }

    private func requireURL(_ path: String) throws -> URL {
        guard let url = url(for: path) else { throw VaultLocation.ResolveError.folderUnavailable }
        return url
    }
}

/// Hears about changes iCloud and other apps make to the notes folder through file coordination.
private final class VaultPresenter: NSObject, NSFilePresenter, @unchecked Sendable {
    let presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue
    private let onChange: @Sendable () -> Void

    init(url: URL, onChange: @escaping @Sendable () -> Void) {
        presentedItemURL = url
        presentedItemOperationQueue = OperationQueue()
        presentedItemOperationQueue.maxConcurrentOperationCount = 1
        self.onChange = onChange
    }

    func presentedSubitemDidChange(at url: URL) { onChange() }
    func presentedSubitemDidAppear(at url: URL) { onChange() }
    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) { onChange() }
    func presentedItemDidChange() { onChange() }

    func accommodatePresentedSubitemDeletion(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        onChange()
        completionHandler(nil)
    }
}

#if os(macOS)
import CoreServices

/// File-system events for the whole tree, so edits made by apps that don't coordinate still show up.
private final class FolderWatcher: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let onChange: @Sendable () -> Void

    init(url: URL, onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue().onChange()
        }
        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            [url.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.4,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        )
        if let stream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
            FSEventStreamStart(stream)
        }
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
#endif
