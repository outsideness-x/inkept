import Foundation
#if os(macOS)
import AppKit
#endif

/// The language inkept speaks: English, unless Russian is chosen in Settings. Everything reads it once, as
/// the app starts — the strings, the system's own menus and panels, the way dates are written — so a new
/// choice takes effect when inkept next opens. It's kept where the system keeps a language chosen for one
/// app, so a choice made in the system's settings shows up here too.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    /// Its name in itself, so it can be read whichever language is on screen.
    var name: String {
        switch self {
        case .english: "English"
        case .russian: "русский"
        }
    }

    /// The language on screen now.
    static var current: AppLanguage {
        language(of: Bundle.main.preferredLocalizations.first)
    }

    /// The language inkept opens in next.
    static var chosen: AppLanguage {
        get { language(of: UserDefaults.standard.stringArray(forKey: key)?.first) }
        set { UserDefaults.standard.set([newValue.rawValue], forKey: key) }
    }

    /// Chooses English the first time inkept opens; the system would otherwise follow the device's own
    /// languages. Called before anything reads a string, so that first launch is in English too.
    static func settle() {
        guard let domain = Bundle.main.bundleIdentifier,
              UserDefaults.standard.persistentDomain(forName: domain)?[key] == nil
        else { return }
        chosen = .english
    }

    /// A string from the catalog in this language, whatever language is on screen.
    func localized(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return Bundle.main.localizedString(forKey: key, value: nil, table: nil) }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    #if os(macOS)
    /// Opens inkept afresh and closes this one, so a new language takes effect straight away.
    @MainActor
    static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        Task {
            guard (try? await NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration)) != nil
            else { return }
            NSApp.terminate(nil)
        }
    }
    #endif

    /// Where the system keeps the languages an app speaks, best first.
    private static let key = "AppleLanguages"

    private static func language(of code: String?) -> AppLanguage {
        guard let code else { return .english }
        return allCases.first { code.hasPrefix($0.rawValue) } ?? .english
    }
}
