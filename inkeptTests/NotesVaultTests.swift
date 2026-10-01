import Foundation
import Testing
@testable import inkept

struct FrontMatterTests {
    @Test func keepsUnknownKeysAndReadsTagsAndFont() {
        let text = """
        ---
        aliases: [lens]
        tags: [optics, "light rays"]
        font: newYork
        cssclasses:
          - wide
        ---

        # Lenses
        """
        var document = NoteDocument(text: text)
        #expect(document.frontMatter.tags == ["optics", "light-rays"])
        #expect(document.frontMatter.font == "newYork")
        #expect(document.body == "# Lenses")

        document.frontMatter.tags.append("physics")
        document.frontMatter.font = nil
        #expect(document.text == """
        ---
        aliases: [lens]
        tags: [optics, light-rays, physics]
        cssclasses:
          - wide
        ---

        # Lenses
        """)
    }

    @Test func readsBlockListsOfTags() {
        let document = NoteDocument(text: "---\ntags:\n  - one\n  - \"#two\"\n---\nbody")
        #expect(document.frontMatter.tags == ["one", "two"])
        #expect(document.body == "body")
    }

    @Test func notesWithoutFrontMatterStayUntouched() {
        let text = "---- not front matter\nhello"
        #expect(NoteDocument(text: text).text == text)
        #expect(NoteDocument(text: "plain").text == "plain")
    }

    @Test func addingATagCreatesFrontMatter() {
        var document = NoteDocument(text: "hello")
        document.frontMatter.tags = ["math"]
        #expect(document.text == "---\ntags: [math]\n---\n\nhello")
        #expect(NoteDocument(text: document.text) == document)
    }

    @Test func inlineTagsSkipHeadingsAndCode() {
        let body = """
        # Heading
        study #calculus and #limits/one-sided
        `#notatag`
        ```
        #nope
        ```
        issue #42 is not a tag
        """
        #expect(NoteText.inlineTags(in: body) == ["calculus", "limits/one-sided"])
    }

    @Test func snippetSkipsMarkdownPunctuation() {
        #expect(NoteText.snippet(of: "# Title\n\n**Bold** [link](x) text") == "Bold link text")
        #expect(NoteText.snippet(of: "```\ncode\n```\n\n$$\nx\n$$\n- item *one*") == "x")
        #expect(NoteText.snippet(of: "- [ ] read *the* book") == "read the book")
    }
}

@MainActor
struct VaultTests {
    private func makeVault() throws -> (Vault, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("inkept-vault-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return (Vault(rootURL: root), root)
    }

    @Test func wikiLinksFindTheirNotes() {
        func note(_ path: String) -> NoteSummary {
            NoteSummary(
                path: path, title: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)), snippet: "", tags: [],
                font: nil, modified: .now, isDownloaded: true
            )
        }
        let root = VaultFolder(path: "", name: "", folders: [
            VaultFolder(path: "Physics", name: "Physics", folders: [], notes: [note("Physics/Lenses.md"), note("Physics/Waves.md")]),
            VaultFolder(path: "Art", name: "Art", folders: [], notes: [note("Art/Lenses.md")]),
        ], notes: [note("Index.md")])
        #expect(root.notePath(linkedAs: "waves", from: "Index.md") == "Physics/Waves.md")
        // Two notes share a name: the one beside the link wins.
        #expect(root.notePath(linkedAs: "Lenses", from: "Art/Colour.md") == "Art/Lenses.md")
        #expect(root.notePath(linkedAs: "Physics/Lenses", from: "Art/Colour.md") == "Physics/Lenses.md")
        #expect(root.notePath(linkedAs: "Waves#Interference", from: "Index.md") == "Physics/Waves.md")
        #expect(root.notePath(linkedAs: "Index.md", from: "Physics/Waves.md") == "Index.md")
        #expect(root.notePath(linkedAs: "Optics", from: "Index.md") == nil)
    }

    @Test func foldersAndNotesRoundTrip() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let physics = try await vault.createFolder(named: "Physics", in: "")
        let optics = try await vault.createFolder(named: "Optics", in: physics)
        let note = try await vault.createNote(in: optics, title: "Lenses: basics")
        #expect(note == "Physics/Optics/Lenses basics.md")

        var document = try await vault.load(note)
        document.body = "A lens bends light. #optics"
        document.frontMatter.tags = ["physics"]
        try await vault.save(document, to: note)
        await vault.reload()

        let summary = try #require(vault.root.note(at: note))
        #expect(summary.title == "Lenses basics")
        // The tag the line ends with is shown as a tag, not repeated in the snippet.
        #expect(summary.snippet == "A lens bends light.")
        #expect(summary.tags == ["physics", "optics"])
        #expect(vault.root.folder(at: physics)?.totalNoteCount == 1)
        #expect(vault.tags.map(\.tag) == ["optics", "physics"])

        let renamed = try await vault.renameNote(note, to: "Thin lenses")
        #expect(renamed == "Physics/Optics/Thin lenses.md")
        let moved = try await vault.moveNote(renamed, toFolder: physics)
        #expect(moved == "Physics/Thin lenses.md")
        let second = try await vault.createNote(in: physics, title: "Thin lenses")
        #expect(second == "Physics/Thin lenses 2.md")

        try await vault.deleteNote(second)
        await vault.reload()
        #expect(vault.root.note(at: second) == nil)
        #expect(vault.root.folder(at: physics)?.notes.count == 1)
    }

    @Test func foldersKeepTheirIconInAHiddenFileInside() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let physics = try await vault.createFolder(named: "Physics", in: "", icon: "atom")
        let optics = try await vault.createFolder(named: "Optics", in: physics)
        await vault.reload()
        let info = root.appendingPathComponent("Physics/\(VaultFolderInfo.fileName)")
        #expect(FileManager.default.fileExists(atPath: info.path))
        #expect(vault.root.folder(at: physics)?.icon == "atom")
        #expect(vault.root.folder(at: physics)?.notes.isEmpty == true)
        #expect(vault.root.folder(at: optics)?.icon == nil)
        #expect(vault.root.icon(forFolder: optics) == "atom")
        #expect(vault.root.icon(forFolder: "") == nil)

        // Whatever else is in the file stays.
        try #"{"icon": "atom", "colour": "red"}"#.write(to: info, atomically: true, encoding: .utf8)
        try await vault.setIcon("magnet", forFolder: physics)
        #expect(vault.root.folder(at: physics)?.icon == "magnet")
        let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: info)) as? [String: String]
        #expect(saved == ["icon": "magnet", "colour": "red"])

        // The icon goes wherever the folder goes.
        let renamed = try await vault.renameFolder(physics, to: "Physik")
        await vault.reload()
        #expect(vault.root.folder(at: renamed)?.icon == "magnet")

        try await vault.setIcon(nil, forFolder: renamed)
        let kept = root.appendingPathComponent("Physik/\(VaultFolderInfo.fileName)")
        #expect(try JSONSerialization.jsonObject(with: Data(contentsOf: kept)) as? [String: String] == ["colour": "red"])
        try #"{"icon": "atom"}"#.write(to: kept, atomically: true, encoding: .utf8)
        try await vault.setIcon(nil, forFolder: renamed)
        #expect(!FileManager.default.fileExists(atPath: kept.path))
        await vault.reload()
        #expect(vault.root.folder(at: renamed)?.icon == nil)
    }

    @Test func foldersKeepTheIconTheyWereGivenAsRemn() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let physics = try await vault.createFolder(named: "Physics", in: "")
        let legacy = root.appendingPathComponent("Physics/\(VaultFolderInfo.legacyFileName)")
        try #"{"icon": "atom", "colour": "red"}"#.write(to: legacy, atomically: true, encoding: .utf8)
        await vault.reload()
        #expect(vault.root.folder(at: physics)?.icon == "atom")
        #expect(vault.root.folder(at: physics)?.notes.isEmpty == true)

        // The next change writes the new file, keeps what the old one held, and drops the old one.
        try await vault.setIcon("magnet", forFolder: physics)
        let info = root.appendingPathComponent("Physics/\(VaultFolderInfo.fileName)")
        let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: info)) as? [String: String]
        #expect(saved == ["icon": "magnet", "colour": "red"])
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        await vault.reload()
        #expect(vault.root.folder(at: physics)?.icon == "magnet")
    }

    @Test func attachmentsLiveBesideTheNoteAndStayOutOfTheTree() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let folder = try await vault.createFolder(named: "Biology", in: "")
        let note = try await vault.createNote(in: folder, title: "Cell")
        let link = try await vault.saveAttachment(Data([0x89, 0x50]), fileExtension: "png", forNoteAt: note)
        #expect(link.hasPrefix("attachments/image-"))
        #expect(!link.contains(" "))
        #expect(vault.resolveLink(link, fromNoteAt: note)?.lastPathComponent == VaultPath.name(of: link))
        #expect(vault.resolveLink("../../etc/passwd", fromNoteAt: note) == nil)

        await vault.reload()
        #expect(vault.root.folder(at: folder)?.folders.isEmpty == true)
    }
}
