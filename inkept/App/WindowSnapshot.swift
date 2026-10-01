#if DEBUG && os(macOS)
import AppKit

/// Design reviews on the Mac: launch with `-windowSnapshot <name>` (and optionally
/// `-windowSnapshotDelay <seconds>`) and the app writes a picture of its own window to
/// `~/Library/Containers/com.chemical-pink.inkept/Data/tmp/<name>.png`.
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
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            capture(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png"), attempts: 5)
        }
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
        // Just this window, at full resolution, without its shadow.
        guard let image = create(.null, 1 << 3, UInt32(window.windowNumber), 1 << 3)?.takeRetainedValue() else { return false }
        let bitmap = NSBitmapImageRep(cgImage: image)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
        return true
    }
}
#endif
