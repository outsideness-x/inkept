import SwiftUI

/// Where a note stands among the others: a small map of the notes round it, the notes that link to it
/// with the line each link is written in, the notes it links to, and what it names that isn't written yet.
/// Beside the note on the Mac and iPad, a sheet on iPhone.
struct NoteLinksPanel: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass

    let path: String
    /// Opens another note.
    let onOpen: (String) -> Void
    let onClose: () -> Void

    @State private var links: NoteLinks?
    @State private var mentions: [String: [NoteMention]] = [:]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let links {
                        if links.isEmpty {
                            empty
                        } else {
                            map
                            incoming(links.incoming)
                            if !links.outgoing.isEmpty {
                                outgoing(links.outgoing)
                            }
                            if !links.missing.isEmpty {
                                missing(links.missing)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .paperBackground()
        .task(id: "\(path)|\(vault.revision)") { await load() }
    }

    private func load() async {
        let found = NoteLinks(root: vault.root, path: path)
        links = found
        // Only the notes that link here are read again, for the lines their links are written in.
        for note in found.incoming.prefix(40) {
            guard let body = try? await vault.load(note.path).body, !Task.isCancelled else { continue }
            let lines = NoteOutline.mentions(in: body) { found.leadsHere($0, from: note.path) }
            if mentions[note.path] != lines { mentions[note.path] = lines }
        }
    }

    // MARK: - Parts

    private var header: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            if sizeClass == .compact {
                SheetGrabber()
            }
            #endif
            HStack(spacing: 8) {
                InkIcon(kind: .links, color: .inkeptInk, size: 21)
                HandwrittenText("notes.links", weight: 0.4)
                    .font(InkeptTypography.navigationTitle)
                    .foregroundStyle(Color.inkeptInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                InkIconButton(kind: .close, label: "close", color: .inkeptGraphite, size: 15, action: onClose)
            }
            .padding(.leading, 18)
            .padding(.trailing, 6)
            .padding(.top, 6)
        }
    }

    private var map: some View {
        let seed = path.inkSeed
        return NoteGraphView(scope: .note(path)) { route in
            if case .note(let target) = route { onOpen(target) }
        }
        .frame(height: 230)
        .background {
            InkPatch(seed: seed ^ 0x51, cornerRadius: 16)
                .fill(Color.inkeptCardPaper)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            InkRoundedRect(seed: seed ^ 0x52, cornerRadius: 16, pen: .fine)
                .fill(Color.inkeptInk.opacity(0.75))
                .allowsHitTesting(false)
        }
        .padding(.top, 8)
    }

    private func incoming(_ notes: [NoteSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("notes.links.incoming", count: notes.count)
            if notes.isEmpty {
                HandwrittenText("notes.links.incoming.none")
                    .font(InkeptTypography.note)
                    .foregroundStyle(Color.inkeptGraphite)
            }
            ForEach(notes) { note in
                Button { onOpen(note.path) } label: {
                    LinkedNoteRow(note: note, icon: icon(for: note), mentions: mentions[note.path] ?? [])
                }
                .buttonStyle(InkRowStyle())
            }
        }
    }

    private func outgoing(_ notes: [NoteSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("notes.links.outgoing", count: notes.count)
            ForEach(notes) { note in
                Button { onOpen(note.path) } label: {
                    LinkedNoteRow(note: note, icon: icon(for: note), showsSnippet: true)
                }
                .buttonStyle(InkRowStyle())
            }
        }
    }

    private func missing(_ names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("notes.links.missing", count: names.count)
            ForEach(names, id: \.self) { name in
                HStack(spacing: 10) {
                    InkDashedRing(seed: name.inkSeed, pen: InkPen(width: 1.3))
                        .fill(Color.inkeptGraphite)
                        .allowsHitTesting(false)
                        .frame(width: 17, height: 17)
                        .frame(width: 22)
                    HandwrittenText(verbatim: name)
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptInk)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    // `[[Folder/Name]]` points at a place; only a bare name can be written beside this note.
                    if !name.contains("/") {
                        Button { write(name) } label: {
                            HandwrittenText("notes.graph.write")
                        }
                        .buttonStyle(InkButtonStyle(kind: .quiet, seed: name.inkSeed))
                    }
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            InkIcon(kind: .links, color: .inkeptGraphite, size: 46)
            HandwrittenText("notes.links.empty", weight: 0.3)
                .font(InkeptTypography.control)
                .foregroundStyle(Color.inkeptInk)
            HandwrittenText("notes.links.empty.hint \(VaultPath.title(ofNoteNamed: VaultPath.name(of: path)))")
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 8)
    }

    private func sectionTitle(_ title: LocalizedStringKey, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            HandwrittenText(title, weight: 0.4)
                .font(InkeptTypography.control)
                .foregroundStyle(Color.inkeptInk)
            HandwrittenText(verbatim: "\(count)")
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
        }
        .padding(.top, 22)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func icon(for note: NoteSummary) -> String? {
        vault.root.icon(forFolder: note.folderPath)
    }

    /// Writes the note a link names, beside this one, and opens it.
    private func write(_ name: String) {
        Task {
            do {
                let made = try await vault.createNote(in: VaultPath.parent(of: path), title: name)
                onOpen(made)
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }
}

/// A note in the panel: its subject's icon and title, then the lines that link here, or what it says.
private struct LinkedNoteRow: View {
    let note: NoteSummary
    let icon: String?
    var mentions: [NoteMention] = []
    var showsSnippet = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SubjectIconSlot(icon: icon, fallback: .list, size: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                HandwrittenText(verbatim: note.title, weight: 0.3)
                    .font(InkeptTypography.display(19, relativeTo: .headline))
                    .foregroundStyle(Color.inkeptInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                ForEach(Array(mentions.enumerated()), id: \.offset) { index, mention in
                    HandwrittenText(text: Text(mention.attributed))
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptGraphite)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 10)
                        .overlay(alignment: .leading) {
                            InkLine(seed: note.path.inkSeed &+ index, pen: .hairline, vertical: true)
                                .fill(Color.inkeptAccent.opacity(0.55))
                                .allowsHitTesting(false)
                                .frame(width: 4)
                        }
                }
                if showsSnippet, !note.snippet.isEmpty {
                    HandwrittenText(verbatim: note.snippet)
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptGraphite)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension NoteMention {
    /// The line as it reads, with the link's own words in red pencil.
    var attributed: AttributedString {
        pieces.reduce(into: AttributedString()) { text, piece in
            var run = AttributedString(piece.text)
            if piece.isLink { run.foregroundColor = .inkeptAccent }
            text += run
        }
    }
}
