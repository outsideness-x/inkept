import CoreGraphics
import Foundation
import Testing
@testable import inkept

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

    @Test func notesNoLinkReachesCanBeLeftOut() throws {
        let alone = VaultFolder(path: "", name: "", folders: [
            VaultFolder(path: "Physics", name: "Physics", folders: [], notes: [
                note("Physics/A.md", links: [NoteLink(kind: .wiki, target: "B")]),
                note("Physics/B.md"),
                note("Physics/Alone.md", tags: ["waves"]),
            ]),
        ], notes: [])
        let all = NoteGraph(root: alone, scope: "", options: .init(showsTags: true))
        #expect(all.index(of: "note:Physics/Alone.md") != nil)
        let linked = NoteGraph(root: alone, scope: "", options: .init(showsTags: true, showsOrphans: false))
        #expect(linked.index(of: "note:Physics/Alone.md") == nil)
        #expect(linked.index(of: "folder:Physics") != nil)
        // What was joined to the note goes with it, and every edge still points at the right nodes.
        let tag = try #require(linked.index(of: "tag:waves"))
        #expect(linked.neighbours[tag].isEmpty)
        for edge in linked.edges {
            #expect(edge.a < linked.nodes.count && edge.b < linked.nodes.count)
        }
        let a = try #require(linked.index(of: "note:Physics/A.md"))
        let b = try #require(linked.index(of: "note:Physics/B.md"))
        #expect(linked.neighbours[a].contains(b))
    }

    @Test func nodesKnowTheSubjectTheyBelongTo() throws {
        let graph = NoteGraph(root: vault, scope: "")
        let a = try #require(graph.index(of: "note:Physics/A.md"))
        #expect(graph.nodes[a].subject == "Physics")
        #expect(graph.nodes[a].tintIcon == "atom")
        let d = try #require(graph.index(of: "note:D.md"))
        #expect(graph.nodes[d].subject == nil)
        let maths = try #require(graph.index(of: "folder:Maths"))
        #expect(graph.nodes[maths].subject == "Maths")
        #expect(NoteGraph.subject(of: "Physics/Optics/Lenses") == "Physics")
    }

    @Test func theViewFitsTheMapUnderTheControls() {
        let bounds = CGRect(x: -100, y: -50, width: 200, height: 100)
        let size = CGSize(width: 400, height: 300)
        let camera = GraphCamera.fitting(bounds, in: size, margin: 20, top: 40)
        let top = camera.screen(CGPoint(x: bounds.midX, y: bounds.minY), in: size)
        let bottom = camera.screen(CGPoint(x: bounds.midX, y: bounds.maxY), in: size)
        // Centred in the room under the controls, and inside it.
        #expect(abs((top.y + bottom.y) / 2 - (40 + (300 - 40) / 2)) < 0.001)
        #expect(top.y >= 40 + 20 - 0.001)
        #expect(bottom.y <= 300 - 20 + 0.001)
        // Halfway between two views, the zoom has changed by the same factor either side.
        let far = GraphCamera(centre: .zero, scale: 0.5)
        let near = GraphCamera(centre: CGPoint(x: 100, y: 0), scale: 2)
        let middle = far.mixed(with: near, by: 0.5)
        #expect(abs(middle.scale - 1) < 0.0001)
        #expect(abs(middle.centre.x - 50) < 0.0001)
    }

    @Test func theLayoutCoolsAtTheSamePaceAtAnyFrameRate() {
        let graph = NoteGraph(root: vault, scope: "")
        var sixty = GraphLayout(graph: graph)
        var oneTwenty = GraphLayout(graph: graph)
        for _ in 0..<60 { sixty.tick(timeScale: 1) }
        for _ in 0..<120 { oneTwenty.tick(timeScale: 0.5) }
        #expect(abs(sixty.alpha - oneTwenty.alpha) < 0.0001)
        #expect(oneTwenty.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    }

    @Test func aTallViewGetsATallerMap() {
        let graph = NoteGraph(root: vault, scope: "")
        func extent(_ aspect: CGFloat) -> CGSize {
            var layout = GraphLayout(graph: graph, aspect: aspect)
            layout.settle(ticks: 400)
            let xs = layout.positions.map(\.x)
            let ys = layout.positions.map(\.y)
            return CGSize(width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
        }
        let tall = extent(2)
        let wide = extent(0.5)
        #expect(tall.height / tall.width > wide.height / wide.width)
    }
}

