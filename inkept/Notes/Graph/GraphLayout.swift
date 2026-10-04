import CoreGraphics
import Foundation

/// Lays a graph out the way springs and magnets would settle: links pull their ends together, every
/// node pushes the rest away, and a gentle pull to the middle keeps loose notes from drifting off.
/// The same forces d3 uses, with a quadtree so a vault of thousands of notes still moves smoothly.
struct GraphLayout: Sendable {
    private(set) var positions: [CGPoint]
    private var velocities: [CGVector]
    private let springs: [Spring]
    private let charges: [CGFloat]
    let radii: [CGFloat]
    /// How hard each node is drawn to the middle, across and down. A tall view pulls harder across,
    /// so the map grows into the shape it's shown in.
    private let gravity: CGVector
    private(set) var alpha: CGFloat
    /// Where the heat settles; above zero while a node is being dragged, so the rest keep moving.
    var alphaTarget: CGFloat = 0
    /// Nodes held where a finger or the pointer has them.
    var pinned: [Int: CGPoint] = [:]

    static let alphaMin: CGFloat = 0.004
    private let alphaDecay: CGFloat = 1 - pow(0.001, 1.0 / 300)
    private let velocityDecay: CGFloat = 0.6
    private let theta2: CGFloat = 0.81

    private struct Spring: Sendable {
        let a: Int
        let b: Int
        let length: CGFloat
        let strength: CGFloat
        /// How much of the pull moves `b` rather than `a`: the busier end moves less.
        let bias: CGFloat
    }

    var isSettled: Bool {
        alpha < Self.alphaMin && pinned.isEmpty
    }

    /// Starts from where nodes were before, if they were; new ones start beside a neighbour.
    /// `spacing` spreads everything further apart or draws it closer, `aspect` is the height of the
    /// view over its width, and `nodeScale` makes every node bigger or smaller.
    init(graph: NoteGraph, previous: [String: CGPoint] = [:], spacing: CGFloat = 1, aspect: CGFloat = 1, nodeScale: CGFloat = 1) {
        let nodes = graph.nodes
        radii = nodes.map { Self.radius(for: $0) * nodeScale }
        // A charge pushes as far as the square root of its strength, so spacing goes in squared.
        let push = spacing * spacing
        charges = nodes.map { node in
            let charge: CGFloat = switch node.kind {
            case .folder: -240
            case .tag: -80
            case .missing: -40
            case .note: -75 - CGFloat(min(node.degree, 12)) * 4
            }
            return charge * push
        }
        let degrees = graph.neighbours.map { CGFloat(max($0.count, 1)) }
        springs = graph.edges.map { edge in
            let length: CGFloat = switch edge.kind {
            case .link: 78
            case .folder: 46
            case .tag: 58
            }
            return Spring(
                a: edge.a,
                b: edge.b,
                length: (length + (nodes[edge.a].kind == .folder || nodes[edge.b].kind == .folder ? 16 : 0)) * spacing,
                strength: (edge.kind == .folder ? 0.7 : 1) / min(degrees[edge.a], degrees[edge.b]),
                bias: degrees[edge.a] / (degrees[edge.a] + degrees[edge.b])
            )
        }
        let stretch = pow(min(max(aspect, 0.45), 2.2), 0.9)
        gravity = CGVector(dx: 0.045 * stretch, dy: 0.045 / stretch)
        positions = Self.startingPositions(graph: graph, previous: previous, spacing: spacing)
        velocities = Array(repeating: .zero, count: nodes.count)
        let known = nodes.filter { previous[$0.id] != nil }.count
        alpha = !nodes.isEmpty && known * 10 >= nodes.count * 9 ? 0.25 : 1
    }

    static func radius(for node: NoteGraph.Node) -> CGFloat {
        switch node.kind {
        case .folder: 17 + min(sqrt(CGFloat(node.degree)) * 1.6, 9)
        case .tag: 6
        case .missing: 4.5
        case .note: 4.5 + min(sqrt(CGFloat(node.degree)) * 2.4, 10)
        }
    }

    /// Wakes the layout up, as when a node is picked up or let go.
    mutating func reheat(to value: CGFloat = 0.3) {
        alpha = max(alpha, value)
    }

    /// Runs until the layout has all but stopped moving, or `ticks` run out.
    mutating func settle(ticks: Int) {
        for _ in 0..<ticks where alpha >= Self.alphaMin {
            tick()
        }
    }

    /// Moves everything on by one step of the simulation, or by `timeScale` of one, so the map
    /// moves at the same pace whether the screen draws 60 frames a second or 120.
    mutating func tick(timeScale: CGFloat = 1) {
        let count = positions.count
        guard count > 0 else { return }
        let step = min(max(timeScale, 0.1), 1.5)
        alpha += (alphaTarget - alpha) * (1 - pow(1 - alphaDecay, step))

        for spring in springs {
            var dx = positions[spring.b].x + velocities[spring.b].dx - positions[spring.a].x - velocities[spring.a].dx
            var dy = positions[spring.b].y + velocities[spring.b].dy - positions[spring.a].y - velocities[spring.a].dy
            if dx == 0, dy == 0 {
                dx = jiggle(spring.a)
                dy = jiggle(spring.b)
            }
            let length = sqrt(dx * dx + dy * dy)
            let pull = (length - spring.length) / length * alpha * spring.strength * step
            dx *= pull
            dy *= pull
            velocities[spring.b].dx -= dx * spring.bias
            velocities[spring.b].dy -= dy * spring.bias
            velocities[spring.a].dx += dx * (1 - spring.bias)
            velocities[spring.a].dy += dy * (1 - spring.bias)
        }

        repel(step: step)

        let gx = gravity.dx * alpha * step
        let gy = gravity.dy * alpha * step
        for index in 0..<count {
            velocities[index].dx -= positions[index].x * gx
            velocities[index].dy -= positions[index].y * gy
        }

        collide(step: step)

        let decay = pow(velocityDecay, step)
        for index in 0..<count {
            if let pin = pinned[index] {
                positions[index] = pin
                velocities[index] = .zero
                continue
            }
            velocities[index].dx *= decay
            velocities[index].dy *= decay
            positions[index].x += velocities[index].dx * step
            positions[index].y += velocities[index].dy * step
        }
    }

    /// Puts the nodes where they're drawn, as when a node is picked up halfway through a move.
    mutating func place(at points: [CGPoint]) {
        guard points.count == positions.count else { return }
        positions = points
        velocities = Array(repeating: .zero, count: points.count)
    }

    // MARK: - Pushing apart

    private struct Quad {
        var minX: CGFloat
        var minY: CGFloat
        var size: CGFloat
        /// The four quarters, as indices into the tree; a tuple keeps each quad free of allocations.
        var children: (Int, Int, Int, Int) = (-1, -1, -1, -1)
        var body = -1
        var isLeaf = true
        var charge: CGFloat = 0
        var weight: CGFloat = 0
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
    }

    /// Every node pushes every other away, far-off crowds counted as one, as in Barnes and Hut.
    private mutating func repel(step: CGFloat) {
        let count = positions.count
        guard count > 1 else { return }
        var minX = CGFloat.infinity, minY = CGFloat.infinity, maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for point in positions {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        let size = max(maxX - minX, maxY - minY, 1) + 1
        var quads = [Quad(minX: minX, minY: minY, size: size)]
        quads.reserveCapacity(count * 3)
        for index in 0..<count {
            insert(index, into: 0, quads: &quads, depth: 0)
        }
        for index in 0..<count where pinned[index] == nil {
            var force = CGVector.zero
            accumulate(on: index, from: 0, quads: quads, force: &force)
            velocities[index].dx += force.dx * alpha * step
            velocities[index].dy += force.dy * alpha * step
        }
    }

    private func insert(_ body: Int, into quad: Int, quads: inout [Quad], depth: Int) {
        let point = positions[body]
        let charge = charges[body]
        let weight = abs(charge)
        quads[quad].charge += charge
        quads[quad].weight += weight
        quads[quad].weightedX += point.x * weight
        quads[quad].weightedY += point.y * weight

        if quads[quad].isLeaf {
            if quads[quad].body == -1 {
                quads[quad].body = body
                return
            }
            // Two nodes on one spot, or a tree grown too deep: they share the leaf.
            if depth > 30 { return }
            let resident = quads[quad].body
            quads[quad].body = -1
            quads[quad].isLeaf = false
            place(resident, in: quad, quads: &quads, depth: depth)
        }
        place(body, in: quad, quads: &quads, depth: depth)
    }

    private func place(_ body: Int, in quad: Int, quads: inout [Quad], depth: Int) {
        let point = positions[body]
        let half = quads[quad].size / 2
        let right = point.x >= quads[quad].minX + half
        let below = point.y >= quads[quad].minY + half
        let slot = (right ? 1 : 0) + (below ? 2 : 0)
        var child = Self.child(slot, of: quads[quad])
        if child == -1 {
            quads.append(Quad(
                minX: quads[quad].minX + (right ? half : 0),
                minY: quads[quad].minY + (below ? half : 0),
                size: half
            ))
            child = quads.count - 1
            switch slot {
            case 0: quads[quad].children.0 = child
            case 1: quads[quad].children.1 = child
            case 2: quads[quad].children.2 = child
            default: quads[quad].children.3 = child
            }
        }
        insert(body, into: child, quads: &quads, depth: depth + 1)
    }

    private static func child(_ slot: Int, of quad: Quad) -> Int {
        switch slot {
        case 0: quad.children.0
        case 1: quad.children.1
        case 2: quad.children.2
        default: quad.children.3
        }
    }

    private func accumulate(on body: Int, from quad: Int, quads: [Quad], force: inout CGVector) {
        let node = quads[quad]
        guard node.weight > 0 else { return }
        let point = positions[body]
        let dx = node.weightedX / node.weight - point.x
        let dy = node.weightedY / node.weight - point.y
        var distance2 = dx * dx + dy * dy
        if !node.isLeaf, node.size * node.size / theta2 < distance2 {
            // Far enough to count the whole crowd as one.
            distance2 = max(distance2, 1)
            force.dx += dx * node.charge / distance2
            force.dy += dy * node.charge / distance2
            return
        }
        if node.isLeaf {
            guard node.body != body else { return }
            if distance2 < 1 {
                force.dx += jiggle(body) * 30
                force.dy += jiggle(body &+ 7) * 30
                return
            }
            force.dx += dx * node.charge / distance2
            force.dy += dy * node.charge / distance2
            return
        }
        for slot in 0..<4 {
            let child = Self.child(slot, of: node)
            if child != -1 { accumulate(on: body, from: child, quads: quads, force: &force) }
        }
    }

    /// Nodes don't sit on top of one another: overlapping ones are nudged apart.
    private mutating func collide(step: CGFloat) {
        let count = positions.count
        guard count > 1, let largest = radii.max() else { return }
        let cell = largest * 2 + 8
        var grid: [Int64: [Int]] = [:]
        func key(_ x: Int, _ y: Int) -> Int64 { Int64(x) << 32 ^ Int64(y & 0xFFFF_FFFF) }
        for index in 0..<count {
            let point = positions[index]
            grid[key(Int(floor(point.x / cell)), Int(floor(point.y / cell))), default: []].append(index)
        }
        for index in 0..<count {
            let point = positions[index]
            let column = Int(floor(point.x / cell))
            let row = Int(floor(point.y / cell))
            for dx in -1...1 {
                for dy in -1...1 {
                    for other in grid[key(column + dx, row + dy)] ?? [] where other > index {
                        var x = positions[other].x + velocities[other].dx - point.x - velocities[index].dx
                        var y = positions[other].y + velocities[other].dy - point.y - velocities[index].dy
                        let reach = radii[index] + radii[other] + 6
                        var distance2 = x * x + y * y
                        guard distance2 < reach * reach else { continue }
                        if distance2 == 0 {
                            x = jiggle(index)
                            y = jiggle(other)
                            distance2 = x * x + y * y
                        }
                        let distance = sqrt(distance2)
                        let push = (reach - distance) / distance * 0.7 * min(step, 1)
                        let share = radii[other] * radii[other] / (radii[index] * radii[index] + radii[other] * radii[other])
                        x *= push
                        y *= push
                        velocities[index].dx -= x * share
                        velocities[index].dy -= y * share
                        velocities[other].dx += x * (1 - share)
                        velocities[other].dy += y * (1 - share)
                    }
                }
            }
        }
    }

    /// A tiny, repeatable nudge for things that sit exactly on top of each other.
    private func jiggle(_ seed: Int) -> CGFloat {
        var random = InkRandom(seed: seed &* 2_654_435_761)
        return (random.unit() - 0.5) * 1e-3
    }

    // MARK: - Starting out

    /// Folders on a sunflower spiral, notes gathered round whatever they're joined to, the rest further out.
    private static func startingPositions(graph: NoteGraph, previous: [String: CGPoint], spacing: CGFloat) -> [CGPoint] {
        let nodes = graph.nodes
        let golden = CGFloat.pi * (3 - sqrt(5))
        var positions = [CGPoint](repeating: .zero, count: nodes.count)
        var placed = [Bool](repeating: false, count: nodes.count)
        for (index, node) in nodes.enumerated() {
            if let point = previous[node.id] {
                positions[index] = point
                placed[index] = true
            }
        }
        var hubs = 0
        for (index, node) in nodes.enumerated() where node.kind == .folder && !placed[index] {
            let radius = 110 * spacing * sqrt(0.5 + CGFloat(hubs))
            let angle = CGFloat(hubs) * golden
            positions[index] = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            placed[index] = true
            hubs += 1
        }
        var gathered = [Int](repeating: 0, count: nodes.count)
        var progress = true
        while progress {
            progress = false
            for index in nodes.indices where !placed[index] {
                guard let anchor = graph.neighbours[index].first(where: { placed[$0] }) else { continue }
                gathered[anchor] += 1
                let step = CGFloat(gathered[anchor])
                let radius = 26 * spacing * sqrt(step)
                let angle = step * golden
                positions[index] = CGPoint(
                    x: positions[anchor].x + radius * cos(angle),
                    y: positions[anchor].y + radius * sin(angle)
                )
                placed[index] = true
                progress = true
            }
        }
        var loose = 0
        let spread = (110 * sqrt(0.5 + CGFloat(max(hubs, 1))) + 60) * spacing
        for index in nodes.indices where !placed[index] {
            let radius = spread + 22 * spacing * sqrt(0.5 + CGFloat(loose))
            let angle = CGFloat(loose) * golden
            positions[index] = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            loose += 1
        }
        return positions
    }
}
