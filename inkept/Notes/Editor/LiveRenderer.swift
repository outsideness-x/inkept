@_spi(Textual) import SwiftUIMath
import ImageIO
import SwiftUI

/// Makes and remembers the pictures that stand in for formulas, images and Typst in a note.
@MainActor
final class LiveRenderer {
    var theme: LiveTheme
    var isDark = false
    var displayScale: CGFloat = 2
    /// How wide the page is; pictures never get wider than this.
    var pageWidth: CGFloat = 600
    /// Finds the file behind an image link in the note.
    var resolveImage: (String) -> URL? = { _ in nil }
    /// Called when a picture that was still being made is ready, so the editor can lay out again.
    var onPictureReady: () -> Void = {}
    /// The note's folder, where paths inside Typst blocks start.
    var noteFolder: URL?

    private var cache: [String: LivePicture] = [:]
    private var loading: Set<String> = []
    private var lastTypst: [Int: LivePicture] = [:]
    private var typstJobs: [Int: (key: String, task: Task<Void, Never>)] = [:]

    init(theme: LiveTheme) {
        self.theme = theme
    }

    func picture(for request: LivePictureRequest) -> LivePicture {
        let key = cacheKey(for: request)
        if let cached = cache[key] { return cached }
        let picture: LivePicture
        switch request.kind {
        case .inlineMath, .blockMath:
            picture = renderMath(request.source, inline: request.kind == .inlineMath, key: key)
            cache[key] = picture
        case .image:
            picture = placeholder(for: request, key: key)
            loadImage(request.source, key: key)
        case .typst:
            // Keep showing the block's last picture while the new one is drawn.
            picture = lastTypst[request.slot] ?? placeholder(for: request, key: key)
            renderTypst(request.source, key: key, slot: request.slot)
        }
        return picture
    }

    /// Forgets pictures drawn for another appearance or page width.
    func invalidate() {
        cache.removeAll()
        lastTypst.removeAll()
    }

    private func cacheKey(for request: LivePictureRequest) -> String {
        let widthBucket = Int(pageWidth / 40)
        return "\(request.kind)|\(isDark)|\(theme.font.rawValue)|\(theme.size)|\(widthBucket)|\(request.source)"
    }

    private func placeholder(for request: LivePictureRequest, key: String) -> LivePicture {
        LivePicture(kind: request.kind, key: key, size: CGSize(width: min(pageWidth, 320), height: 120), image: nil)
    }

    // MARK: - Formulas

    private var mathSize: CGFloat {
        // Latin Modern runs small next to handwriting; match the x-height of the note's face.
        theme.font == .neucha ? theme.size * 0.9 : theme.size * 1.04
    }

    private func renderMath(_ latex: String, inline: Bool, key: String) -> LivePicture {
        let written = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = LatexCompatibility.rewritten(written)
        let size = inline ? mathSize : mathSize * 1.12
        let font = Math.Font(name: .latinModern, size: size)
        let style: Math.TypesettingStyle = inline ? .text : .display
        let bounds = Math.typographicBounds(
            for: source,
            fitting: ProposedViewSize(width: inline ? nil : pageWidth, height: nil),
            font: font,
            style: style
        )
        guard bounds.width > 0, !source.isEmpty else {
            return renderError(written.isEmpty ? "$$" : written, inline: inline, key: key)
        }
        let ink = Color(LiveTheme.ink)
        let view = Math(source)
            .mathFont(font)
            .mathTypesettingStyle(style)
            .mathRenderingMode(.multicolor(base: ink))
            .foregroundStyle(ink)
            .frame(width: ceil(bounds.width), height: ceil(bounds.ascent + bounds.descent))
            .environment(\.colorScheme, isDark ? .dark : .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = displayScale
        guard let image = renderer.cgImage else {
            return renderError(written, inline: inline, key: key)
        }
        return LivePicture(
            kind: inline ? .inlineMath : .blockMath,
            key: key,
            size: CGSize(width: ceil(bounds.width), height: ceil(bounds.ascent + bounds.descent)),
            descent: bounds.descent,
            image: image
        )
    }

    /// Source that doesn't typeset is shown as it was written, in red pencil.
    private func renderError(_ source: String, inline: Bool, key: String) -> LivePicture {
        let view = Text(verbatim: source)
            .font(.system(size: theme.codeSize, design: .monospaced))
            .foregroundStyle(Color(LiveTheme.accent))
            .fixedSize(horizontal: inline, vertical: true)
            .environment(\.colorScheme, isDark ? .dark : .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = displayScale
        if !inline {
            renderer.proposedSize = ProposedViewSize(width: max(pageWidth - 8, 120), height: nil)
        }
        let image = renderer.cgImage
        let size = image.map { CGSize(width: CGFloat($0.width) / displayScale, height: CGFloat($0.height) / displayScale) } ?? .zero
        return LivePicture(kind: inline ? .inlineMath : .blockMath, key: key, size: size, descent: size.height * 0.25, image: image)
    }

    // MARK: - Images

    private func loadImage(_ link: String, key: String) {
        guard !loading.contains(key), let url = resolveImage(link) else {
            cache[key] = LivePicture(kind: .image, key: key, size: CGSize(width: 44, height: 44), image: nil)
            return
        }
        loading.insert(key)
        let maxPixels = pageWidth * displayScale
        Task {
            let image = await Task.detached(priority: .userInitiated) {
                Self.downsampledImage(at: url, maxPixelSize: maxPixels)
            }.value
            loading.remove(key)
            if let image {
                let scale = displayScale
                var size = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
                let maxHeight: CGFloat = 520
                if size.height > maxHeight {
                    size = CGSize(width: size.width * maxHeight / size.height, height: maxHeight)
                }
                cache[key] = LivePicture(kind: .image, key: key, size: size, image: image)
            } else {
                cache[key] = LivePicture(kind: .image, key: key, size: CGSize(width: 44, height: 44), image: nil)
            }
            onPictureReady()
        }
    }

    nonisolated static func downsampledImage(at url: URL, maxPixelSize: CGFloat) -> CGImage? {
        var data: Data?
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &error) { url in
            data = try? Data(contentsOf: url)
        }
        guard let data, let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 64),
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    // MARK: - Typst

    private func renderTypst(_ source: String, key: String, slot: Int) {
        if typstJobs[slot]?.key == key { return }
        typstJobs[slot]?.task.cancel()
        let isEditing = lastTypst[slot] != nil
        let width = max(pageWidth - 8, 120)
        let fontSize = theme.font == .neucha ? theme.size * 0.82 : theme.size * 0.9
        let handwritten = theme.font == .neucha
        let folder = noteFolder
        let scale = displayScale
        let dark = isDark
        let task = Task { [weak self] in
            // While typing, wait for a pause instead of compiling every keystroke.
            if isEditing { try? await Task.sleep(for: .milliseconds(350)) }
            guard !Task.isCancelled else { return }
            let outcome: Result<CGImage, Error>
            do {
                outcome = .success(try await TypstEngine.shared.render(
                    source, width: width, fontSize: fontSize, handwritten: handwritten,
                    folder: folder, scale: scale, dark: dark
                ))
            } catch {
                outcome = .failure(error)
            }
            guard !Task.isCancelled, let self else { return }
            self.finishTypst(outcome, key: key, slot: slot)
        }
        typstJobs[slot] = (key, task)
    }

    private func finishTypst(_ outcome: Result<CGImage, Error>, key: String, slot: Int) {
        let picture: LivePicture
        switch outcome {
        case .success(let image):
            picture = LivePicture(
                kind: .typst,
                key: key,
                size: CGSize(width: CGFloat(image.width) / displayScale, height: CGFloat(image.height) / displayScale),
                image: image
            )
            lastTypst[slot] = picture
        case .failure(let error):
            let message = (error as? TypstEngine.Failure)?.message ?? error.localizedDescription
            let failure = renderError("typst: " + String(message.prefix(240)), inline: false, key: key)
            picture = LivePicture(kind: .typst, key: key, size: failure.size, image: failure.image)
        }
        cache[key] = picture
        typstJobs[slot] = nil
        onPictureReady()
    }
}
