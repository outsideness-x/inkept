import SwiftUI
import Synchronization

/// A small picture turned into paths at one size, ready to paint.
struct EmojiDrawing: Sendable {
    enum Piece: Sendable {
        case fill(Path, InkPencil, opacity: Double, evenOdd: Bool)
        case clipped(Path, [Piece])
        case text(String, at: CGPoint, size: CGFloat, InkPencil, font: EmojiArt.Font, weight: Double, rotation: CGFloat)
    }

    var pieces: [Piece]

    func draw(in context: inout GraphicsContext) {
        Self.draw(pieces, in: &context)
    }

    private static func draw(_ pieces: [Piece], in context: inout GraphicsContext) {
        for piece in pieces {
            switch piece {
            case .fill(let path, let pencil, let opacity, let evenOdd):
                context.fill(path, with: .color(pencil.color.opacity(opacity)), style: FillStyle(eoFill: evenOdd))
            case .clipped(let clip, let inside):
                context.drawLayer { layer in
                    layer.clip(to: clip)
                    draw(inside, in: &layer)
                }
            case .text(let string, let point, let size, let pencil, let font, let weight, let rotation):
                var lettering = context
                lettering.translateBy(x: point.x, y: point.y)
                lettering.rotate(by: .degrees(rotation))
                let text = lettering.resolve(
                    Text(verbatim: string)
                        .font(Self.font(font, size: size))
                        .foregroundStyle(pencil.color)
                )
                lettering.draw(text, at: .zero, anchor: .center)
                if weight > 0 {
                    // A second pass a hair to the side, the way the hand thickens a letter.
                    lettering.draw(text, at: CGPoint(x: weight * size * 0.03, y: weight * size * 0.015), anchor: .center)
                }
            }
        }
    }

    private static func font(_ font: EmojiArt.Font, size: CGFloat) -> Font {
        switch font {
        case .hand: .custom("Neucha", fixedSize: size)
        case .rounded: .system(size: size, weight: .heavy, design: .rounded)
        case .serif: .system(size: size, weight: .semibold, design: .serif)
        case .mono: .system(size: size, weight: .bold, design: .monospaced)
        }
    }
}

/// Draws `EmojiArt` with the ink engine: fills a touch off-register with softly uneven edges,
/// pencil hatching, and pen lines that press, taper and overshoot where they close.
enum EmojiRenderer {
    private static let cache = Mutex<[String: EmojiDrawing]>([:])

    /// The drawing for `key` at `size`, made once and kept.
    static func drawing(key: String, size: CGFloat, seed: Int, art: () -> EmojiArt) -> EmojiDrawing {
        let cacheKey = "\(key)|\(Int((size * 2).rounded()))"
        if let drawing = cache.withLock({ $0[cacheKey] }) { return drawing }
        let drawing = render(art(), size: size, seed: seed)
        cache.withLock { $0[cacheKey] = drawing }
        return drawing
    }

    static func render(_ art: EmojiArt, size: CGFloat, seed: Int) -> EmojiDrawing {
        var hand = EmojiHand(size: size, seed: seed)
        return EmojiDrawing(pieces: hand.render(art.layers))
    }
}

/// The hand behind the drawings. Works on the 32-point grid scaled up four times, so the brush's
/// sampling stays fine even for tiny strokes, and shrinks the result to the size asked for.
private struct EmojiHand {
    private static let work: CGFloat = 4

    let size: CGFloat
    let seed: Int
    private var counter = 0
    /// Grid units per display point, and display points per working unit.
    private let gridToDisplay: CGFloat
    private let workToDisplay: CGFloat
    /// How far the colour plate sits from the ink, in grid units.
    private let registration: CGSize

    init(size: CGFloat, seed: Int) {
        self.size = size
        self.seed = seed
        gridToDisplay = size / 32
        workToDisplay = size / (32 * Self.work)
        registration = CGSize(
            width: max(0.5, 0.42 * size / 32) / (size / 32),
            height: max(0.65, 0.56 * size / 32) / (size / 32)
        )
    }

    mutating func render(_ layers: [EmojiArt.Layer]) -> [EmojiDrawing.Piece] {
        layers.compactMap { render($0) }
    }

    private mutating func nextSeed() -> Int {
        counter += 1
        return seed &+ counter &* 7_919
    }

    private mutating func render(_ layer: EmojiArt.Layer) -> EmojiDrawing.Piece? {
        let seed = nextSeed()
        switch layer {
        case .fill(let figure, let pencil, let opacity, let evenOdd):
            return .fill(patch(figure, seed: seed).applying(scaleDown), pencil, opacity: opacity, evenOdd: evenOdd)

        case .hatch(let figure, let pencil, let angle, let gap, let opacity):
            let clip = patch(figure, seed: seed)
            let bounds = clip.boundingRect
            let spacing = max(gap * Self.work, 1.45 / workToDisplay)
            let width = max(0.42 * gridToDisplay, 0.5) / workToDisplay
            let pen = InkPen(width: width, touchDown: 0.7, liftOff: 0.45, attack: 4, release: 6, pressureVariation: 0.1)
            var strokes = Path()
            for (index, stroke) in InkGeometry.hatching(in: bounds, spacing: spacing, angle: angle * .pi / 180, seed: seed).enumerated() {
                InkBrush.addStroke(stroke, pen: pen, seed: seed &+ index, to: &strokes)
            }
            return .clipped(clip.applying(scaleDown), [.fill(strokes.applying(scaleDown), pencil, opacity: opacity, evenOdd: false)])

        case .ink(let figure, let pencil, let width, let opacity):
            let displayWidth = max(width * gridToDisplay, min(0.85, width * 0.9))
            let pen = InkPen(
                width: displayWidth / workToDisplay,
                touchDown: 0.55,
                liftOff: 0.32,
                attack: 1.3 * Self.work,
                release: 2.4 * Self.work,
                pressureVariation: 0.12
            )
            var path = Path()
            for (index, outline) in figure.outlines().enumerated() where outline.points.count > 1 {
                let strokeSeed = seed &+ index &* 131
                let line = outline.closed ? Self.handLoop(outline.points, seed: strokeSeed) : Self.handLine(outline.points, seed: strokeSeed)
                InkBrush.addStroke(line.map(work), pen: pen, seed: strokeSeed, to: &path)
            }
            return .fill(path.applying(scaleDown), pencil, opacity: opacity, evenOdd: false)

        case .dot(let center, let radius, let pencil):
            var random = InkRandom(seed: seed)
            let rx = radius * (1 + 0.08 * random.signed())
            let ry = radius * (1 + 0.08 * random.signed())
            let tilt = random.signed() * .pi
            let ellipse = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
                .applying(CGAffineTransform(rotationAngle: tilt))
                .applying(CGAffineTransform(translationX: center.x, y: center.y))
                .applying(CGAffineTransform(scaleX: gridToDisplay, y: gridToDisplay))
            return .fill(ellipse, pencil, opacity: 1, evenOdd: false)

        case .text(let string, let point, let textSize, let pencil, let font, let weight, let rotation):
            return .text(
                string,
                at: CGPoint(x: point.x * gridToDisplay, y: point.y * gridToDisplay),
                size: textSize * gridToDisplay,
                pencil,
                font: font,
                weight: weight,
                rotation: rotation
            )

        case .clipped(let figure, let inside):
            return .clipped(patch(figure, seed: seed).applying(scaleDown), render(inside))
        }
    }

    // MARK: - Geometry

    private var scaleDown: CGAffineTransform {
        CGAffineTransform(scaleX: workToDisplay, y: workToDisplay)
    }

    private func work(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * Self.work, y: point.y * Self.work)
    }

    /// The colour plate for a figure: softly uneven edges, shifted off the ink. In working units.
    private func patch(_ figure: EmojiFigure, seed: Int) -> Path {
        var path = Path()
        for (index, outline) in figure.outlines().enumerated() where outline.points.count > 2 {
            let points = Self.handPatch(outline.points, seed: seed &+ index &* 131).map { point in
                work(CGPoint(x: point.x + registration.width, y: point.y + registration.height))
            }
            path.addPath(InkBrush.closedOutline(points))
        }
        return path
    }

    // MARK: - The hand

    private static func handLoop(_ points: [CGPoint], seed: Int) -> [CGPoint] {
        let walker = EmojiWalker(points, closed: true)
        let length = walker.length
        guard length > 0.4 else { return points }
        var random = InkRandom(seed: seed)
        let start = random.unit() * length
        let overshoot = min(max(length * 0.07, 0.5), 2.2) * random.value(in: 0.8...1.2)
        let amplitude = min(0.2, 0.05 + length * 0.0032)
        let landing = random.value(in: 0.12...0.3) * (random.unit() < 0.5 ? -1 : 1)
        let flick = random.value(in: 0.18...0.4) * (landing > 0 ? -1 : 1)
        var result: [CGPoint] = []
        result.reserveCapacity(Int((length + overshoot) / 0.25) + 2)
        var travelled: CGFloat = 0
        while travelled <= length + overshoot {
            let (point, normal) = walker.sample(at: start + travelled)
            var displacement = amplitude * InkNoise.value(travelled / 4.2, seed: seed)
            displacement += amplitude * 0.3 * InkNoise.value(travelled / 1.1, seed: seed ^ 0x51)
            displacement += landing * exp(-travelled / 1.1)
            let tail = travelled - length
            if tail > 0 {
                let t = tail / overshoot
                displacement += flick * t * t
            }
            result.append(CGPoint(x: point.x + normal.dx * displacement, y: point.y + normal.dy * displacement))
            travelled += 0.25
        }
        return result
    }

    private static func handLine(_ points: [CGPoint], seed: Int) -> [CGPoint] {
        let walker = EmojiWalker(points, closed: false)
        let length = walker.length
        guard length > 0.3 else { return points }
        var random = InkRandom(seed: seed)
        let lead = random.value(in: -0.15...0.3)
        let trail = random.value(in: -0.1...0.35)
        let amplitude = min(0.15, 0.04 + length * 0.0035)
        let sag = points.count == 2 ? min(length * 0.012, 0.3) * random.signed() : 0
        let total = length + lead + trail
        var result: [CGPoint] = []
        var travelled = -lead
        while travelled <= length + trail {
            let (point, normal) = walker.sample(at: travelled)
            let t = (travelled + lead) / max(total, 0.001)
            let displacement = amplitude * InkNoise.value(travelled / 4.2, seed: seed) + sag * 4 * t * (1 - t)
            result.append(CGPoint(x: point.x + normal.dx * displacement, y: point.y + normal.dy * displacement))
            travelled += 0.25
        }
        return result
    }

    private static func handPatch(_ points: [CGPoint], seed: Int) -> [CGPoint] {
        let walker = EmojiWalker(points, closed: true)
        let length = walker.length
        guard length > 0.4 else { return points }
        let amplitude = min(0.24, 0.05 + length * 0.0035)
        var result: [CGPoint] = []
        var travelled: CGFloat = 0
        while travelled < length {
            let (point, normal) = walker.sample(at: travelled)
            let displacement = amplitude * InkNoise.value(travelled / 5, seed: seed ^ 0xF111)
            result.append(CGPoint(x: point.x + normal.dx * displacement, y: point.y + normal.dy * displacement))
            travelled += 0.3
        }
        return result
    }
}

/// Walks along a line by distance, with the direction it faces at each point.
private struct EmojiWalker {
    private let points: [CGPoint]
    private let cumulative: [CGFloat]
    private let closed: Bool
    let length: CGFloat

    init(_ points: [CGPoint], closed: Bool) {
        var points = points
        if closed, let first = points.first, let last = points.last, hypot(first.x - last.x, first.y - last.y) > 0.0001 {
            points.append(first)
        }
        self.points = points
        self.closed = closed
        var cumulative: [CGFloat] = [0]
        cumulative.reserveCapacity(points.count)
        for index in 1..<max(points.count, 1) {
            let a = points[index - 1]
            let b = points[index]
            cumulative.append(cumulative[index - 1] + hypot(b.x - a.x, b.y - a.y))
        }
        self.cumulative = cumulative
        length = cumulative.last ?? 0
    }

    /// The point `distance` along, wrapping round a closed line and running straight on past the ends of an open one.
    func sample(at distance: CGFloat) -> (CGPoint, CGVector) {
        guard points.count > 1, length > 0 else { return (points.first ?? .zero, CGVector(dx: 0, dy: -1)) }
        var distance = distance
        if closed {
            distance = distance.truncatingRemainder(dividingBy: length)
            if distance < 0 { distance += length }
        }
        let segment: Int
        if distance <= 0 {
            segment = 1
        } else if distance >= length {
            segment = points.count - 1
        } else {
            var low = 1
            var high = points.count - 1
            while low < high {
                let middle = (low + high) / 2
                if cumulative[middle] < distance { low = middle + 1 } else { high = middle }
            }
            segment = low
        }
        let a = points[segment - 1]
        let b = points[segment]
        let span = max(cumulative[segment] - cumulative[segment - 1], 0.0001)
        let t = (distance - cumulative[segment - 1]) / span
        let dx = (b.x - a.x) / span
        let dy = (b.y - a.y) / span
        return (CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), CGVector(dx: -dy, dy: dx))
    }
}
