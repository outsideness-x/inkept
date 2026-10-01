import SwiftUI

/// A rounded rectangle drawn in one pen stroke. Fill it with the ink colour.
struct InkRoundedRect: Shape {
    var seed: Int
    var cornerRadius: CGFloat = 14
    var pen: InkPen = .pen
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        InkBrush.stroke(
            InkGeometry.roundedRectLoop(in: rect, cornerRadius: cornerRadius, seed: seed),
            pen: pen,
            seed: seed,
            progress: progress
        )
    }
}

/// The inside of a hand-drawn rounded rectangle, for paper and colour.
struct InkPatch: Shape {
    var seed: Int
    var cornerRadius: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        InkBrush.closedOutline(InkGeometry.roundedRectPatch(in: rect, cornerRadius: cornerRadius, seed: seed))
    }
}

/// A line through the middle of its frame, across it or, when `vertical`, down it.
struct InkLine: Shape {
    var seed: Int
    var pen: InkPen = .fine
    var vertical = false
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let start = vertical ? CGPoint(x: rect.midX, y: rect.minY) : CGPoint(x: rect.minX, y: rect.midY)
        let end = vertical ? CGPoint(x: rect.midX, y: rect.maxY) : CGPoint(x: rect.maxX, y: rect.midY)
        return InkBrush.stroke(
            InkGeometry.line(from: start, to: end, seed: seed),
            pen: pen,
            seed: seed,
            progress: progress
        )
    }
}

/// A dashed pencil line, like the fold between the two sides of a card.
struct InkDashes: Shape {
    var seed: Int
    var pen: InkPen = .fine

    func path(in rect: CGRect) -> Path {
        var random = InkRandom(seed: seed)
        var path = Path()
        var x = rect.minX + random.value(in: 0...4)
        var index = 0
        while x < rect.maxX - 3 {
            let dash = min(random.value(in: 5...9), rect.maxX - x)
            let y = rect.midY + random.value(in: -0.5...0.5)
            let points = InkGeometry.line(
                from: CGPoint(x: x, y: y),
                to: CGPoint(x: x + dash, y: y + random.value(in: -0.4...0.4)),
                seed: seed &+ index,
                bow: 0
            )
            InkBrush.addStroke(points, pen: pen, seed: seed &+ index, to: &path)
            x += dash + random.value(in: 4.5...7)
            index += 1
        }
        return path
    }
}

/// A quick underline that flicks up at the end.
struct InkUnderline: Shape {
    var seed: Int
    var pen: InkPen = .bold
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        InkBrush.stroke(InkGeometry.underline(in: rect, seed: seed), pen: pen, seed: seed, progress: progress)
    }
}

/// A loop around an ellipse that doesn't quite meet itself.
struct InkEllipse: Shape {
    var seed: Int
    var pen: InkPen = .pen
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        InkBrush.stroke(InkGeometry.ellipseLoop(in: rect, seed: seed), pen: pen, seed: seed, progress: progress)
    }
}

/// Diagonal hatching across the frame. Clip it to the shape it shades.
struct InkHatch: Shape {
    var seed: Int
    var spacing: CGFloat = 4.5
    var angle: Angle = .degrees(-52)
    var pen: InkPen = .hairline

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let strokes = InkGeometry.hatching(in: rect, spacing: spacing, angle: angle.radians, seed: seed)
        for (index, stroke) in strokes.enumerated() {
            InkBrush.addStroke(stroke, pen: pen, seed: seed &+ index, to: &path)
        }
        return path
    }
}

/// An ink shape that can be drawn partway.
protocol InkDrawable: Shape {
    var progress: CGFloat { get set }
}

extension InkRoundedRect: InkDrawable {}
extension InkLine: InkDrawable {}
extension InkUnderline: InkDrawable {}
extension InkEllipse: InkDrawable {}

/// Fills an ink shape and follows the surrounding `inkProgress`, so it draws on with nearby text.
struct Inked<S: InkDrawable>: View {
    @Environment(\.inkProgress) private var progress
    let shape: S
    let color: Color

    var body: some View {
        var shape = shape
        shape.progress = min(shape.progress, CGFloat(progress))
        return shape.fill(color)
    }
}

extension InkDrawable {
    func ink(_ color: Color) -> Inked<Self> {
        Inked(shape: self, color: color)
    }
}
