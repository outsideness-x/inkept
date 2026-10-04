// Lays App Store screenshots out the way inkept looks: a caption in the app's own hand on its flat
// paper, a red pencil swash under it, and the screen itself in a frame drawn in one pen stroke.
//
//   Scripts/aso-screenshots.sh
//
// Reads a plan — a JSON list of shots — and writes each one at the exact size the App Store asks for.

import AppKit
import CoreText
import SwiftUI

struct Shot: Decodable {
    /// The screen as the app drew it.
    let input: String
    let output: String
    /// The size App Store Connect asks for, in pixels.
    let width: CGFloat
    let height: CGFloat
    let headline: String
    let subline: String
    var dark = false
    /// The forget-me-not beside the caption, for the first shot of a set.
    var flower = false
    /// How round the screen's corners are, as a share of its width: a phone's are rounder than a Mac window's.
    var corner: CGFloat = 0.1
    var seed = 1

    enum CodingKeys: String, CodingKey {
        case input, output, width, height, headline, subline, dark, flower, corner, seed
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        input = try values.decode(String.self, forKey: .input)
        output = try values.decode(String.self, forKey: .output)
        width = try values.decode(CGFloat.self, forKey: .width)
        height = try values.decode(CGFloat.self, forKey: .height)
        headline = try values.decode(String.self, forKey: .headline)
        subline = try values.decode(String.self, forKey: .subline)
        dark = try values.decodeIfPresent(Bool.self, forKey: .dark) ?? false
        flower = try values.decodeIfPresent(Bool.self, forKey: .flower) ?? false
        corner = try values.decodeIfPresent(CGFloat.self, forKey: .corner) ?? 0.1
        seed = try values.decodeIfPresent(Int.self, forKey: .seed) ?? 1
    }
}

@main
struct ComposeScreenshots {
    @MainActor
    static func main() throws {
        let arguments = CommandLine.arguments.dropFirst()
        guard let planPath = arguments.first, let fontPath = arguments.dropFirst().first else {
            print("usage: compose-screenshots plan.json Neucha.ttf")
            exit(1)
        }
        CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: fontPath) as CFURL, .process, nil)
        let shots = try JSONDecoder().decode([Shot].self, from: Data(contentsOf: URL(fileURLWithPath: planPath)))
        for shot in shots {
            guard let screen = NSImage(contentsOfFile: shot.input) else {
                print("missing \(shot.input)")
                continue
            }
            let page = ShotPage(shot: shot, screen: screen)
            let renderer = ImageRenderer(content: page)
            renderer.scale = 1
            renderer.proposedSize = ProposedViewSize(width: shot.width, height: shot.height)
            guard let image = renderer.cgImage else { throw ComposeError.failed(shot.output) }
            try writeOpaque(image, to: URL(fileURLWithPath: shot.output))
            print("wrote \(shot.output) \(image.width)×\(image.height)")
        }
    }

    /// The App Store wants screenshots without transparency, so the picture is drawn onto an opaque bitmap.
    private static func writeOpaque(_ image: CGImage, to url: URL) throws {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw ComposeError.failed(url.path) }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let opaque = context.makeImage() else { throw ComposeError.failed(url.path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw ComposeError.failed(url.path)
        }
        CGImageDestinationAddImage(destination, opaque, nil)
        guard CGImageDestinationFinalize(destination) else { throw ComposeError.failed(url.path) }
    }

    enum ComposeError: Error {
        case failed(String)
    }
}

/// The ink, paper and red pencil of the app, light and dark.
private struct Palette {
    let paper: Color
    let ink: Color
    let graphite: Color
    let accent: Color

    static let light = Palette(paper: Color(hex: 0xF5F1E8), ink: Color(hex: 0x1D1B19), graphite: Color(hex: 0x5E5952), accent: Color(hex: 0xBE3B2C))
    static let dark = Palette(paper: Color(hex: 0x101012), ink: Color(hex: 0xEFEADF), graphite: Color(hex: 0xA39E95), accent: Color(hex: 0xF0674E))
}

private struct ShotPage: View {
    let shot: Shot
    let screen: NSImage

    private var palette: Palette { shot.dark ? .dark : .light }
    private var isLandscape: Bool { shot.width > shot.height }
    /// Everything is sized from the short side, so the same plan reads the same on every device.
    private var unit: CGFloat { isLandscape ? shot.height / 1800 : shot.width / 1320 }

    var body: some View {
        let screenFrame = frameForScreen()
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(palette.paper)
            caption
                .frame(width: shot.width, alignment: .center)
                .position(x: shot.width / 2, y: captionCentre)
            screenView(size: screenFrame.size)
                .position(x: screenFrame.midX, y: screenFrame.midY)
            if shot.flower {
                // The forget-me-not from the icon, stuck over the corner of the screen like a sticker.
                let side = (isLandscape ? 300 : 290) * unit
                ForgetMeNot(colors: shot.dark ? .darkFlower : .lightFlower, size: side, lineWeight: 1.15)
                    .frame(width: side, height: side)
                    .rotationEffect(.degrees(8))
                    .shadow(color: .black.opacity(0.12), radius: 10 * unit, y: 5 * unit)
                    .position(x: screenFrame.maxX - side * 0.18, y: screenFrame.minY + side * 0.06)
            }
        }
        .frame(width: shot.width, height: shot.height)
        .environment(\.colorScheme, shot.dark ? .dark : .light)
    }

    // MARK: - Caption

    private var headlineSize: CGFloat { 104 * unit }
    private var sublineSize: CGFloat { 50 * unit }

    private var captionTop: CGFloat { (isLandscape ? 96 : 150) * unit }
    private var captionHeight: CGFloat { (isLandscape ? 300 : 420) * unit }
    private var captionCentre: CGFloat { captionTop + captionHeight / 2 }

    private var caption: some View {
        VStack(spacing: 10 * unit) {
            HandwrittenText(verbatim: shot.headline, weight: 0.9)
                .font(.custom("Neucha", fixedSize: headlineSize))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(-headlineSize * 0.12)
                .minimumScaleFactor(0.55)
                .lineLimit(2)
                .frame(maxWidth: shot.width * (isLandscape ? 0.72 : 0.86))
                .fixedSize(horizontal: false, vertical: true)
            Swash(seed: shot.seed)
                .fill(palette.accent)
                .frame(width: (isLandscape ? 260 : 230) * unit, height: 22 * unit)
            HandwrittenText(verbatim: shot.subline, weight: 0.2)
                .font(.custom("Neucha", fixedSize: sublineSize))
                .foregroundStyle(palette.graphite)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .frame(maxWidth: shot.width * 0.84)
        }
        .frame(height: captionHeight)
    }

    // MARK: - The screen

    private func frameForScreen() -> CGRect {
        let top = captionTop + captionHeight + (isLandscape ? 34 : 50) * unit
        let bottom = (isLandscape ? 90 : 120) * unit
        let room = CGSize(width: shot.width * (isLandscape ? 0.82 : 0.84), height: shot.height - top - bottom)
        let aspect = screen.size.width / max(screen.size.height, 1)
        var size = CGSize(width: room.width, height: room.width / aspect)
        if size.height > room.height {
            size = CGSize(width: room.height * aspect, height: room.height)
        }
        return CGRect(x: (shot.width - size.width) / 2, y: top, width: size.width, height: size.height)
    }

    private func screenView(size: CGSize) -> some View {
        let radius = size.width * shot.corner
        return ZStack {
            Image(nsImage: screen)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .shadow(color: .black.opacity(shot.dark ? 0.55 : 0.16), radius: 46 * unit, y: 22 * unit)
            InkRoundedRect(seed: shot.seed &* 31 &+ 7, cornerRadius: radius, pen: InkPen(width: 5.2 * unit, touchDown: 0.7, liftOff: 0.5))
                .fill(palette.ink.opacity(shot.dark ? 0.7 : 0.88))
                .frame(width: size.width + 6 * unit, height: size.height + 6 * unit)
        }
        .frame(width: size.width, height: size.height)
    }
}

/// A quick red pencil swash, like the one under every title in the app.
private struct Swash: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        let pen = InkPen(width: rect.height * 0.42, touchDown: 0.6, liftOff: 0.3, attack: rect.width * 0.08, release: rect.width * 0.12)
        return InkBrush.stroke(InkGeometry.underline(in: rect.insetBy(dx: 0, dy: rect.height * 0.2), seed: seed), pen: pen, seed: seed)
    }
}

private extension ForgetMeNot.Colors {
    static let lightFlower = ForgetMeNot.Colors(
        ink: Color(hex: 0x1D1B19), petal: Color(hex: 0xB2CDE0), petalPencil: Color(hex: 0x3563A6),
        eye: Color(hex: 0xEBBB3F), throat: Color(hex: 0x8A5C3B), halo: Color(hex: 0xFBF8F1),
        bud: Color(hex: 0xE59AA2), openingBud: Color(hex: 0x6FA9D8), leaf: Color(hex: 0xA9C3A1), leafPencil: Color(hex: 0x4C8A4B)
    )
    static let darkFlower = ForgetMeNot.Colors(
        ink: Color(hex: 0xEFEADF), petal: Color(hex: 0x566F87), petalPencil: Color(hex: 0x8FBEE6),
        eye: Color(hex: 0xF0C85A), throat: Color(hex: 0xB1835F), halo: Color(hex: 0xE7E1D4),
        bud: Color(hex: 0xEBADB4), openingBud: Color(hex: 0x8FBEE6), leaf: Color(hex: 0x354F35), leafPencil: Color(hex: 0x6DAE69)
    )
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
