import SwiftUI

/// A forget-me-not, the flower of remembering, drawn the way everything else is: bold pen lines that
/// overshoot where they meet, and colour laid in with a pencil, a pale wash under close hatching,
/// a touch off-register. Five round petals, a white star and a yellow eye, a leaf, and the curl of
/// buds at the top of the stem, pink until they open blue. It's the app's icon, and its mark beside its name.
///
/// The drawing is laid out on a 128-point canvas, the scale of the icon, and scaled to `size`.
struct ForgetMeNot: View {
    struct Colors {
        var ink: Color
        /// The pale wash under the petals, and the pencil hatched over it.
        var petal: Color
        var petalPencil: Color
        var eye: Color
        var throat: Color
        /// The white star round the eye.
        var halo: Color
        var bud: Color
        /// The oldest bud, already opening blue.
        var openingBud: Color
        var leaf: Color
        var leafPencil: Color
    }

    var colors: Colors
    var size: CGFloat = 128
    /// Thickens the lines and opens up the hatching, so they still read when the flower is drawn small.
    var lineWeight: CGFloat = 1

    private static let blossom = Blossom(center: CGPoint(x: 57, y: 68), radius: 36, rotation: -.pi / 2 + 0.1, seed: 221)
    private static let leaf = Leaf(base: CGPoint(x: 72, y: 88), tip: CGPoint(x: 107, y: 107), width: 15, seed: 521)
    private static let curl = InkGeometry.smooth([
        CGPoint(x: 66, y: 54), CGPoint(x: 76, y: 39), CGPoint(x: 88, y: 27), CGPoint(x: 100, y: 21),
        CGPoint(x: 109, y: 23), CGPoint(x: 112, y: 30), CGPoint(x: 108, y: 35), CGPoint(x: 103, y: 33),
    ])
    private static let buds = Bud.along(curl)
    /// Where the colour plate sits against the ink.
    private static let registration = CGSize(width: 0.8, height: 1)

    var body: some View {
        let blossom = Self.blossom
        let registration = Self.registration
        ZStack {
            LeafPatch(leaf: Self.leaf)
                .fill(colors.leaf)
                .offset(registration)
            hatching(seed: 611, angle: -35, color: colors.leafPencil)
                .clipShape(LeafPatch(leaf: Self.leaf))
                .offset(registration)
            LeafLines(leaf: Self.leaf, pen: pen(2.1, touchDown: 0.5, liftOff: 0.2))
                .fill(colors.ink)

            Stroke(points: Self.curl, pen: pen(1.9, touchDown: 0.6, liftOff: 0.25, attack: 4.3, release: 10), seed: 321)
                .fill(colors.ink)
            ForEach(Self.buds.indices, id: \.self) { index in
                BudView(
                    bud: Self.buds[index],
                    fill: index == 0 ? colors.openingBud : colors.bud,
                    ink: colors.ink,
                    pen: pen(1.7, touchDown: 0.5, liftOff: 0.25)
                )
            }

            BlossomPatch(blossom: blossom)
                .fill(colors.petal)
                .offset(registration)
            hatching(seed: 612, angle: -52, color: colors.petalPencil)
                .clipShape(BlossomPatch(blossom: blossom))
                .offset(registration)
            BlossomPatch(blossom: blossom.halo)
                .fill(colors.halo)
            Spot(center: blossom.center, radius: blossom.radius * 0.17, seed: blossom.seed ^ 0x3)
                .fill(colors.eye)
            BlossomOutline(blossom: blossom, pen: pen(2.7, touchDown: 0.5, liftOff: 0.25, attack: 6, release: 9, pressureVariation: 0.18))
                .fill(colors.ink)
            Loop(center: blossom.center, radius: blossom.radius * 0.18, seed: blossom.seed ^ 0x9, pen: pen(1.3, touchDown: 0.5, liftOff: 0.25))
                .fill(colors.ink.opacity(0.8))
            Spot(center: blossom.center, radius: blossom.radius * 0.045, seed: blossom.seed ^ 0x4)
                .fill(colors.throat)
        }
        .frame(width: 128, height: 128)
        .scaleEffect(size / 128)
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Coloured-pencil strokes across the whole canvas; clip them to what they shade.
    private func hatching(seed: Int, angle: Double, color: Color) -> some View {
        InkHatch(
            seed: seed,
            spacing: 2.4 * lineWeight,
            angle: .degrees(angle),
            pen: InkPen(width: 1.05 * lineWeight, touchDown: 0.7, liftOff: 0.45, attack: 3, release: 5, pressureVariation: 0.1)
        )
        .fill(color)
    }

    private func pen(
        _ width: CGFloat,
        touchDown: CGFloat,
        liftOff: CGFloat,
        attack: CGFloat = 7,
        release: CGFloat = 12,
        pressureVariation: CGFloat = 0.14
    ) -> InkPen {
        InkPen(
            width: width * lineWeight,
            touchDown: touchDown,
            liftOff: liftOff,
            attack: attack,
            release: release,
            pressureVariation: pressureVariation
        )
    }
}

/// One five-petalled flower, face on: where its petals part, and how far each one reaches.
private struct Blossom {
    var center: CGPoint
    var radius: CGFloat
    var rotation: CGFloat
    var seed: Int
    let petals = 5
    /// How far in the notches between petals reach, as a share of the radius.
    var depth: CGFloat = 0.42
    /// Below 1, petals broaden into round lobes with sharp notches between them.
    var roundness: CGFloat = 0.55

    /// The same flower, small and round: the white star round the eye.
    var halo: Blossom {
        var halo = self
        halo.radius *= 0.31
        halo.depth = 0.3
        halo.roundness = 0.7
        halo.seed ^= 0xA1
        return halo
    }

    /// The angle of each notch, a little uneven, as a hand spaces petals.
    var notches: [CGFloat] {
        var random = InkRandom(seed: seed)
        let step = 2 * .pi / CGFloat(petals)
        return (0..<petals).map { petal in
            let jitter = random.signed() * step * 0.07
            return rotation - step / 2 + step * CGFloat(petal) + jitter
        }
    }

    /// How far each petal reaches; no two quite alike.
    var reaches: [CGFloat] {
        var random = InkRandom(seed: seed ^ 0x51)
        return (0..<petals).map { _ in radius * (1 + random.signed() * 0.06) }
    }

    func span(of petal: Int) -> (start: CGFloat, end: CGFloat) {
        let notches = notches
        let start = notches[petal]
        var end = notches[(petal + 1) % petals]
        if end <= start { end += 2 * .pi }
        return (start, end)
    }

    func point(at angle: CGFloat, distance: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
    }

    /// The rim of one petal, from the notch before it to the notch after.
    func rim(of petal: Int) -> [CGPoint] {
        let (start, end) = span(of: petal)
        let reach = reaches[petal]
        let samples = 48
        return (0...samples).map { index in
            let t = CGFloat(index) / CGFloat(samples)
            let swell = pow(sin(t * .pi), roundness)
            return point(at: start + (end - start) * t, distance: reach * (1 - depth * (1 - swell)))
        }
    }

    var outline: [CGPoint] {
        (0..<petals).flatMap { rim(of: $0).dropLast() }
    }
}

/// The colour plate of a blossom: its outline with softly uneven edges.
private struct BlossomPatch: Shape {
    let blossom: Blossom

    func path(in rect: CGRect) -> Path {
        InkBrush.closedOutline(wobbled(blossom.outline, amplitude: 0.5, seed: blossom.seed ^ 0xF1))
    }
}

/// Each petal in its own stroke, set down a little inside the notch before it and run on past the
/// notch after, the way a quick hand closes a shape, and a fine crease into each notch.
private struct BlossomOutline: Shape {
    let blossom: Blossom
    let pen: InkPen

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var random = InkRandom(seed: blossom.seed ^ 0x77)
        for petal in 0..<blossom.petals {
            let (start, end) = blossom.span(of: petal)
            let notch = blossom.reaches[petal] * (1 - blossom.depth)
            var rim = blossom.rim(of: petal)
            rim.insert(blossom.point(at: start + random.value(in: 0.02...0.06), distance: notch * random.value(in: 0.86...0.94)), at: 0)
            rim.append(blossom.point(at: end + random.value(in: 0.03...0.09), distance: notch * random.value(in: 1.0...1.08)))
            InkBrush.addStroke(
                InkGeometry.smooth(wobbled(rim, amplitude: 0.45, seed: blossom.seed &+ petal)),
                pen: pen,
                seed: blossom.seed &+ petal &* 7,
                to: &path
            )
            let crease = [
                blossom.point(at: start, distance: notch * 0.97),
                blossom.point(at: start + 0.03, distance: notch * 0.78),
                blossom.point(at: start + 0.05, distance: notch * random.value(in: 0.56...0.64)),
            ]
            InkBrush.addStroke(InkGeometry.smooth(crease), pen: pen.scaled(by: 0.62), seed: blossom.seed &+ petal &* 11, to: &path)
        }
        return path
    }
}

/// A slender leaf from its base to its tip, widest a little below the middle.
private struct Leaf {
    let base: CGPoint
    let tip: CGPoint
    let width: CGFloat
    let seed: Int

    /// One edge, base to tip; `side` is 1 or -1.
    func edge(_ side: CGFloat) -> [CGPoint] {
        let dx = tip.x - base.x
        let dy = tip.y - base.y
        let length = hypot(dx, dy)
        let normal = CGVector(dx: -dy / length, dy: dx / length)
        return (0...16).map { index in
            let t = CGFloat(index) / 16
            let half = width / 2 * sin(t * .pi) * (1 - 0.35 * t) * side
            return CGPoint(x: base.x + dx * t + normal.dx * half, y: base.y + dy * t + normal.dy * half)
        }
    }

    var outline: [CGPoint] {
        edge(1) + edge(-1).reversed().dropFirst().dropLast()
    }

    /// The midrib, most of the way to the tip.
    var midrib: [CGPoint] {
        (0...8).map { index in
            let t = CGFloat(index) / 8 * 0.82
            return CGPoint(x: base.x + (tip.x - base.x) * t, y: base.y + (tip.y - base.y) * t)
        }
    }
}

private struct LeafPatch: Shape {
    let leaf: Leaf

    func path(in rect: CGRect) -> Path {
        InkBrush.closedOutline(wobbled(leaf.outline, amplitude: 0.3, seed: leaf.seed))
    }
}

private struct LeafLines: Shape {
    let leaf: Leaf
    let pen: InkPen

    func path(in rect: CGRect) -> Path {
        var path = Path()
        InkBrush.addStroke(InkGeometry.smooth(leaf.edge(1)), pen: pen, seed: leaf.seed, to: &path)
        InkBrush.addStroke(InkGeometry.smooth(leaf.edge(-1)), pen: pen, seed: leaf.seed &+ 1, to: &path)
        InkBrush.addStroke(leaf.midrib, pen: pen.scaled(by: 0.6), seed: leaf.seed &+ 2, to: &path)
        return path
    }
}

/// A bud sitting on the outside of the curl.
private struct Bud {
    let center: CGPoint
    let size: CGSize
    let angle: Angle
    let seed: Int

    /// Four buds along `curl`, each smaller than the last towards its tip.
    static func along(_ curl: [CGPoint]) -> [Bud] {
        var distances: [CGFloat] = [0]
        for index in curl.indices.dropFirst() {
            distances.append(distances[index - 1] + hypot(curl[index].x - curl[index - 1].x, curl[index].y - curl[index - 1].y))
        }
        let total = distances.last ?? 0
        let places: [(share: CGFloat, width: CGFloat, height: CGFloat)] = [(0.4, 10, 12.5), (0.6, 8.6, 10.6), (0.77, 7.2, 8.8), (0.9, 5.8, 7)]
        return places.enumerated().map { index, place in
            let next = max(1, distances.firstIndex { $0 >= total * place.share } ?? curl.count - 1)
            let a = curl[next - 1]
            let b = curl[next]
            let length = max(hypot(b.x - a.x, b.y - a.y), 0.001)
            // The curl turns clockwise, so its outside is to the left of the way it's drawn.
            let outward = CGVector(dx: (b.y - a.y) / length, dy: -(b.x - a.x) / length)
            let reach = place.height / 2 + 0.2
            return Bud(
                center: CGPoint(x: b.x + outward.dx * reach, y: b.y + outward.dy * reach),
                size: CGSize(width: place.width, height: place.height),
                angle: .radians(atan2(outward.dy, outward.dx) + .pi / 2),
                seed: 420 + index
            )
        }
    }
}

private struct BudView: View {
    let bud: Bud
    let fill: Color
    let ink: Color
    let pen: InkPen

    var body: some View {
        let middle = CGPoint(x: bud.size.width / 2, y: bud.size.height / 2)
        ZStack {
            Spot(center: CGPoint(x: middle.x + 0.5, y: middle.y + 0.6), radii: bud.size, seed: bud.seed)
                .fill(fill)
            Loop(center: middle, radii: bud.size, seed: bud.seed ^ 0x2, pen: pen)
                .fill(ink)
        }
        .frame(width: bud.size.width, height: bud.size.height)
        .rotationEffect(bud.angle)
        .position(bud.center)
    }
}

/// A round dab of colour, not quite a circle.
private struct Spot: Shape {
    let center: CGPoint
    let radii: CGSize
    let seed: Int

    init(center: CGPoint, radius: CGFloat, seed: Int) {
        self.init(center: center, radii: CGSize(width: radius * 2, height: radius * 2), seed: seed)
    }

    init(center: CGPoint, radii: CGSize, seed: Int) {
        self.center = center
        self.radii = radii
        self.seed = seed
    }

    func path(in rect: CGRect) -> Path {
        let points = (0..<32).map { index -> CGPoint in
            let angle = CGFloat(index) / 32 * 2 * .pi
            let scale = 1 + 0.05 * InkNoise.value(CGFloat(index) / 5, seed: seed)
            return CGPoint(
                x: center.x + cos(angle) * radii.width / 2 * scale,
                y: center.y + sin(angle) * radii.height / 2 * scale
            )
        }
        return InkBrush.closedOutline(points)
    }
}

/// A pen loop round an ellipse.
private struct Loop: Shape {
    let center: CGPoint
    let radii: CGSize
    let seed: Int
    let pen: InkPen

    init(center: CGPoint, radius: CGFloat, seed: Int, pen: InkPen) {
        self.init(center: center, radii: CGSize(width: radius * 2, height: radius * 2), seed: seed, pen: pen)
    }

    init(center: CGPoint, radii: CGSize, seed: Int, pen: InkPen) {
        self.center = center
        self.radii = radii
        self.seed = seed
        self.pen = pen
    }

    func path(in rect: CGRect) -> Path {
        let frame = CGRect(x: center.x - radii.width / 2, y: center.y - radii.height / 2, width: radii.width, height: radii.height)
        return InkBrush.stroke(InkGeometry.ellipseLoop(in: frame, seed: seed, overshoot: 0.3), pen: pen, seed: seed)
    }
}

/// One stroke through points already laid out.
private struct Stroke: Shape {
    let points: [CGPoint]
    let pen: InkPen
    let seed: Int

    func path(in rect: CGRect) -> Path {
        InkBrush.stroke(points, pen: pen, seed: seed)
    }
}

/// Moves each point of a line along its normal by the slow drift of a hand.
private func wobbled(_ points: [CGPoint], amplitude: CGFloat, seed: Int) -> [CGPoint] {
    var travelled: CGFloat = 0
    return points.indices.map { index in
        if index > 0 {
            travelled += hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y)
        }
        let before = points[max(index - 1, 0)]
        let after = points[min(index + 1, points.count - 1)]
        let length = max(hypot(after.x - before.x, after.y - before.y), 0.001)
        let drift = amplitude * InkNoise.value(travelled / 18, seed: seed)
        return CGPoint(
            x: points[index].x + (after.y - before.y) / length * drift,
            y: points[index].y - (after.x - before.x) / length * drift
        )
    }
}
