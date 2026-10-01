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

    private var colors: ForgetMeNot.Colors {
        switch variant {
        case .light:
            ForgetMeNot.Colors(
                ink: Color(red: 0.114, green: 0.106, blue: 0.098),
                petal: Color(red: 0.53, green: 0.70, blue: 0.92),
                vein: Color(red: 0.29, green: 0.45, blue: 0.76).opacity(0.85),
                eye: Color(red: 0.96, green: 0.78, blue: 0.26),
                throat: Color(red: 0.36, green: 0.28, blue: 0.16),
                halo: Color(red: 0.99, green: 0.98, blue: 0.95),
                bud: Color(red: 0.93, green: 0.52, blue: 0.50),
                leaf: Color(red: 0.67, green: 0.74, blue: 0.56)
            )
        case .dark:
            ForgetMeNot.Colors(
                ink: Color(red: 0.937, green: 0.918, blue: 0.875),
                petal: Color(red: 0.50, green: 0.67, blue: 0.91),
                vein: Color(red: 0.27, green: 0.42, blue: 0.72).opacity(0.85),
                eye: Color(red: 0.96, green: 0.78, blue: 0.26),
                throat: Color(red: 0.36, green: 0.28, blue: 0.16),
                halo: Color(red: 0.95, green: 0.93, blue: 0.88),
                bud: Color(red: 0.94, green: 0.48, blue: 0.48),
                leaf: Color(red: 0.43, green: 0.50, blue: 0.35)
            )
        case .tinted:
            ForgetMeNot.Colors(
                ink: .white,
                petal: Color(white: 0.55),
                vein: Color(white: 0.3),
                eye: Color(white: 0.85),
                throat: Color(white: 0.2),
                halo: Color(white: 0.95),
                bud: Color(white: 0.45),
                leaf: Color(white: 0.3)
            )
        }
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
