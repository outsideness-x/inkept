// Renders remn's app icon with the same ink engine and hand the app draws with.
//
//   Design/Icon/render.sh [output directory]
//
// The art is drawn on a 128-point canvas, the scale of the interface, and rendered at 8×
// so the hand keeps the proportions it has in the app.

import AppKit
import CoreText
import SwiftUI

@main
struct RenderIcon {
    @MainActor
    static func main() throws {
        let arguments = CommandLine.arguments.dropFirst()
        let output = URL(fileURLWithPath: arguments.first ?? ".")
        let font = URL(fileURLWithPath: arguments.dropFirst().first ?? "inkept/Resources/Fonts/Neucha.ttf")
        guard CTFontManagerRegisterFontsForURL(font as CFURL, .process, nil) else { throw RenderError.failed(font.path) }
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

            // The card underneath, shaded with red pencil hatching.
            ZStack {
                InkHatch(seed: 71, spacing: 3.1, angle: .degrees(-50), pen: InkPen(width: 1.15, touchDown: 0.7, liftOff: 0.5, pressureVariation: 0.1))
                    .fill(accent.opacity(variant == .tinted ? 0.55 : 0.85))
                    .clipShape(InkPatch(seed: 72, cornerRadius: 9))
                InkRoundedRect(seed: 73, cornerRadius: 9, pen: InkPen(width: 2.3))
                    .fill(accent)
            }
            .frame(width: 86, height: 58)
            .rotationEffect(.degrees(9))
            .offset(x: 10, y: 17)

            // The card on top: paper laid a touch off-register, an ink outline, the red index rule
            // and the app's name, lettered in its hand.
            ZStack {
                InkPatch(seed: 81, cornerRadius: 9)
                    .fill(cardPaper)
                    .offset(x: 0.9, y: 1.2)
                InkRoundedRect(seed: 82, cornerRadius: 9, pen: InkPen(width: 3.1, touchDown: 0.6, liftOff: 0.35))
                    .fill(ink)
                InkLine(seed: 83, pen: InkPen(width: 2, touchDown: 0.7, liftOff: 0.5))
                    .fill(accent)
                    .frame(width: 70, height: 6)
                    .offset(y: -15)
                HandwrittenText(verbatim: "remn", weight: 0.8)
                    .font(.custom("Neucha", fixedSize: 34))
                    .foregroundStyle(ink)
                    .offset(y: 5)
            }
            .frame(width: 88, height: 60)
            .rotationEffect(.degrees(-7))
            .offset(x: -7, y: -8)
        }
        .frame(width: 128, height: 128)
        .environment(\.colorScheme, variant == .light ? .light : .dark)
    }

    private var paper: Color {
        switch variant {
        case .light: Color(red: 0.961, green: 0.945, blue: 0.910)
        case .dark: Color(red: 0.082, green: 0.078, blue: 0.071)
        case .tinted: .black
        }
    }

    private var cardPaper: Color {
        switch variant {
        case .light: Color(red: 0.984, green: 0.973, blue: 0.945)
        case .dark: Color(red: 0.122, green: 0.114, blue: 0.102)
        case .tinted: Color(white: 0.1)
        }
    }

    private var ink: Color {
        switch variant {
        case .light: Color(red: 0.114, green: 0.106, blue: 0.098)
        case .dark: Color(red: 0.937, green: 0.918, blue: 0.875)
        case .tinted: .white
        }
    }

    private var accent: Color {
        switch variant {
        case .light: Color(red: 0.745, green: 0.231, blue: 0.173)
        case .dark: Color(red: 0.941, green: 0.404, blue: 0.306)
        case .tinted: Color(white: 0.62)
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
