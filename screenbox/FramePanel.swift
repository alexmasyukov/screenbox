import AppKit
import SwiftUI

final class FramePanel: NSPanel {
    init(controller: FrameController, settings: AppSettings) {
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

        let hosting = FrameHostingView(
            rootView: FrameView(controller: controller, settings: settings),
            settings: settings
        )
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Host view that forwards clicks in the transparent center through to windows underneath.
/// The hit zone grows with the configured border thickness, with a floor of 8 px so a thin
/// border is still comfortably grabbable.
final class FrameHostingView<Content: View>: NSHostingView<Content> {
    let settings: AppSettings

    init(rootView: Content, settings: AppSettings) {
        self.settings = settings
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init(rootView: Content) {
        fatalError("use init(rootView:settings:)")
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let b = self.bounds
        let t = max(settings.borderThickness, 8)
        let c: CGFloat = max(14, t + 4)
        let bz: CGFloat = 32

        let onBorder =
            point.x <= t || point.x >= b.width - t ||
            point.y <= t || point.y >= b.height - t

        let inCorner =
            (point.x <= c && point.y <= c) ||
            (point.x <= c && point.y >= b.height - c) ||
            (point.x >= b.width - c && point.y <= c) ||
            (point.x >= b.width - c && point.y >= b.height - c)

        let inButtonZone =
            point.x >= b.width - bz && point.y >= b.height - bz

        if onBorder || inCorner || inButtonZone {
            return super.hitTest(point)
        }
        return nil
    }
}
