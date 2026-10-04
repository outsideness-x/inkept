import SwiftUI

/// What a map is drawn for: a folder and everything in it, or one note and the notes around it.
enum NoteGraphScope: Hashable {
    case folder(String)
    case note(String)
}

/// Notes as a map, in the manner of Obsidian's graph: each note a dot in its subject's pencil, sized
/// by how connected it is; links as faint pencil lines; subjects as rings wearing their icons. Point
/// at a note, or touch it, and it and its neighbours light up while the rest step back. Drag the map
/// to look around — it glides on after a flick — pinch or scroll to come closer, and drag a note to
/// see the notes it's joined to follow. On the Mac a click opens a note; on a touch screen the first
/// tap picks it and the second opens it. Drawn round one note, the map is small, the note is filled
/// in red pencil, and every other note on it opens with a tap.
struct NoteGraphView: View {
    @Environment(Vault.self) private var vault
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    let scope: NoteGraphScope
    /// Goes where a node leads: a note, a folder, a tag.
    let onOpen: (NotesRoute) -> Void

    @AppStorage("graph.showsFolders") private var showsFolders = true
    @AppStorage("graph.showsTags") private var showsTags = false
    @AppStorage("graph.showsMissing") private var showsMissing = true
    @AppStorage("graph.showsOrphans") private var showsOrphans = true
    @AppStorage("graph.names") private var names = 1.0
    @AppStorage("graph.nodeSize") private var nodeSize = 1.0
    @AppStorage("graph.spacing") private var spacing = 1.0

    @State private var model = NoteGraphModel()
    @State private var selection: String?
    @State private var hovered: String?
    @State private var dragging: String?
    @State private var drag: GraphDrag?
    @State private var pinchStart: GraphCamera?
    /// Set when a pinch ends with a finger still down, so panning carries on from where the pinch left the view.
    @State private var panNeedsRebase = false
    /// Whether the drag under way has been part of a pinch; such a drag doesn't fling the map when it ends.
    @State private var dragWasPinch = false
    @State private var showsSettings = false
    #if os(macOS)
    @State private var pointer = GraphPointer()
    #endif

    private enum GraphDrag {
        case node(Int)
        case pan(from: CGSize)
    }

    var body: some View {
        GeometryReader { proxy in
            let style = GraphStyle(centreID: centreID, names: CGFloat(names))
            TimelineView(.animation(paused: !model.isAnimating)) { timeline in
                let _ = model.step(to: timeline.date)
                Canvas { context, size in
                    GraphRenderer(model: model, style: style).draw(in: &context, size: size)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(in: proxy.size).simultaneously(with: pinchGesture(in: proxy.size)))
            .onTapGesture(coordinateSpace: .local) { location in tap(at: location, in: proxy.size) }
            .onContinuousHover(coordinateSpace: .local) { phase in hover(phase, in: proxy.size) }
            #if os(macOS)
            // Beside a note the map sits in a list that scrolls, so there only ⌘ and the wheel zoom it.
            .modifier(GraphScrollWheel(model: model, pointer: pointer, pans: isFolderMap))
            .pointerStyle(pointerStyle)
            #endif
            .onChange(of: proxy.size, initial: true) { _, size in model.resize(to: size) }
        }
        .overlay(alignment: .topTrailing) {
            if isFolderMap {
                controls
            }
        }
        .overlay(alignment: .bottom) {
            if isFolderMap, let selected = selectedNode {
                GraphNodeCard(node: selected.node, connections: selected.connections, open: { open(selected.node) })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 520)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.18), value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("notes.graph.label \(model.graph.nodes.filter { $0.kind == .note }.count)"))
        .accessibilityChildren {
            ForEach(accessibleNodes) { node in
                Button { open(node) } label: {
                    Text(verbatim: node.title)
                }
            }
        }
        .onAppear {
            model.reduceMotion = reduceMotion
            model.margin = isFolderMap ? 40 : 26
            model.topInset = isFolderMap ? 44 : 0
        }
        .onChange(of: reduceMotion) { _, reduce in model.reduceMotion = reduce }
        .onChange(of: focusID, initial: true) { _, id in model.setFocus(id) }
        .task(id: graphKey) { await build() }
    }

    /// What's lit: the note being dragged, else the one under the pointer, else the one picked.
    private var focusID: String? {
        dragging ?? hovered ?? selection
    }

    private var isFolderMap: Bool {
        if case .folder = scope { return true }
        return false
    }

    /// The note the map is drawn round, if it's drawn round one.
    private var centreID: String? {
        if case .note(let path) = scope { return NoteGraph.noteID(path) }
        return nil
    }

    private var graphKey: String {
        "\(scope)|\(vault.revision)|\(showsFolders)|\(showsTags)|\(showsMissing)|\(showsOrphans)|\(spacing)|\(nodeSize)"
    }

    private func build() async {
        // Settings change in quick steps while a slider moves; only the last one is laid out.
        if model.generation > 0 {
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
        }
        let graph: NoteGraph
        switch scope {
        case .folder(let path):
            graph = NoteGraph(
                root: vault.root,
                scope: path,
                options: .init(showsFolders: showsFolders, showsTags: showsTags, showsMissing: showsMissing, showsOrphans: showsOrphans)
            )
            model.show(graph, spacing: CGFloat(spacing), nodeScale: CGFloat(nodeSize))
        case .note(let path):
            graph = NoteGraph(root: vault.root, around: path)
            model.show(graph)
        }
        if let selection, graph.index(of: selection) == nil { self.selection = nil }
    }

    /// The notes, subjects and tags on the map, for VoiceOver to read and open one by one.
    private var accessibleNodes: [NoteGraph.Node] {
        Array(model.graph.nodes.filter { $0.kind != .missing && $0.id != centreID }.prefix(200))
    }

    // MARK: - Controls

    /// Coming closer and going back (on the Mac and iPad), seeing everything, and the map's settings.
    private var controls: some View {
        HStack(spacing: -4) {
            if showsZoomButtons {
                InkIconButton(kind: .minus, label: "notes.graph.zoomOut", size: 16) { model.zoom(by: 1 / 1.6) }
                    .keyboardShortcut("-", modifiers: .command)
                InkIconButton(kind: .plus, label: "notes.graph.zoomIn", size: 16) { model.zoom(by: 1.6) }
                    .keyboardShortcut("=", modifiers: .command)
            }
            InkIconButton(kind: .fit, label: "notes.graph.fit", size: 17) { model.fit(animated: true) }
                .keyboardShortcut("0", modifiers: .command)
            InkIconButton(kind: .settings, label: "notes.graph.settings", size: 18) { showsSettings.toggle() }
                .popover(isPresented: $showsSettings, arrowEdge: .top) {
                    GraphSettingsPanel(
                        showsFolders: $showsFolders,
                        showsTags: $showsTags,
                        showsMissing: $showsMissing,
                        showsOrphans: $showsOrphans,
                        names: $names,
                        nodeSize: $nodeSize,
                        spacing: $spacing
                    )
                    .presentationCompactAdaptation(.popover)
                }
        }
        .padding(.horizontal, 1)
        .frame(height: 40)
        .background {
            InkBox(
                seed: 9_420,
                cornerRadius: 13,
                fill: .inkeptCardPaper,
                outline: .inkeptInk.opacity(0.4),
                pen: .hairline,
                registration: CGSize(width: 0.6, height: 1)
            )
        }
        .padding(.top, 2)
        .padding(.trailing, 14)
    }

    private var showsZoomButtons: Bool {
        #if os(macOS)
        true
        #else
        sizeClass == .regular
        #endif
    }

    // MARK: - Gestures

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .local)
            .onChanged { value in
                if drag == nil {
                    model.hold()
                    let camera = model.camera
                    if pinchStart == nil, let node = model.node(at: camera.world(value.startLocation, in: size), slack: 8 / camera.scale) {
                        drag = .node(node)
                        dragging = model.graph.nodes[node].id
                        model.pickUp(node, at: camera.world(value.location, in: size))
                    } else {
                        drag = .pan(from: camera.offset)
                    }
                }
                switch drag {
                case .node(let node):
                    model.drag(node, to: model.camera.world(value.location, in: size))
                case .pan(let from):
                    if pinchStart != nil {
                        panNeedsRebase = true
                        dragWasPinch = true
                    } else if panNeedsRebase {
                        panNeedsRebase = false
                        drag = .pan(from: CGSize(
                            width: model.camera.offset.width - value.translation.width,
                            height: model.camera.offset.height - value.translation.height
                        ))
                    } else {
                        var camera = model.camera
                        camera.offset = CGSize(width: from.width + value.translation.width, height: from.height + value.translation.height)
                        model.look(from: camera)
                    }
                case nil:
                    break
                }
            }
            .onEnded { value in
                switch drag {
                case .node(let node):
                    model.letGo(node)
                    dragging = nil
                case .pan:
                    if pinchStart == nil, !dragWasPinch { model.fling(value.velocity) }
                case nil:
                    break
                }
                drag = nil
                panNeedsRebase = false
                dragWasPinch = false
                model.release()
            }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if pinchStart == nil {
                    pinchStart = model.camera
                    dragWasPinch = drag != nil
                    model.hold()
                }
                guard let start = pinchStart else { return }
                model.look(from: start.zoomed(by: value.magnification, around: value.startLocation, in: size))
            }
            .onEnded { _ in
                pinchStart = nil
                model.release()
            }
    }

    private func hover(_ phase: HoverPhase, in size: CGSize) {
        switch phase {
        case .active(let location):
            #if os(macOS)
            pointer.isInside = true
            pointer.location = location
            #endif
            guard drag == nil else { return }
            let camera = model.camera
            let hit = model.node(at: camera.world(location, in: size), slack: 5 / camera.scale).map { model.graph.nodes[$0].id }
            if hit != hovered { hovered = hit }
        case .ended:
            #if os(macOS)
            pointer.isInside = false
            #endif
            hovered = nil
        }
    }

    #if os(macOS)
    private var pointerStyle: PointerStyle? {
        switch drag {
        case .node, .pan: .grabActive
        case nil: hovered == nil ? nil : .link
        }
    }
    #endif

    private func tap(at location: CGPoint, in size: CGSize) {
        let camera = model.camera
        guard let index = model.node(at: camera.world(location, in: size), slack: 10 / camera.scale) else {
            selection = nil
            return
        }
        let node = model.graph.nodes[index]
        if centreID != nil {
            if node.kind == .note, node.id != centreID {
                open(node)
            } else {
                selection = selection == node.id ? nil : node.id
            }
            return
        }
        #if os(macOS)
        // With a pointer, what's under it is already lit; a click goes straight there, as in Obsidian.
        open(node)
        #else
        if selection == node.id {
            open(node)
            return
        }
        selection = node.id
        // Keep what's picked clear of the card that opens at the foot of the map.
        let point = camera.screen(model.positions[index], in: size)
        let lowest = size.height - 190
        if point.y > lowest {
            var target = camera
            target.offset.height -= point.y - lowest
            model.fly(to: target, duration: 0.45)
        }
        #endif
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
                        .font(InkeptTypography.display(21, relativeTo: .headline))
                        .foregroundStyle(Color.inkeptInk)
                        .lineLimit(2)
                    if let detail {
                        HandwrittenText(verbatim: detail)
                            .font(InkeptTypography.caption)
                            .foregroundStyle(Color.inkeptGraphite)
                            .lineLimit(2)
                    }
                    HandwrittenText(caption)
                        .font(InkeptTypography.caption)
                        .foregroundStyle(node.kind == .missing ? Color.inkeptAccent : Color.inkeptGraphite)
                }
                Spacer(minLength: 8)
                Button(action: open) {
                    HandwrittenText(action, weight: 0.4)
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptOnAccent)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background {
                            InkBox(seed: 9_310, cornerRadius: 11, fill: .inkeptAccent, outline: .inkeptInk, pen: .fine, registration: CGSize(width: 1.2, height: 1.6))
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

/// The map's settings, in the manner of Obsidian's: what's on it, and how it's drawn.
private struct GraphSettingsPanel: View {
    @Binding var showsFolders: Bool
    @Binding var showsTags: Bool
    @Binding var showsMissing: Bool
    @Binding var showsOrphans: Bool
    @Binding var names: Double
    @Binding var nodeSize: Double
    @Binding var spacing: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("notes.graph.show")
            toggle("notes.graph.folders", isOn: $showsFolders, seed: 9_201)
            toggle("notes.graph.tags", isOn: $showsTags, seed: 9_202)
            toggle("notes.graph.unwritten", isOn: $showsMissing, seed: 9_203)
            toggle("notes.graph.orphans", isOn: $showsOrphans, seed: 9_204)
            heading("notes.graph.look")
                .padding(.top, 14)
            slider("notes.graph.names", value: $names, in: 0.5...2, step: 0.1)
            slider("notes.graph.size", value: $nodeSize, in: 0.6...1.8, step: 0.1)
            slider("notes.graph.spacing", value: $spacing, in: 0.6...1.8, step: 0.1)
            if !isAsShipped {
                Button {
                    names = 1
                    nodeSize = 1
                    spacing = 1
                } label: {
                    HandwrittenText("notes.graph.reset")
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 9_230))
                .padding(.leading, -10)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 290)
        .presentationBackground(Color.inkeptPaper)
    }

    private var isAsShipped: Bool {
        names == 1 && nodeSize == 1 && spacing == 1
    }

    private func heading(_ title: LocalizedStringKey) -> some View {
        HandwrittenText(title, weight: 0.4)
            .font(InkeptTypography.control)
            .foregroundStyle(Color.inkeptInk)
            .padding(.bottom, 2)
            .accessibilityAddTraits(.isHeader)
    }

    private func toggle(_ title: LocalizedStringKey, isOn: Binding<Bool>, seed: Int) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(spacing: 6) {
                InkCheckbox(isOn: isOn.wrappedValue, seed: seed)
                    .scaleEffect(0.8)
                    .frame(width: 26, height: 26)
                HandwrittenText(title)
                    .font(InkeptTypography.note)
                    .foregroundStyle(isOn.wrappedValue ? Color.inkeptInk : Color.inkeptGraphite)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityAddTraits(isOn.wrappedValue ? .isSelected : [])
    }

    private func slider(_ title: LocalizedStringKey, value: Binding<Double>, in range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: -4) {
            HandwrittenText(title)
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
            InkSlider(value: value, range: range, step: step, accessibilityLabel: Text(title), marks: [1])
        }
        .padding(.top, 4)
    }
}

#if os(macOS)
import AppKit

/// Where the pointer is over the map, for the scroll wheel to zoom round.
@MainActor
private final class GraphPointer {
    var isInside = false
    var location: CGPoint = .zero
}

/// On the Mac two fingers move the map around and a pinch brings it closer; a mouse wheel zooms,
/// as it does in Obsidian, and so does scrolling with ⌘ held. When the map doesn't `pan`, scrolling
/// without ⌘ is left to whatever the map sits in.
private struct GraphScrollWheel: ViewModifier {
    let model: NoteGraphModel
    let pointer: GraphPointer
    var pans = true
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else { return }
                let model = model
                let pointer = pointer
                let pans = pans
                monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
                    let dx = event.scrollingDeltaX
                    let dy = event.scrollingDeltaY
                    let isTrackpad = event.hasPreciseScrollingDeltas
                    let zooms = event.modifierFlags.contains(.command) || (pans && !isTrackpad)
                    let used = MainActor.assumeIsolated { () -> Bool in
                        guard pointer.isInside, zooms || pans else { return false }
                        if zooms {
                            if isTrackpad {
                                model.zoom(by: exp(dy / 150), around: pointer.location, animated: false)
                            } else {
                                // A notch of the wheel at a time, each one glided to.
                                model.zoom(by: exp(max(min(dy, 6), -6) * 0.2), around: pointer.location)
                            }
                        } else {
                            var camera = model.camera
                            camera.offset.width += dx
                            camera.offset.height += dy
                            model.look(from: camera)
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
