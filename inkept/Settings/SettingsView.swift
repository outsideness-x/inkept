import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState: AppState?
    @Environment(\.remnIsNavigationRoot) private var isColumnRoot
    @AppStorage("desiredRetention") private var desiredRetention = 0.90
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    @State private var exportDocument = BackupDocument()
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showSRSExplanation = false
    @State private var resultMessage: String?
    @State private var showVaultSetup = false

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: String(localized: "library")) {
                if isColumnRoot {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { appState?.showsSettings = false }
                    } label: {
                        HandwrittenText("done", weight: 0.4)
                    }
                    .buttonStyle(InkButtonStyle(kind: .quiet, seed: 145))
                    .keyboardShortcut(.cancelAction)
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: String(localized: "settings"))
                    section("settings.study") { studySettings }
                        .padding(.top, 28)
                    section("settings.appearance") { appearancePicker }
                        .padding(.top, 38)
                    section("settings.notes") { notesSettings }
                        .padding(.top, 38)
                    section("settings.data") { dataSettings }
                        .padding(.top, 38)
                    section("settings.about") { AboutCard() }
                        .padding(.top, 38)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 44)
                .remnReadableWidth()
            }
        }
        .paperBackground()
        .remnHidesSystemBar()
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            switch result {
            case .success: resultMessage = String(localized: "backup.exported")
            case .failure(let error): resultMessage = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            importBackup(result)
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            ),
            title: "backup.result",
            message: Text(verbatim: resultMessage ?? ""),
            actions: [
                HandmadeDialogAction("ok") { resultMessage = nil }
            ]
        )
        .sheet(isPresented: $showSRSExplanation) {
            SRSExplainerSheet()
        }
        .sheet(isPresented: $showVaultSetup) {
            VaultSetupView(isSheet: true)
        }
    }

    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HandwrittenText(title, weight: 0.4)
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .accessibilityAddTraits(.isHeader)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var studySettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HandwrittenText("settings.retention")
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnInk)
                Spacer()
                HandwrittenText(verbatim: desiredRetention.formatted(.percent.precision(.fractionLength(0))), weight: 0.6)
                    .font(RemnTypography.display(26, relativeTo: .title3))
                    .foregroundStyle(Color.remnAccent)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: desiredRetention)
            }
            InkSlider(
                value: $desiredRetention,
                range: 0.70...0.97,
                step: 0.01,
                accessibilityLabel: Text("settings.retention"),
                marks: [0.90]
            )
            HandwrittenText("settings.retention.help")
                .font(RemnTypography.note)
                .foregroundStyle(Color.remnGraphite)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Button { showSRSExplanation = true } label: {
                HStack(spacing: 8) {
                    HandwrittenText("settings.srs.open")
                    InkIcon(kind: .forward, color: .remnAccent, size: 17)
                }
            }
            .buttonStyle(InkButtonStyle(kind: .quiet, seed: 144))
            .padding(.leading, -10)
        }
    }

    private var appearancePicker: some View {
        InkChoiceRow(
            selection: $appearanceMode,
            options: [
                .init(value: AppearanceMode.system.rawValue, title: Text("appearance.system")),
                .init(value: AppearanceMode.light.rawValue, title: Text("appearance.light")),
                .init(value: AppearanceMode.dark.rawValue, title: Text("appearance.dark")),
            ],
            seed: 380
        )
    }

    private var dataSettings: some View {
        VStack(spacing: 0) {
            syncRow
            InkDivider(seed: 111)
            dataRow("backup.export", note: "backup.export.note", icon: .upload, action: exportBackup)
            InkDivider(seed: 112)
            dataRow("backup.import", note: "backup.import.note", icon: .download) {
                showImporter = true
            }
        }
    }

    private var notesSettings: some View {
        Button { showVaultSetup = true } label: {
            HStack(alignment: .top, spacing: 14) {
                InkIcon(kind: vault.location?.kind == .iCloud ? .cloud : .folder, color: .remnInk, size: 24)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HandwrittenText(verbatim: vaultTitle)
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnInk)
                    HandwrittenText("settings.notes.change")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnAccent)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkRowStyle())
    }

    private var vaultTitle: String {
        switch vault.location?.kind {
        case .iCloud: String(localized: "notes.setup.icloud")
        case .device: String(localized: "notes.setup.device")
        case .folder: vault.rootURL?.lastPathComponent ?? String(localized: "notes.setup.folder")
        case nil: String(localized: "settings.notes.none")
        }
    }

    /// Whether the library is mirrored to iCloud; turning it off happens in the system's iCloud settings.
    private var syncRow: some View {
        let isSignedIn = FileManager.default.ubiquityIdentityToken != nil
        return HStack(alignment: .top, spacing: 14) {
            InkIcon(kind: .cloud, color: isSignedIn ? .remnInk : .remnGraphite, size: 24)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                HandwrittenText("sync.icloud")
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnInk)
                HandwrittenText(isSignedIn ? "sync.on" : "sync.off")
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func dataRow(
        _ title: LocalizedStringKey,
        note: LocalizedStringKey,
        icon: InkIconKind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                InkIcon(kind: icon, color: .remnInk, size: 22)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HandwrittenText(title)
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnInk)
                    HandwrittenText(note)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkRowStyle())
    }

    private var backupFilename: String {
        let date = Date.now.formatted(.iso8601.year().month().day())
        return "remn-backup-\(date)"
    }

    private func exportBackup() {
        do {
            let data = try BackupService.export(
                context: context,
                settings: BackupSettings(
                    desiredRetention: desiredRetention,
                    appearanceMode: appearanceMode
                )
            )
            exportDocument = BackupDocument(data: data)
            showExporter = true
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let archive = try BackupService.decode(Data(contentsOf: url))
            let settings = try BackupService.importArchive(archive, context: context)
            desiredRetention = settings.desiredRetention
            appearanceMode = settings.appearanceMode
            resultMessage = String(localized: "backup.imported")
        } catch {
            resultMessage = error.localizedDescription
        }
    }
}

/// The colophon: what remn is, and whose cards these are.
private struct AboutCard: View {
    var body: some View {
        FlashcardSurface(seed: 734, style: .regular) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    HandwrittenText("remn", weight: 1)
                        .font(RemnTypography.display(40, relativeTo: .title))
                        .foregroundStyle(Color.remnInk)
                    Spacer()
                    StackedCardsDoodle(width: 50)
                }
                HandwrittenText("about.tagline")
                    .font(RemnTypography.body)
                    .foregroundStyle(Color.remnInk)
                    .fixedSize(horizontal: false, vertical: true)
                InkDashes(seed: 735)
                    .fill(Color.remnGraphite.opacity(0.6))
                    .frame(height: 6)
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        HandwrittenText("about.openSource")
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnInk)
                        HandwrittenText(verbatim: versionText)
                            .font(RemnTypography.caption)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    Spacer()
                    HandwrittenText(verbatim: "MIT", weight: 0.8)
                        .font(RemnTypography.display(24, relativeTo: .title3))
                        .foregroundStyle(Color.remnAccent)
                        .inkCircled(seed: 738, inset: CGSize(width: -12, height: -6))
                        .rotationEffect(.degrees(-4))
                        .padding(.trailing, 10)
                        .accessibilityLabel(Text("about.mit"))
                }
                HandwrittenText("about.ownership")
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return String(localized: "about.version \(version) \(build)")
    }
}
