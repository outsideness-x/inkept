import Foundation
import Observation
import SwiftData

/// Keeps the card library in step with the `.inkept` folder inside the notes folder (see `LibraryFiles`),
/// so the folder alone is enough to carry on from: pick it on another device and everything comes along.
///
/// The store on the device is a quick copy of what's in the folder. Every save is written out as it
/// happens, and what other devices write is read in when the folder changes and when the app comes back.
/// The first time the store meets a folder the two are merged, so nothing made before is lost; moving to
/// a different folder swaps the library for that folder's own, the way the notes are swapped.
@MainActor
@Observable
final class LibraryFolder {
    enum Status: Equatable {
        case detached
        case opening
        case ready
        case failed(String)
    }

    private(set) var status: Status = .detached

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let device: String
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let indexURL: URL?
    @ObservationIgnored private var index: Index
    /// The `.inkept` folder, while attached.
    @ObservationIgnored private var root: URL?
    @ObservationIgnored private var presenter: FolderPresenter?
    @ObservationIgnored private let writer = LibraryWriter()
    /// True while changes read from the folder are saved, so they aren't written straight back.
    @ObservationIgnored private var isApplying = false
    @ObservationIgnored private var isReading = false
    @ObservationIgnored private var readsAgain = false
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var indexTask: Task<Void, Never>?
    /// Writes on their way, until what came of each is noted.
    @ObservationIgnored private var inFlight: [UUID: Task<Void, Never>] = [:]

    static let retentionKey = "desiredRetention"
    static let defaultRetention = 0.90

    init(
        context: ModelContext,
        device: String = LibraryFolder.thisDevice,
        defaults: UserDefaults = .standard,
        indexURL: URL? = LibraryFolder.defaultIndexURL
    ) {
        self.context = context
        self.device = device
        self.defaults = defaults
        self.indexURL = indexURL
        index = indexURL.flatMap { try? JSONDecoder().decode(Index.self, from: Data(contentsOf: $0)) } ?? Index()

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: ModelContext.didSave, object: context, queue: nil) { [weak self] note in
            guard Thread.isMainThread else { return }
            let changes = Changes(note)
            MainActor.assumeIsolated { self?.saved(changes) }
        })
        observers.append(center.addObserver(forName: .reviewUndone, object: nil, queue: nil) { [weak self] note in
            guard Thread.isMainThread, let id = note.userInfo?["id"] as? UUID else { return }
            MainActor.assumeIsolated { self?.undone(id) }
        })
        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: defaults, queue: nil) { [weak self] _ in
            guard Thread.isMainThread else { return }
            MainActor.assumeIsolated { self?.writeManifest() }
        })
    }

    /// This device's name in the folder, made up once, so its review log is its own.
    nonisolated static var thisDevice: String {
        let key = "libraryDevice"
        if let device = UserDefaults.standard.string(forKey: key) { return device }
        let device = UUID().uuidString
        UserDefaults.standard.set(device, forKey: key)
        return device
    }

    nonisolated static var defaultIndexURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("LibraryIndex.json")
    }

    // MARK: - Attaching

    private enum Mode {
        /// The folder the store already follows: read only what changed.
        case follow
        /// The store's first folder: keep everything from both, the newer copy of anything in both.
        case merge
        /// A different folder from the one the store followed: take that folder's library instead.
        case replace
    }

    /// Keeps the library in `notesFolder/.inkept`. `identity` names the folder steadily across launches,
    /// where its path may not stay the same.
    func attach(to notesFolder: URL, identity: String) async {
        let root = notesFolder.appendingPathComponent(LibraryFiles.folderName, isDirectory: true)
        if self.root == root, status == .ready {
            await refresh()
            return
        }
        detach()
        status = .opening
        do {
            try await Task.detached { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }.value
        } catch {
            status = .failed(error.localizedDescription)
            return
        }

        let mode: Mode = index.folder == identity ? .follow : (index.folder == nil ? .merge : .replace)
        if mode == .replace { clearLibrary() }
        if mode != .follow { index = Index(folder: identity) }
        self.root = root
        let presenter = FolderPresenter(url: root) { [weak self] in
            Task { @MainActor in self?.scheduleRefresh() }
        }
        NSFileCoordinator.addFilePresenter(presenter)
        self.presenter = presenter

        let seen = await read(readingOwnLog: mode != .follow, merging: mode == .merge)
        guard self.root == root else { return }
        if case .failed = status { return }
        writeAll()
        if mode == .merge, let seen {
            sendReviews(notIn: seen)
        } else {
            sendUnsentReviews()
        }
        writeManifest()
        saveIndexSoon()
        status = .ready
    }

    func detach() {
        refreshTask?.cancel()
        if let presenter { NSFileCoordinator.removeFilePresenter(presenter) }
        presenter = nil
        root = nil
        status = .detached
        saveIndex()
    }

    /// Reads in whatever other devices wrote since the last look.
    func refresh() async {
        guard root != nil, status == .ready else { return }
        guard !isReading else {
            readsAgain = true
            return
        }
        _ = await read(readingOwnLog: false, merging: false)
        if readsAgain {
            readsAgain = false
            scheduleRefresh()
        }
    }

    /// Waits for everything written so far to reach the folder, and for what came of it to be noted.
    func flush() async {
        await settle()
        saveIndex()
    }

    private func settle() async {
        await writer.flush()
        while let task = inFlight.values.first {
            await task.value
        }
    }

    /// Starts a write now, so writes keep their order, and notes how it went on the main actor.
    private func track<Result: Sendable>(
        _ start: (@escaping @Sendable (Result) -> Void) -> Void,
        then finish: @escaping @MainActor (Result) -> Void
    ) {
        let (results, continuation) = AsyncStream<Result>.makeStream()
        start { result in
            continuation.yield(result)
            continuation.finish()
        }
        let id = UUID()
        inFlight[id] = Task { @MainActor [weak self] in
            for await result in results { finish(result) }
            self?.inFlight[id] = nil
        }
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    // MARK: - Reading the folder in

    /// Reads the folder and applies what changed. Returns the ids of the reviews it read.
    private func read(readingOwnLog: Bool, merging: Bool) async -> Set<UUID>? {
        guard let root else { return nil }
        isReading = true
        defer { isReading = false }
        // Whatever is still on its way out must be on disk first, or it would read as an older change.
        await settle()
        let known = index.files.compactMapValues(\.stamp)
        let fingerprints = index.files.mapValues(\.fingerprint)
        let offsets = index.logs
        let skipping = readingOwnLog ? "" : device
        let scan = await Task.detached(priority: .utility) {
            LibraryFiles.scan(root: root, known: known, fingerprints: fingerprints, offsets: offsets, skippingDevice: skipping)
        }.value
        guard self.root == root else { return nil }
        return apply(scan, merging: merging, fingerprints: fingerprints)
    }

    private func apply(_ scan: LibraryFiles.Scan, merging: Bool, fingerprints before: [String: UInt64]) -> Set<UUID> {
        if let manifest = scan.manifest?.record, manifest.format != LibraryFiles.format {
            status = .failed(String(localized: "library.error.newer"))
            return []
        }
        isApplying = true
        defer { isApplying = false }

        // Only what nothing was written over since the read began, and nothing still waiting to go out.
        func isCurrent(_ path: String) -> Bool {
            index.files[path]?.fingerprint == before[path] && index.files[path]?.pending != true
                && !index.removed.contains(path)
        }
        func remember<Record>(_ change: LibraryFiles.Changed<Record>) {
            index.files[change.path] = Index.File(stamp: change.stamp, fingerprint: change.fingerprint)
        }
        for (path, stamp) in scan.restamped where isCurrent(path) {
            index.files[path]?.stamp = stamp
        }

        var subjects = models(SubjectModel.self)
        for change in scan.subjects where isCurrent(change.path) {
            let record = change.record
            remember(change)
            if let subject = subjects[record.id] {
                if merging, subject.updatedAt > record.updatedAt { continue }
                subject.update(from: record)
            } else {
                let subject = SubjectModel(record)
                context.insert(subject)
                subjects[record.id] = subject
            }
        }

        var decks = models(Deck.self)
        for change in scan.decks where isCurrent(change.path) {
            let record = change.record
            // A deck whose subject hasn't arrived yet waits for the next read.
            guard let subject = subjects[record.subjectID] else { continue }
            remember(change)
            if let deck = decks[record.id] {
                if merging, deck.updatedAt > record.updatedAt { continue }
                deck.update(from: record, subject: subject)
            } else {
                let deck = Deck(record, subject: subject)
                context.insert(deck)
                decks[record.id] = deck
            }
        }

        var cards = models(Flashcard.self)
        for change in scan.cards where isCurrent(change.path) {
            let record = change.record
            guard let deck = decks[record.deckID] else { continue }
            remember(change)
            if let card = cards[record.id] {
                if merging, Self.freshness(of: card) > Self.freshness(of: record) { continue }
                card.update(from: record, deck: deck)
            } else {
                let card = Flashcard(record, deck: deck)
                context.insert(card)
                cards[record.id] = card
            }
        }

        // What another device deleted: files this store knew that are gone, not just still in iCloud.
        if !merging {
            for path in index.files.keys where !scan.present.contains(path) && before[path] != nil && isCurrent(path) {
                guard let (kind, id) = LibraryFiles.record(at: path) else { continue }
                switch kind {
                case .subjects: if let subject = subjects.removeValue(forKey: id) { context.delete(subject) }
                case .decks: if let deck = decks.removeValue(forKey: id) { context.delete(deck) }
                case .cards: if let card = cards.removeValue(forKey: id) { context.delete(card) }
                }
                index.files[path] = nil
            }
        }
        index.removed.formIntersection(scan.present)

        var seen = Set<UUID>()
        var reviews: [BackupReviewLog] = []
        var undone = Set<UUID>()
        for chunk in scan.logs {
            for event in chunk.events {
                if let review = event.review {
                    seen.insert(review.id)
                    reviews.append(review)
                }
                if let undo = event.undo { undone.insert(undo) }
            }
            index.logs[chunk.path] = chunk.offset
        }
        if !reviews.isEmpty || !undone.isEmpty {
            var existing = Set(reviewLogs(withIDs: reviews.map(\.id)).map(\.id))
            for review in reviews where !existing.contains(review.id) && !undone.contains(review.id) {
                guard let card = cards[review.cardID], let log = ReviewLogEntry(review, card: card) else { continue }
                context.insert(log)
                existing.insert(review.id)
            }
            for log in reviewLogs(withIDs: Array(undone)) {
                context.delete(log)
            }
        }

        if let manifest = scan.manifest, isCurrent(manifest.path) {
            remember(manifest)
            if let retention = manifest.record.desiredRetention, retention != self.retention {
                defaults.set(retention, forKey: Self.retentionKey)
            }
        }

        try? context.save()
        saveIndexSoon()
        return seen.subtracting(undone)
    }

    /// When a copy was last touched: its text, or its schedule.
    private static func freshness(of card: Flashcard) -> Date {
        max(card.updatedAt, card.lastReview ?? .distantPast)
    }

    private static func freshness(of record: BackupCard) -> Date {
        max(record.updatedAt, record.schedule.lastReview ?? .distantPast)
    }

    /// Empties the store before another folder's library is read in; that folder is now where it lives.
    private func clearLibrary() {
        isApplying = true
        defer { isApplying = false }
        for subject in models(SubjectModel.self).values { context.delete(subject) }
        for deck in models(Deck.self).values where !deck.isDeleted { context.delete(deck) }
        for card in models(Flashcard.self).values where !card.isDeleted { context.delete(card) }
        for session in (try? context.fetch(FetchDescriptor<StudySessionRecord>())) ?? [] { context.delete(session) }
        try? context.save()
    }

    // MARK: - Writing the store out

    private struct Changes: Sendable {
        var inserted: [PersistentIdentifier]
        var updated: [PersistentIdentifier]
        var hasDeletions: Bool

        init(_ note: Notification) {
            let info = note.userInfo ?? [:]
            func ids(_ key: ModelContext.NotificationKey) -> [PersistentIdentifier] {
                info[key.rawValue] as? [PersistentIdentifier] ?? []
            }
            inserted = ids(.insertedIdentifiers)
            updated = ids(.updatedIdentifiers)
            hasDeletions = !ids(.deletedIdentifiers).isEmpty
        }
    }

    private func saved(_ changes: Changes) {
        guard !isApplying else { return }
        let reviews = changes.inserted
            .compactMap { context.model(for: $0) as? ReviewLogEntry }
            .filter { !$0.isDeleted }
            .compactMap(BackupReviewLog.init)
        // Until a folder is open its reviews wait; everything else is written in full once it is.
        guard root != nil, status == .ready else {
            index.unsentReviews.formUnion(reviews.map(\.id))
            saveIndexSoon()
            return
        }
        for id in changes.inserted + changes.updated {
            write(context.model(for: id))
        }
        send(reviews.map { LibraryFiles.ReviewEvent(review: $0) })
        if changes.hasDeletions { removeFilesOfDeleted() }
    }

    private func undone(_ id: UUID) {
        guard root != nil, status == .ready else {
            index.unsentReviews.remove(id)
            return
        }
        send([LibraryFiles.ReviewEvent(undo: id)])
    }

    private func write(_ model: any PersistentModel) {
        guard !model.isDeleted else { return }
        switch model {
        case let subject as SubjectModel:
            write(BackupSubject(subject), to: LibraryFiles.path(.subjects, subject.id))
        case let deck as Deck:
            if let record = BackupDeck(deck) { write(record, to: LibraryFiles.path(.decks, deck.id)) }
        case let card as Flashcard:
            if let record = BackupCard(card) { write(record, to: LibraryFiles.path(.cards, card.id)) }
        default:
            break
        }
    }

    /// Writes every subject, deck and card the folder doesn't hold as they are here, and removes
    /// the files of what's gone: whatever happened while the folder was closed, or was missed.
    private func writeAll() {
        for subject in models(SubjectModel.self).values { write(subject) }
        for deck in models(Deck.self).values { write(deck) }
        for card in models(Flashcard.self).values { write(card) }
        removeFilesOfDeleted()
        for path in index.removed {
            remove(path)
        }
    }

    private func write(_ record: some Encodable, to path: String) {
        guard let root, let data = try? LibraryFiles.encode(record) else { return }
        let fingerprint = LibraryFiles.fingerprint(data)
        if let file = index.files[path], file.fingerprint == fingerprint, file.pending != true { return }
        index.files[path] = Index.File(stamp: nil, fingerprint: fingerprint, pending: true)
        index.removed.remove(path)
        let url = root.appendingPathComponent(path)
        track({ [writer, presenter] done in writer.write(data, to: url, presenter: presenter, done: done) }) { [weak self] stamp in
            self?.written(path, fingerprint: fingerprint, stamp: stamp)
        }
        saveIndexSoon()
    }

    private func written(_ path: String, fingerprint: UInt64, stamp: LibraryFiles.Stamp?) {
        guard index.files[path]?.fingerprint == fingerprint else { return }
        if let stamp {
            index.files[path] = Index.File(stamp: stamp, fingerprint: fingerprint)
        }
        // A write that failed stays pending: the folder keeps the newer copy here, and it goes out next time.
        saveIndexSoon()
    }

    private func removeFilesOfDeleted() {
        let alive: [LibraryFiles.Kind: Set<UUID>] = [
            .subjects: Set(models(SubjectModel.self).keys),
            .decks: Set(models(Deck.self).keys),
            .cards: Set(models(Flashcard.self).keys),
        ]
        for path in index.files.keys {
            guard let (kind, id) = LibraryFiles.record(at: path), alive[kind]?.contains(id) == false else { continue }
            index.files[path] = nil
            index.removed.insert(path)
            remove(path)
        }
        saveIndexSoon()
    }

    /// Until the file is gone, reading the folder passes it by, so it doesn't come back.
    private func remove(_ path: String) {
        guard let root else { return }
        let url = root.appendingPathComponent(path)
        track({ [writer, presenter] done in writer.remove(url, presenter: presenter, done: done) }) { [weak self] removed in
            if removed { self?.index.removed.remove(path) }
            self?.saveIndexSoon()
        }
    }

    // MARK: - Review logs

    /// Adds lines to this device's log, in the month of each event.
    private func send(_ events: [LibraryFiles.ReviewEvent]) {
        guard let root, !events.isEmpty else { return }
        var lines: [String: Data] = [:]
        var ids: [String: [UUID]] = [:]
        for event in events {
            guard let data = try? LibraryFiles.encode(event, lines: true) else { continue }
            let path = LibraryFiles.logPath(device: device, at: event.review?.timestamp ?? .now)
            lines[path, default: Data()].append(data)
            if let id = event.review?.id { ids[path, default: []].append(id) }
        }
        for (path, data) in lines {
            let sent = ids[path] ?? []
            index.unsentReviews.formUnion(sent)
            let url = root.appendingPathComponent(path)
            track({ [writer, presenter] done in writer.append(data, to: url, presenter: presenter, done: done) }) { [weak self] appended in
                if appended { self?.index.unsentReviews.subtract(sent) }
                self?.saveIndexSoon()
            }
        }
        saveIndexSoon()
    }

    /// The store's reviews the folder doesn't have yet, from before it was first opened.
    private func sendReviews(notIn seen: Set<UUID>) {
        let logs = (try? context.fetch(FetchDescriptor<ReviewLogEntry>(sortBy: [SortDescriptor(\.timestamp)]))) ?? []
        send(logs.filter { !seen.contains($0.id) }.compactMap(BackupReviewLog.init).map { LibraryFiles.ReviewEvent(review: $0) })
    }

    /// Reviews made while no folder was open, or whose write didn't land.
    private func sendUnsentReviews() {
        guard !index.unsentReviews.isEmpty else { return }
        let logs = reviewLogs(withIDs: Array(index.unsentReviews)).sorted { $0.timestamp < $1.timestamp }
        index.unsentReviews = []
        send(logs.compactMap(BackupReviewLog.init).map { LibraryFiles.ReviewEvent(review: $0) })
    }

    // MARK: - Settings

    private var retention: Double {
        defaults.object(forKey: Self.retentionKey) as? Double ?? Self.defaultRetention
    }

    private func writeManifest() {
        guard root != nil, status == .ready || status == .opening else { return }
        write(LibraryFiles.Manifest(format: LibraryFiles.format, desiredRetention: retention), to: LibraryFiles.manifestPath)
    }

    // MARK: - Store

    private func models<T: PersistentModel & Identifiable>(_ type: T.Type) -> [UUID: T] where T.ID == UUID {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        return Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The reviews among `ids` that the store has, looked up a few hundred at a time.
    private func reviewLogs(withIDs ids: [UUID]) -> [ReviewLogEntry] {
        stride(from: 0, to: ids.count, by: 500).flatMap { start in
            let batch = Array(ids[start..<min(start + 500, ids.count)])
            return (try? context.fetch(FetchDescriptor<ReviewLogEntry>(predicate: #Predicate { batch.contains($0.id) }))) ?? []
        }
    }

    // MARK: - Index

    /// What this device last saw of the folder: a stamp and fingerprint for every file it read or wrote,
    /// how far into each other device's log it has read, and what's still to go out.
    struct Index: Codable {
        struct File: Codable {
            var stamp: LibraryFiles.Stamp?
            var fingerprint: UInt64
            /// Written here, but not known to have reached the folder.
            var pending: Bool?
        }

        /// The folder the store follows; nil until it has followed one.
        var folder: String?
        var files: [String: File] = [:]
        var logs: [String: UInt64] = [:]
        /// Files of things deleted here that haven't been removed from the folder yet.
        var removed: Set<String> = []
        var unsentReviews: Set<UUID> = []
    }

    private func saveIndexSoon() {
        indexTask?.cancel()
        indexTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.saveIndex()
        }
    }

    private func saveIndex() {
        guard let indexURL, let data = try? JSONEncoder().encode(index) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}

/// Writes into the library folder one thing at a time, in order, off the main actor, coordinating
/// with iCloud and other apps. The presenter it's given doesn't hear about these writes.
final class LibraryWriter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "inkept.library.writer", qos: .utility)

    /// Replaces a file; `done` gets its new stamp, or nil if the write failed.
    func write(_ data: Data, to url: URL, presenter: FolderPresenter?, done: @escaping @Sendable (LibraryFiles.Stamp?) -> Void) {
        queue.async {
            let written = Self.coordinate(url, presenter: presenter, options: .forReplacing) { url in
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            }
            done(written ? LibraryFiles.stamp(of: url) : nil)
        }
    }

    func append(_ data: Data, to url: URL, presenter: FolderPresenter?, done: @escaping @Sendable (Bool) -> Void) {
        queue.async {
            done(Self.coordinate(url, presenter: presenter, options: []) { url in
                if FileManager.default.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forWritingTo: url)
                    defer { try? handle.close() }
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                } else {
                    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try data.write(to: url, options: .atomic)
                }
            })
        }
    }

    func remove(_ url: URL, presenter: FolderPresenter?, done: @escaping @Sendable (Bool) -> Void) {
        queue.async {
            done(Self.coordinate(url, presenter: presenter, options: .forDeleting) { url in
                if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            })
        }
    }

    /// Returns once everything asked for before has been done.
    func flush() async {
        await withCheckedContinuation { continuation in
            queue.async { continuation.resume() }
        }
    }

    private static func coordinate(
        _ url: URL,
        presenter: FolderPresenter?,
        options: NSFileCoordinator.WritingOptions,
        _ body: (URL) throws -> Void
    ) -> Bool {
        var succeeded = false
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: presenter).coordinate(writingItemAt: url, options: options, error: &coordinationError) { url in
            succeeded = (try? body(url)) != nil
        }
        return succeeded && coordinationError == nil
    }
}
