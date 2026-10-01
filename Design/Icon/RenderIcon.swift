// Renders inkept's app icon, a forget-me-not, with the same ink engine and pen the app draws with.
//
//   Design/Icon/render.sh [output directory]
//
// The art is drawn on a 128-point canvas, the scale of the interface, and rendered at 8×
// so the hand keeps the proportions it has in the app.

import AppKit
import SwiftUI

@main
struct RenderIcon {
    @MainActor
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
        for variant in IconArt.Variant.allCases {
            try write(IconArt(variant: variant), to: output.appendingPathComponent(variant.filename))
        }
        try write(MacIconArt(), to: output.appendingPathComponent("AppIcon-Mac-1024.png"))
    }

    @MainActor
    private static func write(_ art: some View, to url: URL) throws {
        let renderer = ImageRenderer(content: art)
        renderer.scale = 8
        guard let image = renderer.cgImage else { throw RenderError.failed(url.lastPathComponent) }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw RenderError.failed(url.path)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw RenderError.failed(url.path) }
        print("wrote \(url.path) \(image.width)×\(image.height)")
    }

    enum RenderError: Error {
        case failed(String)
    }
}

struct IconArt: View {
    enum Variant: String, CaseIterable {
        case light
        case dark
        case tinted

        var filename: String {
            switch self {
            case .light: "AppIcon.png"
            case .dark: "AppIcon-Dark.png"
            case .tinted: "AppIcon-Tinted.png"
            }
        }
    }

    let variant: Variant

    var body: some View {
        ZStack {
            Rectangle().fill(paper)
            ForgetMeNot(colors: colors)
        }
        .frame(width: 128, height: 128)
    }

    private var paper: Color {
        switch variant {
        case .light: Color(red: 0.961, green: 0.945, blue: 0.910)
        case .dark: Color(red: 0.063, green: 0.063, blue: 0.071)
        case .tinted: .black
        }
    }

    /// The pencils are the app's own (`InkPencil`); the washes are those pencils laid pale on the paper.
    private var colors: ForgetMeNot.Colors {
        switch variant {
        case .light:
            ForgetMeNot.Colors(
                ink: Color(hex: 0x1D1B19),
                petal: Color(hex: 0xB2CDE0),
                petalPencil: Color(hex: 0x3563A6),
                eye: Color(hex: 0xEBBB3F),
                throat: Color(hex: 0x8A5C3B),
                halo: Color(hex: 0xFBF8F1),
                bud: Color(hex: 0xE59AA2),
                openingBud: Color(hex: 0x6FA9D8),
                leaf: Color(hex: 0xA9C3A1),
                leafPencil: Color(hex: 0x4C8A4B)
            )
        case .dark:
            ForgetMeNot.Colors(
                ink: Color(hex: 0xEFEADF),
                petal: Color(hex: 0x566F87),
                petalPencil: Color(hex: 0x8FBEE6),
                eye: Color(hex: 0xF0C85A),
                throat: Color(hex: 0xB1835F),
                halo: Color(hex: 0xE7E1D4),
                bud: Color(hex: 0xEBADB4),
                openingBud: Color(hex: 0x8FBEE6),
                leaf: Color(hex: 0x354F35),
                leafPencil: Color(hex: 0x6DAE69)
            )
        case .tinted:
            ForgetMeNot.Colors(
                ink: .white,
                petal: Color(white: 0.32),
                petalPencil: Color(white: 0.78),
                eye: Color(white: 0.85),
                throat: Color(white: 0.3),
                halo: Color(white: 0.95),
                bud: Color(white: 0.55),
                openingBud: Color(white: 0.65),
                leaf: Color(white: 0.2),
                leafPencil: Color(white: 0.55)
            )
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// The Mac icon: the light drawing on the rounded square every Mac app sits in, 824 of 1024 pixels
/// on Apple's grid, so the shadow under it has room.
struct MacIconArt: View {
    var body: some View {
        IconArt(variant: .light)
            .scaleEffect(103 / 128)
            .frame(width: 103, height: 103)
            .clipShape(.rect(cornerRadius: 23.2, style: .continuous))
            .compositingGroup()
            .shadow(color: .black.opacity(0.3), radius: 1.25, y: 1.25)
            .frame(width: 128, height: 128)
    }
}
