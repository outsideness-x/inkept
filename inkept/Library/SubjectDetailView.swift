import SwiftData
import SwiftUI

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Bindable var subject: SubjectModel

    @State private var showCreate = false
    @State private var showIcons = false
    @State private var manageDeck: Deck?
    @State private var renameDeck: Deck?
    @State private var deleteDeck: Deck?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: String(localized: "library")) {
                InkIconButton(kind: .plus, label: "deck.new") { showCreate = true }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: subject.name, icon: subject.icon) { showIcons = true }
                    if subject.allDecks.isEmpty {
                        QuietEmptyState(
                            title: "deck.empty",
                            actionTitle: "deck.make",
                            action: { showCreate = true }
                        )
                        .padding(.top, 24)
                    } else {
                        deckList
                            .padding(.top, 22)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 40)
                .remnReadableWidth()
            }
        }
        .paperBackground()
        .remnHidesSystemBar()
        .onAppear {
            appState.currentSubjectID = subject.id
            appState.currentDeckID = nil
        }
        .safeAreaInset(edge: .bottom) {
            if !subject.cards.isEmpty {
                Button {
                    appState.prepareStudy(subjectIDs: [subject.id])
                } label: {
                    HandwrittenText("study.subject", weight: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .primary, seed: subject.id.inkSeed))
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, RemnPlatform.bottomButtonPadding)
                .remnReadableWidth(600)
                .background(alignment: .bottom) { PaperFade() }
            }
        }
        .sheet(isPresented: $showCreate) {
            NameEditorSheet(title: "deck.new") { name in
                let order = (subject.allDecks.map(\.manualSortOrder).max() ?? -1) + 1
                context.insert(Deck(subject: subject, name: name, manualSortOrder: order))
                subject.updatedAt = .now
                save()
            }
        }
        .sheet(isPresented: $showIcons) {
            SubjectIconPicker(name: subject.name, selection: subject.icon) { icon in
                subject.icon = icon
                subject.updatedAt = .now
                save()
            }
        }
        .sheet(item: $renameDeck) { deck in
            NameEditorSheet(title: "deck.rename", initialValue: deck.name) { name in
                deck.name = name
                deck.updatedAt = .now
                save()
            }
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageDeck != nil },
                set: { if !$0 { manageDeck = nil } }
            ),
            title: "deck",
            message: Text(verbatim: manageDeck?.name ?? ""),
            actions: deckActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteDeck != nil },
                set: { if !$0 { deleteDeck = nil } }
            ),
            title: "deck.delete.title",
            message: Text("deck.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteDeck { context.delete(deleteDeck); save() }
                    deleteDeck = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteDeck = nil }
            ]
        )
    }

    private var deckList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(subject.orderedDecks.enumerated()), id: \.element.id) { index, deck in
                if index > 0 {
                    InkDivider(seed: deck.id.inkSeed)
                }
                HStack(spacing: 0) {
                    NavigationLink {
                        DeckDetailView(deck: deck)
                    } label: {
                        LibraryRow(
                            title: deck.name,
                            dueCount: deck.allCards.dueTodayCount(),
                            totalCount: deck.allCards.count
                        )
                    }
                    .buttonStyle(InkRowStyle())

                    InkIconButton(kind: .more, label: "actions", color: .remnGraphite, size: 20) {
                        manageDeck = deck
                    }
                    .padding(.trailing, -10)
                }
                .remnContextMenu(deckActions(for: deck))
            }
        }
    }

    private var deckActions: [HandmadeDialogAction] {
        guard let deck = manageDeck else { return [] }
        return deckActions(for: deck) + [
            HandmadeDialogAction("cancel", role: .cancel) { manageDeck = nil }
        ]
    }

    private func deckActions(for deck: Deck) -> [HandmadeDialogAction] {
        var actions = [
            HandmadeDialogAction("rename", role: .plain) {
                manageDeck = nil
                renameDeck = deck
            }
        ]
        let decks = subject.orderedDecks
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            if index > decks.startIndex {
                actions.append(
                    HandmadeDialogAction("move.up", role: .plain) { move(deck, by: -1) }
                )
            }
            if index < decks.index(before: decks.endIndex) {
                actions.append(
                    HandmadeDialogAction("move.down", role: .plain) { move(deck, by: 1) }
                )
            }
        }
        actions.append(
            HandmadeDialogAction("delete", role: .destructive) {
                manageDeck = nil
                deleteDeck = deck
            }
        )
        return actions
    }

    private func move(_ deck: Deck, by offset: Int) {
        let decks = subject.orderedDecks
        guard let index = decks.firstIndex(where: { $0.id == deck.id }) else { return }
        let destination = index + offset
        guard decks.indices.contains(destination) else { return }
        let other = decks[destination]
        let oldOrder = deck.manualSortOrder
        deck.manualSortOrder = other.manualSortOrder
        other.manualSortOrder = oldOrder
        save()
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }
}
