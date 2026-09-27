import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// One note, open: its title, its tags and the live editor, saved to its file as you write.
struct NoteView: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var path: String
    @State private var title: String
    @State private var document = NoteDocument()
    @State private var controller = LiveEditorController(font: .default)
    @State private var isLoaded = false
    @State private var savedText = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var loadError: String?

    @State private var showActions = false
    @State private var confirmDelete = false
    @State private var showMove = false
    @State private var showFonts = false
    @State private var showTags = false
    @State private var cardDraft: CardDraft?
    @State private var chooseImageSource = false
    @State private var pickingPhoto = false
    @State private var pickingImageFile = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showTypstGallery = false
    /// What the note is linked with. On the Mac it's a column beside the note that stays open from note
    /// to note; elsewhere it's opened for one note at a time.
    @AppStorage("notes.showsLinks") private var showsLinksBeside = false
    @State private var showsLinksHere = false

    /// A passage of the note on its way to becoming a flashcard.
    private struct CardDraft: Identifiable {
        let id = UUID()
        let text: String
    }

    init(path: String) {
        _path = State(initialValue: path)
        _title = State(initialValue: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)))
    }

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: folderTitle) {
                HStack(spacing: 0) {
                    InkIconButton(kind: .links, label: "notes.links") { showsLinks.wrappedValue.toggle() }
                    InkIconButton(kind: .typeface, label: "notes.font") { showFonts = true }
                    InkIconButton(kind: .more, label: "actions") { showActions = true }
                }
            }
            if let loadError {
                VStack(spacing: 16) {
                    NotebookDoodle(width: 60)
                    HandwrittenText(verbatim: loadError)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .multilineTextAlignment(.center)
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LiveEditorView(controller: controller) {
                    NoteHeader(
                        title: $title,
                        tags: document.frontMatter.tags,
                        inlineTags: NoteText.inlineTags(in: controller.text),
                        font: controller.font,
                        folder: VaultPath.parent(of: path),
                        onCommitTitle: commitTitle,
                        onEditTags: { showTags = true },
                        onFinishTitle: { controller.host?.hostFocus() }
                    )
                }
                .opacity(isLoaded ? 1 : 0)
            }
        }
        .paperBackground()
        .remnHidesSystemBar()
        .safeAreaInset(edge: .bottom) {
            if isLoaded, showsToolbar {
                NoteToolbar(controller: controller, onInsertTypst: { showTypstGallery = true }, onInsertImage: {
                    #if os(iOS)
                    chooseImageSource = true
                    #else
                    pickingImageFile = true
                    #endif
                })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: controller.isFocused)
        .task(id: path) { await load() }
        #if DEBUG
        .task {
            // Design reviews: `-showLinks` opens a note with what it's linked with, once it has slid in.
            guard ProcessInfo.processInfo.arguments.contains("-showLinks") else { return }
            try? await Task.sleep(for: .milliseconds(800))
            showsLinks.wrappedValue = true
        }
        #endif
        .onChange(of: vault.revision) { _, _ in
            Task { await reloadIfChangedElsewhere() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { Task { await saveNow() } }
        }
        .onDisappear {
            Task { await saveNow() }
        }
        .onAppear {
            appState.currentNotesFolder = VaultPath.parent(of: path)
        }
        .handmadeDialog(
            isPresented: $showActions,
            title: "notes.note",
            message: Text(verbatim: title),
            actions: noteActions
        )
        .handmadeDialog(
            isPresented: $confirmDelete,
            title: "notes.delete.title",
            message: Text("notes.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) { delete() },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: $showMove,
            title: "notes.move.title",
            message: nil,
            actions: moveActions
        )
        .sheet(isPresented: $showFonts) {
            FontPickerSheet(selection: Binding(get: { controller.font }, set: { setFont($0) }))
        }
        .handmadeDialog(
            isPresented: $chooseImageSource,
            title: "insert.image",
            message: nil,
            actions: [
                HandmadeDialogAction("insert.image.photos", role: .plain) { pickingPhoto = true },
                HandmadeDialogAction("insert.image.files", role: .plain) { pickingImageFile = true },
                HandmadeDialogAction("cancel", role: .cancel) {},
            ]
        )
        .photosPicker(isPresented: $pickingPhoto, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { await insertImage(data) }
            }
        }
        .fileImporter(isPresented: $pickingImageFile, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
            guard let urls = try? result.get() else { return }
            Task {
                for url in urls {
                    let accessing = url.startAccessingSecurityScopedResource()
                    let data = try? Data(contentsOf: url)
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    if let data { await insertImage(data) }
                }
            }
        }
        .sheet(isPresented: $showTypstGallery) {
            TypstGallerySheet { source in
                // A blank block is for writing in; a template is shown drawn straight away.
                if source.isEmpty {
                    controller.apply(.typst("$ E = m c^2 $"))
                } else {
                    controller.apply(.typst(source.trimmingCharacters(in: .whitespacesAndNewlines)), cursorAfter: true)
                }
            }
        }
        .sheet(item: $cardDraft) { draft in
            CardEditorView(fromNote: path, selection: draft.text)
        }
        .sheet(isPresented: $showTags) {
            TagEditorSheet(tags: Binding(get: { document.frontMatter.tags }, set: { setTags($0) }))
        }
        .inspector(isPresented: showsLinks) {
            NoteLinksPanel(path: path, onOpen: openLinked, onClose: { showsLinks.wrappedValue = false })
                .inspectorColumnWidth(min: 270, ideal: 320, max: 460)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
        }
    }

    private var showsLinks: Binding<Bool> {
        RemnPlatform.isMac ? $showsLinksBeside : $showsLinksHere
    }

    private var showsToolbar: Bool {
        RemnPlatform.isMac || controller.isFocused
    }

    private var folderTitle: String {
        let folder = VaultPath.parent(of: path)
        return folder.isEmpty ? String(localized: "section.notes") : VaultPath.name(of: folder)
    }

    // MARK: - Loading and saving

    private func load() async {
        configureEditor()
        // A rename or a move changes the path but not what's being written.
        guard !isLoaded else { return }
        do {
            let loaded = try await vault.load(path)
            document = loaded
            savedText = loaded.text
            controller.font = NoteFont(frontMatter: loaded.frontMatter.font)
            controller.setText(loaded.body)
            isLoaded = true
            if loaded.body.isEmpty, title == String(localized: "notes.note.untitled") {
                // A note that was just made: its title takes the cursor once the page has slid in.
                try? await Task.sleep(for: .milliseconds(350))
                controller.host?.hostFocusHeader()
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func configureEditor() {
        controller.onTextChange = { _ in scheduleSave() }
        controller.onMakeCard = { text in cardDraft = CardDraft(text: text) }
        controller.onPasteImage = { data in Task { await insertImage(data) } }
        controller.onOpenLink = { target in openLink(target) }
        controller.renderer.resolveImage = { [vault, path] link in vault.resolveLink(link, fromNoteAt: path) }
        controller.renderer.noteFolder = vault.url(for: VaultPath.parent(of: path))
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await saveNow()
            // Nothing waits to be saved any more, so changes from other devices can come in again.
            if !Task.isCancelled { saveTask = nil }
        }
    }

    private func saveNow() async {
        guard isLoaded else { return }
        var updated = document
        updated.body = controller.text
        let text = updated.text
        guard text != savedText else { return }
        do {
            try await vault.save(updated, to: path)
            document = updated
            savedText = text
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    /// Picks up an edit made on another device or in another app, unless there's unsaved writing here.
    private func reloadIfChangedElsewhere() async {
        guard isLoaded, controller.text == document.body, saveTask == nil else { return }
        guard let fresh = try? await vault.load(path) else { return }
        guard fresh.text != savedText else { return }
        document = fresh
        savedText = fresh.text
        controller.font = NoteFont(frontMatter: fresh.frontMatter.font)
        controller.setText(fresh.body)
    }

    // MARK: - Links

    /// Web links open in the browser; `[[a note]]` opens that note, and makes it first, as Obsidian does,
    /// when there's none by that name yet.
    private func openLink(_ target: LiveEditorController.LinkTarget) {
        switch target {
        case .web(let url):
            openURL(url)
        case .note(let name):
            if let linked = vault.root.notePath(linkedAs: name, from: path) {
                appState.notesPath.append(.note(linked))
                return
            }
            let title = VaultPath.sanitized(name.components(separatedBy: "#")[0])
            guard !title.isEmpty, !name.contains("/") else { return }
            Task {
                do {
                    let made = try await vault.createNote(in: VaultPath.parent(of: path), title: title)
                    appState.notesPath.append(.note(made))
                } catch {
                    appState.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Goes to a note from the links panel, which on iPhone and iPad is closed on the way.
    private func openLinked(_ target: String) {
        if !RemnPlatform.isMac { showsLinksHere = false }
        appState.notesPath.append(.note(target))
    }

    // MARK: - Pictures

    /// Saves a picture beside the note and puts it where the cursor is, on a line of its own.
    private func insertImage(_ data: Data) async {
        guard let prepared = await Task.detached(operation: { ImageAttachment.prepare(data) }).value else { return }
        do {
            let link = try await vault.saveAttachment(prepared.data, fileExtension: prepared.fileExtension, forNoteAt: path)
            controller.insert("![](\(link))", asBlock: true)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Title, tags and font

    private func commitTitle() {
        let clean = VaultPath.sanitized(title)
        guard !clean.isEmpty else {
            title = VaultPath.title(ofNoteNamed: VaultPath.name(of: path))
            return
        }
        guard clean != VaultPath.title(ofNoteNamed: VaultPath.name(of: path)) else { return }
        Task {
            await saveNow()
            do {
                path = try await vault.renameNote(path, to: clean)
                title = VaultPath.title(ofNoteNamed: VaultPath.name(of: path))
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func setTags(_ tags: [String]) {
        document.frontMatter.tags = FrontMatter.cleaned(tags)
        Task { await saveNow() }
    }

    private func setFont(_ font: NoteFont) {
        controller.font = font
        document.frontMatter.font = font == .default ? nil : font.rawValue
        Task { await saveNow() }
    }

    // MARK: - Actions

    private var noteActions: [HandmadeDialogAction] {
        var actions = [
            HandmadeDialogAction("notes.tags", role: .plain) { showTags = true },
            HandmadeDialogAction("notes.font", role: .plain) { showFonts = true },
            HandmadeDialogAction("notes.move", role: .plain) { showMove = true },
        ]
        #if os(macOS)
        actions.append(HandmadeDialogAction("notes.revealInFinder", role: .plain) {
            if let url = vault.url(for: path) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        })
        #endif
        actions += [
            HandmadeDialogAction("delete", role: .destructive) { confirmDelete = true },
            HandmadeDialogAction("cancel", role: .cancel) {},
        ]
        return actions
    }

    private var moveActions: [HandmadeDialogAction] {
        let current = VaultPath.parent(of: path)
        let folders = [(path: "", name: String(localized: "section.notes"), depth: 0)]
            + vault.root.flattened().map { (path: $0.folder.path, name: $0.folder.name, depth: $0.depth + 1) }
        return folders.map { folder in
            let indent = String(repeating: "   ", count: folder.depth)
            return HandmadeDialogAction(verbatim: indent + folder.name, role: folder.path == current ? .normal : .plain) {
                move(to: folder.path)
            }
        } + [HandmadeDialogAction("cancel", role: .cancel) {}]
    }

    private func move(to folder: String) {
        Task {
            await saveNow()
            do {
                path = try await vault.moveNote(path, toFolder: folder)
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func delete() {
        saveTask?.cancel()
        isLoaded = false
        Task {
            do {
                try await vault.deleteNote(path)
                dismiss()
                if let index = appState.notesPath.lastIndex(of: .note(path)) {
                    appState.notesPath.remove(at: index)
                }
            } catch {
                isLoaded = true
                appState.errorMessage = error.localizedDescription
            }
        }
    }
}

/// The top of a note: its title, written large, and its tags.
struct NoteHeader: View {
    @Binding var title: String
    let tags: [String]
    let inlineTags: [String]
    let font: NoteFont
    let folder: String
    let onCommitTitle: () -> Void
    let onEditTags: () -> Void
    let onFinishTitle: () -> Void

    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("notes.title.placeholder", text: $title, axis: .vertical)
                    .font(titleFont)
                    .foregroundStyle(Color.remnInk)
                    .tint(.remnAccent)
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
                    .onChange(of: title) { _, value in
                        // Return ends the title rather than starting a new line.
                        guard value.contains("\n") else { return }
                        title = value.replacingOccurrences(of: "\n", with: "")
                        onFinishTitle()
                    }
                    .onChange(of: titleFocused) { _, focused in
                        if !focused { onCommitTitle() }
                    }
                    // Moving the cursor into the note ends the title; unfocusing the field as well would race
                    // it and, on the Mac, leave nothing focused at all.
                    .onSubmit(onFinishTitle)
                TitleSwash(seed: title.inkSeed)
            }

            let shownTags = FrontMatter.cleaned(tags + inlineTags)
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(shownTags, id: \.self) { tag in
                    Button(action: onEditTags) { TagChip(tag: tag) }
                        .buttonStyle(InkPressStyle())
                }
                Button(action: onEditTags) {
                    HStack(spacing: 4) {
                        InkIcon(kind: .plus, color: .remnGraphite, size: 13)
                        HandwrittenText(shownTags.isEmpty ? "notes.tags.add" : "notes.tags.edit")
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(InkPressStyle())
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleFont: Font {
        switch font {
        case .neucha: RemnTypography.display(RemnPlatform.isMac ? 34 : 36, relativeTo: .largeTitle)
        default: font.font(size: RemnPlatform.isMac ? 28 : 30, relativeTo: .largeTitle).weight(.semibold)
        }
    }
}
