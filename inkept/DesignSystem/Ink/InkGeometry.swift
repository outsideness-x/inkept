import CoreGraphics

/// Centerlines for the shapes a hand draws. Every shape wobbles a little, and closed
/// shapes are drawn as one continuous movement that overshoots where it started.
enum InkGeometry {
    // MARK: - Rounded rectangles

    /// One pen loop around a rounded rectangle, starting on the top edge.
    static func roundedRectLoop(in rect: CGRect, cornerRadius: CGFloat, seed: Int) -> [CGPoint] {
        guard rect.width > 1, rect.height > 1 else { return [] }
        var random = InkRandom(seed: seed)
        let perimeter = RoundedPerimeter(rect: rect, cornerRadius: cornerRadius, random: &random)
        let size = min(rect.width, rect.height)
        let amplitude = min(1.4, 0.5 + size * 0.0045)
        let start = perimeter.topLength * random.value(in: 0.12...0.42)
        let overshoot = min(max(rect.width * 0.06, 6), 20) * random.value(in: 0.8...1.2)
        let travel = perimeter.length + overshoot
        // The pen lands a little off the line and settles; it leaves with a flick across the start.
        let landing = random.value(in: 0.5...1.3) * (random.unit() < 0.5 ? -1 : 1)
        let flick = random.value(in: 0.7...1.5) * (landing > 0 ? -1 : 1)
        let step = max(2, perimeter.length / 420)

        var points = [CGPoint]()
        points.reserveCapacity(Int(travel / step) + 2)
        var travelled: CGFloat = 0
        while travelled <= travel {
            let (point, normal) = perimeter.point(at: start + travelled)
            var displacement = amplitude * InkNoise.value(travelled / 64, seed: seed)
            displacement += 0.16 * InkNoise.value(travelled / 9, seed: seed ^ 0x7A11)
            displacement += landing * exp(-travelled / 16)
            let tail = travelled - perimeter.length
            if tail > 0 {
                let t = tail / overshoot
                displacement += flick * t * t
            }
            points.append(CGPoint(x: point.x + normal.dx * displacement, y: point.y + normal.dy * displacement))
            travelled += step
        }
        return points
    }

    /// A closed, softly irregular patch the size of a rounded rectangle, for paper and colour fills.
    static func roundedRectPatch(in rect: CGRect, cornerRadius: CGFloat, seed: Int) -> [CGPoint] {
        guard rect.width > 1, rect.height > 1 else { return [] }
        var random = InkRandom(seed: seed)
        let perimeter = RoundedPerimeter(rect: rect, cornerRadius: cornerRadius, random: &random)
        let amplitude = min(0.9, 0.3 + min(rect.width, rect.height) * 0.003)
        let step = max(3, perimeter.length / 220)
        var points = [CGPoint]()
        var travelled: CGFloat = 0
        while travelled < perimeter.length {
            let (point, normal) = perimeter.point(at: travelled)
            let displacement = amplitude * InkNoise.value(travelled / 60, seed: seed ^ 0xF111)
            points.append(CGPoint(x: point.x + normal.dx * displacement, y: point.y + normal.dy * displacement))
            travelled += step
        }
        return points
    }

    // MARK: - Lines

    /// A hand-drawn line with a slight bow and a little over- or undershoot at the ends.
    static func line(from start: CGPoint, to end: CGPoint, seed: Int, bow: CGFloat? = nil) -> [CGPoint] {
        var random = InkRandom(seed: seed)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.5 else { return [start, end] }
        let direction = CGVector(dx: dx / length, dy: dy / length)
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let lead = random.value(in: -1.2...1.6)
        let trail = random.value(in: -1.2...2.2)
        let from = CGPoint(x: start.x - direction.dx * lead, y: start.y - direction.dy * lead)
        let to = CGPoint(x: end.x + direction.dx * trail, y: end.y + direction.dy * trail)
        let sag = bow ?? min(length * 0.01, 2.2) * random.signed()
        let amplitude = min(0.9, 0.22 + length * 0.002)

        let count = max(2, Int(length / 2.5))
        return (0...count).map { index in
            let t = CGFloat(index) / CGFloat(count)
            let base = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
            let displacement = sag * 4 * t * (1 - t)
                + amplitude * InkNoise.value(t * length / 55, seed: seed)
            return CGPoint(x: base.x + normal.dx * displacement, y: base.y + normal.dy * displacement)
        }
    }

    /// A quick underline that dips a little and flicks up where the pen leaves the paper.
    static func underline(in rect: CGRect, seed: Int) -> [CGPoint] {
        var random = InkRandom(seed: seed)
        let dip = random.value(in: 0.6...1.4)
        let flick = random.value(in: 1.2...2.6)
        let width = rect.width
        let count = max(2, Int(width / 2.5))
        return (0...count).map { index in
            let t = CGFloat(index) / CGFloat(count)
            let lift = t > 0.78 ? pow((t - 0.78) / 0.22, 2) * flick : 0
            let y = rect.midY + dip * sin(.pi * t) - lift
                + 0.35 * InkNoise.value(t * width / 40, seed: seed)
            return CGPoint(x: rect.minX + width * t, y: y)
        }
    }

    // MARK: - Ellipses

    /// A loop around an ellipse that doesn't quite meet itself.
    static func ellipseLoop(in rect: CGRect, seed: Int, overshoot: CGFloat = 0.38) -> [CGPoint] {
        var random = InkRandom(seed: seed)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2
        let startAngle = random.value(in: -2.6 ... -1.2)
        let sweep = 2 * .pi + overshoot * random.value(in: 0.7...1.3)
        let drift = random.value(in: 0.035...0.07) * (random.unit() < 0.5 ? -1 : 1)
        let circumference = .pi * (radiusX + radiusY)
        let count = max(12, Int(circumference * sweep / (2 * .pi) / 2))
        return (0...count).map { index in
            let t = CGFloat(index) / CGFloat(count)
            let angle = startAngle + sweep * t
            let scale = 1 + drift * (t - 0.5) + 0.02 * InkNoise.value(t * 5, seed: seed)
            return CGPoint(
                x: center.x + cos(angle) * radiusX * scale,
                y: center.y + sin(angle) * radiusY * scale
            )
        }
    }

    // MARK: - Hatching

    /// Parallel diagonal strokes covering `rect`; clip them to the shape they fill.
    static func hatching(in rect: CGRect, spacing: CGFloat, angle: CGFloat, seed: Int) -> [[CGPoint]] {
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let reach = hypot(rect.width, rect.height) / 2 + spacing
        var strokes = [[CGPoint]]()
        var offset = -reach
        var index = 0
        while offset <= reach {
            let jitter = InkNoise.lattice(index, seed: seed) * spacing * 0.18
            let middle = CGPoint(
                x: center.x + normal.dx * (offset + jitter),
                y: center.y + normal.dy * (offset + jitter)
            )
            let start = CGPoint(x: middle.x - direction.dx * reach, y: middle.y - direction.dy * reach)
            let end = CGPoint(x: middle.x + direction.dx * reach, y: middle.y + direction.dy * reach)
            strokes.append(line(from: start, to: end, seed: seed &+ index &* 31, bow: 0))
            offset += spacing
            index += 1
        }
        return strokes
    }

    // MARK: - Smoothing

    /// A smooth curve through control points (Catmull-Rom), for doodles and icons.
    static func smooth(_ controls: [CGPoint], density: CGFloat = 1.5) -> [CGPoint] {
        guard controls.count > 2 else { return controls }
        var points = [controls[0]]
        for index in 0..<(controls.count - 1) {
            let p0 = controls[max(index - 1, 0)]
            let p1 = controls[index]
            let p2 = controls[index + 1]
            let p3 = controls[min(index + 2, controls.count - 1)]
            let steps = max(2, Int(hypot(p2.x - p1.x, p2.y - p1.y) / density))
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let t2 = t * t
                let t3 = t2 * t
                let x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t
                    + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
                    + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
                let y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t
                    + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
                    + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
                points.append(CGPoint(x: x, y: y))
            }
        }
        return points
    }
}

/// Arc-length parametrisation of a rounded rectangle with slightly uneven corners, clockwise from the top-left.
private struct RoundedPerimeter {
    private enum Segment {
        case line(from: CGPoint, to: CGPoint, normal: CGVector)
        case arc(center: CGPoint, radius: CGFloat, from: CGFloat, to: CGFloat)

        var length: CGFloat {
            switch self {
            case .line(let from, let to, _): hypot(to.x - from.x, to.y - from.y)
            case .arc(_, let radius, let from, let to): radius * abs(to - from)
            }
        }

        func point(at distance: CGFloat) -> (CGPoint, CGVector) {
            switch self {
            case .line(let from, let to, let normal):
                let length = max(self.length, 0.0001)
                let t = distance / length
                return (CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t), normal)
            case .arc(let center, let radius, let from, let to):
                let span = to - from
                let angle = radius > 0 ? from + span * (distance / max(self.length, 0.0001)) : from
                let normal = CGVector(dx: cos(angle), dy: sin(angle))
                return (CGPoint(x: center.x + normal.dx * radius, y: center.y + normal.dy * radius), normal)
            }
        }
    }

    private let segments: [Segment]
    let length: CGFloat
    let topLength: CGFloat

    init(rect: CGRect, cornerRadius: CGFloat, random: inout InkRandom) {
        let limit = min(rect.width, rect.height) / 2
        let radii = (0..<4).map { _ in min(max(cornerRadius * random.value(in: 0.82...1.22), 0), limit) }
        let (topLeft, topRight, bottomRight, bottomLeft) = (radii[0], radii[1], radii[2], radii[3])
        let segments: [Segment] = [
            .line(
                from: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                to: CGPoint(x: rect.maxX - topRight, y: rect.minY),
                normal: CGVector(dx: 0, dy: -1)
            ),
            .arc(
                center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                radius: topRight, from: -.pi / 2, to: 0
            ),
            .line(
                from: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight),
                normal: CGVector(dx: 1, dy: 0)
            ),
            .arc(
                center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                radius: bottomRight, from: 0, to: .pi / 2
            ),
            .line(
                from: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY),
                normal: CGVector(dx: 0, dy: 1)
            ),
            .arc(
                center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                radius: bottomLeft, from: .pi / 2, to: .pi
            ),
            .line(
                from: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                to: CGPoint(x: rect.minX, y: rect.minY + topLeft),
                normal: CGVector(dx: -1, dy: 0)
            ),
            .arc(
                center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                radius: topLeft, from: .pi, to: .pi * 1.5
            ),
        ]
        self.segments = segments
        length = segments.reduce(0) { $0 + $1.length }
        topLength = segments[0].length
    }

    func point(at distance: CGFloat) -> (CGPoint, CGVector) {
        var remaining = distance.truncatingRemainder(dividingBy: max(length, 0.0001))
        if remaining < 0 { remaining += length }
        for segment in segments {
            let segmentLength = segment.length
            if remaining <= segmentLength {
                return segment.point(at: remaining)
            }
            remaining -= segmentLength
        }
        return segments[0].point(at: 0)
    }
}
