import CoreImage
import Foundation
import RemnTypstC

/// The Typst compiler, built in: turns a ```typst block into a picture, offline, off the main thread.
actor TypstEngine {
    static let shared = TypstEngine()

    struct Failure: Error {
        let message: String
    }

    private var isConfigured = false

    /// Draws `source` on a page `width` points wide, set in `font` at `fontSize`, and returns the
    /// picture trimmed to its ink. `folder` is where relative paths in the block, like images, start.
    func render(
        _ source: String,
        width: CGFloat,
        fontSize: CGFloat,
        handwritten: Bool,
        folder: URL?,
        scale: CGFloat,
        dark: Bool
    ) throws -> CGImage {
        configureIfNeeded()
        let document = Self.prelude(width: width, fontSize: fontSize, handwritten: handwritten) + source
        let image = document.withCString { text in
            if let folder {
                folder.path.withCString { root in remn_typst_render(text, root, Float(scale)) }
            } else {
                remn_typst_render(text, nil, Float(scale))
            }
        }
        defer { remn_typst_free(image) }
        if let error = image.error {
            throw Failure(message: String(cString: error))
        }
        guard let pixels = image.pixels, image.width > 0, image.height > 0,
              let picture = Self.cgImage(pixels: pixels, length: image.length, width: Int(image.width), height: Int(image.height))
        else { throw Failure(message: String(localized: "typst.error.empty")) }
        return dark ? Self.inverted(picture) ?? picture : picture
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        let packages = Bundle.main.url(forResource: "TypstPackages", withExtension: nil)?.path ?? ""
        let fonts = [Bundle.main.url(forResource: "Neucha", withExtension: "ttf")?.path].compactMap { $0 }
        let cStrings = fonts.map { strdup($0) }
        defer { cStrings.forEach { free($0) } }
        var pointers = cStrings.map { UnsafePointer<CChar>($0) }
        packages.withCString { packagesPath in
            pointers.withUnsafeMutableBufferPointer { buffer in
                remn_typst_configure(packagesPath, buffer.baseAddress, buffer.count)
            }
        }
    }

    /// The page every block is set on: as wide as the note, as tall as it needs, transparent,
    /// in the note's ink and hand.
    private static func prelude(width: CGFloat, fontSize: CGFloat, handwritten: Bool) -> String {
        let fonts = handwritten ? "(\"Neucha\", \"New Computer Modern\")" : "(\"Libertinus Serif\", \"New Computer Modern\")"
        return """
        #set page(width: \(Int(width.rounded()))pt, height: auto, margin: (x: 2pt, y: 4pt), fill: none)
        #set text(font: \(fonts), size: \(String(format: "%.1f", fontSize))pt, fill: rgb("#1d1b19"))
        #show math.equation: set text(font: "New Computer Modern Math")
        #show raw: set text(font: "DejaVu Sans Mono")

        """
    }

    private static func cgImage(pixels: UnsafeMutablePointer<UInt8>, length: Int, width: Int, height: Int) -> CGImage? {
        let data = Data(bytes: pixels, count: length) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    private static let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])

    /// For dark paper: light and dark swap while colours keep their hue, so red stays red.
    private static func inverted(_ image: CGImage) -> CGImage? {
        let input = CIImage(cgImage: image)
        guard let invert = CIFilter(name: "CIColorInvert"), let hue = CIFilter(name: "CIHueAdjust") else { return nil }
        invert.setValue(input, forKey: kCIInputImageKey)
        hue.setValue(invert.outputImage, forKey: kCIInputImageKey)
        hue.setValue(Float.pi, forKey: kCIInputAngleKey)
        guard let output = hue.outputImage else { return nil }
        return context.createCGImage(output, from: input.extent)
    }
}
