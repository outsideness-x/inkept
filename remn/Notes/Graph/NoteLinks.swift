import Foundation

/// What one note links to and what links to it, worked out from the links every note in the vault makes.
struct NoteLinks: Sendable {
    /// The notes with a link to this one, the most recently written first.
    private(set) var incoming: [NoteSummary] = []
    /// The notes this one links to, in the order it first names them.
    private(set) var outgoing: [NoteSummary] = []
    /// What this note links to that hasn't been written yet, as the links name it.
    private(set) var missing: [String] = []

    private let path: String
    private let index: NoteIndex

    init(root: VaultFolder, path: String) {
        let everything = root.allNotes
        let index = NoteIndex(everything)
        self.index = index
        guard let note = index.note(at: path) else {
            self.path = path
            return
        }
        self.path = note.path

        var named = Set<String>()
        for link in note.links {
            if let target = index.resolve(link, from: note.path) {
                guard target != note.path, named.insert(target).inserted, let summary = index.note(at: target) else { continue }
                outgoing.append(summary)
            } else if link.kind == .wiki, !missing.contains(where: { $0.caseInsensitiveCompare(link.target) == .orderedSame }) {
                missing.append(link.target)
            }
        }
        incoming = everything
            .filter { other in
                other.path != note.path && other.links.contains { index.resolve($0, from: other.path) == note.path }
            }
            .sorted { $0.written > $1.written }
    }

    var isEmpty: Bool {
        incoming.isEmpty && outgoing.isEmpty && missing.isEmpty
    }

    /// Whether `link`, written in the note at `notePath`, leads to this note.
    func leadsHere(_ link: NoteLink, from notePath: String) -> Bool {
        index.resolve(link, from: notePath) == path
    }
}
