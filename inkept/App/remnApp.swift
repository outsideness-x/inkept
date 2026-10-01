import SwiftData
import SwiftUI

@main
struct remnApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @State private var vault: Vault
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
            container = try LibraryStore.makeContainer()
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
            .tint(.remnAccent)
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
        .commands { RemnCommands() }

    }

    @ViewBuilder
    private var content: some View {
        if let container {
            RootView()
                .modelContainer(container)
                .environment(vault)
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
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.remnGraphite)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
    }
}
