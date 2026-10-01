import Foundation
import Testing
@testable import inkept

struct NoteLinksTests {
    private func note(_ path: String, links: [NoteLink] = [], daysAgo: Double = 0) -> NoteSummary {
        NoteSummary(
            path: path, title: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)), snippet: "", tags: [], font: nil,
            modified: Date(timeIntervalSinceReferenceDate: 800_000_000 - daysAgo * 86_400), isDownloaded: true, links: links
        )
    }

    /// Eigenvalues links to Matrices, to a note still to write and to itself; three notes link back to it,
    /// each its own way; Alone links nowhere.
    private var vault: VaultFolder {
        VaultFolder(path: "", name: "", folders: [
            VaultFolder(path: "Algebra", name: "Algebra", folders: [], notes: [
                note("Algebra/Eigenvalues.md", links: [
                    NoteLink(kind: .wiki, target: "Matrices"),
                    NoteLink(kind: .wiki, target: "Jordan form"),
                    NoteLink(kind: .wiki, target: "matrices"),
                    NoteLink(kind: .wiki, target: "Eigenvalues"),
                ]),
                note("Algebra/Matrices.md", links: [NoteLink(kind: .wiki, target: "Eigenvalues")], daysAgo: 3),
                note("Algebra/Spaces.md", links: [NoteLink(kind: .path, target: "Eigenvalues.md")], daysAgo: 1),
            ]),
        ], notes: [
            note("Inbox.md", links: [NoteLink(kind: .wiki, target: "Algebra/Eigenvalues")], daysAgo: 2),
            note("Alone.md"),
        ])
    }

    @Test func aNoteKnowsWhatLinksToItAndWhereItLeads() {
        let links = NoteLinks(root: vault, path: "Algebra/Eigenvalues.md")
        #expect(links.incoming.map(\.path) == ["Algebra/Spaces.md", "Inbox.md", "Algebra/Matrices.md"])
        #expect(links.outgoing.map(\.path) == ["Algebra/Matrices.md"])
        #expect(links.missing == ["Jordan form"])
        #expect(!links.isEmpty)
        #expect(NoteLinks(root: vault, path: "Alone.md").isEmpty)
        #expect(NoteLinks(root: vault, path: "Gone.md").isEmpty)
    }

    @Test func theLineALinkIsWrittenInIsPickedOut() {
        let links = NoteLinks(root: vault, path: "Algebra/Eigenvalues.md")
        let body = """
        # Matrices
        - A square matrix has [[Eigenvalues|eigenvalues]] when **det** is zero.
        `[[Eigenvalues]]` in code doesn't count
        ```
        [[Eigenvalues]]
        ```
        See also [the proof](Eigenvalues.md#proof) and [[Spaces]].
        """
        let mentions = NoteOutline.mentions(in: body) { links.leadsHere($0, from: "Algebra/Matrices.md") }
        #expect(mentions == [
            NoteMention(pieces: [
                .init(text: "A square matrix has ", isLink: false),
                .init(text: "eigenvalues", isLink: true),
                .init(text: " when det is zero.", isLink: false),
            ]),
            NoteMention(pieces: [
                .init(text: "See also ", isLink: false),
                .init(text: "the proof", isLink: true),
                .init(text: " and Spaces.", isLink: false),
            ]),
        ])
    }

    @Test func aLongLineIsCutToTheWordsBeforeTheLink() throws {
        let words = String(repeating: "and so on ", count: 20)
        let mention = try #require(NoteOutline.mentions(in: words + "[[Eigenvalues]]") { $0.target == "Eigenvalues" }.first)
        #expect(mention.pieces.count == 2)
        #expect(mention.pieces[0].text.hasPrefix("…"))
        #expect(mention.pieces[0].text.count <= 49)
        #expect(mention.pieces[1] == .init(text: "Eigenvalues", isLink: true))
    }
}
