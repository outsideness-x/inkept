import SwiftData
import SwiftUI

struct StudyCompletionView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: StudySessionRecord

    @State private var tick: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                StackedCardsDoodle(width: 84)
                HStack(alignment: .center, spacing: 6) {
                    HandwrittenText("done.", weight: 1)
                        .font(RemnTypography.display(54, relativeTo: .largeTitle))
                        .foregroundStyle(Color.remnInk)
                        .accessibilityAddTraits(.isHeader)
                    InkTick(seed: 91, pen: .marker, progress: tick)
                        .fill(Color.remnAccent)
                        .frame(width: 46, height: 42)
                        .offset(y: -8)
                        .accessibilityHidden(true)
                }
                HandwrittenText(verbatim: summary)
                    .font(RemnTypography.body)
                    .foregroundStyle(Color.remnGraphite)
                    .multilineTextAlignment(.center)
            }
            .inkWritesOn(duration: 0.7)
            Spacer()
            VStack(spacing: 6) {
                Button(action: finish) {
                    HandwrittenText("study.backLibrary", weight: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .primary, seed: 63))
                Button(action: studyMore) {
                    HandwrittenText("study.more")
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 64))
            }
            .remnReadableWidth(560)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .sensoryFeedback(.success, trigger: tick == 1)
        .onAppear {
            if reduceMotion {
                tick = 1
            } else {
                withAnimation(.easeOut(duration: 0.35).delay(0.75)) { tick = 1 }
            }
        }
    }

    private func finish() {
        session.isActive = false
        try? context.save()
        appState.presentedSession = nil
    }

    private func studyMore() {
        finish()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            appState.prepareStudy(subjectIDs: Set(session.subjectIDs), deckID: session.deckID)
        }
    }

    private var summary: String {
        let cards = session.admittedCardIDs.count
        let fresh = session.initialNewCount
        let reviews = max(0, cards - fresh)
        var parts = [String(localized: "count.cards \(cards)")]
        if fresh > 0 { parts.append(String(localized: "count.new \(fresh)")) }
        if reviews > 0 { parts.append(String(localized: "count.reviews \(reviews)")) }
        return parts.joined(separator: "  ·  ")
    }
}
