import AppKit
import ScreenCaptureKit
import CoreGraphics
import UniformTypeIdentifiers

enum ScreenshotError: Error {
    case noDisplay
    case captureFailed
    case encodingFailed
    case writeFailed(Error)
}

enum Screenshotter {
    /// Capture a region of the screen. `globalAppKitRect` is in AppKit coordinates (Y grows up, origin at bottom-left of primary screen).
    /// The panel is hidden for one composited frame before capture so it does not appear in the output.
    @MainActor
    static func capture(globalAppKitRect rect: NSRect, hiding panel: NSPanel) async throws -> URL {
        let wasVisible = panel.isVisible
        panel.orderOut(nil)
        defer {
            if wasVisible { panel.orderFront(nil) }
        }

        // Give the window server one composited frame so the frame is actually gone from the framebuffer.
        try? await Task.sleep(nanoseconds: 100_000_000)

        let cgImage: CGImage
        if #available(macOS 14.0, *) {
            do {
                cgImage = try await captureWithScreenCaptureKit(globalAppKitRect: rect)
            } catch {
                NSLog("[screenbox] SCScreenshotManager failed, falling back: %@", String(describing: error))
                cgImage = try captureWithCGWindowList(globalAppKitRect: rect)
            }
        } else {
            cgImage = try captureWithCGWindowList(globalAppKitRect: rect)
        }

        return try writePNG(cgImage: cgImage)
    }

    // MARK: - ScreenCaptureKit

    @available(macOS 14.0, *)
    private static func captureWithScreenCaptureKit(globalAppKitRect rect: NSRect) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        guard let (scDisplay, nsScreen) = pickDisplay(for: rect, displays: content.displays) else {
            throw ScreenshotError.noDisplay
        }

        // Convert AppKit global rect → display-local rect in SCDisplay coordinates (Y grows down, origin top-left of this display).
        let screenFrame = nsScreen.frame
        let localX = rect.origin.x - screenFrame.origin.x
        let localYAppKit = rect.origin.y - screenFrame.origin.y
        let localYTopDown = screenFrame.size.height - (localYAppKit + rect.size.height)
        let localRect = CGRect(x: localX, y: localYTopDown, width: rect.size.width, height: rect.size.height)

        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])

        let config = SCStreamConfiguration()
        let scale = nsScreen.backingScaleFactor
        config.sourceRect = localRect
        config.width = Int(rect.size.width * scale)
        config.height = Int(rect.size.height * scale)
        config.showsCursor = false
        config.capturesAudio = false
        config.scalesToFit = false

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    @available(macOS 14.0, *)
    private static func pickDisplay(for rect: NSRect, displays: [SCDisplay]) -> (SCDisplay, NSScreen)? {
        var best: (SCDisplay, NSScreen, CGFloat)? = nil
        for scDisplay in displays {
            guard let nsScreen = NSScreen.screens.first(where: { screen in
                (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == scDisplay.displayID
            }) else { continue }
            let intersection = nsScreen.frame.intersection(rect)
            let area = intersection.isNull ? 0 : intersection.size.width * intersection.size.height
            if area > 0 && (best == nil || area > best!.2) {
                best = (scDisplay, nsScreen, area)
            }
        }
        if let best { return (best.0, best.1) }
        // Fall back to main display even if no intersection — allows capture of whatever is there.
        if let mainID = NSScreen.main?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
           let scDisplay = displays.first(where: { $0.displayID == mainID.uint32Value }),
           let nsScreen = NSScreen.main {
            return (scDisplay, nsScreen)
        }
        return nil
    }

    // MARK: - CGWindowList fallback

    private static func captureWithCGWindowList(globalAppKitRect rect: NSRect) throws -> CGImage {
        // CGWindowListCreateImage uses top-left origin with Y growing down, measured from the top of the primary screen.
        let primary = NSScreen.screens.first?.frame ?? .zero
        let cgRect = CGRect(
            x: rect.origin.x,
            y: primary.size.height - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
        if let image = CGWindowListCreateImage(cgRect, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming]) {
            return image
        }
        // Last resort: full screen then crop.
        if let full = CGWindowListCreateImage(.infinite, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution]) {
            let scaleX = CGFloat(full.width) / primary.size.width
            let scaleY = CGFloat(full.height) / primary.size.height
            let cropRect = CGRect(
                x: cgRect.origin.x * scaleX,
                y: cgRect.origin.y * scaleY,
                width: cgRect.size.width * scaleX,
                height: cgRect.size.height * scaleY
            )
            if let cropped = full.cropping(to: cropRect) {
                return cropped
            }
        }
        throw ScreenshotError.captureFailed
    }

    // MARK: - PNG output

    private static func writePNG(cgImage: CGImage) throws -> URL {
        let fm = FileManager.default
        let picturesDir: URL
        if let url = fm.urls(for: .picturesDirectory, in: .userDomainMask).first {
            picturesDir = url
        } else {
            picturesDir = fm.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
        }
        let targetDir = picturesDir.appendingPathComponent("ScreenshotFrame", isDirectory: true)
        if !fm.fileExists(atPath: targetDir.path) {
            try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        let filename = "shot-\(df.string(from: Date())).png"
        let url = targetDir.appendingPathComponent(filename)

        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.encodingFailed
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ScreenshotError.writeFailed(error)
        }
        return url
    }
}
