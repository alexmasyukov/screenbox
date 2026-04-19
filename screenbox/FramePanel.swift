import AppKit
import SwiftUI

final class FramePanel: NSPanel {
    init(controller: FrameController) {
        let frame = controller.restoreFrame()
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.ignoresMouseEvents = false
        self.hidesOnDeactivate = false

        let hosting = FrameHostingView(rootView: FrameView(controller: controller))
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Host view that forwards clicks in the transparent center through to windows underneath.
/// Clicks on the 6px border, the 14x14 corner handles, and the shutter button are kept.
final class FrameHostingView<Content: View>: NSHostingView<Content> {
    static var borderThickness: CGFloat { 6 }
    static var cornerHandle: CGFloat { 14 }
    static var buttonZone: CGFloat { 32 }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let b = self.bounds
        let t = Self.borderThickness
        let c = Self.cornerHandle
        let bz = Self.buttonZone

        let onBorder =
            point.x <= t || point.x >= b.width - t ||
            point.y <= t || point.y >= b.height - t

        let inCorner =
            (point.x <= c && point.y <= c) ||
            (point.x <= c && point.y >= b.height - c) ||
            (point.x >= b.width - c && point.y <= c) ||
            (point.x >= b.width - c && point.y >= b.height - c)

        // Button sits in the top-right, overlapping the border — reserve a small zone inside.
        let inButtonZone =
            point.x >= b.width - bz && point.y >= b.height - bz

        if onBorder || inCorner || inButtonZone {
            return super.hitTest(point)
        }
        return nil
    }
}
