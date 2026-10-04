import CoreGraphics

/// Where the map is looked at from: how close, and how far moved.
struct GraphCamera: Equatable {
    static let farthest: CGFloat = 0.12
    static let closest: CGFloat = 4

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    init(scale: CGFloat = 1, offset: CGSize = .zero) {
        self.scale = scale
        self.offset = offset
    }

    /// Looking straight at `centre` of the map, from `scale`.
    init(centre: CGPoint, scale: CGFloat) {
        self.scale = scale
        offset = CGSize(width: -centre.x * scale, height: -centre.y * scale)
    }

    /// The point of the map in the middle of the view.
    var centre: CGPoint {
        CGPoint(x: -offset.width / scale, y: -offset.height / scale)
    }

    func screen(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + offset.width + point.x * scale, y: size.height / 2 + offset.height + point.y * scale)
    }

    func world(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: (point.x - size.width / 2 - offset.width) / scale, y: (point.y - size.height / 2 - offset.height) / scale)
    }

    /// Close enough to see everything in `bounds`, with room round the edge for names, and `top`
    /// more above for whatever floats over the top of the map.
    static func fitting(_ bounds: CGRect, in size: CGSize, margin: CGFloat = 46, top: CGFloat = 0, closest: CGFloat = 1.6) -> GraphCamera {
        let height = size.height - top
        guard !bounds.isNull, !bounds.isInfinite, size.width > margin * 2, height > margin * 2 else { return GraphCamera() }
        let scale = min(max(min(
            (size.width - margin * 2) / max(bounds.width, 1),
            (height - margin * 2) / max(bounds.height, 1)
        ), farthest), closest)
        // The middle of the map goes in the middle of the room left under `top`.
        let centre = CGPoint(x: bounds.midX, y: bounds.midY - top / 2 / scale)
        return GraphCamera(centre: centre, scale: scale)
    }

    /// Zooms by `factor` keeping the point under `anchor` where it is.
    func zoomed(by factor: CGFloat, around anchor: CGPoint, in size: CGSize) -> GraphCamera {
        let fixed = world(anchor, in: size)
        let scale = min(max(scale * factor, Self.farthest), Self.closest)
        return GraphCamera(
            scale: scale,
            offset: CGSize(
                width: anchor.x - size.width / 2 - fixed.x * scale,
                height: anchor.y - size.height / 2 - fixed.y * scale
            )
        )
    }

    /// Part of the way to `target`: the middle moves in a straight line and the zoom changes evenly,
    /// so neither seems to rush.
    func mixed(with target: GraphCamera, by t: CGFloat) -> GraphCamera {
        let from = centre
        let to = target.centre
        let scale = exp(log(scale) + (log(target.scale) - log(scale)) * t)
        return GraphCamera(centre: CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t), scale: scale)
    }
}
