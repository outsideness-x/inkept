import SwiftData
import SwiftUI

@main
struct inkeptApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @State private var vault: Vault
    /// The card library's place in the notes folder; none for the demo library, which stays in memory.
    @State private var library: LibraryFolder?
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        #if DEBUG
        _vault = State(initialValue: DemoLibrary.isRequested ? DemoLibrary.makeVault() : Vault())
        #else
        _vault = State(initialValue: Vault())
        #endif
        do {
            #if DEBUG
            if DemoLibrary.isRequested {
                container = try DemoLibrary.makeContainer()
                startupError = nil
                return
            }
            #endif
            let container = try LibraryStore.makeContainer()
            self.container = container
            _library = State(initialValue: LibraryFolder(context: container.mainContext))
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-inkLab") {
                    InkLab()
                } else {
                    content
                }
                #else
                content
                #endif
            }
            .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
            .tint(.inkeptAccent)
            #if DEBUG && os(macOS)
            .onAppear {
                WindowSnapshot.scheduleIfRequested()
                TypingProbe.scheduleIfRequested()
            }
            #endif
            #if os(macOS)
            .frame(minWidth: 760, minHeight: 540)
            // The window keeps its close, minimise and zoom buttons over the paper; nothing else sits up there.
            .toolbarBackground(.hidden, for: .windowToolbar)
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 780)
        .windowBackgroundDragBehavior(.enabled)
        #endif
        .commands { InkeptCommands() }

    }

    @ViewBuilder
    private var content: some View {
        if let container {
            RootView()
                .modelContainer(container)
                .environment(vault)
                .modifier(LibraryFolderLink(library: library, vault: vault))
        } else {
            StartupFailureView(message: startupError ?? String(localized: "storage.error"))
        }
    }
}

private struct StartupFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            StackedCardsDoodle(width: 84)
            HandwrittenText("storage.couldNotOpen", weight: 0.6)
                .font(InkeptTypography.sectionTitle)
                .foregroundStyle(Color.inkeptInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.inkeptGraphite)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
    }
}

/// Keeps the card library in the notes folder while the app runs: opens it along with the folder,
/// reads it again whenever the app comes back, and finishes writing when the app goes away.
private struct LibraryFolderLink: ViewModifier {
    let library: LibraryFolder?
    let vault: Vault
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        if let library {
            content
                .environment(library)
                .task(id: vault.libraryIdentity) {
                    if let folder = vault.rootURL, let identity = vault.libraryIdentity {
                        await library.attach(to: folder, identity: identity)
                    } else {
                        library.detach()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active: Task { await library.refresh() }
                    case .background: Task { await library.flush() }
                    default: break
                    }
                }
        } else {
            content
        }
    }
}
