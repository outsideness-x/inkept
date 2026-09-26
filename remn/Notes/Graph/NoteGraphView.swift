import SwiftUI

/// What a map is drawn for: a folder and everything in it, or one note and the notes around it.
enum NoteGraphScope: Hashable {
    case folder(String)
    case note(String)
}

/// Where the map is looked at from: how close, and how far moved.
struct GraphCamera: Equatable {
    var scale: CGFloat = 1
    var offset: CGSize = .zero

    func screen(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + offset.width + point.x * scale, y: size.height / 2 + offset.height + point.y * scale)
    }

    func world(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: (point.x - size.width / 2 - offset.width) / scale, y: (point.y - size.height / 2 - offset.height) / scale)
    }

    /// Close enough to see everything in `bounds`, with room round the edge for names.
    static func fitting(_ bounds: CGRect, in size: CGSize, margin: CGFloat = 46) -> GraphCamera {
        guard !bounds.isNull, !bounds.isInfinite, size.width > margin * 2, size.height > margin * 2 else { return GraphCamera() }
        let scale = min(
            (size.width - margin * 2) / max(bounds.width, 1),
            (size.height - margin * 2) / max(bounds.height, 1)
        )
        let clamped = min(max(scale, 0.2), 1.8)
        return GraphCamera(scale: clamped, offset: CGSize(width: -bounds.midX * clamped, height: -bounds.midY * clamped))
    }

    /// Zooms by `factor` keeping the point under `anchor` where it is.
    func zoomed(by factor: CGFloat, around anchor: CGPoint, in size: CGSize) -> GraphCamera {
        let fixed = world(anchor, in: size)
        let scale = min(max(scale * factor, 0.15), 4)
        return GraphCamera(
            scale: scale,
            offset: CGSize(
                width: anchor.x - size.width / 2 - fixed.x * scale,
                height: anchor.y - size.height / 2 - fixed.y * scale
            )
        )
    }
}

/// The graph and its layout, moving on a frame at a time while anything is still settling.
@MainActor
@Observable
final class NoteGraphModel {
    private(set) var graph = NoteGraph()
    /// Counts up with every new layout, so the view can bring the first one into view.
    private(set) var generation = 0
    /// True while nodes move or the map is still being drawn on.
    private(set) var isMoving = false

    @ObservationIgnored private(set) var layout: GraphLayout?
    @ObservationIgnored private var appeared: Date?
    @ObservationIgnored private var lastTick: Date?
    @ObservationIgnored private var remembered: [String: CGPoint] = [:]
    @ObservationIgnored private var strokes: [Int: Path] = [:]
    @ObservationIgnored private var loops: [Int: Path] = [:]
    @ObservationIgnored private var task: Task<Void, Never>?

    static let appearDuration: TimeInterval = 1.1
    /// Edges are drawn once, along a line this long, then turned and stretched onto their ends.
    static let unitLength: CGFloat = 100
    /// Node outlines are drawn once, round a circle this big, then moved and scaled.
    static let unitRadius: CGFloat = 12

    /// Lays `graph` out off the main thread, keeping every node that was already on the map where it was.
    func show(_ graph: NoteGraph) {
        task?.cancel()
        let previous = remembered
        let count = graph.nodes.count
        task = Task { [weak self] in
            let layout = await Task.detached(priority: .userInitiated) {
                var layout = GraphLayout(graph: graph, previous: previous)
                // Small maps settle before they're shown; big ones are shown sooner and settle as you watch.
                layout.settle(ticks: previous.isEmpty ? (count > 200 ? 70 : 260) : 40)
                return layout
            }.value
            guard let self, !Task.isCancelled else { return }
            if self.layout == nil { self.appeared = .now }
            self.graph = graph
            self.layout = layout
            self.strokes = [:]
            self.loops = [:]
            self.lastTick = nil
            self.remember()
            self.generation += 1
            self.isMoving = true
        }
    }

    /// Moves the layout on to `date`. Called as each frame is drawn; stops the frames once all is still.
    func advance(to date: Date) {
        guard var layout else { return }
        let steps = lastTick.map { Int((date.timeIntervalSince($0) * 60).rounded()) } ?? 1
        lastTick = date
        if !layout.isSettled {
            for _ in 0..<min(max(steps, 1), 3) {
                layout.tick()
            }
            self.layout = layout
        }
        if layout.isSettled, appearance(at: date) >= 1, isMoving {
            remember()
            Task { @MainActor [weak self] in self?.stopIfStill() }
        }
    }

    private func stopIfStill() {
        guard let layout, layout.isSettled, appearance(at: .now) >= 1 else { return }
        isMoving = false
    }

    /// How far the map has been drawn on, from 0 to 1.
    func appearance(at date: Date) -> Double {
        guard let appeared else { return 1 }
        return min(1, date.timeIntervalSince(appeared) / Self.appearDuration)
    }

    func pin(_ node: Int, at point: CGPoint) {
        layout?.pinned[node] = point
        layout?.alphaTarget = 0.25
        layout?.reheat(to: 0.3)
        isMoving = true
    }

    func release(_ node: Int) {
        layout?.pinned[node] = nil
        layout?.alphaTarget = 0
    }

    func position(of node: Int) -> CGPoint {
        layout?.positions[node] ?? .zero
    }

    func radius(of node: Int) -> CGFloat {
        layout?.radii[node] ?? 6
    }

    /// Everything on the map, with room for the nodes themselves.
    var bounds: CGRect {
        guard let layout, !layout.positions.isEmpty else { return .null }
        return zip(layout.positions, layout.radii).reduce(CGRect.null) { rect, item in
            rect.union(CGRect(x: item.0.x - item.1, y: item.0.y - item.1, width: item.1 * 2, height: item.1 * 2 + 14))
        }
    }

    /// The node nearest `point`, if it's on or right beside it.
    func node(at point: CGPoint, slack: CGFloat) -> Int? {
        guard let layout else { return nil }
        var best: (index: Int, distance: CGFloat)?
        for (index, position) in layout.positions.enumerated() {
            let distance = hypot(position.x - point.x, position.y - point.y) - layout.radii[index]
            if distance < slack, distance < (best?.distance ?? .infinity) {
                best = (index, distance)
            }
        }
        return best?.index
    }

    private func remember() {
        guard let layout else { return }
        for (index, node) in graph.nodes.enumerated() where index < layout.positions.count {
            remembered[node.id] = layout.positions[index]
        }
    }

    // MARK: - Ink, drawn once

    /// A pencil line of `unitLength` along the x-axis, for edge `index`.
    func stroke(for index: Int, bold: Bool) -> Path {
        let key = index * 2 + (bold ? 1 : 0)
        if let cached = strokes[key] { return cached }
        let seed = 40_001 &+ index &* 7_919
        let pen = bold
            ? InkPen(width: 1.9, touchDown: 0.7, liftOff: 0.45, attack: 9, release: 12, pressureVariation: 0.12)
            : InkPen(width: 1.15, touchDown: 0.75, liftOff: 0.5, attack: 8, release: 12, pressureVariation: 0.14)
        let line = InkGeometry.line(from: .zero, to: CGPoint(x: Self.unitLength, y: 0), seed: seed)
        let path = InkBrush.stroke(line, pen: pen, seed: seed)
        strokes[key] = path
        return path
    }

    /// A loop round a circle of `unitRadius` at the origin, in the pen node `index` is drawn with.
    func loop(for index: Int) -> Path {
        if let cached = loops[index] { return cached }
        let kind = index < graph.nodes.count ? graph.nodes[index].kind : .note
        let seed = 50_021 &+ (index < graph.nodes.count ? graph.nodes[index].id.inkSeed : index)
        let rect = CGRect(x: -Self.unitRadius, y: -Self.unitRadius, width: Self.unitRadius * 2, height: Self.unitRadius * 2)
        let path: Path
        switch kind {
        case .missing:
            path = InkDashedRing(seed: seed, pen: InkPen(width: 1.4)).path(in: rect)
        case .folder:
            path = InkBrush.stroke(InkGeometry.ellipseLoop(in: rect, seed: seed, overshoot: 0.45), pen: InkPen(width: 1.25), seed: seed)
        case .note, .tag:
            path = InkBrush.stroke(InkGeometry.ellipseLoop(in: rect, seed: seed, overshoot: 0.45), pen: InkPen(width: 2), seed: seed)
        }
        loops[index] = path
        return path
    }
}

/// Notes as a map: each a dot sized by how connected it is, links drawn in pencil, subjects as circles
/// wearing their icons. Drag to move around, pinch or scroll to look closer, pick a note to see what it
/// touches, and pick it again to open it.
struct NoteGraphView: View {
    @Environment(Vault.self) private var vault
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let scope: NoteGraphScope
    /// Goes where a node leads: a note, a folder, a tag.
    let onOpen: (NotesRoute) -> Void

    @AppStorage("graph.showsFolders") private var showsFolders = true
    @AppStorage("graph.showsTags") private var showsTags = false

    @State private var model = NoteGraphModel()
    @State private var camera = GraphCamera()
    @State private var canvasSize: CGSize = .zero
    /// The first layout is brought into view once there's a layout and a size to fit it in;
    /// later ones leave the view where you've put it.
    @State private var needsFit = true
    @State private var selection: String?
    @State private var hovered: String?
    @State private var drag: GraphDrag?
    @State private var pinchStart: GraphCamera?
    #if os(macOS)
    @State private var pointer = GraphPointer()
    #endif

    private enum GraphDrag {
        case node(Int)
        case pan(from: CGSize)
    }

    var body: some View {
        VStack(spacing: 0) {
            if case .folder = scope {
                controls
            }
            GeometryReader { proxy in
                // Read here, so SwiftUI draws again when they change; the canvas only sees these copies.
                let camera = camera
                let selected = selection
                let focused = selection ?? hovered
                TimelineView(.animation(paused: !model.isMoving)) { timeline in
                    let _ = model.advance(to: timeline.date)
                    Canvas { context, size in
                        draw(in: &context, size: size, date: timeline.date, camera: camera, selected: selected, focused: focused)
                    }
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(in: proxy.size).simultaneously(with: pinchGesture(in: proxy.size)))
                .onTapGesture(coordinateSpace: .local) { location in tap(at: location, in: proxy.size) }
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        let hit = model.node(at: camera.world(location, in: proxy.size), slack: 6 / camera.scale).map { model.graph.nodes[$0].id }
                        if hit != hovered { hovered = hit }
                        #if os(macOS)
                        pointer.isInside = true
                        pointer.location = location
                        #endif
                    case .ended:
                        hovered = nil
                        #if os(macOS)
                        pointer.isInside = false
                        #endif
                    }
                }
                #if os(macOS)
                .modifier(GraphScrollWheel(pointer: pointer, camera: $camera, size: proxy.size))
                #endif
                .onAppear { canvasSize = proxy.size }
                .onChange(of: proxy.size) { _, size in
                    canvasSize = size
                    fitIfNeeded()
                }
            }
            .overlay(alignment: .bottom) {
                if let selected = selectedNode {
                    GraphNodeCard(node: selected.node, connections: selected.connections, open: { open(selected.node) })
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .frame(maxWidth: 520)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0.2), value: selection)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("notes.graph.label \(model.graph.nodes.filter { $0.kind == .note }.count)"))
        }
        .task(id: graphKey) { build() }
        .onChange(of: model.generation) { _, _ in fitIfNeeded() }
    }

    private var graphKey: String {
        "\(scope)|\(vault.revision)|\(showsFolders)|\(showsTags)"
    }

    private func build() {
        let graph: NoteGraph
        switch scope {
        case .folder(let path):
            graph = NoteGraph(root: vault.root, scope: path, options: .init(showsFolders: showsFolders, showsTags: showsTags))
        case .note(let path):
            graph = NoteGraph(root: vault.root, around: path)
        }
        if let selection, graph.index(of: selection) == nil { self.selection = nil }
        model.show(graph)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 18) {
            toggle("notes.graph.folders", isOn: $showsFolders, seed: 9_201)
            toggle("notes.graph.tags", isOn: $showsTags, seed: 9_202)
            Spacer(minLength: 8)
            InkIconButton(kind: .fit, label: "notes.graph.fit", color: .remnGraphite, size: 18) {
                fit(animated: true)
            }
            .padding(.trailing, -10)
        }
        .padding(.horizontal, 22)
        .padding(.top, 2)
        .remnReadableWidth()
    }

    private func toggle(_ title: LocalizedStringKey, isOn: Binding<Bool>, seed: Int) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(spacing: 4) {
                InkCheckbox(isOn: isOn.wrappedValue, seed: seed)
                    .scaleEffect(0.8)
                    .frame(width: 26, height: 26)
                HandwrittenText(title)
                    .font(RemnTypography.note)
                    .foregroundStyle(isOn.wrappedValue ? Color.remnInk : Color.remnGraphite)
            }
            .frame(minHeight: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityAddTraits(isOn.wrappedValue ? .isSelected : [])
    }

    private func fitIfNeeded() {
        guard needsFit, model.generation > 0, canvasSize.width > 100, canvasSize.height > 100 else { return }
        needsFit = false
        fit(animated: false)
    }

    private func fit(animated: Bool) {
        let target = GraphCamera.fitting(model.bounds, in: canvasSize)
        if animated, !reduceMotion {
            withAnimation(.spring(duration: 0.45, bounce: 0.15)) { camera = target }
        } else {
            camera = target
        }
    }

    // MARK: - Gestures

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .local)
            .onChanged { value in
                if drag == nil {
                    let start = camera.world(value.startLocation, in: size)
                    if let node = model.node(at: start, slack: 8 / camera.scale) {
                        drag = .node(node)
                    } else {
                        drag = .pan(from: camera.offset)
                    }
                }
                switch drag {
                case .node(let node):
                    model.pin(node, at: camera.world(value.location, in: size))
                case .pan(let from):
                    camera.offset = CGSize(width: from.width + value.translation.width, height: from.height + value.translation.height)
                case nil:
                    break
                }
            }
            .onEnded { _ in
                if case .node(let node) = drag { model.release(node) }
                drag = nil
            }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                let start = pinchStart ?? camera
                if pinchStart == nil { pinchStart = camera }
                camera = start.zoomed(by: value.magnification, around: value.startLocation, in: size)
            }
            .onEnded { _ in pinchStart = nil }
    }

    private func tap(at location: CGPoint, in size: CGSize) {
        guard let node = model.node(at: camera.world(location, in: size), slack: 10 / camera.scale) else {
            selection = nil
            return
        }
        let id = model.graph.nodes[node].id
        if selection == id {
            open(model.graph.nodes[node])
            return
        }
        selection = id
        // Keep what's picked clear of the card that opens at the foot of the map.
        let point = camera.screen(model.position(of: node), in: size)
        let lowest = size.height - 170
        if point.y > lowest {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                camera.offset.height -= point.y - lowest
            }
        }
    }

    private var selectedNode: (node: NoteGraph.Node, connections: Int)? {
        guard let selection, let index = model.graph.index(of: selection) else { return nil }
        return (model.graph.nodes[index], model.graph.neighbours[index].count)
    }

    private func open(_ node: NoteGraph.Node) {
        switch node.kind {
        case .note:
            onOpen(.note(node.path))
        case .folder:
            onOpen(.folder(node.path))
        case .tag:
            onOpen(.tag(node.path))
        case .missing:
            // Writing the note that's been linked to, beside the note that links to it.
            let linking = model.graph.index(of: node.id).flatMap { model.graph.neighbours[$0].first }
            let folder = linking.map { VaultPath.parent(of: model.graph.nodes[$0].path) } ?? ""
            Task {
                if let made = try? await vault.createNote(in: folder, title: node.title) {
                    onOpen(.note(made))
                }
            }
        }
        selection = nil
    }

    // MARK: - Drawing

    private func draw(
        in context: inout GraphicsContext, size: CGSize, date: Date,
        camera: GraphCamera, selected: String?, focused: String?
    ) {
        guard let layout = model.layout, layout.positions.count == model.graph.nodes.count else { return }
        let graph = model.graph
        let appearance = reduceMotion ? 1 : model.appearance(at: date)
        let visible = CGRect(origin: .zero, size: size).insetBy(dx: -60, dy: -60)
        let focus = focused.flatMap { graph.index(of: $0) }
        let lit: Set<Int> = focus.map { Set([$0] + graph.neighbours[$0]) } ?? []
        let screen = layout.positions.map { camera.screen($0, in: size) }
        let zoom = camera.scale

        // Edges first, in pencil.
        let edgesShown = min(1, max(0, (appearance - 0.25) / 0.5))
        if edgesShown > 0 {
            for (index, edge) in graph.edges.enumerated() {
                let a = screen[edge.a]
                let b = screen[edge.b]
                guard visible.intersects(CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x) + 1, height: abs(a.y - b.y) + 1)) else { continue }
                let emphasised = focus != nil && (edge.a == focus || edge.b == focus)
                let length = hypot(b.x - a.x, b.y - a.y)
                guard length > 1 else { continue }
                let transform = CGAffineTransform(translationX: a.x, y: a.y)
                    .rotated(by: atan2(b.y - a.y, b.x - a.x))
                    .scaledBy(x: length / NoteGraphModel.unitLength, y: 1)
                let path = model.stroke(for: index, bold: emphasised).applying(transform)
                let colour: Color
                var opacity: Double
                switch edge.kind {
                case .link:
                    colour = emphasised ? .remnAccent : .remnInk
                    opacity = emphasised ? 0.85 : 0.5
                case .folder:
                    colour = emphasised ? .remnAccent : .remnGraphite
                    opacity = emphasised ? 0.7 : 0.34
                case .tag:
                    colour = .remnAccent
                    opacity = emphasised ? 0.75 : 0.28
                }
                if focus != nil, !emphasised { opacity *= 0.3 }
                context.fill(path, with: .color(colour.opacity(opacity * edgesShown)))
            }
        }

        // Then the nodes: tags and notes still to write at the back, subjects on top.
        let order = graph.nodes.indices.sorted { drawOrder(graph.nodes[$0].kind) < drawOrder(graph.nodes[$1].kind) }
        var labels: [(index: Int, point: CGPoint, radius: CGFloat)] = []
        for index in order {
            let node = graph.nodes[index]
            let centre = screen[index]
            var radius = layout.radii[index] * zoom
            radius = node.kind == .folder ? max(radius, 11) : max(radius, 3.2)
            guard visible.insetBy(dx: -radius, dy: -radius).contains(centre) else { continue }

            let delay = min(Double(hypot(layout.positions[index].x, layout.positions[index].y)) / 900, 0.45)
            let shown = min(1, max(0, (appearance - delay) / 0.4))
            guard shown > 0 else { continue }
            let grow = 0.6 + 0.4 * shown

            var layer = context
            layer.opacity = shown * (focus != nil && !lit.contains(index) ? 0.3 : 1) * (node.isOutside ? 0.55 : 1)
            let r = radius * grow
            let disc = Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2))
            let outline = model.loop(for: index)
                .applying(CGAffineTransform(scaleX: r / NoteGraphModel.unitRadius, y: r / NoteGraphModel.unitRadius))
                .applying(CGAffineTransform(translationX: centre.x, y: centre.y))

            switch node.kind {
            case .note:
                let tint = SubjectIcon.named(node.icon)?.tint.color ?? .remnCardPaper
                layer.fill(disc, with: .color(tint.opacity(node.icon == nil ? 1 : 0.9)))
                layer.fill(outline, with: .color(.remnInk))
            case .folder:
                layer.fill(disc, with: .color(.remnCardPaper))
                layer.fill(outline, with: .color(.remnInk))
                if let icon = SubjectIcon.named(node.icon) {
                    let side = (r * 1.45 / 2).rounded() * 2
                    var inside = layer
                    inside.translateBy(x: centre.x - side / 2, y: centre.y - side / 2)
                    icon.drawing(size: side).draw(in: &inside)
                } else {
                    let letter = layer.resolve(
                        Text(verbatim: String(node.title.prefix(1)).uppercased())
                            .font(.custom("Neucha", fixedSize: max(r * 0.95, 9)))
                            .foregroundStyle(Color.remnInk)
                    )
                    layer.draw(letter, at: centre, anchor: .center)
                }
            case .tag:
                layer.fill(disc, with: .color(Color.remnAccent.opacity(0.14)))
                layer.fill(outline, with: .color(.remnAccent))
            case .missing:
                layer.fill(outline, with: .color(.remnGraphite))
            }

            if node.id == selected {
                let ring = InkBrush.stroke(
                    InkGeometry.ellipseLoop(in: CGRect(x: centre.x - r - 6, y: centre.y - r - 6, width: (r + 6) * 2, height: (r + 6) * 2), seed: 60_013, overshoot: 0.5),
                    pen: .fine,
                    seed: 60_013
                )
                context.fill(ring, with: .color(.remnAccent))
            }
            if showsLabel(for: index, node: node, focus: focus, lit: lit, zoom: zoom) {
                labels.append((index, centre, r))
            }
        }

        // Names last, on a little paper so pencil lines don't run through them. Subjects and whatever is
        // picked are named first; a name that would land on another, or on a subject, is left off.
        let ranked = labels.sorted { labelRank(graph.nodes[$0.index], index: $0.index, focus: focus) > labelRank(graph.nodes[$1.index], index: $1.index, focus: focus) }
        var taken: [CGRect] = labels.filter { graph.nodes[$0.index].kind == .folder }.map { label in
            CGRect(x: label.point.x - label.radius, y: label.point.y - label.radius, width: label.radius * 2, height: label.radius * 2)
        }
        for label in ranked {
            let node = graph.nodes[label.index]
            let isSubject = node.kind == .folder
            let emphasised = focus == label.index
            let size = isSubject ? min(max(15 * zoom, 13), 20) : min(max(12.5 * zoom, 11), 16)
            let colour: Color = switch node.kind {
            case .tag: .remnAccent
            case .missing: .remnGraphite
            default: emphasised || isSubject ? .remnInk : .remnInk.opacity(0.8)
            }
            let text = context.resolve(
                Text(verbatim: shortened(node.title))
                    .font(.custom("Neucha", fixedSize: size))
                    .foregroundStyle(colour)
            )
            let measured = text.measure(in: CGSize(width: 260, height: 60))
            let origin = CGPoint(x: label.point.x - measured.width / 2, y: label.point.y + label.radius + 3)
            let frame = CGRect(origin: origin, size: measured).insetBy(dx: -2, dy: -1)
            if !isSubject, !emphasised, taken.contains(where: { $0.intersects(frame) }) { continue }
            taken.append(frame)
            var paper = context
            paper.opacity = (focus != nil && !lit.contains(label.index) ? 0.3 : 1) * (node.isOutside ? 0.6 : 1)
            paper.fill(
                Path(roundedRect: CGRect(origin: origin, size: measured).insetBy(dx: -3, dy: -1), cornerRadius: 4),
                with: .color(Color.remnPaper.opacity(0.62))
            )
            paper.draw(text, in: CGRect(origin: origin, size: measured))
            if isSubject || emphasised {
                paper.draw(text, in: CGRect(origin: CGPoint(x: origin.x + 0.4, y: origin.y + 0.2), size: measured))
            }
        }
    }

    /// Which names win a place: subjects, then what's picked and what it touches, then the best connected.
    private func labelRank(_ node: NoteGraph.Node, index: Int, focus: Int?) -> Int {
        if node.kind == .folder { return 10_000 }
        if index == focus { return 9_000 }
        return (focus != nil ? 1_000 : 0) + node.degree * 10 + (node.kind == .note ? 1 : 0)
    }

    private func drawOrder(_ kind: NoteGraph.NodeKind) -> Int {
        switch kind {
        case .missing: 0
        case .tag: 1
        case .note: 2
        case .folder: 3
        }
    }

    /// Subjects are always named; notes once you're close enough to read them, or when they're lit.
    private func showsLabel(for index: Int, node: NoteGraph.Node, focus: Int?, lit: Set<Int>, zoom: CGFloat) -> Bool {
        if node.kind == .folder || lit.contains(index) { return true }
        if focus != nil { return false }
        if zoom >= 0.8 { return true }
        return zoom >= 0.5 && node.degree >= 3
    }

    private func shortened(_ title: String) -> String {
        title.count > 28 ? String(title.prefix(26)) + "…" : title
    }
}

/// What's picked on the map, and the way into it.
private struct GraphNodeCard: View {
    @Environment(Vault.self) private var vault
    let node: NoteGraph.Node
    let connections: Int
    let open: () -> Void

    var body: some View {
        FlashcardSurface(seed: node.id.inkSeed, style: .compact) {
            HStack(alignment: .center, spacing: 12) {
                if let icon = SubjectIcon.named(node.icon) {
                    SubjectIconView(icon: icon, size: 34)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HandwrittenText(verbatim: node.title, weight: 0.4)
                        .font(RemnTypography.display(21, relativeTo: .headline))
                        .foregroundStyle(Color.remnInk)
                        .lineLimit(2)
                    if let detail {
                        HandwrittenText(verbatim: detail)
                            .font(RemnTypography.caption)
                            .foregroundStyle(Color.remnGraphite)
                            .lineLimit(2)
                    }
                    HandwrittenText(caption)
                        .font(RemnTypography.caption)
                        .foregroundStyle(node.kind == .missing ? Color.remnAccent : Color.remnGraphite)
                }
                Spacer(minLength: 8)
                Button(action: open) {
                    HandwrittenText(action, weight: 0.4)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnOnAccent)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background {
                            InkBox(seed: 9_310, cornerRadius: 11, fill: .remnAccent, outline: .remnInk, pen: .fine, registration: CGSize(width: 1.2, height: 1.6))
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(InkPressStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var detail: String? {
        switch node.kind {
        case .note:
            let summary = vault.root.note(at: node.path)
            let folder = VaultPath.parent(of: node.path)
            let excerpt = summary?.snippet ?? ""
            return excerpt.isEmpty ? (folder.isEmpty ? nil : folder.replacingOccurrences(of: "/", with: " / ")) : excerpt
        case .folder:
            let parent = VaultPath.parent(of: node.path)
            return parent.isEmpty ? nil : parent.replacingOccurrences(of: "/", with: " / ")
        case .tag, .missing:
            return nil
        }
    }

    private var caption: LocalizedStringKey {
        switch node.kind {
        case .missing: "notes.graph.missing"
        default: "notes.graph.connections \(connections)"
        }
    }

    private var action: LocalizedStringKey {
        switch node.kind {
        case .missing: "notes.graph.write"
        default: "notes.graph.open"
        }
    }
}

#if os(macOS)
import AppKit

/// Whether the pointer is over the map, for the scroll wheel.
@MainActor
private final class GraphPointer {
    var isInside = false
    var location: CGPoint = .zero
}

/// On the Mac, two fingers or a wheel move the map around, and with ⌘ held they zoom.
private struct GraphScrollWheel: ViewModifier {
    let pointer: GraphPointer
    @Binding var camera: GraphCamera
    let size: CGSize
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else { return }
                let pointer = pointer
                let camera = $camera
                let size = size
                monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
                    let dx = event.scrollingDeltaX
                    let dy = event.scrollingDeltaY
                    let zooms = event.modifierFlags.contains(.command)
                    let used = MainActor.assumeIsolated { () -> Bool in
                        guard pointer.isInside else { return false }
                        if zooms {
                            camera.wrappedValue = camera.wrappedValue.zoomed(by: exp(-dy / 120), around: pointer.location, in: size)
                        } else {
                            camera.wrappedValue.offset.width += dx
                            camera.wrappedValue.offset.height += dy
                        }
                        return true
                    }
                    return used ? nil : event
                }
            }
            .onDisappear {
                if let monitor { NSEvent.removeMonitor(monitor) }
                monitor = nil
            }
    }
}
#endif
