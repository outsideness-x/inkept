import SwiftUI

struct SRSExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "srs.title", leadingTitle: "done") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    FlashcardSurface(seed: 606, style: .regular) {
                        VStack(alignment: .leading, spacing: 10) {
                            HandwrittenText(verbatim: "FSRS-6", weight: 1)
                                .font(RemnTypography.display(36, relativeTo: .title))
                                .foregroundStyle(Color.remnAccent)
                            HandwrittenText("srs.intro")
                                .font(RemnTypography.body)
                                .foregroundStyle(Color.remnInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    section(number: 1, title: "srs.memory.title", body: "srs.memory.body") {
                        GrowingIntervals()
                    }
                    section(number: 2, title: "srs.ratings.title", body: "srs.ratings.body") {
                        ratingLegend
                    }
                    section(number: 3, title: "srs.queue.title", body: "srs.queue.body") {
                        EmptyView()
                    }
                    section(number: 4, title: "srs.retention.title", body: "srs.retention.body") {
                        EmptyView()
                    }

                    HandwrittenText("srs.history")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 40)
                .remnReadableWidth(640)
            }
        }
        .paperBackground()
        .remnSheetFrame(width: 560, height: 720)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
    }

    private func section<Detail: View>(
        number: Int,
        title: LocalizedStringKey,
        body: LocalizedStringKey,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                HandwrittenText(verbatim: "\(number)", weight: 0.8)
                    .font(RemnTypography.display(22, relativeTo: .headline))
                    .foregroundStyle(Color.remnAccent)
                    .inkCircled(seed: 620 + number, inset: CGSize(width: -9, height: -5))
                    .padding(.leading, 6)
                HandwrittenText(title, weight: 0.4)
                    .font(RemnTypography.sectionTitle)
                    .foregroundStyle(Color.remnInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            HandwrittenText(body)
                .font(RemnTypography.body)
                .foregroundStyle(Color.remnInk)
                .fixedSize(horizontal: false, vertical: true)
            detail()
        }
    }

    private var ratingLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            ratingLine("rating.again", note: "srs.again", accent: true)
            ratingLine("rating.hard", note: "srs.hard")
            ratingLine("rating.good", note: "srs.good")
            ratingLine("rating.easy", note: "srs.easy")
        }
        .padding(.top, 4)
    }

    private func ratingLine(_ rating: LocalizedStringKey, note: LocalizedStringKey, accent: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HandwrittenText(rating, weight: 0.4)
                .font(RemnTypography.control)
                .foregroundStyle(accent ? Color.remnAccent : Color.remnInk)
                .frame(minWidth: 70, alignment: .leading)
            HandwrittenText(note)
                .font(RemnTypography.note)
                .foregroundStyle(Color.remnGraphite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Now, later, much later: each successful recall pushes the next one further out.
private struct GrowingIntervals: View {
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            step("srs.now", width: 58, seed: 1)
            arrow(seed: 1)
            step("srs.later", width: 84, seed: 2)
            arrow(seed: 2)
            step("srs.muchLater", width: 118, seed: 3)
        }
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
    }

    private func step(_ title: LocalizedStringKey, width: CGFloat, seed: Int) -> some View {
        HandwrittenText(title)
            .font(RemnTypography.note)
            .foregroundStyle(Color.remnInk)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(minWidth: width * 0.8, maxWidth: width)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background { InkBox(seed: 640 + seed, cornerRadius: 10, pen: .fine) }
    }

    private func arrow(seed: Int) -> some View {
        InkIcon(kind: .forward, color: .remnAccent, size: 18)
            .accessibilityHidden(true)
    }
}
