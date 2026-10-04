#if DEBUG && os(macOS)
import AppKit

/// Design reviews on the Mac: launch with `-windowSnapshot <name>` (and optionally
/// `-windowSnapshotDelay <seconds>`, and `-windowSize <width>x<height>` in points) and the app writes
/// a picture of its own window to `~/Library/Containers/com.chemical-pink.inkept/Data/tmp/<name>.png`.
@MainActor
enum WindowSnapshot {
    private typealias CreateImage = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?

    static func scheduleIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-windowSnapshot"), arguments.indices.contains(index + 1) else { return }
        let name = arguments[index + 1]
        var delay = 3.0
        if let delayIndex = arguments.firstIndex(of: "-windowSnapshotDelay"),
           arguments.indices.contains(delayIndex + 1), let value = Double(arguments[delayIndex + 1]) {
            delay = value
        }
        if let sizeIndex = arguments.firstIndex(of: "-windowSize"), arguments.indices.contains(sizeIndex + 1) {
            let parts = arguments[sizeIndex + 1].split(separator: "x").compactMap { Double($0) }
            if parts.count == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { resize(to: CGSize(width: parts[0], height: parts[1])) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            capture(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png"), attempts: 5)
        }
    }

    /// Gives the main window a content area of exactly `size`, in the middle of the screen.
    private static func resize(to size: CGSize) {
        guard let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else { return }
        window.setContentSize(size)
        window.center()
    }

    private static func capture(to url: URL, attempts: Int) {
        if capture(to: url) || attempts <= 1 { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { capture(to: url, attempts: attempts - 1) }
    }

    @discardableResult
    private static func capture(to url: URL) -> Bool {
        let candidates = NSApp.windows.filter { $0.isVisible && $0.windowNumber > 0 && $0.canBecomeMain }
        guard let window = candidates.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }),
              let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWindowListCreateImage")
        else {
            let report = NSApp.windows.map { "\($0.windowNumber) \($0.isVisible) \($0.frame) \(type(of: $0))" }.joined(separator: "\n")
            try? report.write(to: url.deletingPathExtension().appendingPathExtension("txt"), atomically: true, encoding: .utf8)
            return false
        }
        let create = unsafeBitCast(symbol, to: CreateImage.self)
        // Just this window, at full resolution, without its shadow: framing ignored, best resolution.
        // Without the screen recording permission there's no picture, so the window draws itself instead.
        guard let bitmap = create(.null, 1 << 3, UInt32(window.windowNumber), 1 << 0 | 1 << 3)
            .map({ NSBitmapImageRep(cgImage: $0.takeRetainedValue()) }) ?? drawing(of: window)
        else { return false }
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
        return true
    }

    /// The window's whole frame, title bar included, drawn by its own views at the screen's scale.
    private static func drawing(of window: NSWindow) -> NSBitmapImageRep? {
        guard let view = window.contentView?.superview ?? window.contentView,
              let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap
    }
}
#endif
