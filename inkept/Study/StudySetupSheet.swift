import SwiftData
import SwiftUI

struct StudySetupSheet: View {
    enum CountChoice: String, CaseIterable, Identifiable {
        case ten, twenty, thirty, fifty, allDue, custom
        var id: String { rawValue }

        var value: Int? {
            switch self {
            case .ten: 10
            case .twenty: 20
            case .thirty: 30
            case .fifty: 50
            case .allDue, .custom: nil
            }
        }

        var title: Text {
            switch self {
            case .ten: Text(verbatim: "10")
            case .twenty: Text(verbatim: "20")
            case .thirty: Text(verbatim: "30")
            case .fifty: Text(verbatim: "50")
            case .allDue: Text("study.allDue")
            case .custom: Text("study.custom")
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @Query private var cards: [Flashcard]
    @AppStorage("lastSubjectIDs") private var lastSubjectIDs = ""

    let initialSubjectIDs: Set<UUID>
    let initialDeckID: UUID?
    let onStart: (StudySessionRecord) -> Void

    @State private var selectedSubjectIDs: Set<UUID>
    @State private var countChoice = CountChoice.twenty
    @State private var customCount = 20
    @State private var noCards = false

    init(
        initialSubjectIDs: Set<UUID>,
        initialDeckID: UUID?,
        onStart: @escaping (StudySessionRecord) -> Void
    ) {
        self.initialSubjectIDs = initialSubjectIDs
        self.initialDeckID = initialDeckID
        self.onStart = onStart
        _selectedSubjectIDs = State(initialValue: initialSubjectIDs)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "study.setup") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("study.what")
                    scopePicker
                        .padding(.top, 8)
                    sectionTitle("study.howMany")
                        .padding(.top, 30)
                    countPicker
                        .padding(.top, 12)
                    if countChoice == .custom {
                        customStepper
                            .padding(.top, 14)
                    }
                    TimelineView(.periodic(from: .now, by: 15)) { timeline in
                        sessionSummary(at: timeline.date)
                    }
                    .padding(.top, 26)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .remnReadableWidth(600)
            }
        }
        .paperBackground()
        .safeAreaInset(edge: .bottom) {
            Button(action: start) {
                HandwrittenText("study.start", weight: 0.5)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle(kind: .primary, seed: 91))
            .disabled(selectedSubjectIDs.isEmpty && initialDeckID == nil)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, RemnPlatform.bottomButtonPadding)
            .remnReadableWidth(600)
            .background(alignment: .bottom) { PaperFade() }
        }
        .remnSheetFrame(width: 520, height: 640)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .onAppear(perform: restoreSelection)
        .handmadeDialog(
            isPresented: $noCards,
            title: "study.noneAvailable",
            message: Text("study.noneAvailable.message"),
            actions: [HandmadeDialogAction("ok") {}]
        )
    }

    // MARK: - Scope

    @ViewBuilder
    private var scopePicker: some View {
        if let deck = scopedDeck {
            HStack(spacing: 14) {
                InkCheckbox(isOn: true, seed: 505)
                VStack(alignment: .leading, spacing: 2) {
                    HandwrittenText(verbatim: deck.name, weight: 0.3)
                        .font(RemnTypography.rowTitle)
                        .foregroundStyle(Color.remnInk)
                    if let subject = deck.subject {
                        HandwrittenText(verbatim: subject.name)
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                    }
                }
                Spacer()
                HandwrittenText("count.cards \(deck.allCards.count)")
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
            }
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                    if index > 0 {
                        InkDivider(seed: subject.id.inkSeed ^ 0x55)
                    }
                    subjectToggle(subject)
                }
            }
        }
    }

    private func subjectToggle(_ subject: SubjectModel) -> some View {
        let isOn = selectedSubjectIDs.contains(subject.id)
        return Button {
            if isOn {
                selectedSubjectIDs.remove(subject.id)
            } else {
                selectedSubjectIDs.insert(subject.id)
            }
        } label: {
            HStack(spacing: 14) {
                InkCheckbox(isOn: isOn, seed: subject.id.inkSeed)
                if let icon = SubjectIcon.named(subject.icon) {
                    SubjectIconView(icon: icon, size: 28)
                        .padding(.trailing, -4)
                }
                HandwrittenText(verbatim: subject.name, weight: 0.3)
                    .font(RemnTypography.display(23, relativeTo: .headline))
                    .foregroundStyle(isOn ? Color.remnInk : Color.remnGraphite)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                HandwrittenText("count.cards \(subject.cards.count)")
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkRowStyle())
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Count

    private var countPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 8) {
            ForEach(Array(CountChoice.allCases.enumerated()), id: \.element.id) { index, choice in
                let chosen = countChoice == choice
                Button {
                    countChoice = choice
                } label: {
                    HandwrittenText(text: choice.title)
                        .font(RemnTypography.control)
                        .foregroundStyle(chosen ? Color.remnInk : Color.remnGraphite)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .inkCircled(chosen, seed: 310 + index * 19, inset: CGSize(width: -14, height: -6))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: countChoice)
    }

    private var customStepper: some View {
        HStack(spacing: 18) {
            stepperButton(.minus, label: "decrease") { customCount = max(1, customCount - 5) }
                .disabled(customCount == 1)
            HandwrittenText("count.cards \(customCount)")
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
            stepperButton(.plus, label: "increase") { customCount = min(500, customCount + 5) }
                .disabled(customCount == 500)
        }
        .sensoryFeedback(.selection, trigger: customCount)
    }

    private func stepperButton(_ kind: InkIconKind, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            InkIcon(kind: kind, size: 18)
                .frame(width: 48, height: 48)
                .background { InkBox(seed: 517 + kind.rawValue, cornerRadius: 12, pen: .fine) }
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(label))
    }

    // MARK: - Summary

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        HandwrittenText(key, weight: 0.3)
            .font(RemnTypography.sectionTitle)
            .foregroundStyle(Color.remnInk)
            .accessibilityAddTraits(.isHeader)
    }

    private var targetCount: Int? {
        countChoice == .custom ? customCount : countChoice.value
    }

    private func sessionSummary(at date: Date) -> some View {
        let selected = StudyQueueBuilder.select(
            from: cards,
            subjectIDs: scopeSubjectIDs,
            deckID: initialDeckID,
            targetCount: targetCount,
            now: date
        ).count
        let availability = StudyQueueBuilder.availability(
            from: cards,
            subjectIDs: scopeSubjectIDs,
            deckID: initialDeckID,
            now: date
        )

        return FlashcardSurface(seed: 441, style: .compact) {
            HStack(alignment: .center, spacing: 16) {
                HandwrittenText(verbatim: "\(selected)", weight: 1)
                    .font(RemnTypography.display(46, relativeTo: .largeTitle))
                    .foregroundStyle(selected > 0 ? Color.remnAccent : Color.remnGraphite)
                    .contentTransition(.numericText())
                    .frame(minWidth: 44)
                VStack(alignment: .leading, spacing: 3) {
                    HandwrittenText("study.inSession")
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnInk)
                    HandwrittenText("study.availability \(availability.availableNow) \(availability.scheduledLater)")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                }
                Spacer(minLength: 0)
            }
        }
        .animation(.snappy, value: selected)
        .accessibilityElement(children: .combine)
    }

    // MARK: - State

    private var scopedDeck: Deck? {
        guard let initialDeckID else { return nil }
        return subjects.lazy.flatMap(\.allDecks).first { $0.id == initialDeckID }
    }

    private var scopeSubjectIDs: Set<UUID> {
        if let subjectID = scopedDeck?.subject?.id { return [subjectID] }
        return selectedSubjectIDs
    }

    private func restoreSelection() {
        guard selectedSubjectIDs.isEmpty else { return }
        let saved = Set(
            lastSubjectIDs.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
        )
        let available = Set(subjects.map(\.id))
        selectedSubjectIDs = saved.intersection(available)
        if selectedSubjectIDs.isEmpty {
            selectedSubjectIDs = available
        }
    }

    private func start() {
        do {
            let session = try SessionService.start(
                cards: cards,
                subjectIDs: scopeSubjectIDs,
                deckID: initialDeckID,
                targetCount: targetCount,
                context: context
            )
            guard let session else { noCards = true; return }
            if initialDeckID == nil {
                lastSubjectIDs = selectedSubjectIDs.map(\.uuidString).joined(separator: ",")
            }
            onStart(session)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}
