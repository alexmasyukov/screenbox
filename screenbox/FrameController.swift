import AppKit
import SwiftUI
import Combine

enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

@MainActor
final class FrameController: ObservableObject {
    static let borderThickness: CGFloat = 3
    static let minSize = CGSize(width: 200, height: 150)
    static let defaultsKey = "screenbox.frame"

    weak var panel: FramePanel?
    @Published var savedIndicator: Bool = false

    func restoreFrame() -> NSRect {
        if let arr = UserDefaults.standard.array(forKey: Self.defaultsKey) as? [Double],
           arr.count == 4 {
            let rect = NSRect(x: arr[0], y: arr[1], width: arr[2], height: arr[3])
            let screen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) ?? NSScreen.main
            return clamp(rect, to: screen?.frame ?? rect)
        }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = CGSize(width: 600, height: 400)
        return NSRect(
            x: screen.midX - size.width / 2,
            y: screen.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func persist() {
        guard let frame = panel?.frame else { return }
        UserDefaults.standard.set(
            [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height],
            forKey: Self.defaultsKey
        )
    }

    func setOrigin(from anchor: NSRect, delta: CGSize) {
        guard let panel else { return }
        var f = anchor
        f.origin.x += delta.width
        f.origin.y += delta.height
        if let screen = targetScreen(for: f) {
            f = clamp(f, to: screen.frame)
        }
        panel.setFrame(f, display: true)
    }

    /// Resize from a corner. AppKit Y grows upward — "top" corresponds to max-Y.
    /// NSEvent.mouseLocation delta is in AppKit space, so +dy means mouse moved up.
    func setFrame(from anchor: NSRect, corner: Corner, delta: CGSize) {
        guard let panel else { return }
        let min = Self.minSize
        var f = anchor
        let dx = delta.width
        let dy = delta.height

        switch corner {
        case .topLeft:
            let newX = f.origin.x + dx
            let newW = f.size.width - dx
            let newH = f.size.height + dy
            if newW >= min.width { f.origin.x = newX; f.size.width = newW }
            else { f.origin.x = anchor.origin.x + (anchor.size.width - min.width); f.size.width = min.width }
            f.size.height = max(min.height, newH)
        case .topRight:
            let newW = f.size.width + dx
            let newH = f.size.height + dy
            f.size.width = max(min.width, newW)
            f.size.height = max(min.height, newH)
        case .bottomLeft:
            let newX = f.origin.x + dx
            let newW = f.size.width - dx
            let newY = f.origin.y + dy
            let newH = f.size.height - dy
            if newW >= min.width { f.origin.x = newX; f.size.width = newW }
            else { f.origin.x = anchor.origin.x + (anchor.size.width - min.width); f.size.width = min.width }
            if newH >= min.height { f.origin.y = newY; f.size.height = newH }
            else { f.origin.y = anchor.origin.y + (anchor.size.height - min.height); f.size.height = min.height }
        case .bottomRight:
            let newW = f.size.width + dx
            let newY = f.origin.y + dy
            let newH = f.size.height - dy
            f.size.width = max(min.width, newW)
            if newH >= min.height { f.origin.y = newY; f.size.height = newH }
            else { f.origin.y = anchor.origin.y + (anchor.size.height - min.height); f.size.height = min.height }
        }

        if let screen = targetScreen(for: f) {
            f = clamp(f, to: screen.frame)
        }
        panel.setFrame(f, display: true)
    }

    func capture() async {
        guard let panel else { return }
        let outer = panel.frame
        let t = Self.borderThickness
        let inner = NSRect(
            x: outer.origin.x + t,
            y: outer.origin.y + t,
            width: outer.size.width - 2 * t,
            height: outer.size.height - 2 * t
        )
        do {
            let url = try await Screenshotter.capture(globalAppKitRect: inner, hiding: panel)
            NSLog("[screenbox] saved: %@", url.path)
            savedIndicator = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            savedIndicator = false
        } catch {
            NSLog("[screenbox] capture failed: %@", String(describing: error))
            NSSound.beep()
        }
    }

    private func targetScreen(for rect: NSRect) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.intersects(rect) }) ?? NSScreen.main
    }

    private func clamp(_ r: NSRect, to bounds: NSRect) -> NSRect {
        var r = r
        r.size.width = max(Self.minSize.width, min(r.size.width, bounds.size.width))
        r.size.height = max(Self.minSize.height, min(r.size.height, bounds.size.height))
        r.origin.x = max(bounds.minX, min(r.origin.x, bounds.maxX - r.size.width))
        r.origin.y = max(bounds.minY, min(r.origin.y, bounds.maxY - r.size.height))
        return r
    }
}
