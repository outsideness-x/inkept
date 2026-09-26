import SwiftUI

/// How a folder's notes are shown.
enum NotesViewMode: String, CaseIterable, Identifiable {
    /// Folders, then notes, most recently touched first.
    case list
    /// Pages pinned to a board, with the pictures and formulas they open with.
    case board
    /// A map of how the notes link to one another and to their subjects.
    case graph
    /// Notes by the day they were written, and the rhythm of the last weeks.
    case timeline

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .list: "notes.view.list"
        case .board: "notes.view.board"
        case .graph: "notes.view.graph"
        case .timeline: "notes.view.timeline"
        }
    }
}

/// What the notes sidebar has chosen for the page beside it.
enum NotesSidebarItem: Hashable {
    case folder(String)
    case tag(String)
    case search
}

/// Where a route in the notes column leads.
struct NotesDestination: View {
    let route: NotesRoute

    var body: some View {
        switch route {
        case .folder(let path): FolderView(path: path)
        case .tag(let tag): TagNotesView(tag: tag)
        case .note(let path): NoteView(path: path).id(path)
        }
    }
}

/// The notes tab on iPhone: the notes folder, and everything opened from it.
struct NotesTab: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $appState.notesPath) {
            Group {
                if vault.status == .ready {
                    FolderView(path: "", isTabRoot: true)
                } else {
                    VaultStatusView()
                        .safeAreaInset(edge: .bottom) {
                            RemnTabBar(selection: $appState.section)
                        }
                        .remnHidesSystemBar()
                }
            }
            .navigationDestination(for: NotesRoute.self) { route in
                NotesDestination(route: route)
            }
        }
        .notesCommands()
    }
}

/// The notes side of the split layout: folders and tags down the side, the chosen one beside them.
struct NotesSplitDetail: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    let selection: NotesSidebarItem?

    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $appState.notesPath) {
            Group {
                if vault.status != .ready {
                    VaultStatusView()
                        .remnHidesSystemBar()
                } else {
                    switch selection {
                    case .folder, nil:
                        FolderView(path: folderPath)
                            .id(folderPath)
                    case .tag(let tag):
                        TagNotesView(tag: tag)
                    case .search:
                        TagNotesView(tag: "")
                    }
                }
            }
            .environment(\.remnIsNavigationRoot, true)
            .navigationDestination(for: NotesRoute.self) { route in
                NotesDestination(route: route)
            }
        }
        .notesCommands()
    }

    private var folderPath: String {
        if case .folder(let path) = selection { return path }
        return ""
    }
}

/// The sidebar for notes on iPad and the Mac: the folder tree, then tags.
struct NotesSidebar: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    @Binding var selection: NotesSidebarItem?

    @State private var expanded: Set<String> = []
    @State private var showNewFolder = false
    @State private var newFolderParent = ""
    @State private var renameFolder: VaultFolder?
    @State private var iconFolder: VaultFolder?
    @State private var deleteFolder: VaultFolder?

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SidebarHeader(
                    section: $appState.section,
                    searchSelected: selection == .search,
                    onSearch: { selection = .search }
                )
                if vault.status == .ready {
                    tree
                        .padding(.top, 18)
                    tags
                        .padding(.top, 26)
                } else {
                    HandwrittenText("notes.sidebar.setup")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .padding(.top, 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, RemnPlatform.isMac ? 30 : 6)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.never)
        .paperBackground()
        .remnHidesSystemBar()
        .sheet(isPresented: $showNewFolder) {
            NameEditorSheet(title: "notes.folder.new", initialIcon: nil) { name, icon in
                Task {
                    do {
                        let folder = try await vault.createFolder(named: name, in: newFolderParent, icon: icon)
                        expanded.insert(newFolderParent)
                        selection = .folder(folder)
                    } catch {
                        appState.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .sheet(item: $renameFolder) { folder in
            NameEditorSheet(title: "notes.folder.rename", initialValue: folder.name, initialIcon: folder.icon) { name, icon in
                Task {
                    do {
                        let renamed = try await vault.renameFolder(folder.path, to: name)
                        if icon != folder.icon { try await vault.setIcon(icon, forFolder: renamed) }
                        if selection == .folder(folder.path) { selection = .folder(renamed) }
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
            isPresented: Binding(get: { deleteFolder != nil }, set: { if !$0 { deleteFolder = nil } }),
            title: "notes.folder.delete.title",
            message: Text("notes.folder.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    guard let folder = deleteFolder else { return }
                    Task {
                        do {
                            try await vault.deleteFolder(folder.path)
                            if case .folder(let path) = selection, path == folder.path || path.hasPrefix(folder.path + "/") {
                                selection = .folder("")
                            }
                        } catch {
                            appState.errorMessage = error.localizedDescription
                        }
                    }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .onChange(of: appState.requestedCommand) { _, command in
            guard command == .newFolder else { return }
            appState.requestedCommand = nil
            newFolderParent = currentFolder
            showNewFolder = true
        }
        .onChange(of: selection) { _, item in
            if case .folder(let path) = item { expandAncestors(of: path) }
        }
    }

    private var currentFolder: String {
        if case .folder(let path) = selection { return path }
        return ""
    }

    // MARK: - Folders

    private var tree: some View {
        VStack(alignment: .leading, spacing: 4) {
            row(
                title: String(localized: "notes.all"),
                count: vault.root.totalNoteCount,
                depth: 0,
                path: "",
                icon: nil,
                hasChildren: false,
                item: .folder("")
            )
            ForEach(visibleFolders, id: \.folder.id) { entry in
                row(
                    title: entry.folder.name,
                    count: entry.folder.totalNoteCount,
                    depth: entry.depth,
                    path: entry.folder.path,
                    icon: entry.folder.icon,
                    hasChildren: !entry.folder.folders.isEmpty,
                    item: .folder(entry.folder.path)
                )
                .remnContextMenu(actions(for: entry.folder))
            }
            Button {
                newFolderParent = ""
                showNewFolder = true
            } label: {
                HStack(spacing: 8) {
                    InkIcon(kind: .plus, color: .remnAccent, size: 18)
                    HandwrittenText("notes.folder.new")
                }
            }
            .buttonStyle(InkButtonStyle(kind: .quiet, seed: 8_602))
            .padding(.leading, -10)
            .padding(.top, 4)
        }
    }

    private var visibleFolders: [(folder: VaultFolder, depth: Int)] {
        vault.root.flattened().filter { entry in
            var parent = VaultPath.parent(of: entry.folder.path)
            while !parent.isEmpty {
                if !expanded.contains(parent) { return false }
                parent = VaultPath.parent(of: parent)
            }
            return true
        }
    }

    private func row(
        title: String,
        count: Int,
        depth: Int,
        path: String,
        icon: String?,
        hasChildren: Bool,
        item: NotesSidebarItem
    ) -> some View {
        let isSelected = selection == item && !appState.showsSettings
        return Button {
            selection = item
            appState.showsSettings = false
        } label: {
            HStack(spacing: 6) {
                if hasChildren {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            if expanded.contains(path) { expanded.remove(path) } else { expanded.insert(path) }
                        }
                    } label: {
                        InkIcon(kind: expanded.contains(path) ? .down : .forward, color: .remnGraphite, size: 12)
                            .frame(width: 18, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(InkPressStyle())
                } else {
                    Color.clear.frame(width: 18, height: 28)
                }
                if path.isEmpty {
                    NotebookDoodle(ink: .remnGraphite, accent: .remnAccent, width: 17)
                        .frame(width: 24, height: 24)
                } else {
                    SubjectIconSlot(icon: icon, size: depth == 0 ? 24 : 21)
                }
                HandwrittenText(verbatim: title, weight: depth == 0 ? 0.3 : 0)
                    .font(depth == 0 ? RemnTypography.display(22, relativeTo: .title3) : RemnTypography.display(20, relativeTo: .body))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(1)
                Spacer(minLength: 6)
                HandwrittenText(verbatim: "\(count)")
                    .font(RemnTypography.caption)
                    .foregroundStyle(Color.remnGraphite)
            }
            .padding(.leading, 6 + CGFloat(depth) * 16)
            .padding(.trailing, 12)
            .padding(.vertical, 7)
        }
        .buttonStyle(SidebarRowStyle(isSelected: isSelected, seed: path.inkSeed ^ 0x5A))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func actions(for folder: VaultFolder) -> [HandmadeDialogAction] {
        [
            HandmadeDialogAction("notes.folder.newInside", role: .plain) {
                newFolderParent = folder.path
                showNewFolder = true
            },
            HandmadeDialogAction("rename", role: .plain) { renameFolder = folder },
            HandmadeDialogAction("icon.choose", role: .plain) { iconFolder = folder },
            HandmadeDialogAction("delete", role: .destructive) { deleteFolder = folder },
        ]
    }

    private func expandAncestors(of path: String) {
        var parent = VaultPath.parent(of: path)
        while !parent.isEmpty {
            expanded.insert(parent)
            parent = VaultPath.parent(of: parent)
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private var tags: some View {
        let tags = vault.tags
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HandwrittenText("notes.tags", weight: 0.3)
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnGraphite)
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(tags, id: \.tag) { item in
                        Button {
                            selection = .tag(item.tag)
                            appState.showsSettings = false
                        } label: {
                            TagChip(tag: item.tag, count: item.count, isSelected: selection == .tag(item.tag) && !appState.showsSettings)
                        }
                        .buttonStyle(InkPressStyle())
                    }
                }
            }
        }
    }
}

private struct NotesCommands: ViewModifier {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content.onChange(of: appState.requestedCommand) { _, command in
            guard command == .newNote, appState.section == .notes, vault.status == .ready else { return }
            appState.requestedCommand = nil
            let folder = appState.currentNotesFolder
            Task {
                do {
                    let note = try await vault.createNote(in: folder)
                    appState.notesPath.append(.note(note))
                } catch {
                    appState.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension View {
    /// New notes from the menu bar or the sidebar land in the folder on screen and open at once.
    func notesCommands() -> some View {
        modifier(NotesCommands())
    }
}
