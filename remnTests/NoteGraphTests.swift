import CoreGraphics
import Foundation
import Testing
@testable import remn

struct NoteGraphTests {
    private func note(_ path: String, links: [NoteLink] = [], tags: [String] = []) -> NoteSummary {
        NoteSummary(
            path: path, title: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)), snippet: "", tags: tags,
            font: nil, modified: .now, isDownloaded: true, links: links
        )
    }

    /// Physics (with an icon) holds A and B; Maths holds C; D sits at the top.
    private var vault: VaultFolder {
        VaultFolder(path: "", name: "", folders: [
            VaultFolder(path: "Physics", name: "Physics", folders: [], notes: [
                note("Physics/A.md", links: [NoteLink(kind: .wiki, target: "B"), NoteLink(kind: .wiki, target: "Ghost#Intro")], tags: ["waves"]),
                note("Physics/B.md", tags: ["waves"]),
            ], icon: "atom"),
            VaultFolder(path: "Maths", name: "Maths", folders: [], notes: [
                note("Maths/C.md", links: [NoteLink(kind: .wiki, target: "A"), NoteLink(kind: .wiki, target: "A")]),
            ]),
        ], notes: [
            note("D.md", links: [NoteLink(kind: .path, target: "Physics/B.md"), NoteLink(kind: .path, target: "Physics/../Maths/C.md")]),
        ])
    }

    @Test func linksFoldersAndNotesStillToWriteAreJoined() throws {
        let graph = NoteGraph(root: vault, scope: "")
        let ids = Set(graph.nodes.map(\.id))
        #expect(ids == ["note:Physics/A.md", "note:Physics/B.md", "note:Maths/C.md", "note:D.md", "folder:Physics", "folder:Maths", "missing:ghost"])
        let a = try #require(graph.index(of: "note:Physics/A.md"))
        #expect(graph.nodes[a].icon == "atom")
        #expect(graph.nodes[a].degree == 4)
        #expect(graph.edges.count == 8)
        #expect(graph.edges.filter { $0.kind == .folder }.count == 3)
        let d = try #require(graph.index(of: "note:D.md"))
        #expect(Set(graph.neighbours[d].map { graph.nodes[$0].id }) == ["note:Physics/B.md", "note:Maths/C.md"])
    }

    @Test func aFoldersMapShowsWhatLinksInFromElsewhere() throws {
        let graph = NoteGraph(root: vault, scope: "Physics")
        let outside = graph.nodes.filter(\.isOutside).map(\.id).sorted()
        #expect(outside == ["note:D.md", "note:Maths/C.md"])
        #expect(graph.index(of: "folder:Physics") != nil)
        #expect(graph.index(of: "folder:Maths") == nil)
        let bare = NoteGraph(root: vault, scope: "", options: .init(showsFolders: false, showsTags: true, showsMissing: false))
        #expect(bare.nodes.allSatisfy { $0.kind != .folder && $0.kind != .missing })
        let waves = try #require(bare.index(of: "tag:waves"))
        #expect(bare.neighbours[waves].count == 2)
    }

    @Test func aNotesNeighbourhoodReachesAsFarAsAsked() {
        let near = NoteGraph(root: vault, around: "Physics/A.md", depth: 1)
        #expect(Set(near.nodes.map(\.id)) == ["note:Physics/A.md", "note:Physics/B.md", "note:Maths/C.md", "missing:ghost"])
        let far = NoteGraph(root: vault, around: "Physics/A.md", depth: 2)
        #expect(far.index(of: "note:D.md") != nil)
    }

    @Test func pathsAreWorkedOut() {
        #expect(VaultPath.normalized("Physics/../Maths/./Sets.md") == "Maths/Sets.md")
        #expect(VaultPath.normalized("../x.md") == "x.md")
    }

    @Test func theLayoutSettlesTheSameWayEveryTime() {
        let graph = NoteGraph(root: vault, scope: "")
        var first = GraphLayout(graph: graph)
        var second = GraphLayout(graph: graph)
        first.settle(ticks: 400)
        second.settle(ticks: 400)
        #expect(first.positions == second.positions)
        #expect(first.isSettled)
        // Nothing sits on top of anything else.
        for i in first.positions.indices {
            for j in first.positions.indices where j > i {
                let distance = hypot(first.positions[i].x - first.positions[j].x, first.positions[i].y - first.positions[j].y)
                #expect(distance > first.radii[i] + first.radii[j])
            }
        }
    }

    @Test func aLargeVaultIsLaidOutQuickly() {
        var random = InkRandom(seed: 11)
        let folders = (0..<12).map { folder in
            VaultFolder(path: "F\(folder)", name: "F\(folder)", folders: [], notes: (0..<40).map { index in
                let links = (0..<2).map { _ in
                    NoteLink(kind: .wiki, target: "N\(Int(random.unit() * 12))-\(Int(random.unit() * 40))")
                }
                return note("F\(folder)/N\(folder)-\(index).md", links: links)
            })
        }
        let graph = NoteGraph(root: VaultFolder(path: "", name: "", folders: folders, notes: []), scope: "")
        #expect(graph.nodes.count == 492)
        var layout = GraphLayout(graph: graph)
        let elapsed = ContinuousClock().measure { layout.settle(ticks: 260) }
        #expect(elapsed < .seconds(20))
        #expect(layout.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }
}
