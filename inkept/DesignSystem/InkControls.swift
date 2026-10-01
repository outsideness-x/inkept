import SwiftUI

// MARK: - Boxes and lines

/// A hand-drawn box: paper or colour laid down a touch off-register, then a pen outline in one stroke.
struct InkBox: View {
    @Environment(\.inkProgress) private var progress

    var seed: Int
    var cornerRadius: CGFloat = 14
    var fill: Color? = .remnCardPaper
    var outline: Color? = .remnInk
    var pen: InkPen = .pen
    var registration = CGSize(width: 1.3, height: 1.8)

    var body: some View {
        ZStack {
            if let fill {
                InkPatch(seed: seed ^ 0xF1, cornerRadius: cornerRadius)
                    .fill(fill)
                    .offset(registration)
                    .opacity(progress)
            }
            if let outline {
                InkRoundedRect(seed: seed, cornerRadius: cornerRadius, pen: pen, progress: CGFloat(progress))
                    .fill(outline)
            }
        }
    }
}

/// A light pencil rule between rows.
struct InkDivider: View {
    var seed: Int
    var color: Color = .remnInk.opacity(0.3)

    var body: some View {
        InkLine(seed: seed, pen: .hairline)
            .ink(color)
            .frame(height: 6)
            .accessibilityHidden(true)
    }
}

/// The red line under the header of an index card.
struct IndexRule: View {
    var seed: Int

    var body: some View {
        InkLine(seed: seed, pen: .hairline)
            .ink(.remnAccent.opacity(0.75))
            .frame(height: 6)
            .accessibilityHidden(true)
    }
}

/// A small, quick swash under a title.
struct TitleSwash: View {
    var seed: Int
    var width: CGFloat = 78

    var body: some View {
        InkUnderline(seed: seed, pen: .bold)
            .ink(.remnAccent)
            .frame(width: width, height: 9)
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

struct InkButtonStyle: ButtonStyle {
    enum Kind {
        /// Red pencil filled in, outlined in ink.
        case primary
        /// Paper outlined in ink.
        case secondary
        /// Paper outlined in red pencil, for things that can't be taken back.
        case destructive
        /// Just words in red pencil; underlined while pressed.
        case quiet
    }

    var kind: Kind = .primary
    var seed: Int = 1

    func makeBody(configuration: Configuration) -> some View {
        InkButtonBody(configuration: configuration, kind: kind, seed: seed)
    }
}

private struct InkButtonBody: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let configuration: ButtonStyleConfiguration
    let kind: InkButtonStyle.Kind
    let seed: Int

    var body: some View {
        let pressed = configuration.isPressed
        label(pressed: pressed)
            .opacity(isEnabled ? 1 : 0.38)
            .scaleEffect(pressed && !reduceMotion ? 0.975 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.22, bounce: 0.4), value: pressed)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func label(pressed: Bool) -> some View {
        switch kind {
        case .primary:
            configuration.label
                .font(RemnTypography.control)
                .foregroundStyle(Color.remnOnAccent)
                .padding(.horizontal, 22)
                .frame(minHeight: 56)
                .background {
                    InkBox(
                        seed: pressed ? seed &+ 1 : seed,
                        cornerRadius: 17,
                        fill: .remnAccent,
                        outline: .remnInk,
                        pen: .pen,
                        registration: pressed ? .zero : CGSize(width: 2.2, height: 2.8)
                    )
                }
        case .secondary, .destructive:
            let ink = kind == .destructive ? Color.remnAccent : Color.remnInk
            configuration.label
                .font(RemnTypography.control)
                .foregroundStyle(ink)
                .padding(.horizontal, 22)
                .frame(minHeight: 56)
                .background {
                    InkBox(
                        seed: pressed ? seed &+ 1 : seed,
                        cornerRadius: 17,
                        fill: pressed ? ink.opacity(0.08) : .remnCardPaper,
                        outline: ink,
                        pen: .fine,
                        registration: pressed ? .zero : CGSize(width: 1.4, height: 2)
                    )
                }
        case .quiet:
            configuration.label
                .font(RemnTypography.control)
                .foregroundStyle(Color.remnAccent)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .overlay(alignment: .bottom) {
                    InkUnderline(seed: seed, pen: .fine, progress: pressed ? 1 : 0)
                        .fill(Color.remnAccent)
                        .frame(height: 6)
                        .padding(.horizontal, 8)
                        .offset(y: -6)
                        .animation(.easeOut(duration: 0.15), value: pressed)
                }
        }
    }
}

/// A 44-point target around a small drawing.
struct InkIconButton: View {
    let kind: InkIconKind
    let label: LocalizedStringKey
    var color: Color = .remnInk
    var size: CGFloat = 22
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            InkIcon(kind: kind, color: color, size: size)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(label))
    }
}

/// Presses a drawing a little into the paper.
struct InkPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2, bounce: 0.4), value: configuration.isPressed)
    }
}

// MARK: - Marks

/// A tick drawn the way a pen makes it: a short dip and a long pull up and away.
struct InkTick: Shape {
    var seed: Int = 7
    var pen: InkPen = .bold
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let points = [
            CGPoint(x: rect.minX + w * 0.12, y: rect.minY + h * 0.52),
            CGPoint(x: rect.minX + w * 0.27, y: rect.minY + h * 0.66),
            CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.80),
            CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.45),
            CGPoint(x: rect.minX + w * 0.98, y: rect.minY + h * 0.02),
        ]
        return InkBrush.stroke(InkGeometry.smooth(points, density: 1), pen: pen, seed: seed, progress: progress)
    }
}

/// A square ticked the way you tick things on paper; the tick runs past the box.
struct InkCheckbox: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOn: Bool
    var seed: Int = 3

    var body: some View {
        ZStack {
            InkRoundedRect(seed: seed, cornerRadius: 6, pen: .fine)
                .fill(isOn ? Color.remnInk : Color.remnGraphite)
                .frame(width: 22, height: 22)
            InkTick(seed: seed &+ 5, progress: isOn ? 1 : 0)
                .fill(Color.remnAccent)
                .frame(width: 26, height: 24)
                .offset(x: 4, y: -5)
                .animation(reduceMotion ? nil : .easeOut(duration: isOn ? 0.28 : 0.12), value: isOn)
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

/// Circles a choice the way you would circle an answer on paper.
struct InkCircled: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOn: Bool
    let seed: Int
    var color: Color = .remnAccent
    var inset = CGSize(width: -12, height: -7)

    func body(content: Content) -> some View {
        content.background {
            InkEllipse(seed: seed, pen: .fine, progress: isOn ? 1 : 0)
                .fill(color)
                .padding(.horizontal, inset.width)
                .padding(.vertical, inset.height)
                .animation(reduceMotion ? nil : .easeOut(duration: isOn ? 0.38 : 0.1), value: isOn)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    func inkCircled(
        _ isOn: Bool = true,
        seed: Int,
        color: Color = .remnAccent,
        inset: CGSize = CGSize(width: -12, height: -7)
    ) -> some View {
        modifier(InkCircled(isOn: isOn, seed: seed, color: color, inset: inset))
    }
}

// MARK: - Choices

/// A row of words; the chosen one is circled.
struct InkChoiceRow<Value: Hashable>: View {
    struct Option: Identifiable {
        let value: Value
        let title: Text
        var id: Value { value }
    }

    @Binding var selection: Value
    let options: [Option]
    var seed: Int = 300

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let chosen = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    HandwrittenText(text: option.title)
                        .font(RemnTypography.control)
                        .foregroundStyle(chosen ? Color.remnInk : Color.remnGraphite)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .inkCircled(chosen, seed: seed &+ index &* 17)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - Slider

/// A pencil line with a red stroke up to a drawn knob.
struct InkSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accessibilityLabel: Text
    var marks: [Double] = []

    private let knob: CGFloat = 26

    var body: some View {
        GeometryReader { proxy in
            let travel = max(1, proxy.size.width - knob)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let knobX = travel * CGFloat(fraction)

            ZStack(alignment: .leading) {
                InkLine(seed: 611, pen: .hairline)
                    .fill(Color.remnGraphite.opacity(0.8))
                    .frame(height: 8)
                    .padding(.horizontal, knob / 2)

                InkLine(seed: 612, pen: .marker)
                    .fill(Color.remnAccent)
                    .frame(height: 10)
                    .padding(.horizontal, knob / 2)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: knobX + knob / 2)
                    }

                ForEach(marks, id: \.self) { mark in
                    let x = travel * CGFloat((mark - range.lowerBound) / (range.upperBound - range.lowerBound))
                    InkLine(seed: 613, pen: .fine)
                        .fill(Color.remnGraphite)
                        .frame(width: 10, height: 4)
                        .rotationEffect(.degrees(88))
                        .offset(x: x + knob / 2 - 5, y: 12)
                }

                ZStack {
                    Circle()
                        .fill(Color.remnCardPaper)
                        .padding(2)
                    InkEllipse(seed: 614, pen: .pen)
                        .fill(Color.remnInk)
                }
                .frame(width: knob, height: knob)
                .offset(x: knobX)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let fraction = min(max((gesture.location.x - knob / 2) / travel, 0), 1)
                        let raw = range.lowerBound + Double(fraction) * (range.upperBound - range.lowerBound)
                        let stepped = (raw / step).rounded() * step
                        value = min(range.upperBound, max(range.lowerBound, stepped))
                    }
            )
        }
        .frame(height: 44)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityRepresentation {
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
        }
    }
}
