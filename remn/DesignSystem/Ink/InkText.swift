import SwiftUI

extension EnvironmentValues {
    /// How much of the ink in this subtree has been laid down: 0 is blank paper, 1 is finished.
    @Entry var inkProgress: Double = 1
    /// How irregular hand lettering is; 0 draws type exactly as laid out.
    @Entry var inkWobble: Double = 1
}

/// Draws text glyph by glyph with the small irregularities of hand lettering, and writes it on
/// as if a pen were moving through the line. `weight` goes over the letters a second time.
struct InkTextRenderer: TextRenderer, Animatable {
    var progress: Double = 1
    var wobble: Double = 1
    var weight: Double = 0

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Just enough room for a tilted letter. SwiftUI wraps lines as if the side padding were part of the
    /// width, so anything wider makes wrapped text run past its frame.
    var displayPadding: EdgeInsets {
        EdgeInsets(top: 3, leading: 1, bottom: 3, trailing: 1)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        if progress >= 1, wobble == 0, weight == 0 {
            for line in layout {
                context.draw(line)
            }
            return
        }

        let slices = layout.flatMap { line in line.flatMap { run in run } }
        let fade = 2.5
        let head = progress * (Double(slices.count) + fade)

        for (index, slice) in slices.enumerated() {
            let appearance = min(max((head - Double(index)) / fade, 0), 1)
            guard appearance > 0 else { break }

            let bounds = slice.typographicBounds.rect
            var random = InkRandom(seed: index &* 7_919 &+ Int((bounds.width * 8).rounded()))
            let angle = random.signed() * 1.5 * wobble
            let lift = random.signed() * bounds.height * 0.022 * wobble
            let scale = 1 + random.signed() * 0.018 * wobble

            var glyph = context
            glyph.translateBy(x: bounds.midX, y: bounds.midY + lift)
            glyph.rotate(by: .degrees(angle))
            glyph.scaleBy(x: scale, y: scale)
            glyph.translateBy(x: -bounds.midX, y: -bounds.midY)
            if appearance < 1 {
                glyph.opacity = appearance * appearance
                glyph.addFilter(.blur(radius: (1 - appearance) * 1.2))
            }
            glyph.draw(slice, options: .disablesSubpixelQuantization)
            if weight > 0 {
                var second = glyph
                second.translateBy(x: weight * 0.55, y: weight * 0.3)
                second.draw(slice, options: .disablesSubpixelQuantization)
            }
        }
    }
}

/// Text in the hand the rest of the interface is drawn in.
struct HandwrittenText: View {
    @Environment(\.inkProgress) private var progress
    @Environment(\.inkWobble) private var wobble

    private let content: Text
    private let weight: Double

    init(_ key: LocalizedStringKey, weight: Double = 0) {
        content = Text(key)
        self.weight = weight
    }

    init(verbatim value: String, weight: Double = 0) {
        content = Text(verbatim: value)
        self.weight = weight
    }

    init(text: Text, weight: Double = 0) {
        content = text
        self.weight = weight
    }

    var body: some View {
        content
            .textRenderer(InkTextRenderer(progress: progress, wobble: wobble, weight: weight))
    }
}

/// Lays the ink of a subtree down once, when it first appears.
private struct InkWritesOn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let duration: Double
    let delay: Double

    @State private var progress: Double = 0

    func body(content: Content) -> some View {
        content
            .environment(\.inkProgress, reduceMotion ? 1 : progress)
            .onAppear {
                guard progress < 1 else { return }
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(.easeOut(duration: duration).delay(delay)) { progress = 1 }
                }
            }
    }
}

extension View {
    /// Writes text and draws strokes in this view the first time it appears.
    func inkWritesOn(duration: Double = 0.7, delay: Double = 0) -> some View {
        modifier(InkWritesOn(duration: duration, delay: delay))
    }
}
