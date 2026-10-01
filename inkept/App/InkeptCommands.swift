import SwiftUI

/// The menu bar on the Mac, and the shortcuts a hardware keyboard shows on iPad.
struct InkeptCommands: Commands {
    @FocusedValue(\.inkeptAppState) private var appState
    @AppStorage("notesViewMode") private var notesViewMode: NotesViewMode = .list
    @AppStorage("notes.showsLinks") private var showsNoteLinks = false

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("menu.settings") { appState?.showsSettings = true }
                .keyboardShortcut(",")
                .disabled(appState == nil)
        }
        CommandGroup(replacing: .newItem) {
            if appState?.section == .notes {
                Button("menu.newNote") { appState?.requestedCommand = .newNote }
                    .keyboardShortcut("n")
                Button("menu.newFolder") { appState?.requestedCommand = .newFolder }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            } else {
                Button("menu.newCard") { appState?.requestedCommand = .newCard }
                    .keyboardShortcut("n")
                    .disabled(appState == nil)
                Button("menu.newSubject") { appState?.requestedCommand = .newSubject }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .disabled(appState == nil)
            }
        }
        CommandGroup(before: .sidebar) {
            Button("menu.showCards") { appState?.section = .cards }
                .keyboardShortcut("1")
                .disabled(appState == nil)
            Button("menu.showNotes") { appState?.section = .notes }
                .keyboardShortcut("2")
                .disabled(appState == nil)
            Divider()
            if appState?.section == .notes {
                ForEach(Array(NotesViewMode.allCases.enumerated()), id: \.element) { index, mode in
                    Toggle(mode.menuTitle, isOn: Binding(get: { notesViewMode == mode }, set: { if $0 { notesViewMode = mode } }))
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command, .option])
                }
                #if os(macOS)
                Button(showsNoteLinks ? "menu.hideLinks" : "menu.showLinks") { showsNoteLinks.toggle() }
                    .keyboardShortcut("l", modifiers: [.command, .option])
                #endif
                Divider()
            }
        }
        CommandGroup(after: .textEditing) {
            Button(appState?.section == .notes ? "menu.searchNotes" : "menu.search") { appState?.requestedCommand = .search }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(appState == nil)
        }
        CommandMenu("menu.study") {
            Button("menu.startStudying") { appState?.prepareStudy() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState == nil || appState?.presentedSession != nil)
        }
    }
}
