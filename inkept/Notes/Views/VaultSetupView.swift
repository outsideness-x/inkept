import SwiftUI
import UniformTypeIdentifiers

/// The first time notes are opened: where should they live?
struct VaultSetupView: View {
    @Environment(Vault.self) private var vault
    @Environment(\.dismiss) private var dismiss
    /// Shown from settings as a sheet, with a way out.
    var isSheet = false

    @State private var pickingFolder = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if isSheet {
                SheetHeader(title: "notes.setup.sheetTitle") { dismiss() }
            }
            ScrollView {
                VStack(spacing: 26) {
                    NotebookDoodle(width: 80)
                        .padding(.top, isSheet ? 12 : 36)
                    VStack(spacing: 10) {
                        HandwrittenText("notes.setup.title", weight: 0.6)
                            .font(RemnTypography.display(32, relativeTo: .title))
                            .foregroundStyle(Color.remnInk)
                            .multilineTextAlignment(.center)
                        HandwrittenText("notes.setup.message")
                            .font(RemnTypography.body)
                            .foregroundStyle(Color.remnGraphite)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .inkWritesOn(duration: 0.6)

                    VStack(spacing: 14) {
                        option(
                            seed: 8_101,
                            icon: .cloud,
                            title: "notes.setup.icloud",
                            note: VaultLocation.isICloudAvailable ? "notes.setup.icloud.note" : "notes.setup.icloud.off",
                            isCurrent: vault.location?.kind == .iCloud,
                            isEnabled: VaultLocation.isICloudAvailable
                        ) {
                            choose(.iCloud)
                        }
                        #if os(iOS)
                        option(
                            seed: 8_102,
                            icon: .download,
                            title: "notes.setup.device",
                            note: "notes.setup.device.note",
                            isCurrent: vault.location?.kind == .device,
                            isEnabled: true
                        ) {
                            choose(.device)
                        }
                        #endif
                        option(
                            seed: 8_103,
                            icon: .forward,
                            title: "notes.setup.folder",
                            note: "notes.setup.folder.note",
                            isCurrent: vault.location?.kind == .folder,
                            isEnabled: true
                        ) {
                            pickingFolder = true
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .remnReadableWidth(540)
            }
            .scrollIndicators(.hidden)
        }
        .paperBackground()
        .remnSheetFrame(width: 560, height: 700)
        .fileImporter(isPresented: $pickingFolder, allowedContentTypes: [.folder]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                choose(try VaultLocation.folder(url))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .handmadeDialog(
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }),
            title: "error",
            message: Text(verbatim: errorMessage ?? ""),
            actions: [HandmadeDialogAction("ok") { errorMessage = nil }]
        )
    }

    private func choose(_ location: VaultLocation) {
        vault.choose(location)
        if isSheet { dismiss() }
    }

    private func option(
        seed: Int,
        icon: InkIconKind,
        title: LocalizedStringKey,
        note: LocalizedStringKey,
        isCurrent: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                InkIcon(kind: icon, color: isCurrent ? .remnAccent : .remnInk, size: 24)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        HandwrittenText(title, weight: 0.3)
                            .font(RemnTypography.control)
                            .foregroundStyle(Color.remnInk)
                        if isCurrent {
                            InkIcon(kind: .check, color: .remnAccent, size: 16)
                        }
                    }
                    HandwrittenText(note)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                InkBox(
                    seed: seed,
                    cornerRadius: 16,
                    fill: .remnCardPaper,
                    outline: isCurrent ? .remnAccent : .remnInk,
                    pen: .fine,
                    registration: CGSize(width: 1.4, height: 2)
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Opening the notes folder, or explaining why it couldn't be opened.
struct VaultStatusView: View {
    @Environment(Vault.self) private var vault
    @State private var showSetup = false

    var body: some View {
        switch vault.status {
        case .unconfigured:
            VaultSetupView()
        case .opening, .ready:
            VStack(spacing: 16) {
                NotebookDoodle(width: 56)
                HandwrittenText("notes.opening")
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnGraphite)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paperBackground()
        case .failed(let message):
            VStack(spacing: 18) {
                NotebookDoodle(width: 70)
                HandwrittenText("notes.failed")
                    .font(RemnTypography.sectionTitle)
                    .foregroundStyle(Color.remnInk)
                HandwrittenText(verbatim: message)
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button { vault.open() } label: { HandwrittenText("notes.retry") }
                        .buttonStyle(InkButtonStyle(kind: .secondary, seed: 8_120))
                    Button { showSetup = true } label: { HandwrittenText("notes.chooseAnother") }
                        .buttonStyle(InkButtonStyle(kind: .quiet, seed: 8_121))
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paperBackground()
            .sheet(isPresented: $showSetup) { VaultSetupView(isSheet: true) }
        }
    }
}
