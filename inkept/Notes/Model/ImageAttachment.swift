import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Readies a picture for a notes folder: PNGs and GIFs stay as they are; photos become JPEGs no bigger
/// than they need to be, so any Markdown app can show them and iCloud doesn't carry a 12-megapixel HEIC.
enum ImageAttachment {
    static let maxPixelSize: CGFloat = 2_560

    static func prepare(_ data: Data) -> (data: Data, fileExtension: String)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String?
        else { return nil }
        if type == UTType.png.identifier { return (data, "png") }
        if type == UTType.gif.identifier { return (data, "gif") }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return (output as Data, "jpg")
    }
}
