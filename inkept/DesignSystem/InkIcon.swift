import SwiftUI

enum InkIconKind: Int, CaseIterable {
    case search
    case settings
    case plus
    case minus
    case back
    case forward
    case more
    case flip
    case down
    case info
    case upload
    case download
    case check
    case close
    case undo
    case cloud
    case typeface
    case picture
    case card
    case list
    case folder
    /// Four corners: fit everything in view.
    case fit
    /// Three notes and the lines between them: what a note is linked with.
    case links
    /// An arrow out of a box: this opens somewhere outside the app.
    case external
}

/// A small drawing in the same pen as the rest of the interface, on a 24-point grid.
struct InkIconShape: Shape {
    let kind: InkIconKind
    var pen: InkPen = .pen

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let origin = CGPoint(x: rect.midX - 12 * scale, y: rect.midY - 12 * scale)
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
        }

        let drawing = InkIconDrawing.drawing(for: kind)
        let pen = pen.scaled(by: max(scale, 0.75))
        let seed = 9_103 &+ kind.rawValue &* 131
        var path = Path()
        for (index, stroke) in drawing.strokes.enumerated() {
            let points = stroke.points.map(place)
            let line = stroke.smooth ? InkGeometry.smooth(points) : points
            InkBrush.addStroke(line, pen: pen, seed: seed &+ index, to: &path)
        }
        for (index, loop) in drawing.loops.enumerated() {
            let frame = CGRect(
                x: origin.x + loop.minX * scale,
                y: origin.y + loop.minY * scale,
                width: loop.width * scale,
                height: loop.height * scale
            )
            InkBrush.addStroke(
                InkGeometry.ellipseLoop(in: frame, seed: seed &+ 50 &+ index, overshoot: 0.5),
                pen: pen,
                seed: seed &+ 50 &+ index,
                to: &path
            )
        }
        for dot in drawing.dots {
            let center = place(dot.center)
            let radius = dot.radius * scale
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius * 0.9, width: radius * 2, height: radius * 1.85))
        }
        return path
    }
}

struct InkIcon: View {
    let kind: InkIconKind
    var color: Color = .inkeptInk
    var size: CGFloat = 22

    var body: some View {
        InkIconShape(kind: kind)
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct InkIconDrawing {
    struct Stroke {
        var points: [CGPoint]
        var smooth = false
    }

    struct Dot {
        var center: CGPoint
        var radius: CGFloat
    }

    var strokes: [Stroke] = []
    var loops: [CGRect] = []
    var dots: [Dot] = []

    static func drawing(for kind: InkIconKind) -> InkIconDrawing {
        switch kind {
        case .search:
            InkIconDrawing(
                strokes: [Stroke(points: [p(15.1, 15.3), p(20.6, 20.9)])],
                loops: [CGRect(x: 3.4, y: 3.2, width: 13.6, height: 13.4)]
            )
        case .settings:
            InkIconDrawing(
                strokes: [
                    Stroke(points: [p(2.8, 6.2), p(5.2, 6.1)]),
                    Stroke(points: [p(10.0, 6.0), p(21.2, 5.8)]),
                    Stroke(points: [p(2.9, 12.2), p(13.3, 12.0)]),
                    Stroke(points: [p(18.1, 12.1), p(21.1, 12.0)]),
                    Stroke(points: [p(3.0, 18.2), p(7.4, 18.1)]),
                    Stroke(points: [p(12.2, 18.0), p(21.0, 17.8)]),
                ],
                loops: [
                    CGRect(x: 5.3, y: 3.7, width: 4.6, height: 4.7),
                    CGRect(x: 13.4, y: 9.7, width: 4.6, height: 4.6),
                    CGRect(x: 7.5, y: 15.8, width: 4.6, height: 4.6),
                ]
            )
        case .plus:
            InkIconDrawing(strokes: [
                Stroke(points: [p(12.3, 3.8), p(11.8, 20.3)]),
                Stroke(points: [p(3.9, 12.3), p(20.2, 11.7)]),
            ])
        case .minus:
            InkIconDrawing(strokes: [Stroke(points: [p(4.2, 12.3), p(19.9, 11.8)])])
        case .back:
            InkIconDrawing(strokes: [
                Stroke(points: [p(20.3, 12.4), p(12.5, 12.0), p(4.3, 12.1)], smooth: true),
                Stroke(points: [p(10.6, 5.6), p(4.3, 12.1)]),
                Stroke(points: [p(4.3, 12.1), p(10.9, 18.4)]),
            ])
        case .forward:
            InkIconDrawing(strokes: [
                Stroke(points: [p(3.7, 12.2), p(11.5, 11.9), p(19.7, 12.0)], smooth: true),
                Stroke(points: [p(13.4, 5.5), p(19.7, 12.0)]),
                Stroke(points: [p(19.7, 12.0), p(13.2, 18.5)]),
            ])
        case .more:
            InkIconDrawing(dots: [
                Dot(center: p(5.0, 12.4), radius: 1.45),
                Dot(center: p(12.0, 11.9), radius: 1.5),
                Dot(center: p(19.0, 12.2), radius: 1.4),
            ])
        case .flip:
            InkIconDrawing(strokes: [
                Stroke(points: [p(4.6, 15.4), p(6.6, 9.8), p(12.0, 7.3), p(18.2, 9.9)], smooth: true),
                Stroke(points: [p(12.9, 5.1), p(18.2, 9.9)]),
                Stroke(points: [p(18.2, 9.9), p(13.4, 14.2)]),
            ])
        case .down:
            InkIconDrawing(strokes: [
                Stroke(points: [p(4.4, 8.6), p(12.1, 16.2)]),
                Stroke(points: [p(12.1, 16.2), p(19.7, 8.2)]),
            ])
        case .info:
            InkIconDrawing(
                strokes: [Stroke(points: [p(12.1, 10.8), p(11.9, 16.9)])],
                loops: [CGRect(x: 2.8, y: 2.9, width: 18.4, height: 18.0)],
                dots: [Dot(center: p(12.1, 7.4), radius: 1.3)]
            )
        case .upload, .download:
            InkIconDrawing(strokes: [
                Stroke(points: [p(3.8, 15.2), p(4.0, 20.0), p(20.1, 19.7), p(20.2, 15.0)]),
                Stroke(points: [p(12.1, kind == .upload ? 15.9 : 3.8), p(11.9, kind == .upload ? 3.8 : 15.9)]),
                Stroke(points: [p(7.2, kind == .upload ? 8.6 : 11.0), p(11.9, kind == .upload ? 3.8 : 15.9)]),
                Stroke(points: [p(11.9, kind == .upload ? 3.8 : 15.9), p(16.9, kind == .upload ? 8.8 : 11.2)]),
            ])
        case .check:
            InkIconDrawing(strokes: [
                Stroke(points: [p(4.2, 12.9), p(9.3, 18.0)]),
                Stroke(points: [p(9.3, 18.0), p(20.2, 5.6)]),
            ])
        case .close:
            InkIconDrawing(strokes: [
                Stroke(points: [p(5.2, 5.0), p(19.0, 19.2)]),
                Stroke(points: [p(19.1, 5.2), p(5.0, 18.9)]),
            ])
        case .cloud:
            InkIconDrawing(strokes: [
                Stroke(points: [
                    p(7.0, 17.6), p(4.4, 16.6), p(3.7, 13.8), p(5.4, 11.5), p(8.1, 11.1),
                    p(9.3, 7.7), p(12.5, 6.0), p(15.6, 7.3), p(16.9, 10.3), p(19.4, 10.9),
                    p(20.7, 13.6), p(19.7, 16.6), p(17.0, 17.7), p(7.4, 17.5),
                ], smooth: true),
            ])
        case .typeface:
            InkIconDrawing(
                strokes: [
                    Stroke(points: [p(2.6, 19.2), p(7.6, 4.8), p(12.4, 19.0)]),
                    Stroke(points: [p(4.7, 13.7), p(10.3, 13.4)]),
                    Stroke(points: [p(20.4, 11.2), p(20.7, 19.3)]),
                ],
                loops: [CGRect(x: 14.0, y: 11.8, width: 6.4, height: 7.3)]
            )
        case .picture:
            InkIconDrawing(
                strokes: [
                    Stroke(points: [p(3.2, 5.4), p(20.9, 5.1), p(20.7, 18.9), p(3.0, 19.1), p(3.3, 5.0)]),
                    Stroke(points: [p(5.0, 17.2), p(9.6, 11.2), p(12.9, 14.6), p(15.4, 12.2), p(19.2, 17.0)]),
                ],
                loops: [CGRect(x: 14.4, y: 7.4, width: 3.2, height: 3.1)]
            )
        case .card:
            InkIconDrawing(strokes: [
                Stroke(points: [p(6.4, 3.9), p(20.6, 4.2), p(20.3, 14.6)]),
                Stroke(points: [p(3.2, 7.6), p(17.2, 7.4), p(17.4, 20.1), p(3.4, 20.3), p(3.3, 7.3)]),
                Stroke(points: [p(6.3, 12.1), p(14.3, 11.9)]),
                Stroke(points: [p(6.2, 15.7), p(11.9, 15.6)]),
            ])
        case .folder:
            InkIconDrawing(strokes: [
                Stroke(points: [p(3.1, 18.9), p(2.9, 6.2), p(9.4, 6.0), p(11.2, 8.4), p(20.8, 8.2), p(21.0, 19.1), p(3.3, 19.2)]),
                Stroke(points: [p(3.2, 11.1), p(20.7, 10.9)]),
            ])
        case .list:
            InkIconDrawing(
                strokes: [
                    Stroke(points: [p(9.2, 6.3), p(20.6, 6.0)]),
                    Stroke(points: [p(9.1, 12.2), p(20.4, 12.0)]),
                    Stroke(points: [p(9.3, 18.1), p(17.6, 17.9)]),
                ],
                dots: [
                    Dot(center: p(4.4, 6.2), radius: 1.5),
                    Dot(center: p(4.3, 12.1), radius: 1.5),
                    Dot(center: p(4.5, 18.0), radius: 1.5),
                ]
            )
        case .fit:
            InkIconDrawing(strokes: [
                Stroke(points: [p(3.6, 9.4), p(3.8, 3.8), p(9.6, 3.6)]),
                Stroke(points: [p(14.6, 3.7), p(20.3, 3.8), p(20.4, 9.2)]),
                Stroke(points: [p(20.2, 14.8), p(20.3, 20.4), p(14.4, 20.2)]),
                Stroke(points: [p(9.4, 20.3), p(3.7, 20.2), p(3.8, 14.6)]),
            ])
        case .links:
            InkIconDrawing(
                strokes: [
                    Stroke(points: [p(9.3, 6.6), p(15.4, 5.8)]),
                    Stroke(points: [p(7.8, 9.8), p(11.2, 14.9)]),
                    Stroke(points: [p(17.7, 8.5), p(14.9, 14.7)]),
                ],
                loops: [
                    CGRect(x: 2.9, y: 3.6, width: 6.3, height: 6.1),
                    CGRect(x: 15.6, y: 2.7, width: 5.7, height: 5.8),
                    CGRect(x: 9.7, y: 14.6, width: 6.9, height: 6.7),
                ]
            )
        case .external:
            InkIconDrawing(strokes: [
                Stroke(points: [p(11.2, 4.6), p(5.1, 4.8), p(4.9, 19.3), p(19.2, 19.1), p(19.3, 13.1)]),
                Stroke(points: [p(10.6, 13.6), p(19.9, 4.2)]),
                Stroke(points: [p(13.8, 3.9), p(20.2, 3.8), p(20.1, 10.2)]),
            ])
        case .undo:
            InkIconDrawing(strokes: [
                Stroke(points: [p(5.4, 9.6), p(13.5, 8.6), p(19.4, 12.6), p(17.6, 18.3), p(11.6, 19.2)], smooth: true),
                Stroke(points: [p(9.8, 4.5), p(5.4, 9.6)]),
                Stroke(points: [p(5.4, 9.6), p(10.6, 13.5)]),
            ])
        }
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}
