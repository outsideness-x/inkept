import SwiftUI

/// The map as it's drawn: the graph and its layout, where each node is this frame, how lit it is,
/// and where the map is looked at from. Whatever moves — nodes settling, light coming up round a
/// note, names fading in, the view gliding to a stop — moves a frame at a time, and the frames
/// stop once everything is still.
@MainActor
@Observable
final class NoteGraphModel {
    private(set) var graph = NoteGraph()
    /// Counts up with every new layout.
    private(set) var generation = 0
    /// True while anything on the map still moves, so the view keeps drawing frames.
    private(set) var isAnimating = false

    @ObservationIgnored private(set) var layout: GraphLayout?
    /// Where each node is drawn this frame: where the layout has it, or on the way there.
    @ObservationIgnored private(set) var positions: [CGPoint] = []
    /// How far each node has come onto the map, from 0 to 1.
    @ObservationIgnored private(set) var presence: [CGFloat] = []
    /// How lit each node is: the one in focus, and everything it's joined to.
    @ObservationIgnored private(set) var lit: [CGFloat] = []
    /// How much each node is the one in focus.
    @ObservationIgnored private(set) var focused: [CGFloat] = []
    /// How far everything that isn't lit has stepped back.
    @ObservationIgnored private(set) var dim: CGFloat = 0
    /// How visible each node's name is. The renderer eases these towards what it wants, frame by frame.
    @ObservationIgnored var labels: [CGFloat] = []
    /// Where each name last sat round its node — under, over, right or left — so it stays put
    /// for as long as there's room there.
    @ObservationIgnored var labelPlaces: [UInt8] = []
    /// Set by the renderer while a name is still fading in or out.
    @ObservationIgnored var labelsAreMoving = false
    /// The pencil each node is coloured with, and its colours: a pale wash and the pencil itself.
    @ObservationIgnored private(set) var washes: [Color] = []
    @ObservationIgnored private(set) var pencils: [Color] = []
    /// Seconds since the last frame, for whatever eases towards where it's going.
    @ObservationIgnored private(set) var frameTime: CGFloat = 1.0 / 60
    @ObservationIgnored private(set) var camera = GraphCamera()
    @ObservationIgnored private(set) var viewport: CGSize = .zero
    /// The room left round the map when it's fitted to the view, and above it for the controls.
    @ObservationIgnored var margin: CGFloat = 46
    @ObservationIgnored var topInset: CGFloat = 0
    @ObservationIgnored var reduceMotion = false

    /// The node in focus, by id, so it stays in focus when the map is drawn again.
    @ObservationIgnored private(set) var focusID: String?
    @ObservationIgnored private var focus: Int?
    /// Whether the view has been moved by hand since it was last fitted round the map.
    @ObservationIgnored private var cameraWasMoved = false
    @ObservationIgnored private var flight: Flight?
    /// How fast the view is still sliding after a flick, in points a second.
    @ObservationIgnored private var drift: CGSize = .zero
    @ObservationIgnored private var move: Move?
    @ObservationIgnored private var lastFrame: Date?
    /// Gestures under way; the frames keep coming while any is.
    @ObservationIgnored private var holds = 0
    @ObservationIgnored private var lightIsStill = true
    @ObservationIgnored private var task: Task<Void, Never>?
    /// A map asked for before the view had a size, laid out once it has one, in its shape.
    @ObservationIgnored private var waiting: (graph: NoteGraph, spacing: CGFloat, nodeScale: CGFloat)?
    @ObservationIgnored private var labelSizes: [CGSize?] = []
    @ObservationIgnored private var outlines: [Int: Path] = [:]

    private struct Flight {
        let from: GraphCamera
        let to: GraphCamera
        let start: Date
        let duration: TimeInterval
    }

    /// Nodes on their way from where they were to where the layout has them.
    private struct Move {
        let from: [CGPoint]
        let start: Date
        let duration: TimeInterval
        /// How long each node waits before it sets off, as a share of the move.
        let delays: [CGFloat]
        /// The first time a map is shown it opens out from the middle, overshooting a little.
        let opensOut: Bool
    }

    // MARK: - Laying out

    /// Lays `graph` out off the main thread, keeping every node already on the map where it was;
    /// the nodes then move to their places, and a first map opens out from the middle.
    func show(_ graph: NoteGraph, spacing: CGFloat = 1, nodeScale: CGFloat = 1) {
        task?.cancel()
        guard viewport.width > 1, viewport.height > 1 else {
            waiting = (graph, spacing, nodeScale)
            return
        }
        waiting = nil
        let previous = placesByID()
        let aspect = viewport.width > 1 && viewport.height > 1 ? viewport.height / viewport.width : 1
        let count = graph.nodes.count
        let fresh = previous.isEmpty
        task = Task { [weak self] in
            let layout = await Task.detached(priority: .userInitiated) {
                var layout = GraphLayout(graph: graph, previous: previous, spacing: spacing, aspect: aspect, nodeScale: nodeScale)
                // Small maps settle before they're shown; big ones are shown sooner and settle as you watch.
                layout.settle(ticks: fresh ? (count > 1_200 ? 90 : count > 400 ? 180 : 320) : 200)
                return layout
            }.value
            guard let self, !Task.isCancelled else { return }
            self.adopt(graph, layout: layout)
        }
    }

    /// Where the layout has each node now, by id.
    private func placesByID() -> [String: CGPoint] {
        guard let layout, layout.positions.count == graph.nodes.count else { return [:] }
        var places: [String: CGPoint] = [:]
        for (index, node) in graph.nodes.enumerated() {
            places[node.id] = layout.positions[index]
        }
        return places
    }

    private func adopt(_ graph: NoteGraph, layout: GraphLayout) {
        let opensOut = self.layout == nil
        var before: [String: (position: CGPoint, presence: CGFloat, label: CGFloat)] = [:]
        if positions.count == self.graph.nodes.count {
            for (index, node) in self.graph.nodes.enumerated() {
                before[node.id] = (positions[index], presence[index], labels[index])
            }
        }
        let count = graph.nodes.count
        let targets = layout.positions
        var from = targets
        var delays = [CGFloat](repeating: 0, count: count)
        presence = [CGFloat](repeating: 0, count: count)
        labels = [CGFloat](repeating: 0, count: count)
        if opensOut {
            // Everything starts bunched in the middle and opens out, the outside a moment after the rest.
            let middle = Self.middle(of: targets)
            let reach = targets.map { hypot($0.x - middle.x, $0.y - middle.y) }.max() ?? 1
            for index in 0..<count {
                let offset = CGPoint(x: targets[index].x - middle.x, y: targets[index].y - middle.y)
                from[index] = CGPoint(x: middle.x + offset.x * 0.08, y: middle.y + offset.y * 0.08)
                delays[index] = min(hypot(offset.x, offset.y) / max(reach, 1), 1) * 0.3
            }
        } else {
            for (index, node) in graph.nodes.enumerated() {
                if let old = before[node.id] {
                    from[index] = old.position
                    presence[index] = old.presence
                    labels[index] = old.label
                } else if let neighbour = graph.neighbours[index].first(where: { before[graph.nodes[$0].id] != nil }) {
                    // A newcomer grows out of whatever it's joined to.
                    from[index] = before[graph.nodes[neighbour].id]?.position ?? targets[index]
                }
            }
        }
        self.graph = graph
        self.layout = layout
        positions = from
        lit = [CGFloat](repeating: 0, count: count)
        focused = [CGFloat](repeating: 0, count: count)
        focus = focusID.flatMap { graph.index(of: $0) }
        labelSizes = [CGSize?](repeating: nil, count: count)
        labelPlaces = [UInt8](repeating: 0, count: count)
        outlines = [:]
        colour(graph)
        move = Move(from: from, start: .now, duration: opensOut ? 1.15 : 0.75, delays: delays, opensOut: opensOut)
        if reduceMotion {
            move = nil
            positions = targets
            presence = [CGFloat](repeating: 1, count: count)
        }
        if opensOut || !cameraWasMoved {
            fit(animated: !opensOut)
        }
        generation += 1
        wake()
    }

    /// Each subject has a pencil of its own, as Obsidian's groups have colours: its icon's, if that
    /// pencil isn't already another subject's, else one close to it, else a spare — the same every time.
    /// Notes outside any subject are graphite, tags teal, and notes not written yet plain graphite.
    private func colour(_ graph: NoteGraph) {
        var wishes: [String: InkPencil] = [:]
        for node in graph.nodes where node.kind == .folder || node.kind == .note {
            guard let subject = node.subject, let tint = SubjectIcon.named(node.tintIcon)?.tint else { continue }
            // The subject's own icon wins over an icon further down inside it.
            if node.kind == .folder, node.path == subject {
                wishes[subject] = tint
            } else if wishes[subject] == nil {
                wishes[subject] = tint
            }
        }
        let subjects = Set(graph.nodes.compactMap(\.subject)).sorted()
        var taken = Set<InkPencil>()
        var chosen: [String: InkPencil] = [:]
        for subject in subjects {
            let wish = wishes[subject].flatMap { Self.spare.contains($0) ? $0 : nil }
            let start = abs(subject.lowercased().inkSeed) % Self.spare.count
            let spares = Array(Self.spare[start...] + Self.spare[..<start])
            let options = (wish.map { [$0] + (Self.kin[$0] ?? []) } ?? []) + spares
            let pencil = options.first { !taken.contains($0) } ?? wish ?? spares[0]
            taken.insert(pencil)
            chosen[subject] = pencil
        }

        washes = []
        pencils = []
        washes.reserveCapacity(graph.nodes.count)
        pencils.reserveCapacity(graph.nodes.count)
        for node in graph.nodes {
            let pencil: Color = switch node.kind {
            case .note, .folder: node.subject.flatMap { chosen[$0]?.color } ?? .inkeptGraphite
            case .tag: InkPencil.teal.color
            case .missing: .inkeptGraphite
            }
            pencils.append(pencil)
            washes.append(pencil.mix(with: .inkeptCardPaper, by: node.kind == .folder ? 0.85 : 0.4))
        }
    }

    /// The pencils a subject can have, in the order they're handed out once icons have had their say.
    private static let spare: [InkPencil] = [.sky, .green, .orange, .purple, .teal, .gold, .rose, .red, .blue, .navy, .mint, .terracotta, .lime, .brown]

    /// For a subject whose icon's pencil is already taken: pencils near it, nearest first.
    private static let kin: [InkPencil: [InkPencil]] = [
        .red: [.orange, .terracotta, .rose],
        .rose: [.purple, .terracotta, .red],
        .orange: [.gold, .terracotta, .red],
        .yellow: [.gold, .orange, .lime],
        .gold: [.orange, .brown, .lime],
        .lime: [.green, .gold, .mint],
        .mint: [.green, .teal, .lime],
        .green: [.teal, .lime, .mint],
        .teal: [.green, .sky, .mint],
        .sky: [.teal, .blue, .navy],
        .blue: [.teal, .sky, .navy, .purple],
        .navy: [.blue, .purple, .sky],
        .purple: [.navy, .rose, .blue],
        .brown: [.terracotta, .gold, .orange],
        .tan: [.brown, .gold, .orange],
        .terracotta: [.orange, .red, .brown],
    ]

    private static func middle(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    // MARK: - Frames

    /// Moves everything on to `date`. Called as each frame is drawn; stops the frames once all is still.
    func step(to date: Date) {
        let elapsed = lastFrame.map { date.timeIntervalSince($0) } ?? 1.0 / 60
        lastFrame = date
        let dt = CGFloat(min(max(elapsed, 1.0 / 240), 1.0 / 15))
        frameTime = dt
        guard var layout else { return }
        var busy = holds > 0 || labelsAreMoving

        if !layout.isSettled {
            layout.tick(timeScale: dt * 60)
            self.layout = layout
            busy = true
        }

        if let move, !reduceMotion {
            let progress = CGFloat(date.timeIntervalSince(move.start) / move.duration)
            if progress >= 1 {
                self.move = nil
                positions = layout.positions
            } else {
                for index in positions.indices where index < move.from.count {
                    let delay = move.delays[index]
                    let local = min(max((progress - delay) / (1 - delay), 0), 1)
                    let eased = move.opensOut ? Self.easeOutBack(local) : Self.easeInOut(local)
                    let target = layout.positions[index]
                    positions[index] = CGPoint(
                        x: move.from[index].x + (target.x - move.from[index].x) * eased,
                        y: move.from[index].y + (target.y - move.from[index].y) * eased
                    )
                    if move.opensOut {
                        presence[index] = min(1, local * 2.2)
                    }
                }
                busy = true
            }
        } else {
            move = nil
            positions = layout.positions
        }

        lightIsStill = true
        let rate: CGFloat = reduceMotion ? 1_000 : 13
        let ease = 1 - exp(-rate * dt)
        let neighbours = focus.map { Set(graph.neighbours[$0]) } ?? []
        for index in presence.indices {
            if move?.opensOut != true {
                presence[index] = approach(presence[index], 1, ease)
            }
            let isFocus = index == focus
            lit[index] = approach(lit[index], isFocus || neighbours.contains(index) ? 1 : 0, ease)
            focused[index] = approach(focused[index], isFocus ? 1 : 0, ease)
        }
        dim = approach(dim, focus == nil ? 0 : 1, ease)
        if !lightIsStill { busy = true }

        if let flight {
            let progress = CGFloat(date.timeIntervalSince(flight.start) / flight.duration)
            if progress >= 1 || reduceMotion {
                camera = flight.to
                self.flight = nil
            } else {
                camera = flight.from.mixed(with: flight.to, by: Self.easeInOut(progress))
                busy = true
            }
        } else if holds == 0, hypot(drift.width, drift.height) > 8 {
            camera.offset.width += drift.width * dt
            camera.offset.height += drift.height * dt
            let friction = exp(-4.2 * dt)
            drift.width *= friction
            drift.height *= friction
            busy = true
        } else if holds == 0 {
            drift = .zero
        }

        if !busy, isAnimating {
            Task { @MainActor [weak self] in self?.stopIfStill() }
        }
    }

    private func approach(_ value: CGFloat, _ target: CGFloat, _ ease: CGFloat) -> CGFloat {
        let next = value + (target - value) * ease
        if abs(target - next) < 0.003 { return target }
        lightIsStill = false
        return next
    }

    private func stopIfStill() {
        guard holds == 0, !labelsAreMoving, move == nil, flight == nil, drift == .zero, lightIsStill,
              layout?.isSettled ?? true
        else { return }
        isAnimating = false
    }

    /// Starts the frames again, if they'd stopped.
    func wake() {
        guard !isAnimating else { return }
        lastFrame = nil
        isAnimating = true
    }

    private static func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    /// Out past the mark and gently back, like something set down a little too briskly.
    private static func easeOutBack(_ t: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.1
        let c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }

    // MARK: - Focus

    /// Whether `index` is the node coming into focus, rather than one going out of it.
    func isFocus(_ index: Int) -> Bool {
        index == focus
    }

    /// Lights a node and everything joined to it, and lets the rest step back; nothing to light them all again.
    func setFocus(_ id: String?) {
        guard id != focusID else { return }
        focusID = id
        focus = id.flatMap { graph.index(of: $0) }
        wake()
    }

    // MARK: - The view

    /// The view's size; the map is fitted to it until it's been moved by hand.
    func resize(to size: CGSize) {
        guard size != viewport, size.width > 1, size.height > 1 else { return }
        viewport = size
        if let waiting {
            show(waiting.graph, spacing: waiting.spacing, nodeScale: waiting.nodeScale)
        }
        if layout != nil, !cameraWasMoved {
            fit(animated: false)
        }
        wake()
    }

    /// Everything on the map, with room for the nodes and the names under them.
    var bounds: CGRect {
        guard let layout, !layout.positions.isEmpty else { return .null }
        return zip(layout.positions, layout.radii).reduce(CGRect.null) { rect, item in
            rect.union(CGRect(x: item.0.x - item.1, y: item.0.y - item.1, width: item.1 * 2, height: item.1 * 2 + 16))
        }
    }

    /// Brings the whole map into view. Round one note there are only a few to show, in a small space,
    /// so they come closer to the edge.
    func fit(animated: Bool) {
        let target = GraphCamera.fitting(bounds, in: viewport, margin: margin, top: topInset)
        cameraWasMoved = false
        drift = .zero
        if animated {
            fly(to: target)
        } else {
            flight = nil
            camera = target
            wake()
        }
    }

    /// Glides the view to `target`.
    func fly(to target: GraphCamera, duration: TimeInterval = 0.5) {
        drift = .zero
        if reduceMotion {
            camera = target
            flight = nil
        } else {
            flight = Flight(from: camera, to: target, start: .now, duration: duration)
        }
        wake()
    }

    /// Zooms by `factor` round `anchor`, gliding there unless `animated` is false.
    func zoom(by factor: CGFloat, around anchor: CGPoint? = nil, animated: Bool = true) {
        let point = anchor ?? CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        let base = flight?.to ?? camera
        let target = base.zoomed(by: factor, around: point, in: viewport)
        cameraWasMoved = true
        if animated {
            fly(to: target, duration: 0.32)
        } else {
            flight = nil
            camera = target
            wake()
        }
    }

    /// Puts the view exactly where a gesture has it.
    func look(from camera: GraphCamera) {
        flight = nil
        drift = .zero
        cameraWasMoved = true
        self.camera = camera
        wake()
    }

    /// Lets the view slide on after a flick, slowing as it goes.
    func fling(_ velocity: CGSize) {
        guard !reduceMotion else { return }
        let speed = hypot(velocity.width, velocity.height)
        guard speed > 120 else { return }
        // Very fast flicks are reined in, so the map never shoots off the page.
        let limit = min(speed, 2_600) / speed
        drift = CGSize(width: velocity.width * limit, height: velocity.height * limit)
        wake()
    }

    /// Keeps the frames coming while a finger or the pointer is on the map.
    func hold() {
        holds += 1
        flight = nil
        drift = .zero
        wake()
    }

    func release() {
        holds = max(holds - 1, 0)
        wake()
    }

    // MARK: - Dragging nodes

    func pickUp(_ node: Int, at point: CGPoint) {
        guard var layout, node < layout.positions.count else { return }
        if move != nil {
            // Halfway through a move: carry on from where things are drawn, not where they were going.
            layout.place(at: positions)
            move = nil
            presence = [CGFloat](repeating: 1, count: presence.count)
        }
        layout.pinned[node] = point
        // Warm enough that the notes it's joined to follow it round, the way they do in Obsidian.
        layout.alphaTarget = 0.45
        layout.reheat(to: 0.5)
        self.layout = layout
        wake()
    }

    func drag(_ node: Int, to point: CGPoint) {
        layout?.pinned[node] = point
        wake()
    }

    func letGo(_ node: Int) {
        layout?.pinned[node] = nil
        layout?.alphaTarget = 0
        wake()
    }

    // MARK: - Finding things

    func radius(of node: Int) -> CGFloat {
        guard let layout, node < layout.radii.count else { return 6 }
        return layout.radii[node]
    }

    /// The node nearest `point` on the map, if it's on it or within `slack` of it.
    func node(at point: CGPoint, slack: CGFloat) -> Int? {
        guard let layout, positions.count == layout.radii.count else { return nil }
        var best: (index: Int, distance: CGFloat)?
        for (index, position) in positions.enumerated() where presence[index] > 0.5 {
            let reach = layout.radii[index] * (1 + 0.28 * focused[index])
            let distance = hypot(position.x - point.x, position.y - point.y) - reach
            if distance < slack, distance < (best?.distance ?? .infinity) {
                best = (index, distance)
            }
        }
        return best?.index
    }

    // MARK: - Drawn once

    /// The size of a node's name at `fontSize`, measured once at a size of 12 and scaled.
    func labelSize(of index: Int, fontSize: CGFloat, measure: () -> CGSize) -> CGSize {
        guard index < labelSizes.count else { return .zero }
        let base: CGSize
        if let known = labelSizes[index] {
            base = known
        } else {
            base = measure()
            labelSizes[index] = base
        }
        return CGSize(width: base.width * fontSize / 12, height: base.height * fontSize / 12)
    }

    /// The line a node is outlined with, round a circle of radius 1: a dot as a pencil leaves it,
    /// a little uneven, or a subject's loop that runs on past where it began. It's stroked on the
    /// screen, so the pencil keeps its weight however close the map is.
    func outline(for index: Int) -> Path {
        if let cached = outlines[index] { return cached }
        let node = index < graph.nodes.count ? graph.nodes[index] : nil
        let seed = 50_021 &+ (node?.id.inkSeed ?? index)
        let path: Path
        switch node?.kind ?? .note {
        case .folder:
            path = Self.loop(seed: seed, overshoot: 0.35)
        case .missing:
            path = Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2))
        case .note, .tag:
            var random = InkRandom(seed: seed)
            let turn = random.value(in: 0...(2 * .pi))
            let points = (0..<28).map { step -> CGPoint in
                let angle = turn + CGFloat(step) / 28 * 2 * .pi
                let wobble = 1 + 0.035 * InkNoise.value(CGFloat(step) / 4, seed: seed)
                return CGPoint(x: cos(angle) * wobble, y: sin(angle) * wobble)
            }
            path = InkBrush.closedOutline(points)
        }
        outlines[index] = path
        return path
    }

    /// A hand-drawn loop round a circle of radius 1, as one line, for stroking.
    static func loop(seed: Int, overshoot: CGFloat) -> Path {
        let unit: CGFloat = 24
        let points = InkGeometry.ellipseLoop(in: CGRect(x: -unit, y: -unit, width: unit * 2, height: unit * 2), seed: seed, overshoot: overshoot)
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.x / unit, y: $0.y / unit) })
        return path
    }
}
