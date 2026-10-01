import Foundation
import Observation
import SwiftUI

/// Something asked for from a menu or a keyboard shortcut, handled by whichever view owns it.
enum AppCommand: Equatable {
    case newSubject
    case newCard
    case newNote
    case newFolder
    case search
}

/// Where the notes column is, as a path the navigation stack can follow.
enum NotesRoute: Hashable {
    case folder(String)
    case tag(String)
    case note(String)
}

@MainActor
@Observable
final class AppState {
    var presentedSession: StudySessionRecord?
    var errorMessage: String?
    var showStudySetup = false
    var preselectedSubjectIDs: Set<UUID> = []
    var preselectedDeckID: UUID?
    var requestedCommand: AppCommand?
    var section: AppSection = .cards
    /// On iPad and the Mac, settings open beside the sidebar instead of what was chosen in it.
    var showsSettings = false
    var notesPath: [NotesRoute] = []
    /// The folder on screen in notes, so a new note lands where you're looking.
    var currentNotesFolder = ""

    /// The subject and deck on screen, so a new card lands where you're looking.
    var currentSubjectID: UUID?
    var currentDeckID: UUID?

    /// Opens a note from anywhere, like the card it was made into.
    func openNote(_ path: String) {
        section = .notes
        notesPath = [.note(path)]
    }

    func prepareStudy(subjectIDs: Set<UUID> = [], deckID: UUID? = nil) {
        preselectedSubjectIDs = subjectIDs
        preselectedDeckID = deckID
        showStudySetup = true
    }
}

extension FocusedValues {
    /// The state of the window in front, for menu commands.
    @Entry var remnAppState: AppState?
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
