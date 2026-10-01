import SwiftUI

/// How a pen lays ink along a stroke.
struct InkPen: Hashable, Sendable {
    /// Nib width at full pressure, in points.
    var width: CGFloat
    /// Pressure where the pen touches down and lifts off, relative to full pressure.
    var touchDown: CGFloat = 0.55
    var liftOff: CGFloat = 0.3
    /// Distance, in points, the pen takes to reach full pressure and to lift off.
    var attack: CGFloat = 7
    var release: CGFloat = 12
    /// How much the pressure breathes along the stroke.
    var pressureVariation: CGFloat = 0.14

    static let hairline = InkPen(width: 1.05, touchDown: 0.65, liftOff: 0.45, pressureVariation: 0.1)
    static let fine = InkPen(width: 1.45)
    static let pen = InkPen(width: 1.85)
    static let bold = InkPen(width: 2.5, touchDown: 0.6, liftOff: 0.3)
    static let marker = InkPen(
        width: 3.3,
        touchDown: 0.75,
        liftOff: 0.6,
        attack: 4,
        release: 6,
        pressureVariation: 0.08
    )

    func scaled(by factor: CGFloat) -> InkPen {
        var pen = self
        pen.width *= factor
        pen.attack *= factor
        pen.release *= factor
        return pen
    }
}

/// Turns a centerline into the filled outline a real pen would leave: pressure,
/// tapered ends and round tips, instead of a uniform geometric stroke.
enum InkBrush {
    private static let spacing: CGFloat = 2

    static func stroke(
        _ points: [CGPoint],
        pen: InkPen,
        seed: Int,
        progress: CGFloat = 1
    ) -> Path {
        var path = Path()
        addStroke(points, pen: pen, seed: seed, progress: progress, to: &path)
        return path
    }

    /// Appends one stroke. `progress` draws only the first part of it, as if the pen were still moving.
    static func addStroke(
        _ points: [CGPoint],
        pen: InkPen,
        seed: Int,
        progress: CGFloat = 1,
        to path: inout Path
    ) {
        guard progress > 0, let first = points.first else { return }
        let samples = resample(points)
        let length = samples.length

        guard length > 0.5 else {
            let radius = pen.width * 0.5
            path.addEllipse(in: CGRect(x: first.x - radius, y: first.y - radius, width: radius * 2, height: radius * 2))
            return
        }

        let visible = visiblePart(of: samples, progress: min(progress, 1))
        let count = visible.count
        guard count > 1 else { return }

        var centers = [CGPoint]()
        var tangents = [CGVector]()
        var halfWidths = [CGFloat]()
        centers.reserveCapacity(count)
        tangents.reserveCapacity(count)
        halfWidths.reserveCapacity(count)

        for index in 0..<count {
            let previous = visible[max(index - 1, 0)].point
            let next = visible[min(index + 1, count - 1)].point
            centers.append(visible[index].point)
            tangents.append(normalized(CGVector(dx: next.x - previous.x, dy: next.y - previous.y)))
            let pressure = pressure(at: visible[index].distance, length: length, pen: pen, seed: seed)
            halfWidths.append(pen.width * pressure * 0.5)
        }

        var left = [CGPoint]()
        var right = [CGPoint]()
        left.reserveCapacity(count)
        right.reserveCapacity(count)
        for index in 0..<count {
            let normal = CGVector(dx: -tangents[index].dy, dy: tangents[index].dx)
            let center = centers[index]
            let half = halfWidths[index]
            left.append(CGPoint(x: center.x + normal.dx * half, y: center.y + normal.dy * half))
            right.append(CGPoint(x: center.x - normal.dx * half, y: center.y - normal.dy * half))
        }

        path.move(to: left[0])
        if count > 2 {
            for index in 1..<(count - 1) {
                path.addQuadCurve(to: midpoint(left[index], left[index + 1]), control: left[index])
            }
        }
        path.addLine(to: left[count - 1])
        path.addQuadCurve(
            to: right[count - 1],
            control: offset(centers[count - 1], by: tangents[count - 1], distance: halfWidths[count - 1] * 2)
        )
        if count > 2 {
            for index in stride(from: count - 2, to: 0, by: -1) {
                path.addQuadCurve(to: midpoint(right[index], right[index - 1]), control: right[index])
            }
        }
        path.addLine(to: right[0])
        path.addQuadCurve(
            to: left[0],
            control: offset(centers[0], by: tangents[0], distance: -halfWidths[0] * 2)
        )
        path.closeSubpath()
    }

    /// A closed, smooth outline through `points`, for off-register fills and patches.
    static func closedOutline(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else { return path }
        path.move(to: midpoint(points[points.count - 1], points[0]))
        for index in 0..<points.count {
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: midpoint(points[index], next), control: points[index])
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Pressure

    private static func pressure(at distance: CGFloat, length: CGFloat, pen: InkPen, seed: Int) -> CGFloat {
        var pressure: CGFloat = 1
        let attack = min(pen.attack, length * 0.3)
        if attack > 0, distance < attack {
            let t = distance / attack
            pressure *= pen.touchDown + (1 - pen.touchDown) * (1 - (1 - t) * (1 - t))
        }
        let release = min(pen.release, length * 0.4)
        let remaining = length - distance
        if release > 0, remaining < release {
            let t = max(remaining, 0) / release
            pressure *= pen.liftOff + (1 - pen.liftOff) * t * (2 - t)
        }
        pressure *= 1 + pen.pressureVariation * InkNoise.value(distance / 19, seed: seed ^ 0x5EED)
        return max(pressure, 0.15)
    }

    // MARK: - Sampling

    private struct Sample {
        var point: CGPoint
        var distance: CGFloat
    }

    private struct Samples {
        var samples: [Sample]
        var length: CGFloat
    }

    /// Evenly spaced points along a polyline, so pressure and wobble don't depend on how it was built.
    private static func resample(_ input: [CGPoint]) -> Samples {
        guard input.count > 1 else {
            return Samples(samples: input.map { Sample(point: $0, distance: 0) }, length: 0)
        }
        var cumulative = [CGFloat](repeating: 0, count: input.count)
        for index in 1..<input.count {
            cumulative[index] = cumulative[index - 1] + distance(input[index - 1], input[index])
        }
        let length = cumulative[input.count - 1]
        guard length > 0.01 else {
            return Samples(samples: [Sample(point: input[0], distance: 0)], length: 0)
        }

        let count = max(2, Int((length / spacing).rounded(.up)) + 1)
        let step = length / CGFloat(count - 1)
        var result = [Sample]()
        result.reserveCapacity(count)
        var segment = 1
        for index in 0..<count {
            let target = min(CGFloat(index) * step, length)
            while segment < input.count - 1, cumulative[segment] < target {
                segment += 1
            }
            let start = cumulative[segment - 1]
            let end = cumulative[segment]
            let t = end > start ? (target - start) / (end - start) : 0
            result.append(Sample(point: lerp(input[segment - 1], input[segment], t), distance: target))
        }
        return Samples(samples: result, length: length)
    }

    private static func visiblePart(of samples: Samples, progress: CGFloat) -> [Sample] {
        guard progress < 1 else { return samples.samples }
        let limit = samples.length * progress
        var visible = [Sample]()
        visible.reserveCapacity(samples.samples.count)
        for sample in samples.samples {
            if sample.distance <= limit {
                visible.append(sample)
                continue
            }
            if let last = visible.last, sample.distance > last.distance {
                let t = (limit - last.distance) / (sample.distance - last.distance)
                visible.append(Sample(point: lerp(last.point, sample.point, t), distance: limit))
            }
            break
        }
        return visible
    }

    // MARK: - Geometry helpers

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }

    private static func normalized(_ vector: CGVector) -> CGVector {
        let length = hypot(vector.dx, vector.dy)
        guard length > 0.0001 else { return CGVector(dx: 1, dy: 0) }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }

    private static func offset(_ point: CGPoint, by direction: CGVector, distance: CGFloat) -> CGPoint {
        CGPoint(x: point.x + direction.dx * distance, y: point.y + direction.dy * distance)
    }
}
