import SwiftData
import SwiftUI

struct StudySessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var cards: [Flashcard]
    @AppStorage("desiredRetention") private var desiredRetention = 0.90
    @AppStorage("didShowRatingHelp") private var didShowRatingHelp = false

    @Bindable var session: StudySessionRecord
    @State private var revealed = false
    @State private var showingBack = false
    @State private var turn: Double = 0
    @State private var isFlipping = false
    @State private var answerInk: Double = 1
    @State private var ratingsVisible = false
    @State private var candidates: [StudyRating: ScheduleCandidate] = [:]
    @State private var reviewTime = Date()
    @State private var showRatingsHelp = false
    @State private var showUndo = false
    @State private var flips = 0
    @State private var grades = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            if session.isActive, let card = currentCard {
                study(card)
            } else {
                StudyCompletionView(session: session)
                    .transition(.opacity)
            }
        }
        .paperBackground()
        .handmadeDialog(
            isPresented: $showRatingsHelp,
            title: "study.ratingsHelp.title",
            message: Text("study.ratingsHelp.message"),
            actions: [HandmadeDialogAction("ok") {}]
        )
        .onAppear(perform: prepareQueue)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: flips)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: grades)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            if session.isActive, currentCard != nil {
                VStack(spacing: 2) {
                    HandwrittenText(verbatim: "\(position)/\(total)")
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnInk)
                        .contentTransition(.numericText())
                    StudyProgressLine(fraction: progress)
                        .frame(width: 96, height: 8)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("study.progress \(position) \(total)"))
            }
            HStack {
                Button { appState.presentedSession = nil } label: {
                    HandwrittenText("close")
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 31))
                .keyboardShortcut(.cancelAction)
                Spacer()
                if showUndo {
                    Button(action: undo) {
                        HStack(spacing: 5) {
                            InkIcon(kind: .undo, color: .remnAccent, size: 17)
                            HandwrittenText("undo")
                        }
                    }
                    .buttonStyle(InkButtonStyle(kind: .quiet, seed: 32))
                    .keyboardShortcut("z", modifiers: .command)
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    // MARK: - Card

    private func study(_ card: Flashcard) -> some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let cardHeight = min(max(proxy.size.height * 0.64, 260), 560)
                ScrollView {
                    VStack(spacing: 14) {
                        HandwrittenText(verbatim: card.deckContext)
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                            .lineLimit(1)
                        studyCard(card, height: cardHeight)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .remnReadableWidth(620)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .id(card.id)
            .transition(cardTransition)

            answerControls(for: card)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .remnReadableWidth(620)
        }
    }

    private func studyCard(_ card: Flashcard, height: CGFloat) -> some View {
        let header: CGFloat = 52
        let footer: CGFloat = 40
        let padding = FlashcardSurfaceStyle.study.padding
        let contentHeight = max(height - header - footer - padding.top - padding.bottom, 80)
        return FlashcardSurface(seed: card.id.inkSeed &+ (showingBack ? 1 : 0), style: .study) {
            CardContentView(
                markdown: showingBack ? card.backMarkdown : card.frontMarkdown,
                context: .study
            )
            .opacity(showingBack ? answerInk : 1)
            .blur(radius: showingBack ? (1 - answerInk) * 5 : 0)
            .offset(y: showingBack ? (1 - answerInk) * 4 : 0)
            .frame(maxWidth: .infinity, minHeight: contentHeight, alignment: .leading)
            .padding(.top, header)
            .padding(.bottom, footer)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    FlashcardSideLabel(title: showingBack ? "card.back" : "card.front")
                    IndexRule(seed: card.id.inkSeed ^ (showingBack ? 0x21 : 0x11))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if revealed {
                    HStack(spacing: 7) {
                        InkIcon(kind: .flip, color: .remnGraphite, size: 17)
                        HandwrittenText("study.tapFlip")
                            .font(RemnTypography.caption)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    .accessibilityHidden(true)
                }
            }
        }
        .rotation3DEffect(.degrees(turn), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
        .contentShape(Rectangle())
        .onTapGesture { revealOrFlip(card) }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text(revealed ? "study.tapFlip" : "study.tapReveal"))
        .accessibilityAction(named: Text(showingBack ? "card.front" : "card.back")) {
            revealOrFlip(card)
        }
    }

    private var cardTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: 60, y: 8).combined(with: .opacity),
            removal: .offset(x: -80, y: 4).combined(with: .opacity)
        )
    }

    // MARK: - Answer

    private func answerControls(for card: Flashcard) -> some View {
        ZStack(alignment: .bottom) {
            Button { revealOrFlip(card) } label: {
                HStack(spacing: 10) {
                    InkIcon(kind: .flip, color: .remnInk, size: 19)
                    HandwrittenText("study.showAnswer")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle(kind: .secondary, seed: 57))
            .keyboardShortcut(.space, modifiers: [])
            .opacity(revealed ? 0 : 1)
            .allowsHitTesting(!revealed)
            .accessibilityHidden(revealed)

            ratings(for: card)
                .opacity(ratingsVisible ? 1 : 0)
                .offset(y: ratingsVisible || reduceMotion ? 0 : 10)
                .allowsHitTesting(ratingsVisible)
                .accessibilityHidden(!ratingsVisible)
        }
    }

    private func ratings(for card: Flashcard) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                HandwrittenText("study.rate")
                    .font(RemnTypography.note)
                    .foregroundStyle(Color.remnGraphite)
                Spacer()
                InkIconButton(kind: .info, label: "study.ratingsHelp.title", color: .remnGraphite, size: 19) {
                    showRatingsHelp = true
                }
                .padding(.trailing, -8)
            }
            .padding(.leading, 6)
            HStack(spacing: 8) {
                ForEach(StudyRating.allCases) { rating in
                    if let candidate = candidates[rating] {
                        RatingButton(
                            rating: rating,
                            interval: RemnFormatters.interval(from: reviewTime, to: candidate.schedule.due)
                        ) {
                            grade(rating, candidate: candidate, card: card)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func revealOrFlip(_ card: Flashcard) {
        guard !isFlipping else { return }

        if revealed {
            flipCard(toBack: !showingBack)
            return
        }

        reviewTime = .now
        do {
            candidates = try ReviewService().candidates(
                for: card,
                at: reviewTime,
                desiredRetention: desiredRetention
            )
            let needsHelp = !didShowRatingHelp
            didShowRatingHelp = true
            revealed = true
            ratingsVisible = false
            flipCard(toBack: true) {
                withAnimation(.easeOut(duration: 0.22)) {
                    ratingsVisible = true
                }
                if needsHelp {
                    showRatingsHelp = true
                }
            }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func flipCard(toBack: Bool, completion: (() -> Void)? = nil) {
        guard showingBack != toBack else {
            completion?()
            return
        }
        flips += 1

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.15)) {
                showingBack = toBack
                answerInk = 1
            }
            completion?()
            return
        }

        isFlipping = true
        withAnimation(.easeIn(duration: 0.14)) {
            turn = 88
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            var quiet = Transaction()
            quiet.disablesAnimations = true
            withTransaction(quiet) {
                showingBack = toBack
                turn = -88
                answerInk = toBack ? 0 : 1
            }
            withAnimation(.spring(duration: 0.42, bounce: 0.3)) {
                turn = 0
            }
            if toBack {
                withAnimation(.easeOut(duration: 0.5).delay(0.08)) {
                    answerInk = 1
                }
            }
            try? await Task.sleep(for: .milliseconds(220))
            isFlipping = false
            completion?()
        }
    }

    private var currentCard: Flashcard? {
        guard let id = session.queueCardIDs.first else { return nil }
        return cards.first { $0.id == id }
    }

    private var total: Int {
        max(session.admittedCardIDs.count, 1)
    }

    private var finished: Int {
        max(0, session.admittedCardIDs.count - session.queueCardIDs.count)
    }

    private var position: Int {
        min(finished + 1, total)
    }

    private var progress: Double {
        Double(finished) / Double(total)
    }

    private func grade(_ rating: StudyRating, candidate: ScheduleCandidate, card: Flashcard) {
        grades += 1
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.42, bounce: 0.18)) {
            do {
                try ReviewService().apply(
                    rating,
                    candidate: candidate,
                    to: card,
                    in: session,
                    context: context,
                    at: reviewTime
                )
                resetFace()
                SessionService.refreshQueue(session, cards: cards)
                try context.save()
                showUndo = true
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func undo() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.42, bounce: 0.18)) {
            do {
                try ReviewService().undoLastReview(in: session, context: context)
                resetFace()
                showUndo = false
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func resetFace() {
        revealed = false
        showingBack = false
        ratingsVisible = false
        turn = 0
        answerInk = 1
        candidates = [:]
    }

    private func prepareQueue() {
        let existingIDs = Set(cards.map(\.id))
        session.queueCardIDs.removeAll { !existingIDs.contains($0) }
        SessionService.refreshQueue(session, cards: cards)
        try? context.save()
    }
}

/// How far through the session you are: a pencil line with red pencil over the part you've done.
struct StudyProgressLine: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                InkLine(seed: 2_701, pen: .hairline)
                    .fill(Color.remnGraphite.opacity(0.7))
                InkLine(seed: 2_702, pen: .bold)
                    .fill(Color.remnAccent)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                    }
            }
        }
        .animation(.easeOut(duration: 0.35), value: fraction)
        .accessibilityHidden(true)
    }
}
