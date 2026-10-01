import Foundation

/// The card library written into the notes folder, beside the notes, so the folder alone carries
/// everything: pick it on another device and the cards, their schedules and their history come along.
///
///     .inkept/library.json                        the format, and the library's settings
///     .inkept/subjects/<id>.json
///     .inkept/decks/<id>.json
///     .inkept/cards/<id>.json                     both sides, the note it came from, and its schedule
///     .inkept/reviews/<device>/<yyyy-MM>.jsonl    every review a device made, one a line, and undos
///
/// Each thing is a small file of its own, and each device writes only its own review log, so two
/// devices syncing the folder rarely touch the same file. Obsidian, Finder and Files leave the hidden
/// folder alone. Reading never needs the main actor.
enum LibraryFiles {
    static let folderName = ".inkept"
    static let format = "inkept-library-v1"
    static let manifestPath = "library.json"
    static let reviewsFolder = "reviews"

    enum Kind: String, CaseIterable, Sendable {
        case subjects
        case decks
        case cards
    }

    struct Manifest: Codable, Equatable, Sendable {
        var format: String
        var desiredRetention: Double?
    }

    /// One line of a review log: a review, or the undoing of one.
    struct ReviewEvent: Codable, Equatable, Sendable {
        var review: BackupReviewLog?
        var undo: UUID?
    }

    struct Stamp: Codable, Equatable, Sendable {
        var modified: Date
        var size: Int
    }

    /// A record read from a file that changed since it was last seen.
    struct Changed<Record: Sendable>: Sendable {
        var path: String
        var record: Record
        var stamp: Stamp
        var fingerprint: UInt64
    }

    /// The new lines of one device's review log, and where reading stopped.
    struct LogChunk: Sendable {
        var path: String
        var events: [ReviewEvent]
        var offset: UInt64
    }

    /// What's in the folder now, and everything that changed since `known`.
    struct Scan: Sendable {
        /// Every subject, deck and card file there, downloaded or not.
        var present: Set<String> = []
        var manifest: Changed<Manifest>?
        var subjects: [Changed<BackupSubject>] = []
        var decks: [Changed<BackupDeck>] = []
        var cards: [Changed<BackupCard>] = []
        var logs: [LogChunk] = []
        /// Stamps of files that changed on disk but hold what was already known.
        var restamped: [String: Stamp] = [:]
    }

    // MARK: - Paths

    static func path(_ kind: Kind, _ id: UUID) -> String {
        "\(kind.rawValue)/\(id.uuidString).json"
    }

    /// The kind and id a record file's path names, or nil for anything else.
    static func record(at path: String) -> (kind: Kind, id: UUID)? {
        let parts = path.split(separator: "/")
        guard parts.count == 2, let kind = Kind(rawValue: String(parts[0])), parts[1].hasSuffix(".json"),
              let id = UUID(uuidString: String(parts[1].dropLast(5)))
        else { return nil }
        return (kind, id)
    }

    /// One log a month per device keeps every file small enough to sync quickly.
    static func logPath(device: String, at date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let parts = calendar.dateComponents([.year, .month], from: date)
        return "\(reviewsFolder)/\(device)/" + String(format: "%04d-%02d.jsonl", parts.year ?? 0, parts.month ?? 0)
    }

    // MARK: - Coding

    static func encode(_ value: some Encodable, lines: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = lines ? [.sortedKeys] : [.prettyPrinted, .sortedKeys]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(type, from: data)
    }

    /// FNV-1a over the bytes: enough to tell whether a file holds what was last written or read.
    static func fingerprint(_ data: Data) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    // MARK: - Reading

    /// Reads whatever changed under `root` (the `.inkept` folder) since `known` and `offsets`.
    /// Logs in `skippingDevice`'s folder are this device's own and aren't read back.
    /// Files iCloud hasn't brought down yet are asked for, counted as present, and read once they arrive.
    static func scan(
        root: URL,
        known: [String: Stamp],
        fingerprints: [String: UInt64],
        offsets: [String: UInt64],
        skippingDevice device: String
    ) -> Scan {
        var scan = Scan()

        func readChanged<Record: Decodable & Sendable>(_ path: String, _ url: URL, _ stamp: Stamp) -> Changed<Record>? {
            guard known[path] != stamp, let data = try? Data(contentsOf: url) else { return nil }
            let fingerprint = Self.fingerprint(data)
            if fingerprints[path] == fingerprint {
                scan.restamped[path] = stamp
                return nil
            }
            // A file that doesn't read yet is still arriving; it's tried again next time.
            guard let record = try? decode(Record.self, from: data) else { return nil }
            return Changed(path: path, record: record, stamp: stamp, fingerprint: fingerprint)
        }

        let manifestURL = root.appendingPathComponent(manifestPath)
        if let manifestStamp = Self.stamp(of: manifestURL) {
            scan.manifest = readChanged(manifestPath, manifestURL, manifestStamp)
        }

        for kind in Kind.allCases {
            for entry in entries(in: root.appendingPathComponent(kind.rawValue, isDirectory: true)) {
                let path = "\(kind.rawValue)/\(entry.name)"
                guard Self.record(at: path) != nil else { continue }
                scan.present.insert(path)
                guard let stamp = entry.stamp else { continue }
                switch kind {
                case .subjects:
                    if let changed: Changed<BackupSubject> = readChanged(path, entry.url, stamp) { scan.subjects.append(changed) }
                case .decks:
                    if let changed: Changed<BackupDeck> = readChanged(path, entry.url, stamp) { scan.decks.append(changed) }
                case .cards:
                    if let changed: Changed<BackupCard> = readChanged(path, entry.url, stamp) { scan.cards.append(changed) }
                }
            }
        }

        let reviews = root.appendingPathComponent(reviewsFolder, isDirectory: true)
        for folder in entries(in: reviews) where folder.isDirectory && folder.name != device {
            for log in entries(in: folder.url) where log.name.hasSuffix(".jsonl") {
                guard let stamp = log.stamp else { continue }
                let path = "\(reviewsFolder)/\(folder.name)/\(log.name)"
                var offset = offsets[path] ?? 0
                // A log that shrank was replaced, by a sync conflict or by hand: read it again from the top.
                if UInt64(stamp.size) < offset { offset = 0 }
                guard UInt64(stamp.size) > offset, let chunk = readLines(of: log.url, from: offset) else { continue }
                scan.logs.append(LogChunk(path: path, events: chunk.events, offset: chunk.offset))
            }
        }
        return scan
    }

    private struct Entry {
        let name: String
        let url: URL
        let isDirectory: Bool
        /// Nil while the file is still in iCloud.
        let stamp: Stamp?
    }

    private static func entries(in folder: URL) -> [Entry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys) else {
            return []
        }
        return urls.map { url in
            let name = url.lastPathComponent
            // iOS keeps files still in iCloud as `.Name.icloud` stand-ins; ask for the real thing.
            if name.hasPrefix("."), name.hasSuffix(".icloud") {
                let real = String(name.dropFirst().dropLast(".icloud".count))
                let realURL = folder.appendingPathComponent(real)
                try? FileManager.default.startDownloadingUbiquitousItem(at: realURL)
                return Entry(name: real, url: realURL, isDirectory: false, stamp: nil)
            }
            let values = try? url.resourceValues(forKeys: Set(keys))
            return Entry(
                name: name,
                url: url,
                isDirectory: values?.isDirectory == true,
                stamp: values?.isDirectory == true ? nil : Self.stamp(from: values)
            )
        }
    }

    static func stamp(of url: URL) -> Stamp? {
        stamp(from: try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]))
    }

    private static func stamp(from values: URLResourceValues?) -> Stamp? {
        guard let modified = values?.contentModificationDate, let size = values?.fileSize else { return nil }
        return Stamp(modified: modified, size: size)
    }

    /// The whole lines after `offset`; a last line still being written waits for the next read.
    private static func readLines(of url: URL, from offset: UInt64) -> (events: [ReviewEvent], offset: UInt64)? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: offset)) != nil, let data = try? handle.readToEnd(),
              let end = data.lastIndex(of: 0x0A)
        else { return nil }
        let complete = data[data.startIndex...end]
        let events = complete.split(separator: 0x0A).compactMap { try? decode(ReviewEvent.self, from: Data($0)) }
        return (events, offset + UInt64(complete.count))
    }
}
