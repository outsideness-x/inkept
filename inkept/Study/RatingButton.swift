import SwiftUI

/// One of the four answers, with the real interval it leads to.
struct RatingButton: View {
    let rating: StudyRating
    let interval: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HandwrittenText(LocalizedStringKey(rating.titleKey))
                    .font(InkeptTypography.control)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HandwrittenText(verbatim: interval)
                    .font(InkeptTypography.caption)
                    .foregroundStyle(Color.inkeptGraphite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(rating == .again ? Color.inkeptAccent : Color.inkeptInk)
            .frame(maxWidth: .infinity, minHeight: 62)
            .padding(.horizontal, 4)
        }
        .buttonStyle(RatingButtonStyle(rating: rating))
        .overlay(alignment: .topTrailing) {
            if InkeptPlatform.isMac {
                HandwrittenText(verbatim: "\(rating.rawValue)")
                    .font(InkeptTypography.display(13, relativeTo: .caption2))
                    .foregroundStyle(Color.inkeptGraphite.opacity(0.7))
                    .padding(.top, 5)
                    .padding(.trailing, 9)
                    .accessibilityHidden(true)
            }
        }
        .keyboardShortcut(KeyEquivalent(Character("\(rating.rawValue)")), modifiers: [])
        .accessibilityLabel(Text(LocalizedStringKey(rating.titleKey)))
        .accessibilityValue(Text(verbatim: interval))
    }
}

private struct RatingButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let rating: StudyRating

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let seed = 2_300 + rating.rawValue * 23
        configuration.label
            .background {
                InkBox(
                    seed: pressed ? seed &+ 1 : seed,
                    cornerRadius: 14,
                    fill: pressed ? tint.opacity(0.12) : .inkeptCardPaper,
                    outline: rating == .again ? .inkeptAccent : .inkeptInk,
                    pen: .fine,
                    registration: pressed ? .zero : CGSize(width: 1.2, height: 1.8)
                )
            }
            .scaleEffect(pressed && !reduceMotion ? 0.95 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2, bounce: 0.45), value: pressed)
            .contentShape(Rectangle())
    }

    private var tint: Color {
        rating == .again ? .inkeptAccent : .inkeptInk
    }
}
