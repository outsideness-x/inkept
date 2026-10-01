#if DEBUG
import SwiftUI

/// A debug sheet of every ink primitive, for tuning the hand. Launch with `-inkLab`.
struct InkLab: View {
    @State private var replay = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HandwrittenText(verbatim: "ink lab", weight: 1)
                    .font(InkeptTypography.display(40, relativeTo: .largeTitle))
                    .foregroundStyle(Color.inkeptInk)

                HStack(spacing: 18) {
                    ForEach(0..<3) { index in
                        ZStack {
                            InkPatch(seed: 40 + index, cornerRadius: 12)
                                .fill(Color.inkeptCardPaper)
                                .offset(x: 1.5, y: 1.5)
                            InkRoundedRect(seed: 40 + index, cornerRadius: 12)
                                .fill(Color.inkeptInk)
                        }
                        .frame(width: 96, height: 64)
                    }
                }

                ZStack {
                    InkHatch(seed: 7)
                        .fill(Color.inkeptAccent.opacity(0.55))
                        .clipShape(InkPatch(seed: 9, cornerRadius: 16))
                        .offset(x: 5, y: 7)
                    InkPatch(seed: 8, cornerRadius: 16)
                        .fill(Color.inkeptCardPaper)
                    InkRoundedRect(seed: 8, cornerRadius: 16, pen: .pen)
                        .fill(Color.inkeptInk)
                    VStack(alignment: .leading, spacing: 10) {
                        HandwrittenText(verbatim: "front")
                            .font(InkeptTypography.display(17, relativeTo: .subheadline))
                            .foregroundStyle(Color.inkeptGraphite)
                        InkLine(seed: 3, pen: .fine)
                            .fill(Color.inkeptAccent)
                            .frame(height: 6)
                        HandwrittenText(verbatim: "What is an eigenvector of a linear map?")
                            .font(InkeptTypography.display(25, relativeTo: .title3))
                            .foregroundStyle(Color.inkeptInk)
                    }
                    .padding(24)
                }
                .frame(height: 190)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array([InkPen.hairline, .fine, .pen, .bold, .marker].enumerated()), id: \.offset) { index, pen in
                        InkLine(seed: 100 + index, pen: pen)
                            .fill(Color.inkeptInk)
                            .frame(height: 8)
                    }
                    InkUnderline(seed: 5)
                        .fill(Color.inkeptAccent)
                        .frame(width: 120, height: 8)
                }

                HStack(spacing: 22) {
                    InkEllipse(seed: 11)
                        .fill(Color.inkeptAccent)
                        .frame(width: 44, height: 44)
                    InkEllipse(seed: 12, pen: .fine)
                        .fill(Color.inkeptInk)
                        .frame(width: 90, height: 40)
                    ZStack {
                        InkHatch(seed: 13, spacing: 4)
                            .fill(Color.inkeptAccent.opacity(0.7))
                            .clipShape(InkPatch(seed: 14, cornerRadius: 10))
                        InkRoundedRect(seed: 14, cornerRadius: 10, pen: .fine)
                            .fill(Color.inkeptAccent)
                    }
                    .frame(width: 90, height: 44)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HandwrittenText(verbatim: "things worth remembering")
                        .font(InkeptTypography.display(30, relativeTo: .title))
                    HandwrittenText(verbatim: "things worth remembering", weight: 1)
                        .font(InkeptTypography.display(30, relativeTo: .title))
                    HandwrittenText(verbatim: "то, что стоит запомнить")
                        .font(InkeptTypography.display(30, relativeTo: .title))
                    HandwrittenText(verbatim: "7 cards are waiting")
                        .font(InkeptTypography.display(22, relativeTo: .body))
                        .foregroundStyle(Color.inkeptGraphite)
                }
                .foregroundStyle(Color.inkeptInk)

                VStack(alignment: .leading, spacing: 6) {
                    HandwrittenText(verbatim: "written on, once", weight: 1)
                        .font(InkeptTypography.display(34, relativeTo: .title))
                        .foregroundStyle(Color.inkeptInk)
                    InkUnderline(seed: 21)
                        .ink(.inkeptAccent)
                        .frame(width: 150, height: 8)
                }
                .inkWritesOn(duration: 1.1)
                .id(replay)
                .onTapGesture { replay += 1 }
            }
            .padding(24)
        }
        .paperBackground()
    }
}
#endif
