import SwiftUI
#if os(iOS)
import Photos
#else
import AppKit
import UniformTypeIdentifiers
#endif

enum CardImageExportError: LocalizedError {
    case renderingFailed
    case photoAccessDenied

    var errorDescription: String? {
        switch self {
        case .renderingFailed: String(localized: "export.renderFailed")
        case .photoAccessDenied: String(localized: "export.photosDenied")
        }
    }
}

@MainActor
enum CardImageExporter {
    static func render(_ card: Flashcard) throws -> CGImage {
        let renderer = ImageRenderer(content: CardExportView(card: card))
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: 540, height: nil)
        guard let image = renderer.cgImage else {
            throw CardImageExportError.renderingFailed
        }
        return image
    }

    /// Saves the card as a picture: to Photos on iPhone and iPad, to a file of your choosing on the Mac.
    /// Returns the message to show, or `nil` when the save was called off.
    static func save(_ card: Flashcard) async throws -> String? {
        let image = try render(card)
        #if os(iOS)
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw CardImageExportError.photoAccessDenied
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: UIImage(cgImage: image))
            } completionHandler: { success, error in
                if let error { continuation.resume(throwing: error) }
                else if success { continuation.resume() }
                else { continuation.resume(throwing: CardImageExportError.renderingFailed) }
            }
        }
        return String(localized: "export.saved")
        #else
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = filename(for: card)
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: image)
        bitmap.size = NSSize(width: image.width / 2, height: image.height / 2)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw CardImageExportError.renderingFailed
        }
        try png.write(to: url, options: .atomic)
        return String(localized: "export.savedFile")
        #endif
    }

    private static func filename(for card: Flashcard) -> String {
        let title = RemnFormatters.usefulLine(card.frontMarkdown)
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined()
            .prefix(60)
        return "\(title).png"
    }
}
