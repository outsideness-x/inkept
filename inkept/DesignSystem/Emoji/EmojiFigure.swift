import CoreGraphics
import Foundation

/// An outline on the 32-point grid small pictures are drawn on. Angles are in degrees,
/// clockwise from three o'clock, as on the screen.
indirect enum EmojiFigure: Sendable {
    case polygon([CGPoint])
    case polyline([CGPoint])
    /// A smooth curve through the points.
    case smooth([CGPoint], closed: Bool)
    case ellipse(center: CGPoint, rx: CGFloat, ry: CGFloat, rotation: CGFloat)
    case arc(center: CGPoint, rx: CGFloat, ry: CGFloat, from: CGFloat, to: CGFloat, rotation: CGFloat)
    case roundedRect(CGRect, corner: CGFloat)
    /// SVG path data, for shapes easier to write as curves.
    case svg(String)
    /// Several outlines drawn or filled together.
    case group([EmojiFigure])
    case transformed(EmojiFigure, CGAffineTransform)

    // MARK: - Building

    static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> EmojiFigure {
        .ellipse(center: CGPoint(x: x, y: y), rx: r, ry: r, rotation: 0)
    }

    static func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, rotation: CGFloat = 0) -> EmojiFigure {
        .ellipse(center: CGPoint(x: x, y: y), rx: rx, ry: ry, rotation: rotation)
    }

    static func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, r: CGFloat = 0) -> EmojiFigure {
        .roundedRect(CGRect(x: x, y: y, width: width, height: height), corner: r)
    }

    /// A closed shape with straight sides through `x, y` pairs.
    static func poly(_ coordinates: CGFloat...) -> EmojiFigure {
        .polygon(points(coordinates))
    }

    /// An open line through `x, y` pairs.
    static func line(_ coordinates: CGFloat...) -> EmojiFigure {
        .polyline(points(coordinates))
    }

    /// An open, smooth line through `x, y` pairs.
    static func curve(_ coordinates: CGFloat...) -> EmojiFigure {
        .smooth(points(coordinates), closed: false)
    }

    /// A closed, smooth shape through `x, y` pairs.
    static func blob(_ coordinates: CGFloat...) -> EmojiFigure {
        .smooth(points(coordinates), closed: true)
    }

    static func path(_ data: String) -> EmojiFigure {
        .svg(data)
    }

    static func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, from: CGFloat, to: CGFloat) -> EmojiFigure {
        .arc(center: CGPoint(x: x, y: y), rx: r, ry: r, from: from, to: to, rotation: 0)
    }

    static func star(
        _ x: CGFloat, _ y: CGFloat, _ outer: CGFloat,
        inner: CGFloat? = nil, points count: Int = 5, rotation: CGFloat = -90
    ) -> EmojiFigure {
        let inner = inner ?? outer * 0.42
        let step = CGFloat.pi / CGFloat(count)
        let start = rotation * .pi / 180
        return .polygon((0..<(count * 2)).map { index in
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = start + step * CGFloat(index)
            return CGPoint(x: x + cos(angle) * radius, y: y + sin(angle) * radius)
        })
    }

    static func ngon(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, sides: Int, rotation: CGFloat = -90) -> EmojiFigure {
        let start = rotation * .pi / 180
        return .polygon((0..<sides).map { index in
            let angle = start + 2 * .pi * CGFloat(index) / CGFloat(sides)
            return CGPoint(x: x + cos(angle) * r, y: y + sin(angle) * r)
        })
    }

    /// A cog with `teeth` teeth between the `inner` and `outer` radii.
    static func gear(_ x: CGFloat, _ y: CGFloat, outer: CGFloat, inner: CGFloat, teeth: Int, rotation: CGFloat = 0) -> EmojiFigure {
        let pitch = 2 * CGFloat.pi / CGFloat(teeth)
        let start = rotation * .pi / 180
        var points: [CGPoint] = []
        for tooth in 0..<teeth {
            let angle = start + pitch * CGFloat(tooth)
            for (offset, radius) in [(-0.5, inner), (-0.26, outer), (0.26, outer), (0.5, inner)] {
                let a = angle + pitch * CGFloat(offset) * 0.9
                points.append(CGPoint(x: x + cos(a) * radius, y: y + sin(a) * radius))
            }
        }
        return .polygon(points)
    }

    /// A point turned about a centre, for placing things on something drawn at an angle.
    static func turn(_ x: CGFloat, _ y: CGFloat, _ degrees: CGFloat, around cx: CGFloat = 16, _ cy: CGFloat = 16) -> CGPoint {
        let angle = degrees * .pi / 180
        let dx = x - cx
        let dy = y - cy
        return CGPoint(x: cx + dx * cos(angle) - dy * sin(angle), y: cy + dx * sin(angle) + dy * cos(angle))
    }

    func rotated(_ degrees: CGFloat, around x: CGFloat = 16, _ y: CGFloat = 16) -> EmojiFigure {
        .transformed(self, CGAffineTransform(translationX: x, y: y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -x, y: -y))
    }

    func moved(_ dx: CGFloat, _ dy: CGFloat) -> EmojiFigure {
        .transformed(self, CGAffineTransform(translationX: dx, y: dy))
    }

    func scaled(_ sx: CGFloat, _ sy: CGFloat? = nil, around x: CGFloat = 16, _ y: CGFloat = 16) -> EmojiFigure {
        .transformed(self, CGAffineTransform(translationX: x, y: y)
            .scaledBy(x: sx, y: sy ?? sx)
            .translatedBy(x: -x, y: -y))
    }

    /// The same figure reflected across the vertical line through `x`.
    func mirrored(around x: CGFloat = 16) -> EmojiFigure {
        .transformed(self, CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * x, ty: 0))
    }

    private static func points(_ coordinates: [CGFloat]) -> [CGPoint] {
        stride(from: 0, to: coordinates.count - 1, by: 2).map { CGPoint(x: coordinates[$0], y: coordinates[$0 + 1]) }
    }

    // MARK: - Flattening

    /// The figure as lines through closely spaced points.
    func outlines() -> [EmojiOutline] {
        switch self {
        case .polygon(let points):
            return [EmojiOutline(points: points, closed: true)]
        case .polyline(let points):
            return [EmojiOutline(points: points, closed: false)]
        case .smooth(let points, let closed):
            return [EmojiOutline(points: EmojiCurves.catmullRom(points, closed: closed), closed: closed)]
        case .ellipse(let center, let rx, let ry, let rotation):
            let count = max(28, Int(.pi * (rx + ry) / 0.28))
            let points = (0..<count).map { index in
                EmojiCurves.ellipsePoint(center, rx, ry, rotation, 2 * .pi * CGFloat(index) / CGFloat(count))
            }
            return [EmojiOutline(points: points, closed: true)]
        case .arc(let center, let rx, let ry, let from, let to, let rotation):
            let start = from * .pi / 180
            let sweep = (to - from) * .pi / 180
            let count = max(6, Int(abs(sweep) * (rx + ry) / 2 / 0.28))
            let points = (0...count).map { index in
                EmojiCurves.ellipsePoint(center, rx, ry, rotation, start + sweep * CGFloat(index) / CGFloat(count))
            }
            return [EmojiOutline(points: points, closed: false)]
        case .roundedRect(let rect, let corner):
            return [EmojiOutline(points: EmojiCurves.roundedRect(rect, corner: corner), closed: true)]
        case .svg(let data):
            return EmojiSVGPath.outlines(data)
        case .group(let figures):
            return figures.flatMap { $0.outlines() }
        case .transformed(let figure, let transform):
            return figure.outlines().map { outline in
                EmojiOutline(points: outline.points.map { $0.applying(transform) }, closed: outline.closed)
            }
        }
    }
}

/// One continuous line of a figure.
struct EmojiOutline: Sendable {
    var points: [CGPoint]
    var closed: Bool
}

enum EmojiCurves {
    static func ellipsePoint(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ rotation: CGFloat, _ angle: CGFloat) -> CGPoint {
        let tilt = rotation * .pi / 180
        let x = cos(angle) * rx
        let y = sin(angle) * ry
        return CGPoint(
            x: center.x + x * cos(tilt) - y * sin(tilt),
            y: center.y + x * sin(tilt) + y * cos(tilt)
        )
    }

    static func roundedRect(_ rect: CGRect, corner: CGFloat) -> [CGPoint] {
        let radius = min(max(corner, 0), min(rect.width, rect.height) / 2)
        guard radius > 0.05 else {
            return [
                CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
            ]
        }
        var points: [CGPoint] = []
        let corners: [(CGPoint, CGFloat)] = [
            (CGPoint(x: rect.maxX - radius, y: rect.minY + radius), -.pi / 2),
            (CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), 0),
            (CGPoint(x: rect.minX + radius, y: rect.maxY - radius), .pi / 2),
            (CGPoint(x: rect.minX + radius, y: rect.minY + radius), .pi),
        ]
        let steps = max(4, Int(radius * .pi / 2 / 0.28))
        for (center, start) in corners {
            for step in 0...steps {
                let angle = start + .pi / 2 * CGFloat(step) / CGFloat(steps)
                points.append(CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            }
        }
        return points
    }

    /// A smooth curve through control points; a closed one wraps around.
    static func catmullRom(_ controls: [CGPoint], closed: Bool) -> [CGPoint] {
        guard controls.count > 2 else { return controls }
        let count = controls.count
        func control(_ index: Int) -> CGPoint {
            if closed { return controls[(index % count + count) % count] }
            return controls[min(max(index, 0), count - 1)]
        }
        var points: [CGPoint] = [controls[0]]
        let segments = closed ? count : count - 1
        for index in 0..<segments {
            let p0 = control(index - 1)
            let p1 = control(index)
            let p2 = control(index + 1)
            let p3 = control(index + 2)
            let steps = max(3, Int(hypot(p2.x - p1.x, p2.y - p1.y) / 0.25))
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
        if closed { points.removeLast() }
        return points
    }

    static func cubic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> [CGPoint] {
        let length = hypot(p1.x - p0.x, p1.y - p0.y) + hypot(p2.x - p1.x, p2.y - p1.y) + hypot(p3.x - p2.x, p3.y - p2.y)
        let steps = max(4, Int(length / 0.25))
        return (1...steps).map { step in
            let t = CGFloat(step) / CGFloat(steps)
            let u = 1 - t
            let a = u * u * u
            let b = 3 * u * u * t
            let c = 3 * u * t * t
            let d = t * t * t
            return CGPoint(
                x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
                y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
            )
        }
    }

    static func quadratic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> [CGPoint] {
        cubic(
            p0,
            CGPoint(x: p0.x + 2 / 3 * (p1.x - p0.x), y: p0.y + 2 / 3 * (p1.y - p0.y)),
            CGPoint(x: p2.x + 2 / 3 * (p1.x - p2.x), y: p2.y + 2 / 3 * (p1.y - p2.y)),
            p2
        )
    }

    /// An SVG elliptical arc from `start` to `end`.
    static func svgArc(
        from start: CGPoint, to end: CGPoint, rx: CGFloat, ry: CGFloat,
        rotation: CGFloat, largeArc: Bool, sweep: Bool
    ) -> [CGPoint] {
        var rx = abs(rx)
        var ry = abs(ry)
        guard rx > 0.001, ry > 0.001, start != end else { return [end] }
        let phi = rotation * .pi / 180
        let dx = (start.x - end.x) / 2
        let dy = (start.y - end.y) / 2
        let x1 = cos(phi) * dx + sin(phi) * dy
        let y1 = -sin(phi) * dx + cos(phi) * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 {
            rx *= sqrt(lambda)
            ry *= sqrt(lambda)
        }
        let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var factor = sqrt(max(0, numerator / denominator))
        if largeArc == sweep { factor = -factor }
        let cx1 = factor * rx * y1 / ry
        let cy1 = -factor * ry * x1 / rx
        let center = CGPoint(
            x: cos(phi) * cx1 - sin(phi) * cy1 + (start.x + end.x) / 2,
            y: sin(phi) * cx1 + cos(phi) * cy1 + (start.y + end.y) / 2
        )
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let sign: CGFloat = ux * vy - uy * vx < 0 ? -1 : 1
            let dot = (ux * vx + uy * vy) / (hypot(ux, uy) * hypot(vx, vy))
            return sign * acos(min(max(dot, -1), 1))
        }
        let theta = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep, delta > 0 { delta -= 2 * .pi }
        if sweep, delta < 0 { delta += 2 * .pi }
        let steps = max(4, Int(abs(delta) * (rx + ry) / 2 / 0.25))
        return (1...steps).map { step in
            let t = theta + delta * CGFloat(step) / CGFloat(steps)
            let x = cos(t) * rx
            let y = sin(t) * ry
            return CGPoint(x: center.x + x * cos(phi) - y * sin(phi), y: center.y + x * sin(phi) + y * cos(phi))
        }
    }
}

/// Reads SVG path data: moves, lines, cubic and quadratic curves, arcs and closes.
enum EmojiSVGPath {
    static func outlines(_ data: String) -> [EmojiOutline] {
        var tokens = Tokens(data)
        var outlines: [EmojiOutline] = []
        var points: [CGPoint] = []
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint?
        var lastQuadratic: CGPoint?
        var command: Character = "M"

        func finish(closed: Bool) {
            if points.count > 1 { outlines.append(EmojiOutline(points: points, closed: closed)) }
            points = []
        }

        while let next = tokens.peek() {
            if case .command(let letter) = next {
                tokens.advance()
                command = letter
                if letter == "Z" || letter == "z" {
                    finish(closed: true)
                    current = start
                    lastControl = nil
                    lastQuadratic = nil
                    continue
                }
            }
            guard tokens.hasNumber else {
                // A command letter with nothing after it.
                if case .command = tokens.peek() { continue }
                tokens.advance()
                continue
            }
            let relative = command.isLowercase
            func point() -> CGPoint {
                let x = tokens.number()
                let y = tokens.number()
                return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            }
            switch command {
            case "M", "m":
                finish(closed: false)
                current = point()
                start = current
                points = [current]
                // Pairs after a move are lines.
                command = relative ? "l" : "L"
                lastControl = nil
                lastQuadratic = nil
            case "L", "l":
                current = point()
                points.append(current)
                lastControl = nil
                lastQuadratic = nil
            case "H", "h":
                let x = tokens.number()
                current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                points.append(current)
                lastControl = nil
                lastQuadratic = nil
            case "V", "v":
                let y = tokens.number()
                current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                points.append(current)
                lastControl = nil
                lastQuadratic = nil
            case "C", "c":
                let c1 = point()
                let c2 = point()
                let end = point()
                points += EmojiCurves.cubic(current, c1, c2, end)
                lastControl = c2
                lastQuadratic = nil
                current = end
            case "S", "s":
                let c1 = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let c2 = point()
                let end = point()
                points += EmojiCurves.cubic(current, c1, c2, end)
                lastControl = c2
                lastQuadratic = nil
                current = end
            case "Q", "q":
                let control = point()
                let end = point()
                points += EmojiCurves.quadratic(current, control, end)
                lastQuadratic = control
                lastControl = nil
                current = end
            case "T", "t":
                let control = lastQuadratic.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let end = point()
                points += EmojiCurves.quadratic(current, control, end)
                lastQuadratic = control
                lastControl = nil
                current = end
            case "A", "a":
                let rx = tokens.number()
                let ry = tokens.number()
                let rotation = tokens.number()
                let largeArc = tokens.number() != 0
                let sweep = tokens.number() != 0
                let end = point()
                points += EmojiCurves.svgArc(from: current, to: end, rx: rx, ry: ry, rotation: rotation, largeArc: largeArc, sweep: sweep)
                current = end
                lastControl = nil
                lastQuadratic = nil
            default:
                tokens.advance()
            }
        }
        finish(closed: false)
        return outlines
    }

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    private struct Tokens {
        private var items: [Token] = []
        private var index = 0

        init(_ data: String) {
            var buffer = ""
            func flush() {
                if let value = Double(buffer) { items.append(.number(CGFloat(value))) }
                buffer = ""
            }
            for character in data {
                if character.isLetter, character != "e", character != "E" {
                    flush()
                    items.append(.command(character))
                } else if character == "-" {
                    if buffer.last == "e" || buffer.last == "E" {
                        buffer.append(character)
                    } else {
                        flush()
                        buffer = "-"
                    }
                } else if character == "." {
                    if buffer.contains(".") { flush() }
                    buffer.append(character)
                } else if character.isNumber || character == "e" || character == "E" {
                    buffer.append(character)
                } else {
                    flush()
                }
            }
            flush()
        }

        func peek() -> Token? {
            index < items.count ? items[index] : nil
        }

        var hasNumber: Bool {
            if case .number = peek() { return true }
            return false
        }

        mutating func advance() {
            index += 1
        }

        mutating func number() -> CGFloat {
            guard case .number(let value) = peek() else { return 0 }
            index += 1
            return value
        }
    }
}
