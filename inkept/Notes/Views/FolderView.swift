import SwiftUI

/// A folder of notes: the folders inside it, then its notes, most recently touched first.
/// The notes folder itself is the first page of the notes tab.
struct FolderView: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.inkeptIsNavigationRoot) private var isColumnRoot

    let path: String
    /// The first page of the notes tab on iPhone, with the tab bar under it.
    var isTabRoot = false

    @State private var showNewFolder = false
    @State private var renaming = false
    @State private var showActions = false
    @State private var confirmDelete = false
    @State private var manageFolder: VaultFolder?
    @State private var renameFolder: VaultFolder?
    @State private var iconFolder: VaultFolder?
    @State private var deleteFolder: VaultFolder?
    @AppStorage("notesViewMode") private var mode: NotesViewMode = .list

    private var folder: VaultFolder? { vault.root.folder(at: path) }

    /// The way the notes are shown; an empty folder is always a list, with its one thing to do.
    private var shownMode: NotesViewMode {
        guard let folder, folder.totalNoteCount > 0 else { return .list }
        return mode
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isTabRoot {
                InkeptNavigationHeader(backTitle: backTitle) {
                    HStack(spacing: 0) {
                        InkIconButton(kind: .plus, label: "notes.new") { createNote() }
                        InkIconButton(kind: .more, label: "actions") { showActions = true }
                    }
                }
            }
            if shownMode == .graph {
                // The map needs the page to itself, so only the title and the choice of view stay above it.
                VStack(alignment: .leading, spacing: 0) {
                    heading
                    modePicker
                }
                .padding(.horizontal, 22)
                .padding(.top, isTabRoot ? 6 : 10)
                .inkeptReadableWidth()
                NoteGraphView(scope: .folder(path)) { route in
                    appState.notesPath.append(route)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        heading
                        if let folder {
                            if folder.totalNoteCount > 0 {
                                modePicker
                            }
                            switch shownMode {
                            case .list, .graph:
                                content(folder)
                            case .board:
                                board(folder)
                            case .timeline:
                                NoteTimeline(folder: folder)
                                    .padding(.top, 14)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, isTabRoot ? 6 : 10)
                    .padding(.bottom, 40)
                    .inkeptReadableWidth(shownMode == .board ? 1_060 : 640)
                }
            }
        }
        .paperBackground()
        .inkeptHidesSystemBar()
        .onAppear { appState.currentNotesFolder = path }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Button(action: createNote) {
                    HStack(spacing: 12) {
                        NotebookDoodle(ink: .inkeptOnAccent, accent: .inkeptOnAccent, paper: .inkeptAccent, width: 22)
                        HandwrittenText("notes.new", weight: 0.5)
                        Spacer()
                        InkIcon(kind: .plus, color: .inkeptOnAccent, size: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .primary, seed: path.inkSeed ^ 0x77))
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, isTabRoot ? 4 : InkeptPlatform.bottomButtonPadding)
                .inkeptReadableWidth(600)
                if isTabRoot {
                    @Bindable var appState = appState
                    InkeptTabBar(selection: $appState.section)
                }
            }
            .background(alignment: .bottom) { PaperFade() }
        }
        .sheet(isPresented: $showNewFolder) {
            NameEditorSheet(title: "notes.folder.new", initialIcon: nil) { name, icon in
                Task {
                    do { try await vault.createFolder(named: name, in: path, icon: icon) }
                    catch { appState.errorMessage = error.localizedDescription }
                }
            }
        }
        .sheet(item: $renameFolder) { folder in
            NameEditorSheet(title: "notes.folder.rename", initialValue: folder.name, initialIcon: folder.icon) { name, icon in
                Task {
                    do {
                        let renamed = try await vault.renameFolder(folder.path, to: name)
                        if icon != folder.icon { try await vault.setIcon(icon, forFolder: renamed) }
                        if folder.path == path { replaceRoute(with: .folder(renamed)) }
                    } catch {
                        appState.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .sheet(item: $iconFolder) { folder in
            SubjectIconPicker(name: folder.name, selection: folder.icon) { icon in
                Task {
                    do { try await vault.setIcon(icon, forFolder: folder.path) }
                    catch { appState.errorMessage = error.localizedDescription }
                }
            }
        }
        .handmadeDialog(
            isPresented: $showActions,
            title: "notes.folder",
            message: Text(verbatim: title),
            actions: ownActions
        )
        .handmadeDialog(
            isPresented: Binding(get: { manageFolder != nil }, set: { if !$0 { manageFolder = nil } }),
            title: "notes.folder",
            message: Text(verbatim: manageFolder?.name ?? ""),
            actions: manageFolder.map { folderActions(for: $0) + [HandmadeDialogAction("cancel", role: .cancel) {}] } ?? []
        )
        .handmadeDialog(
            isPresented: Binding(get: { deleteFolder != nil }, set: { if !$0 { deleteFolder = nil } }),
            title: "notes.folder.delete.title",
            message: Text("notes.folder.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    guard let folder = deleteFolder else { return }
                    Task {
                        do {
                            try await vault.deleteFolder(folder.path)
                            if folder.path == path, !isColumnRoot { dismiss() }
                        } catch {
                            appState.errorMessage = error.localizedDescription
                        }
                    }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
    }

    // MARK: - Content

    private var title: String {
        path.isEmpty ? String(localized: "section.notes") : VaultPath.name(of: path)
    }

    private var backTitle: String {
        let parent = VaultPath.parent(of: path)
        return parent.isEmpty ? String(localized: "section.notes") : VaultPath.name(of: parent)
    }

    @ViewBuilder
    private var heading: some View {
        if isTabRoot {
            rootHeader
        } else {
            ScreenTitle(title: title, icon: folder?.icon) {
                iconFolder = folder
            }
        }
    }

    /// List, board, graph or timeline: circled like any other choice.
    private var modePicker: some View {
        InkChoiceRow(
            selection: $mode,
            options: NotesViewMode.allCases.map { .init(value: $0, title: Text($0.title)) },
            seed: 8_700
        )
        .frame(maxWidth: 460, alignment: .leading)
        .padding(.horizontal, -6)
        .padding(.top, isTabRoot ? 0 : 4)
    }

    private func board(_ folder: VaultFolder) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HandwrittenText("count.notes \(folder.totalNoteCount)")
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
            NoteBoard(folder: folder)
                .padding(.top, 22)
        }
    }

    private var rootHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            ScreenTitle(title: String(localized: "section.notes"))
            Spacer()
            NavigationLink(value: NotesRoute.tag("")) {
                InkIcon(kind: .search, size: 23)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(Text("search"))
            InkIconButton(kind: .more, label: "actions") { showActions = true }
        }
        .padding(.trailing, -10)
    }

    @ViewBuilder
    private func content(_ folder: VaultFolder) -> some View {
        let total = folder.totalNoteCount
        if folder.folders.isEmpty, folder.notes.isEmpty {
            VStack(spacing: 24) {
                NotebookDoodle(width: 84)
                HandwrittenText(path.isEmpty ? "notes.empty.root" : "notes.empty.folder")
                    .font(InkeptTypography.sectionTitle)
                    .foregroundStyle(Color.inkeptInk)
                    .multilineTextAlignment(.center)
                if path.isEmpty {
                    Button { showNewFolder = true } label: {
                        HandwrittenText("notes.folder.make")
                    }
                    .buttonStyle(InkButtonStyle(kind: .secondary, seed: 8_201))
                }
            }
            .inkWritesOn(duration: 0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        } else {
            HandwrittenText("count.notes \(total)")
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
                .padding(.top, isTabRoot ? 2 : 14)

            if isTabRoot, !vault.tags.isEmpty {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(vault.tags.prefix(12), id: \.tag) { item in
                        NavigationLink(value: NotesRoute.tag(item.tag)) {
                            TagChip(tag: item.tag, count: item.count)
                        }
                        .buttonStyle(InkPressStyle())
                    }
                }
                .padding(.top, 14)
            }

            if !folder.folders.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(Array(folder.folders.enumerated()), id: \.element.id) { index, child in
                        if index > 0 { InkDivider(seed: child.path.inkSeed) }
                        HStack(spacing: 0) {
                            NavigationLink(value: NotesRoute.folder(child.path)) {
                                FolderRow(folder: child)
                            }
                            .buttonStyle(InkRowStyle())
                            InkIconButton(kind: .more, label: "actions", color: .inkeptGraphite, size: 20) {
                                manageFolder = child
                            }
                            .padding(.trailing, -10)
                        }
                        .inkeptContextMenu(folderActions(for: child))
                    }
                }
                .padding(.top, 18)
            }

            if path.isEmpty || !folder.folders.isEmpty {
                Button { showNewFolder = true } label: {
                    HStack(spacing: 8) {
                        InkIcon(kind: .plus, color: .inkeptAccent, size: 18)
                        HandwrittenText("notes.folder.new")
                    }
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 8_202))
                .padding(.leading, -10)
                .padding(.top, 6)
            }

            if !folder.notes.isEmpty {
                LazyVStack(spacing: 14) {
                    ForEach(folder.notes) { note in
                        NavigationLink(value: NotesRoute.note(note.path)) {
                            NoteRow(note: note)
                        }
                        .buttonStyle(InkRowStyle())
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Actions

    private var ownActions: [HandmadeDialogAction] {
        var actions = [
            HandmadeDialogAction("notes.folder.new", role: .plain) { showNewFolder = true }
        ]
        if !path.isEmpty, let folder {
            actions += folderActions(for: folder, includesNew: false)
        }
        return actions + [HandmadeDialogAction("cancel", role: .cancel) {}]
    }

    private func folderActions(for folder: VaultFolder, includesNew: Bool = false) -> [HandmadeDialogAction] {
        [
            HandmadeDialogAction("rename", role: .plain) { renameFolder = folder },
            HandmadeDialogAction("icon.choose", role: .plain) { iconFolder = folder },
            HandmadeDialogAction("delete", role: .destructive) { deleteFolder = folder },
        ]
    }

    private func createNote() {
        Task {
            do {
                let note = try await vault.createNote(in: path)
                appState.notesPath.append(.note(note))
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func replaceRoute(with route: NotesRoute) {
        if let index = appState.notesPath.lastIndex(of: .folder(path)) {
            appState.notesPath[index] = route
        }
    }
}

/// A folder in a list: its name and how many notes it holds, counting the folders inside it.
struct FolderRow: View {
    let folder: VaultFolder
    var compact = false

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 14) {
            SubjectIconSlot(icon: folder.icon, size: compact ? 28 : 38)
            VStack(alignment: .leading, spacing: compact ? 2 : 5) {
                HandwrittenText(verbatim: folder.name, weight: 0.3)
                    .font(compact ? InkeptTypography.display(22, relativeTo: .title3) : InkeptTypography.rowTitle)
                    .foregroundStyle(Color.inkeptInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    HandwrittenText("count.notes \(folder.totalNoteCount)")
                    if !folder.folders.isEmpty {
                        HandwrittenText(verbatim: "·")
                            .accessibilityHidden(true)
                        HandwrittenText("count.folders \(folder.folders.count)")
                    }
                }
                .font(compact ? InkeptTypography.caption : InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 10 : 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Every note with one tag — or, with an empty tag, every note there is, to search through.
struct TagNotesView: View {
    @Environment(Vault.self) private var vault
    let tag: String
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            InkeptNavigationHeader(backTitle: String(localized: "section.notes"))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if tag.isEmpty {
                        searchField
                    } else {
                        ScreenTitle(title: "#\(tag)")
                    }
                    HandwrittenText("count.notes \(notes.count)")
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptGraphite)
                        .padding(.top, 14)
                    LazyVStack(spacing: 14) {
                        ForEach(notes) { note in
                            NavigationLink(value: NotesRoute.note(note.path)) {
                                NoteRow(note: note, showsFolder: true, folderIcon: vault.root.icon(forFolder: note.folderPath))
                            }
                            .buttonStyle(InkRowStyle())
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 40)
                .inkeptReadableWidth()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .paperBackground()
        .inkeptHidesSystemBar()
        .onAppear { if tag.isEmpty { searchFocused = true } }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            InkIcon(kind: .search, color: .inkeptGraphite, size: 21)
            TextField("notes.search.placeholder", text: $query)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .font(InkeptTypography.display(24, relativeTo: .title3))
                .foregroundStyle(Color.inkeptInk)
                .tint(.inkeptAccent)
                .focused($searchFocused)
            if !query.isEmpty {
                InkIconButton(kind: .close, label: "search.clear", color: .inkeptGraphite, size: 15) { query = "" }
                    .padding(.trailing, -12)
            }
        }
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            InkLine(seed: 8_301, pen: .fine)
                .fill(Color.inkeptInk.opacity(0.55))
                .allowsHitTesting(false)
                .frame(height: 6)
                .offset(y: 2)
        }
    }

    private var notes: [NoteSummary] {
        let all = vault.root.allNotes.sorted { $0.modified > $1.modified }
        if !tag.isEmpty {
            return all.filter { $0.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame } }
        }
        let clean = query.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return all }
        return all.filter { note in
            [note.title, note.snippet, note.folderPath, note.tags.joined(separator: " ")]
                .contains { $0.localizedStandardContains(clean) }
        }
    }
}
