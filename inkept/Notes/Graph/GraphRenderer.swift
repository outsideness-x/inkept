import SwiftUI

/// How a map is drawn: what's at its centre, and how readily names appear.
struct GraphStyle {
    /// The note a small map is drawn round, filled in red pencil; everything on such a map is named.
    var centreID: String?
    /// How readily names appear as the map comes closer: 1 as usual, more for more names sooner.
    var names: CGFloat = 1
}

/// Draws one frame of the map: faint pencil lines between notes, the notes as dots in their subject's
/// pencil, subjects as hand-drawn rings wearing their icons, and the names of whatever there's room to
/// name. Whatever's in focus is ringed in red pencil, with its lines and its neighbours lit.
@MainActor
struct GraphRenderer {
    let model: NoteGraphModel
    let style: GraphStyle

    func draw(in context: inout GraphicsContext, size: CGSize) {
        let graph = model.graph
        let positions = model.positions
        guard let layout = model.layout, !positions.isEmpty, positions.count == graph.nodes.count,
              model.presence.count == positions.count, model.washes.count == positions.count,
              layout.radii.count == positions.count
        else { return }
        let camera = model.camera
        let zoom = camera.scale
        let page = CGRect(origin: .zero, size: size)
        let visible = page.insetBy(dx: -40, dy: -40)
        let screen = positions.map { camera.screen($0, in: size) }
        let centre = style.centreID.flatMap { graph.index(of: $0) }
        let line = min(max(sqrt(zoom) * 1.05, 0.75), 1.6)
        let radii: [CGFloat] = graph.nodes.indices.map { index in
            let least: CGFloat = switch graph.nodes[index].kind {
            case .folder: 11
            case .missing: 2.5
            case .note, .tag: 3
            }
            let grown = 1 + 0.28 * model.focused[index]
            return max(layout.radii[index] * zoom, least) * grown * (0.35 + 0.65 * model.presence[index])
        }

        drawLines(in: &context, screen: screen, visible: visible, width: line)
        drawNodes(in: &context, screen: screen, radii: radii, visible: visible, centre: centre)
        drawNames(in: &context, screen: screen, radii: radii, page: page, zoom: zoom, centre: centre)
    }

    // MARK: - Lines

    /// Every line at rest goes into one of three paths and is drawn in one go; the lines of whatever
    /// is in focus are drawn again on top, in red pencil.
    private func drawLines(in context: inout GraphicsContext, screen: [CGPoint], visible: CGRect, width: CGFloat) {
        let graph = model.graph
        var links = Path()
        var belongs = Path()
        var tagged = Path()
        var arriving: [(edge: NoteGraph.Edge, presence: CGFloat)] = []
        var lit: [(edge: NoteGraph.Edge, amount: CGFloat)] = []
        for edge in graph.edges {
            let a = screen[edge.a]
            let b = screen[edge.b]
            guard visible.intersects(CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x) + 1, height: abs(a.y - b.y) + 1)) else { continue }
            let presence = min(model.presence[edge.a], model.presence[edge.b])
            guard presence > 0.02 else { continue }
            let amount = max(model.focused[edge.a] * model.lit[edge.b], model.focused[edge.b] * model.lit[edge.a])
            if amount > 0.02 { lit.append((edge, amount)) }
            if presence < 0.98 {
                arriving.append((edge, presence))
                continue
            }
            switch edge.kind {
            case .link:
                links.move(to: a)
                links.addLine(to: b)
            case .folder:
                belongs.move(to: a)
                belongs.addLine(to: b)
            case .tag:
                tagged.move(to: a)
                tagged.addLine(to: b)
            }
        }
        let rest = 1 - 0.85 * model.dim
        let round = StrokeStyle(lineWidth: width, lineCap: .round)
        let thin = StrokeStyle(lineWidth: width * 0.85, lineCap: .round)
        context.stroke(belongs, with: .color(Color.inkeptGraphite.opacity(0.22 * rest)), style: thin)
        context.stroke(tagged, with: .color(InkPencil.teal.color.opacity(0.3 * rest)), style: thin)
        context.stroke(links, with: .color(Color.inkeptInk.opacity(0.3 * rest)), style: round)
        for (edge, presence) in arriving {
            var path = Path()
            path.move(to: screen[edge.a])
            path.addLine(to: screen[edge.b])
            let colour: Color = switch edge.kind {
            case .link: Color.inkeptInk.opacity(0.3)
            case .folder: Color.inkeptGraphite.opacity(0.22)
            case .tag: InkPencil.teal.color.opacity(0.3)
            }
            var layer = context
            layer.opacity = Double(presence * presence * rest)
            layer.stroke(path, with: .color(colour), style: edge.kind == .link ? round : thin)
        }
        let bright = StrokeStyle(lineWidth: width * 1.8, lineCap: .round)
        for (edge, amount) in lit {
            var path = Path()
            path.move(to: screen[edge.a])
            path.addLine(to: screen[edge.b])
            context.stroke(path, with: .color(Color.inkeptAccent.opacity(0.85 * amount)), style: bright)
        }
    }

    // MARK: - Nodes

    private func drawNodes(in context: inout GraphicsContext, screen: [CGPoint], radii: [CGFloat], visible: CGRect, centre: Int?) {
        let graph = model.graph
        // Notes still to write at the back, then tags, notes and subjects; whatever is lit on top.
        let order = graph.nodes.indices.sorted { a, b in
            let first = layer(of: a)
            let second = layer(of: b)
            return first == second ? a < b : first < second
        }
        for index in order {
            let node = graph.nodes[index]
            let point = screen[index]
            let radius = radii[index]
            guard visible.insetBy(dx: -radius, dy: -radius).contains(point) else { continue }
            var layer = context
            let stepsBack = model.dim * (1 - model.lit[index]) * 0.8
            layer.opacity = Double(model.presence[index] * (1 - stepsBack) * (node.isOutside ? 0.55 : 1))
            let place = CGAffineTransform(a: radius, b: 0, c: 0, d: radius, tx: point.x, ty: point.y)
            let disc = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))

            switch node.kind {
            case .note where index == centre:
                let shape = model.outline(for: index).applying(place)
                layer.fill(shape, with: .color(.inkeptAccent))
                layer.stroke(shape, with: .color(.inkeptInk), lineWidth: 1.3)
            case .note, .tag:
                let shape = model.outline(for: index).applying(place)
                layer.fill(shape, with: .color(model.washes[index]))
                layer.stroke(shape, with: .color(model.pencils[index]), lineWidth: min(max(radius * 0.17, 0.9), 1.7))
            case .folder:
                layer.fill(disc, with: .color(model.washes[index]))
                layer.stroke(
                    model.outline(for: index).applying(place),
                    with: .color(model.pencils[index]),
                    style: StrokeStyle(lineWidth: min(max(radius * 0.09, 1.4), 2.2), lineCap: .round, lineJoin: .round)
                )
                drawBadge(of: node, index: index, at: point, radius: radius, in: &layer)
            case .missing:
                layer.fill(disc, with: .color(.inkeptPaper))
                layer.stroke(
                    disc,
                    with: .color(Color.inkeptGraphite.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [2.2, 2.4])
                )
            }

            // The red pencil round what's in focus: drawn round it as it comes into focus, and fading
            // as it goes out of it.
            let ring = index == centre ? 1 : model.focused[index]
            if ring > 0.01 {
                let arriving = index == centre || model.isFocus(index)
                let reach = radius + 4.5 + radius * 0.08
                let loop = Self.ring
                    .applying(CGAffineTransform(a: reach, b: 0, c: 0, d: reach, tx: point.x, ty: point.y))
                    .trimmedPath(from: 0, to: arriving ? ring : 1)
                context.stroke(
                    loop,
                    with: .color(Color.inkeptAccent.opacity(0.9 * (arriving ? 1 : ring))),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }

    private static let ring = NoteGraphModel.loop(seed: 60_013, overshoot: 0.5)

    private func layer(of index: Int) -> Int {
        let base = switch model.graph.nodes[index].kind {
        case .missing: 0
        case .tag: 1
        case .note: 2
        case .folder: 3
        }
        return base + (model.lit[index] > 0.5 ? 4 : 0)
    }

    /// A subject's icon in the middle of its ring, or the first letter of its name in its pencil.
    /// Icons are drawn at a few fixed sizes and scaled, so zooming never draws them afresh.
    private func drawBadge(of node: NoteGraph.Node, index: Int, at point: CGPoint, radius: CGFloat, in context: inout GraphicsContext) {
        if let icon = SubjectIcon.named(node.icon) {
            let side = radius * 1.38
            let drawn: CGFloat = side > 34 ? 64 : side > 22 ? 40 : 28
            var inside = context
            inside.translateBy(x: point.x - side / 2, y: point.y - side / 2)
            inside.scaleBy(x: side / drawn, y: side / drawn)
            icon.drawing(size: drawn).draw(in: &inside)
        } else {
            let letter = context.resolve(
                Text(verbatim: String(node.title.prefix(1)).uppercased())
                    .font(.custom("Neucha", fixedSize: max(radius * 1.05, 9)))
                    .foregroundStyle(model.pencils[index])
            )
            context.draw(letter, at: CGPoint(x: point.x, y: point.y + radius * 0.04), anchor: .center)
        }
    }

    // MARK: - Names

    /// Names go under their nodes, or over them, or beside them, wherever they're clear of other
    /// names and of the nodes themselves; a name stays where it sat for as long as there's room
    /// there, so nothing jumps about as the map moves. The most important are placed first, and a
    /// name with no room anywhere fades away; each fades in or out over a moment, never all at once.
    private func drawNames(in context: inout GraphicsContext, screen: [CGPoint], radii: [CGFloat], page: CGRect, zoom: CGFloat, centre: Int?) {
        let graph = model.graph
        let reach = page.insetBy(dx: -20, dy: -20)
        var candidates: [(index: Int, rank: Int, want: CGFloat)] = []
        var discs: [(index: Int, frame: CGRect)] = []
        for index in graph.nodes.indices {
            guard reach.contains(screen[index]), model.presence[index] > 0.3 else {
                model.labels[index] = 0
                continue
            }
            let radius = radii[index]
            discs.append((index, CGRect(x: screen[index].x - radius, y: screen[index].y - radius, width: radius * 2, height: radius * 2)))
            let want = wanted(index, zoom: zoom, centre: centre)
            if want > 0.002 || model.labels[index] > 0.002 {
                candidates.append((index, rank(of: index, centre: centre), want))
            }
        }
        candidates.sort { $0.rank == $1.rank ? $0.index < $1.index : $0.rank > $1.rank }

        let ease = 1 - exp(-(model.reduceMotion ? 1_000 : 11) * model.frameTime)
        let room = page.insetBy(dx: 2, dy: 2)
        var taken: [CGRect] = []
        var moving = false
        for candidate in candidates {
            let index = candidate.index
            let node = graph.nodes[index]
            let isSubject = node.kind == .folder
            let focus = model.focused[index]
            let fontSize = (isSubject ? min(max(15 * sqrt(zoom), 13.5), 19) : min(max(12.5 * sqrt(zoom), 11.5), 15.5))
                * (1 + 0.14 * focus)
            let title = shortened(node.title)
            let size = model.labelSize(of: index, fontSize: fontSize) {
                context.resolve(Text(verbatim: title).font(.custom("Neucha", fixedSize: 12)))
                    .measure(in: CGSize(width: 600, height: 100))
            }
            let point = screen[index]
            let radius = radii[index]
            let gap = radius + (isSubject ? 4 : 2)
            let places = [
                CGRect(x: point.x - size.width / 2, y: point.y + gap, width: size.width, height: size.height),
                CGRect(x: point.x - size.width / 2, y: point.y - gap - size.height, width: size.width, height: size.height),
                CGRect(x: point.x + radius + 5, y: point.y - size.height / 2, width: size.width, height: size.height),
                CGRect(x: point.x - radius - 5 - size.width, y: point.y - size.height / 2, width: size.width, height: size.height),
            ]
            // Text sits a little inside its line box, so a name may brush a neighbour's edge.
            func isClear(_ place: CGRect) -> Bool {
                let ink = place.insetBy(dx: 1, dy: place.height * 0.1)
                return room.contains(ink)
                    && !taken.contains { $0.intersects(ink) }
                    && !discs.contains { $0.index != index && $0.frame.intersects(ink) }
            }
            let usual = Int(model.labelPlaces[index])
            let chosen = isClear(places[usual]) ? usual : (0..<places.count).first { $0 != usual && isClear(places[$0]) }
            var alpha = model.labels[index]
            let frame: CGRect
            let target: CGFloat
            if let chosen {
                if chosen != usual {
                    model.labelPlaces[index] = UInt8(chosen)
                    // Moving to another side: it fades back in there rather than leap.
                    alpha = min(alpha, 0.25)
                }
                frame = places[chosen]
                target = candidate.want
            } else {
                frame = places[usual]
                target = 0
            }
            alpha += (target - alpha) * ease
            if abs(target - alpha) < 0.004 {
                alpha = target
            } else {
                moving = true
            }
            model.labels[index] = alpha
            if target > 0.05 || alpha > 0.35 {
                taken.append(frame.insetBy(dx: -3, dy: -1))
            }
            guard alpha > 0.01 else { continue }

            let colour: Color = switch node.kind {
            case .tag: InkPencil.teal.color
            case .missing: .inkeptGraphite
            case .note where node.isOutside: .inkeptGraphite
            case .note, .folder: .inkeptInk
            }
            var paper = context
            paper.opacity = Double(alpha)
            paper.fill(
                Path(roundedRect: frame.insetBy(dx: -3, dy: size.height * 0.08), cornerRadius: 4),
                with: .color(Color.inkeptPaper.opacity(0.7))
            )
            let text = paper.resolve(
                Text(verbatim: title)
                    .font(.custom("Neucha", fixedSize: fontSize))
                    .foregroundStyle(colour.opacity(isSubject || focus > 0.5 ? 1 : 0.86))
            )
            paper.draw(text, in: frame)
            if isSubject || focus > 0.5 || index == centre {
                // A second pass a hair to the side, the way a hand presses harder on what matters.
                paper.draw(text, in: frame.offsetBy(dx: 0.45, dy: 0.2))
            }
        }
        model.labelsAreMoving = moving
    }

    /// How much a node's name wants to be shown: subjects always, notes as the map comes close enough
    /// to read them — the best connected first — and, while something's in focus, it and its neighbours.
    private func wanted(_ index: Int, zoom: CGFloat, centre: Int?) -> CGFloat {
        let node = model.graph.nodes[index]
        if centre != nil { return 1 }
        let base: CGFloat
        if node.kind == .folder {
            base = 1
        } else {
            let importance = 1 + 0.45 * log2(1 + CGFloat(node.degree))
            let closeness = zoom * importance * style.names
            let t = min(max((closeness - 0.55) / 0.4, 0), 1)
            base = t * t * (3 - 2 * t)
        }
        return max(base * (1 - 0.92 * model.dim), model.lit[index])
    }

    /// Which names win a place: what's in focus, what it touches, subjects, then the best connected.
    private func rank(of index: Int, centre: Int?) -> Int {
        let node = model.graph.nodes[index]
        if index == centre { return 300_000 }
        var rank = node.degree * 10
        switch node.kind {
        case .folder: rank += 20_000
        case .note: rank += 5
        case .tag: rank += 2
        case .missing: break
        }
        if model.focused[index] > 0.5 { rank += 200_000 }
        if model.lit[index] > 0.5 { rank += 100_000 }
        return rank
    }

    private func shortened(_ title: String) -> String {
        title.count > 30 ? String(title.prefix(28)) + "…" : title
    }
}
