import CoreGraphics

/// A small picture described the way it's drawn: colour laid down first, a touch off-register,
/// then the pen over it. Everything is placed on a 32-point grid.
struct EmojiArt: Sendable {
    enum Font: Sendable {
        /// The hand the interface is lettered in.
        case hand
        case rounded
        case serif
        case mono
    }

    enum Layer: Sendable {
        case fill(EmojiFigure, InkPencil, opacity: Double, evenOdd: Bool)
        case hatch(EmojiFigure, InkPencil, angle: CGFloat, gap: CGFloat, opacity: Double)
        case ink(EmojiFigure, InkPencil, width: CGFloat, opacity: Double)
        case dot(CGPoint, radius: CGFloat, InkPencil)
        case text(String, at: CGPoint, size: CGFloat, InkPencil, font: Font, weight: Double, rotation: CGFloat)
        /// Colour kept inside an outline, the way paint stays on a stencil.
        case clipped(EmojiFigure, [Layer])
    }

    private(set) var layers: [Layer] = []

    // MARK: - Colour

    mutating func fill(_ figure: EmojiFigure, _ pencil: InkPencil, opacity: Double = 1, evenOdd: Bool = false) {
        layers.append(.fill(figure, pencil, opacity: opacity, evenOdd: evenOdd))
    }

    /// Pencil hatching across a shape.
    mutating func hatch(
        _ figure: EmojiFigure, _ pencil: InkPencil,
        angle: CGFloat = -50, gap: CGFloat = 1.7, opacity: Double = 1
    ) {
        layers.append(.hatch(figure, pencil, angle: angle, gap: gap, opacity: opacity))
    }

    /// The shadow side of something, hatched lightly in ink.
    mutating func shade(_ figure: EmojiFigure, opacity: Double = 0.3, angle: CGFloat = -50, gap: CGFloat = 1.5) {
        hatch(figure, .ink, angle: angle, gap: gap, opacity: opacity)
    }

    /// Paints inside `figure` only.
    mutating func clip(_ figure: EmojiFigure, _ draw: (inout EmojiArt) -> Void) {
        var inside = EmojiArt()
        draw(&inside)
        layers.append(.clipped(figure, inside.layers))
    }

    // MARK: - Pen

    mutating func ink(_ figure: EmojiFigure, _ pencil: InkPencil = .ink, width: CGFloat = 1.5, opacity: Double = 1) {
        layers.append(.ink(figure, pencil, width: width, opacity: opacity))
    }

    mutating func fine(_ figure: EmojiFigure, _ pencil: InkPencil = .ink, opacity: Double = 1) {
        ink(figure, pencil, width: 0.95, opacity: opacity)
    }

    mutating func bold(_ figure: EmojiFigure, _ pencil: InkPencil = .ink) {
        ink(figure, pencil, width: 2.2)
    }

    /// Colour, then the pen around it: most things are drawn like this.
    mutating func shape(_ figure: EmojiFigure, _ pencil: InkPencil, width: CGFloat = 1.5, outline: InkPencil = .ink) {
        fill(figure, pencil)
        ink(figure, outline, width: width)
    }

    mutating func dot(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat = 0.9, _ pencil: InkPencil = .ink) {
        layers.append(.dot(CGPoint(x: x, y: y), radius: radius, pencil))
    }

    /// Letters, centred on `x, y`.
    mutating func text(
        _ string: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat,
        _ pencil: InkPencil = .ink, font: Font = .hand, weight: Double = 0, rotation: CGFloat = 0
    ) {
        layers.append(.text(string, at: CGPoint(x: x, y: y), size: size, pencil, font: font, weight: weight, rotation: rotation))
    }

    /// A square tile of colour with an ink edge, for logos that are letters.
    mutating func tile(_ pencil: InkPencil, corner: CGFloat = 5, inset: CGFloat = 4) {
        shape(.box(inset, inset, 32 - inset * 2, 32 - inset * 2, r: corner), pencil)
    }
}

// MARK: - Flags

extension EmojiArt {
    /// A flag stirring in a breeze: colour painted on a cloth, then its edge drawn round.
    mutating func flag(_ paint: (inout EmojiFlag) -> Void) {
        var flag = EmojiFlag()
        paint(&flag)
        let cloth = flag.region(0, 0, 1, 1)
        layers.append(.clipped(cloth, flag.layers + flag.folds))
        ink(cloth, width: 1.4)
    }
}

/// Paints a flag in its own coordinates: `u` across from the pole, `v` down, both from 0 to 1.
/// Sizes of discs and stars are fractions of the flag's height.
struct EmojiFlag: Sendable {
    fileprivate(set) var layers: [EmojiArt.Layer] = []

    private let left: CGFloat = 3
    private let right: CGFloat = 29
    private let height: CGFloat = 17.4
    private let wave: CGFloat = 1.05

    /// Where a point of the cloth lands on the grid once the cloth is waving.
    func point(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
        let depth = 1 - 0.07 * u
        let rise = wave * sin(2 * .pi * 0.85 * u - 0.55)
        return CGPoint(
            x: left + (right - left) * u - 0.35 * wave * cos(2 * .pi * 0.85 * u - 0.55) * (v - 0.5),
            y: 16.6 + (v - 0.5) * height * depth + rise
        )
    }

    /// The width of the flag in heights, for keeping discs round.
    var aspect: CGFloat { (right - left) / height }

    /// A polygon given in cloth coordinates, bent with the cloth.
    func figure(_ uv: [CGPoint], closed: Bool = true) -> EmojiFigure {
        var points: [CGPoint] = []
        let corners = closed ? uv + [uv[0]] : uv
        for index in 0..<(corners.count - 1) {
            let a = corners[index]
            let b = corners[index + 1]
            let steps = max(1, Int(max(abs(b.x - a.x) * 24, abs(b.y - a.y) * 10)))
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                points.append(point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t))
            }
        }
        if !closed, let last = uv.last { points.append(point(last.x, last.y)) }
        return closed ? .polygon(points) : .polyline(points)
    }

    func region(_ u0: CGFloat, _ v0: CGFloat, _ u1: CGFloat, _ v1: CGFloat) -> EmojiFigure {
        figure([CGPoint(x: u0, y: v0), CGPoint(x: u1, y: v0), CGPoint(x: u1, y: v1), CGPoint(x: u0, y: v1)])
    }

    /// Colour everywhere, the cloth's ground.
    mutating func field(_ pencil: InkPencil) {
        layers.append(.fill(region(-0.05, -0.1, 1.05, 1.1), pencil, opacity: 1, evenOdd: false))
    }

    /// Equal stripes from top to bottom, or from the pole outwards.
    mutating func stripes(_ pencils: [InkPencil], vertical: Bool = false) {
        let count = CGFloat(pencils.count)
        for (index, pencil) in pencils.enumerated() {
            let start = CGFloat(index) / count
            // Each stripe runs past the far edge; the next one covers it, so no paper shows between.
            if vertical {
                rect(index == 0 ? -0.05 : start, -0.1, 1.05, 1.1, pencil)
            } else {
                rect(-0.05, index == 0 ? -0.1 : start, 1.05, 1.1, pencil)
            }
        }
    }

    mutating func rect(_ u0: CGFloat, _ v0: CGFloat, _ u1: CGFloat, _ v1: CGFloat, _ pencil: InkPencil) {
        layers.append(.fill(region(u0, v0, u1, v1), pencil, opacity: 1, evenOdd: false))
    }

    mutating func poly(_ pencil: InkPencil, _ coordinates: CGFloat...) {
        let uv = stride(from: 0, to: coordinates.count - 1, by: 2).map { CGPoint(x: coordinates[$0], y: coordinates[$0 + 1]) }
        layers.append(.fill(figure(uv), pencil, opacity: 1, evenOdd: false))
    }

    /// A cross of two bars through `u, v`, as on Nordic flags; `t` is the bar's width in heights.
    mutating func cross(_ u: CGFloat, _ v: CGFloat, _ t: CGFloat, _ pencil: InkPencil) {
        let halfU = t / aspect / 2
        rect(u - halfU, -0.1, u + halfU, 1.1, pencil)
        rect(-0.05, v - t / 2, 1.05, v + t / 2, pencil)
    }

    /// Diagonal bars from corner to corner of the flag, or of part of it.
    mutating func saltire(_ t: CGFloat, _ pencil: InkPencil, in area: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 1, 1)) {
        let (u0, v0, u1, v1) = area
        let reach = (u1 - u0) * 0.1
        let bars = [
            bar(CGPoint(x: u0 - reach, y: v0 - reach * aspect), CGPoint(x: u1 + reach, y: v1 + reach * aspect), t),
            bar(CGPoint(x: u1 + reach, y: v0 - reach * aspect), CGPoint(x: u0 - reach, y: v1 + reach * aspect), t),
        ]
        let fills = bars.map { EmojiArt.Layer.fill(figure($0), pencil, opacity: 1, evenOdd: false) }
        layers.append(.clipped(bleed(u0, v0, u1, v1), fills))
    }

    /// The Union Jack, in the whole flag or in its canton.
    mutating func unionJack(in area: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 1, 1)) {
        let (u0, v0, u1, v1) = area
        let scale = v1 - v0
        rect(u0 - (u0 == 0 ? 0.05 : 0), v0 - (v0 == 0 ? 0.1 : 0), u1, v1, .navy)
        saltire(0.2 * scale, .white, in: area)
        saltire(0.07 * scale, .red, in: area)
        let middle = CGPoint(x: (u0 + u1) / 2, y: (v0 + v1) / 2)
        let crosses: [(CGFloat, InkPencil)] = [(0.34 * scale, .white), (0.2 * scale, .red)]
        var inside: [EmojiArt.Layer] = []
        for (width, pencil) in crosses {
            let halfU = width / aspect / 2
            inside.append(.fill(region(middle.x - halfU, v0 - 0.1, middle.x + halfU, v1 + 0.1), pencil, opacity: 1, evenOdd: false))
            inside.append(.fill(region(u0 - 0.05, middle.y - width / 2, u1 + 0.05, middle.y + width / 2), pencil, opacity: 1, evenOdd: false))
        }
        layers.append(.clipped(bleed(u0, v0, u1, v1), inside))
    }

    /// Part of the flag, running past the cloth wherever it meets the flag's edge.
    private func bleed(_ u0: CGFloat, _ v0: CGFloat, _ u1: CGFloat, _ v1: CGFloat) -> EmojiFigure {
        region(u0 <= 0 ? -0.05 : u0, v0 <= 0 ? -0.1 : v0, u1 >= 1 ? 1.05 : u1, v1 >= 1 ? 1.1 : v1)
    }

    /// A band `t` heights wide from `a` to `b`, in cloth coordinates.
    private func bar(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> [CGPoint] {
        let ax = a.x * aspect
        let bx = b.x * aspect
        let length = max(hypot(bx - ax, b.y - a.y), 0.0001)
        let nx = -(b.y - a.y) / length * t / 2
        let ny = (bx - ax) / length * t / 2
        return [
            CGPoint(x: (ax + nx) / aspect, y: a.y + ny),
            CGPoint(x: (bx + nx) / aspect, y: b.y + ny),
            CGPoint(x: (bx - nx) / aspect, y: b.y - ny),
            CGPoint(x: (ax - nx) / aspect, y: a.y - ny),
        ]
    }

    /// A shape given in heights around `u, v`, like a leaf or an emblem.
    mutating func emblem(_ u: CGFloat, _ v: CGFloat, _ size: CGFloat, _ pencil: InkPencil, _ coordinates: CGFloat...) {
        let uv = stride(from: 0, to: coordinates.count - 1, by: 2).map {
            CGPoint(x: u + coordinates[$0] * size / aspect, y: v + coordinates[$0 + 1] * size)
        }
        layers.append(.fill(figure(uv), pencil, opacity: 1, evenOdd: false))
    }

    mutating func disc(_ u: CGFloat, _ v: CGFloat, _ r: CGFloat, _ pencil: InkPencil, outline: Bool = false) {
        let shape = circle(u, v, r)
        layers.append(.fill(shape, pencil, opacity: 1, evenOdd: false))
        if outline { layers.append(.ink(shape, .ink, width: 0.7, opacity: 0.8)) }
    }

    mutating func star(_ u: CGFloat, _ v: CGFloat, _ r: CGFloat, _ pencil: InkPencil, rotation: CGFloat = -90, points: Int = 5) {
        let inner = r * 0.42
        let step = CGFloat.pi / CGFloat(points)
        let start = rotation * .pi / 180
        let uv = (0..<(points * 2)).map { index -> CGPoint in
            let radius = index.isMultiple(of: 2) ? r : inner
            let angle = start + step * CGFloat(index)
            return CGPoint(x: u + cos(angle) * radius / aspect, y: v + sin(angle) * radius)
        }
        layers.append(.fill(figure(uv), pencil, opacity: 1, evenOdd: false))
    }

    /// A circle on the cloth; `r` is in heights.
    func circle(_ u: CGFloat, _ v: CGFloat, _ r: CGFloat) -> EmojiFigure {
        let count = 28
        return .smooth((0..<count).map { index in
            let angle = 2 * .pi * CGFloat(index) / CGFloat(count)
            return point(u + cos(angle) * r / aspect, v + sin(angle) * r)
        }, closed: true)
    }

    /// An ink line drawn on the cloth, given in cloth coordinates.
    mutating func line(_ width: CGFloat, _ pencil: InkPencil = .ink, _ coordinates: CGFloat...) {
        let uv = stride(from: 0, to: coordinates.count - 1, by: 2).map { CGPoint(x: coordinates[$0], y: coordinates[$0 + 1]) }
        layers.append(.ink(figure(uv, closed: false), pencil, width: width, opacity: 1))
    }

    /// Anything else, already on the grid.
    mutating func paint(_ layer: EmojiArt.Layer) {
        layers.append(layer)
    }

    /// Soft shadow where the cloth turns away.
    fileprivate var folds: [EmojiArt.Layer] {
        [
            .hatch(region(0.5, -0.1, 0.8, 1.1), .ink, angle: -62, gap: 1.35, opacity: 0.16),
            .hatch(region(-0.05, -0.1, 0.12, 1.1), .ink, angle: -62, gap: 1.35, opacity: 0.1),
        ]
    }
}
