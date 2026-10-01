import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Bindable var card: Flashcard

    @State private var showEditor = false
    @State private var showActions = false
    @State private var showDelete = false
    @State private var showReset = false
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: card.deck?.name) {
                InkIconButton(kind: .more, label: "actions") { showActions = true }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FlashcardSurface(seed: card.id.inkSeed) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .firstTextBaseline) {
                                FlashcardSideLabel(title: "card.front")
                                Spacer()
                                HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                                    .font(RemnTypography.note)
                                    .foregroundStyle(isDue ? Color.remnAccent : Color.remnGraphite)
                            }
                            IndexRule(seed: card.id.inkSeed ^ 0x11)
                                .padding(.top, 4)
                                .padding(.bottom, 14)
                            CardContentView(markdown: card.frontMarkdown)
                            InkDashes(seed: card.id.inkSeed ^ 0x22)
                                .fill(Color.remnGraphite.opacity(0.6))
                                .frame(height: 6)
                                .padding(.vertical, 18)
                                .accessibilityHidden(true)
                            FlashcardSideLabel(title: "card.back")
                                .padding(.bottom, 10)
                            CardContentView(markdown: card.backMarkdown)
                        }
                    }
                    HandwrittenText(verbatim: history)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .padding(.horizontal, 4)
                    if let notePath = card.sourceNotePath {
                        Button { appState.openNote(notePath) } label: {
                            HStack(spacing: 10) {
                                NotebookDoodle(width: 18)
                                HandwrittenText("card.fromNote")
                                    .foregroundStyle(Color.remnGraphite)
                                HandwrittenText(verbatim: VaultPath.title(ofNoteNamed: VaultPath.name(of: notePath)))
                                    .foregroundStyle(Color.remnAccent)
                                    .lineLimit(1)
                                InkIcon(kind: .forward, color: .remnAccent, size: 15)
                            }
                            .font(RemnTypography.note)
                        }
                        .buttonStyle(InkPressStyle())
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
                .remnReadableWidth()
            }
        }
        .paperBackground()
        .remnHidesSystemBar()
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        StackedCardsDoodle(width: 48)
                        HandwrittenText("export.saving")
                            .font(RemnTypography.control)
                            .foregroundStyle(Color.remnInk)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 22)
                    .background { InkBox(seed: 688, cornerRadius: 14) }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExporting)
        .sheet(isPresented: $showEditor) {
            if let deck = card.deck { CardEditorView(initialDeck: deck, card: card) }
        }
        .handmadeDialog(
            isPresented: $showActions,
            title: "card",
            message: Text(verbatim: RemnFormatters.usefulLine(card.frontMarkdown)),
            actions: cardActions
        )
        .handmadeDialog(
            isPresented: $showDelete,
            title: "card.delete.title",
            message: Text("card.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    context.delete(card)
                    do { try context.save(); dismiss() }
                    catch { appState.errorMessage = error.localizedDescription }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: $showReset,
            title: "card.reset.title",
            message: Text("card.reset.message"),
            actions: [
                HandmadeDialogAction("card.reset", role: .destructive) {
                    do { try ReviewService().reset(card, context: context) }
                    catch { appState.errorMessage = error.localizedDescription }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { exportMessage != nil },
                set: { if !$0 { exportMessage = nil } }
            ),
            title: "export.result",
            message: Text(verbatim: exportMessage ?? ""),
            actions: [
                HandmadeDialogAction("ok") { exportMessage = nil }
            ]
        )
    }

    private var isDue: Bool {
        card.state != .new && card.due <= .now
    }

    private var history: String {
        guard card.state != .new else { return String(localized: "card.notStudied") }
        let reviews = String(localized: "count.reviews \(card.allReviewLogs.count)")
        let next = card.due <= .now
            ? String(localized: "card.dueNow")
            : String(localized: "card.nextReview \(card.due.formatted(.dateTime.month(.wide).day()).lowercased())")
        return "\(next)  ·  \(reviews)"
    }

    private func duplicate() {
        guard let deck = card.deck else { return }
        context.insert(
            Flashcard(deck: deck, frontMarkdown: card.frontMarkdown, backMarkdown: card.backMarkdown)
        )
        do { try context.save() }
        catch { appState.errorMessage = error.localizedDescription }
    }

    private var cardActions: [HandmadeDialogAction] {
        [
            HandmadeDialogAction("edit", role: .plain) {
                showActions = false
                showEditor = true
            },
            HandmadeDialogAction("card.duplicate", role: .plain, perform: duplicate),
            HandmadeDialogAction("card.saveImage", role: .plain, perform: export),
            HandmadeDialogAction("card.reset", role: .plain) {
                showActions = false
                showReset = true
            },
            HandmadeDialogAction("delete", role: .destructive) {
                showActions = false
                showDelete = true
            },
            HandmadeDialogAction("cancel", role: .cancel) { showActions = false }
        ]
    }

    private func export() {
        isExporting = true
        Task { @MainActor in
            defer { isExporting = false }
            do {
                exportMessage = try await CardImageExporter.save(card)
            } catch {
                exportMessage = error.localizedDescription
            }
        }
    }
}
