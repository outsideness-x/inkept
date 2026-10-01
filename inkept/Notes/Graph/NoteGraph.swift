import Foundation

/// Finds the notes links point at, the way Obsidian does: `[[Name]]` by title, the note beside the
/// link first; `[[Folder/Name]]` and `[text](path.md)` by path.
struct NoteIndex: Sendable {
    private let byPath: [String: NoteSummary]
    private let byTitle: [String: [NoteSummary]]

    init(_ notes: [NoteSummary]) {
        byPath = Dictionary(notes.map { ($0.path.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        byTitle = Dictionary(grouping: notes) { $0.title.lowercased() }
    }

    func note(at path: String) -> NoteSummary? {
        byPath[path.lowercased()]
    }

    /// The path of the note `link`, written in the note at `notePath`, leads to.
    func resolve(_ link: NoteLink, from notePath: String) -> String? {
        switch link.kind {
        case .wiki:
            var name = link.target
            if let heading = name.firstIndex(of: "#") { name = String(name[..<heading]) }
            name = name.trimmingCharacters(in: .whitespaces)
            if name.lowercased().hasSuffix(".md") { name = String(name.dropLast(3)) }
            guard !name.isEmpty else { return nil }
            if name.contains("/") {
                let wanted = name.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + ".md"
                return byPath[wanted.lowercased()]?.path
            }
            let named = byTitle[name.lowercased()] ?? []
            let folder = VaultPath.parent(of: notePath)
            return (named.first { $0.folderPath == folder } ?? named.first)?.path
        case .path:
            let base = link.target.hasPrefix("/") ? "" : VaultPath.parent(of: notePath)
            let target = link.target.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return byPath[VaultPath.normalized(VaultPath.join(base, target)).lowercased()]?.path
        }
    }
}

/// Notes and what joins them — links, the folders they sit in, the tags they share — for drawing as a map.
struct NoteGraph: Sendable {
    enum NodeKind: Hashable, Sendable {
        case note
        /// A folder of notes: a subject, or a part of one.
        case folder
        case tag
        /// A `[[link]]` to a note that hasn't been written yet.
        case missing
    }

    struct Node: Identifiable, Sendable {
        let id: String
        let kind: NodeKind
        let title: String
        /// The note's or folder's path, or the tag's name.
        let path: String
        /// A folder's own icon; for a note, the icon of the subject it's in.
        let icon: String?
        /// A note elsewhere that links in or is linked to, drawn fainter.
        var isOutside = false
        var degree = 0
    }

    enum EdgeKind: Hashable, Sendable {
        case link
        case folder
        case tag
    }

    struct Edge: Hashable, Sendable {
        let a: Int
        let b: Int
        let kind: EdgeKind
    }

    struct Options: Equatable, Sendable {
        var showsFolders = true
        var showsTags = false
        var showsMissing = true
    }

    private(set) var nodes: [Node] = []
    private(set) var edges: [Edge] = []
    /// For each node, the nodes it's joined to.
    private(set) var neighbours: [[Int]] = []
    private var indexByID: [String: Int] = [:]
    private var joined = Set<Int>()

    init() {}

    func index(of id: String) -> Int? {
        indexByID[id]
    }

    // MARK: - A folder's map

    /// Every note in the folder at `scope` and below, what they link to, and what links to them from elsewhere.
    init(root: VaultFolder, scope: String, options: Options = Options()) {
        let scopeFolder = root.folder(at: scope) ?? root
        let everything = root.allNotes
        let index = NoteIndex(everything)
        let inside = scopeFolder.allNotes
        let insidePaths = Set(inside.map(\.path))

        for note in inside {
            addNote(note, root: root, outside: false)
        }
        for note in inside {
            guard let from = indexByID[Self.noteID(note.path)] else { continue }
            for link in note.links {
                if let target = index.resolve(link, from: note.path) {
                    guard target != note.path, let summary = index.note(at: target) else { continue }
                    let to = addNote(summary, root: root, outside: !insidePaths.contains(target))
                    addEdge(from, to, .link)
                } else if options.showsMissing, link.kind == .wiki {
                    addEdge(from, addMissing(link.target), .link)
                }
            }
        }
        // Notes elsewhere that link in.
        if !scope.isEmpty {
            for note in everything where !insidePaths.contains(note.path) {
                for link in note.links {
                    guard let target = index.resolve(link, from: note.path), insidePaths.contains(target),
                          let to = indexByID[Self.noteID(target)]
                    else { continue }
                    addEdge(addNote(note, root: root, outside: true), to, .link)
                }
            }
        }
        if options.showsFolders {
            let folders = (scopeFolder.isRoot ? [] : [scopeFolder]) + scopeFolder.flattened().map(\.folder)
            for folder in folders {
                add(Node(id: Self.folderID(folder.path), kind: .folder, title: folder.name, path: folder.path, icon: folder.icon))
            }
            for folder in folders {
                if let parent = indexByID[Self.folderID(VaultPath.parent(of: folder.path))], let child = indexByID[Self.folderID(folder.path)] {
                    addEdge(child, parent, .folder)
                }
            }
            for note in inside {
                if let from = indexByID[Self.noteID(note.path)], let folder = indexByID[Self.folderID(note.folderPath)] {
                    addEdge(from, folder, .folder)
                }
            }
        }
        if options.showsTags {
            for note in inside {
                guard let from = indexByID[Self.noteID(note.path)] else { continue }
                for tag in note.tags {
                    let id = "tag:" + tag.lowercased()
                    let to = indexByID[id] ?? add(Node(id: id, kind: .tag, title: "#" + tag, path: tag, icon: nil))
                    addEdge(from, to, .tag)
                }
            }
        }
        finish()
    }

    // MARK: - One note's neighbourhood

    /// The notes within `depth` links of one note, either way round, and the notes it names that don't exist yet.
    init(root: VaultFolder, around notePath: String, depth: Int = 2) {
        let everything = root.allNotes
        let index = NoteIndex(everything)
        var linked: [String: Set<String>] = [:]
        var missing: [String: [String]] = [:]
        for note in everything {
            for link in note.links {
                if let target = index.resolve(link, from: note.path), target != note.path {
                    linked[note.path, default: []].insert(target)
                    linked[target, default: []].insert(note.path)
                } else if link.kind == .wiki, index.resolve(link, from: note.path) == nil {
                    missing[note.path, default: []].append(link.target)
                }
            }
        }
        guard let centre = index.note(at: notePath) else { return }
        addNote(centre, root: root, outside: false)
        var frontier = [centre.path]
        var seen: Set<String> = [centre.path]
        for _ in 0..<depth {
            var next: [String] = []
            for path in frontier {
                for other in (linked[path] ?? []).sorted() where !seen.contains(other) {
                    guard let summary = index.note(at: other) else { continue }
                    seen.insert(other)
                    addNote(summary, root: root, outside: false)
                    next.append(other)
                }
            }
            frontier = next
        }
        for path in seen {
            guard let from = indexByID[Self.noteID(path)] else { continue }
            for other in linked[path] ?? [] {
                if let to = indexByID[Self.noteID(other)] { addEdge(from, to, .link) }
            }
        }
        for name in missing[centre.path] ?? [] {
            if let from = indexByID[Self.noteID(centre.path)] {
                addEdge(from, addMissing(name), .link)
            }
        }
        finish()
    }

    // MARK: - Building

    static func noteID(_ path: String) -> String { "note:" + path }
    static func folderID(_ path: String) -> String { "folder:" + path }

    @discardableResult
    private mutating func addNote(_ note: NoteSummary, root: VaultFolder, outside: Bool) -> Int {
        if let existing = indexByID[Self.noteID(note.path)] { return existing }
        return add(Node(
            id: Self.noteID(note.path),
            kind: .note,
            title: note.title,
            path: note.path,
            icon: root.icon(forFolder: note.folderPath),
            isOutside: outside
        ))
    }

    private mutating func addMissing(_ target: String) -> Int {
        var name = target
        if let heading = name.firstIndex(of: "#") { name = String(name[..<heading]) }
        name = VaultPath.name(of: name.trimmingCharacters(in: .whitespaces))
        let id = "missing:" + name.lowercased()
        return indexByID[id] ?? add(Node(id: id, kind: .missing, title: name, path: name, icon: nil))
    }

    @discardableResult
    private mutating func add(_ node: Node) -> Int {
        if let existing = indexByID[node.id] { return existing }
        nodes.append(node)
        indexByID[node.id] = nodes.count - 1
        return nodes.count - 1
    }

    /// Joins two nodes once, however many times one links to the other.
    private mutating func addEdge(_ a: Int, _ b: Int, _ kind: EdgeKind) {
        guard a != b, joined.insert(min(a, b) << 32 | max(a, b)).inserted else { return }
        edges.append(Edge(a: min(a, b), b: max(a, b), kind: kind))
    }

    private mutating func finish() {
        neighbours = Array(repeating: [], count: nodes.count)
        for edge in edges {
            neighbours[edge.a].append(edge.b)
            neighbours[edge.b].append(edge.a)
        }
        for index in nodes.indices {
            nodes[index].degree = neighbours[index].count
        }
    }
}

extension VaultPath {
    /// A path with `.` and `..` worked out: `Physics/../Maths/Sets.md` is `Maths/Sets.md`.
    static func normalized(_ path: String) -> String {
        var parts: [Substring] = []
        for part in path.split(separator: "/") {
            switch part {
            case ".": continue
            case "..": if !parts.isEmpty { parts.removeLast() }
            default: parts.append(part)
            }
        }
        return parts.joined(separator: "/")
    }
}
