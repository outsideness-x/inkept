import SwiftData
import SwiftUI

struct CardEditorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case edit
        case preview
        var id: String { rawValue }
    }

    enum Side: Equatable { case front, back }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \Deck.name) private var decks: [Deck]
    @AppStorage("lastNoteCardDeckID") private var lastNoteCardDeckID = ""

    private let card: Flashcard?
    /// The note a new card is being made from, and the subject its folder suggests.
    private let sourceNotePath: String?
    private let suggestedSubject: String?
    private let initialFront: String
    private let initialBack: String
    @State private var selectedDeckID: UUID?
    @State private var front: String
    @State private var back: String
    @State private var showNewDeck = false
    @State private var frontSelection: TextSelection?
    @State private var backSelection: TextSelection?
    @State private var mode = Mode.edit
    @State private var showDeckPicker = false
    @State private var confirmDiscard = false
    @FocusState private var focusedSide: Side?

    init(initialDeck: Deck, card: Flashcard? = nil) {
        self.card = card
        sourceNotePath = card?.sourceNotePath
        suggestedSubject = nil
        initialFront = card?.frontMarkdown ?? ""
        initialBack = card?.backMarkdown ?? ""
        _selectedDeckID = State(initialValue: card?.deck?.id ?? initialDeck.id)
        _front = State(initialValue: initialFront)
        _back = State(initialValue: initialBack)
    }

    /// A new card from a passage of a note; the passage goes on the front, and can be swapped to the back.
    init(fromNote notePath: String, selection: String) {
        card = nil
        sourceNotePath = notePath
        let folder = notePath.split(separator: "/").dropLast().first.map(String.init)
        suggestedSubject = folder
        initialFront = selection
        initialBack = ""
        _selectedDeckID = State(initialValue: nil)
        _front = State(initialValue: selection)
        _back = State(initialValue: "")
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: card == nil ? "card.new" : "card.edit") {
                if hasChanges {
                    focusedSide = nil
                    confirmDiscard = true
                } else {
                    dismiss()
                }
            } trailing: {
                Button(action: save) {
                    HandwrittenText("save", weight: 0.4)
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 13))
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.4)
            }
            modeSwitch
                .padding(.top, 4)
            if mode == .edit { editor } else { preview }
        }
        .paperBackground()
        .onAppear(perform: chooseDeckForNote)
        .sheet(isPresented: $showNewDeck) {
            NameEditorSheet(title: "deck.new") { name in createDeck(named: name) }
        }
        .remnSheetFrame(width: 640, height: 760)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .interactiveDismissDisabled(hasChanges)
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focusedSide = nil
                } label: {
                    HandwrittenText("done")
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnAccent)
                }
            }
        }
        #endif
        .handmadeDialog(
            isPresented: $confirmDiscard,
            title: "editor.discard.title",
            message: Text("editor.discard.message"),
            actions: [
                HandmadeDialogAction("editor.discard", role: .destructive) { dismiss() },
                HandmadeDialogAction("editor.keepEditing", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: $showDeckPicker,
            title: "deck",
            message: selectedDeck.map { Text(verbatim: deckLabel($0)) },
            actions: deckActions
        )
    }

    private var modeSwitch: some View {
        HStack(spacing: 34) {
            modeButton(.edit, title: "edit")
            modeButton(.preview, title: "preview")
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: mode)
    }

    private func modeButton(_ value: Mode, title: LocalizedStringKey) -> some View {
        let chosen = mode == value
        return Button {
            focusedSide = nil
            withAnimation(.easeOut(duration: 0.18)) { mode = value }
        } label: {
            VStack(spacing: 0) {
                HandwrittenText(title, weight: chosen ? 0.5 : 0)
                    .font(RemnTypography.control)
                    .foregroundStyle(chosen ? Color.remnInk : Color.remnGraphite)
                InkUnderline(seed: value == .edit ? 71 : 72, pen: .bold, progress: chosen ? 1 : 0)
                    .fill(Color.remnAccent)
                    .frame(width: 52, height: 8)
                    .animation(.easeOut(duration: chosen ? 0.3 : 0.1), value: chosen)
            }
            .frame(minWidth: 72, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    // MARK: - Edit

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let sourceNotePath {
                    sourceRow(sourceNotePath)
                        .padding(.horizontal, 20)
                }
                deckMenu
                    .padding(.horizontal, 20)
                MarkdownToolbar(insert: insert)
                editorSection(title: "card.front", text: $front, selection: $frontSelection, side: .front)
                    .padding(.horizontal, 20)
                editorSection(title: "card.back", text: $back, selection: $backSelection, side: .back)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 14)
            .padding(.bottom, 36)
            .remnReadableWidth(680)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// Where the card comes from, and a way to put the passage on the other side.
    private func sourceRow(_ path: String) -> some View {
        HStack(spacing: 12) {
            NotebookDoodle(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                HandwrittenText("card.fromNote")
                    .font(RemnTypography.caption)
                    .foregroundStyle(Color.remnGraphite)
                HandwrittenText(verbatim: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)))
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) { swap(&front, &back) }
            } label: {
                HStack(spacing: 6) {
                    InkIcon(kind: .flip, color: .remnAccent, size: 17)
                    HandwrittenText("card.swapSides")
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .buttonStyle(InkButtonStyle(kind: .quiet, seed: 205))
            .accessibilityHint(Text("card.swapSides.hint"))
        }
    }

    private var deckMenu: some View {
        Button { showDeckPicker = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HandwrittenText("deck")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                    if selectedDeck == nil {
                        HandwrittenText(decks.isEmpty ? "deck.noneYet" : "deck.choose", weight: 0.3)
                            .font(RemnTypography.display(23, relativeTo: .body))
                            .foregroundStyle(Color.remnAccent)
                    }
                    if let selectedDeck {
                        HandwrittenText(verbatim: selectedDeck.name, weight: 0.3)
                            .font(RemnTypography.display(23, relativeTo: .body))
                            .foregroundStyle(Color.remnInk)
                            .lineLimit(1)
                        if let subject = selectedDeck.subject {
                            HandwrittenText(verbatim: subject.name)
                                .font(RemnTypography.note)
                                .foregroundStyle(Color.remnGraphite)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 8)
                InkIcon(kind: .down, color: .remnGraphite, size: 18)
                    .frame(width: 44, height: 44)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                InkDivider(seed: 204)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(InkRowStyle())
        .accessibilityLabel(Text("deck"))
        .accessibilityValue(Text(verbatim: selectedDeck.map(deckLabel) ?? ""))
    }

    private var deckActions: [HandmadeDialogAction] {
        decks.map { deck in
            HandmadeDialogAction(
                verbatim: deckLabel(deck),
                role: selectedDeckID == deck.id ? .normal : .plain
            ) {
                selectedDeckID = deck.id
                showDeckPicker = false
            }
        } + [
            HandmadeDialogAction("deck.newEllipsis", role: .plain) {
                showDeckPicker = false
                showNewDeck = true
            },
            HandmadeDialogAction("cancel", role: .cancel) { showDeckPicker = false }
        ]
    }

    /// For a card from a note: the deck used last time, else one in the subject named like the note's folder.
    private func chooseDeckForNote() {
        guard sourceNotePath != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            focusedSide = back.isEmpty ? .back : .front
        }
        guard selectedDeckID == nil else { return }
        if let last = UUID(uuidString: lastNoteCardDeckID), decks.contains(where: { $0.id == last }),
           suggestedSubject == nil || decks.first(where: { $0.id == last })?.subject?.name.localizedCaseInsensitiveCompare(suggestedSubject ?? "") == .orderedSame {
            selectedDeckID = last
        } else if let suggestedSubject,
                  let deck = decks.first(where: { $0.subject?.name.localizedCaseInsensitiveCompare(suggestedSubject) == .orderedSame }) {
            selectedDeckID = deck.id
        } else if let last = UUID(uuidString: lastNoteCardDeckID), decks.contains(where: { $0.id == last }) {
            selectedDeckID = last
        } else {
            selectedDeckID = decks.first?.id
        }
    }

    /// A new deck, in the subject named like the note's folder (made if it isn't there yet).
    private func createDeck(named name: String) {
        let subjectName = suggestedSubject ?? selectedDeck?.subject?.name ?? String(localized: "section.notes")
        let subjects = (try? context.fetch(FetchDescriptor<SubjectModel>())) ?? []
        let subject = subjects.first { $0.name.localizedCaseInsensitiveCompare(subjectName) == .orderedSame } ?? {
            let order = (subjects.map(\.manualSortOrder).max() ?? -1) + 1
            let subject = SubjectModel(name: subjectName, manualSortOrder: order)
            context.insert(subject)
            return subject
        }()
        let order = (subject.allDecks.map(\.manualSortOrder).max() ?? -1) + 1
        let deck = Deck(subject: subject, name: name, manualSortOrder: order)
        context.insert(deck)
        do {
            try context.save()
            selectedDeckID = deck.id
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func editorSection(
        title: LocalizedStringKey,
        text: Binding<String>,
        selection: Binding<TextSelection?>,
        side: Side
    ) -> some View {
        let focused = focusedSide == side
        return VStack(alignment: .leading, spacing: 8) {
            HandwrittenText(title, weight: focused ? 0.4 : 0)
                .font(RemnTypography.display(23, relativeTo: .headline))
                .foregroundStyle(focused ? Color.remnAccent : Color.remnGraphite)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    HandwrittenText(side == .front ? "editor.front.placeholder" : "editor.back.placeholder")
                        .font(RemnTypography.body)
                        .foregroundStyle(Color.remnGraphite.opacity(0.75))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                TextEditor(text: text, selection: selection)
                    .focused($focusedSide, equals: side)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Color.remnInk)
                    .tint(.remnAccent)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .accessibilityLabel(Text(title))
            }
            .frame(minHeight: side == .front ? 150 : 180)
            .background {
                InkBox(
                    seed: side == .front ? 141 : 177,
                    cornerRadius: 14,
                    fill: .remnCardPaper,
                    outline: focused ? .remnAccent : .remnInk.opacity(0.55),
                    pen: focused ? .pen : .fine,
                    registration: CGSize(width: 1, height: 1.4)
                )
            }
            .animation(.easeOut(duration: 0.15), value: focused)
            .onTapGesture { focusedSide = side }
        }
    }

    // MARK: - Preview

    private var preview: some View {
        ScrollView {
            FlashcardSurface(seed: card?.id.inkSeed ?? 88) {
                VStack(alignment: .leading, spacing: 0) {
                    FlashcardSideLabel(title: "card.front")
                    IndexRule(seed: 89)
                        .padding(.top, 4)
                        .padding(.bottom, 14)
                    CardContentView(markdown: front, context: .preview)
                    InkDashes(seed: 90)
                        .fill(Color.remnGraphite.opacity(0.6))
                        .frame(height: 6)
                        .padding(.vertical, 18)
                    FlashcardSideLabel(title: "card.back")
                        .padding(.bottom, 10)
                    CardContentView(markdown: back, context: .preview)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 44)
            .remnReadableWidth()
        }
    }

    // MARK: - Actions

    private var canSave: Bool {
        selectedDeckID != nil
            && !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasChanges: Bool {
        front != initialFront || back != initialBack
    }

    private func insert(_ insertion: MarkdownInsertion) {
        if focusedSide == .back {
            let selected = insertion.apply(to: &back, selecting: offsets(of: backSelection, in: back))
            backSelection = selection(selected, in: back)
        } else {
            let selected = insertion.apply(to: &front, selecting: offsets(of: frontSelection, in: front))
            frontSelection = selection(selected, in: front)
            focusedSide = .front
        }
    }

    private func offsets(of selection: TextSelection?, in text: String) -> Range<Int>? {
        guard let selection else { return nil }
        switch selection.indices {
        case .selection(let range):
            guard range.lowerBound >= text.startIndex, range.upperBound <= text.endIndex else { return nil }
            return text.distance(from: text.startIndex, to: range.lowerBound)
                ..< text.distance(from: text.startIndex, to: range.upperBound)
        default:
            return nil
        }
    }

    private func selection(_ offsets: Range<Int>, in text: String) -> TextSelection {
        let lower = text.index(text.startIndex, offsetBy: min(offsets.lowerBound, text.count))
        let upper = text.index(text.startIndex, offsetBy: min(offsets.upperBound, text.count))
        return TextSelection(range: lower..<upper)
    }

    private func save() {
        guard let deck = decks.first(where: { $0.id == selectedDeckID }) else { return }
        if let card {
            card.deck = deck
            card.frontMarkdown = front
            card.backMarkdown = back
            card.updatedAt = .now
        } else {
            context.insert(Flashcard(deck: deck, frontMarkdown: front, backMarkdown: back, sourceNotePath: sourceNotePath))
            if sourceNotePath != nil { lastNoteCardDeckID = deck.id.uuidString }
        }
        do {
            try context.save()
            dismiss()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func deckLabel(_ deck: Deck) -> String {
        if let subject = deck.subject { return "\(subject.name) / \(deck.name)" }
        return deck.name
    }

    private var selectedDeck: Deck? {
        decks.first { $0.id == selectedDeckID }
    }
}
