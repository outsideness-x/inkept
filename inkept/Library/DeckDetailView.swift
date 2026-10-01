import SwiftData
import SwiftUI

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \Flashcard.createdAt) private var cards: [Flashcard]
    @Bindable var deck: Deck

    @State private var showCreateCard = false
    @State private var manageCard: Flashcard?
    @State private var editingCard: Flashcard?
    @State private var deleteCard: Flashcard?
    @State private var resetCard: Flashcard?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: deck.subject?.name) {
                InkIconButton(kind: .plus, label: "card.new") { showCreateCard = true }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: deck.name)
                    if deckCards.isEmpty {
                        QuietEmptyState(
                            title: "card.empty",
                            actionTitle: "card.make",
                            action: { showCreateCard = true }
                        )
                        .padding(.top, 24)
                    } else {
                        HandwrittenText("count.cards \(deckCards.count)")
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                            .padding(.top, 14)
                        LazyVStack(spacing: 14) {
                            ForEach(deckCards, id: \.id) { card in
                                NavigationLink {
                                    CardDetailView(card: card)
                                } label: {
                                    CardRow(card: card)
                                }
                                .buttonStyle(InkRowStyle())
                                .overlay(alignment: .topTrailing) {
                                    InkIconButton(kind: .more, label: "actions", color: .remnGraphite, size: 19) {
                                        manageCard = card
                                    }
                                    .padding(.top, 2)
                                    .padding(.trailing, 8)
                                }
                                .remnContextMenu(cardActions(for: card))
                            }
                        }
                        .padding(.top, 16)
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
            appState.currentDeckID = deck.id
            appState.currentSubjectID = deck.subject?.id
        }
        .safeAreaInset(edge: .bottom) {
            if !deckCards.isEmpty {
                Button {
                    if let subjectID = deck.subject?.id {
                        appState.prepareStudy(subjectIDs: [subjectID], deckID: deck.id)
                    }
                } label: {
                    HandwrittenText("study.deck", weight: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .primary, seed: deck.id.inkSeed))
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, RemnPlatform.bottomButtonPadding)
                .remnReadableWidth(600)
                .background(alignment: .bottom) { PaperFade() }
            }
        }
        .sheet(isPresented: $showCreateCard) {
            CardEditorView(initialDeck: deck)
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(initialDeck: deck, card: card)
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageCard != nil },
                set: { if !$0 { manageCard = nil } }
            ),
            title: "card",
            message: Text(verbatim: manageCard.map { RemnFormatters.usefulLine($0.frontMarkdown) } ?? ""),
            actions: cardActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteCard != nil },
                set: { if !$0 { deleteCard = nil } }
            ),
            title: "card.delete.title",
            message: Text("card.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteCard { context.delete(deleteCard); save() }
                    deleteCard = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteCard = nil }
            ]
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { resetCard != nil },
                set: { if !$0 { resetCard = nil } }
            ),
            title: "card.reset.title",
            message: Text("card.reset.message"),
            actions: [
                HandmadeDialogAction("card.reset", role: .destructive) {
                    if let resetCard {
                        do { try ReviewService().reset(resetCard, context: context) }
                        catch { appState.errorMessage = error.localizedDescription }
                    }
                    resetCard = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { resetCard = nil }
            ]
        )
    }

    private var cardActions: [HandmadeDialogAction] {
        guard let card = manageCard else { return [] }
        return cardActions(for: card) + [
            HandmadeDialogAction("cancel", role: .cancel) { manageCard = nil }
        ]
    }

    private func cardActions(for card: Flashcard) -> [HandmadeDialogAction] {
        [
            HandmadeDialogAction("edit", role: .plain) {
                manageCard = nil
                editingCard = card
            },
            HandmadeDialogAction("card.duplicate", role: .plain) { duplicate(card) },
            HandmadeDialogAction("card.reset", role: .plain) {
                manageCard = nil
                resetCard = card
            },
            HandmadeDialogAction("delete", role: .destructive) {
                manageCard = nil
                deleteCard = card
            }
        ]
    }

    private func duplicate(_ card: Flashcard) {
        context.insert(
            Flashcard(
                deck: deck,
                frontMarkdown: card.frontMarkdown,
                backMarkdown: card.backMarkdown
            )
        )
        save()
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }

    private var deckCards: [Flashcard] {
        cards.filter { $0.deck?.id == deck.id }
    }
}
