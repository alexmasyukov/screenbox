import AppKit
import SwiftUI

/// Floating chat panel. Key flags:
/// - `.nonactivatingPanel` so clicks here don't steal activation from the app the user is actually working in
/// - `canBecomeKey = true` (+ `becomesKeyOnlyIfNeeded = true`) so the TextField receives keystrokes without
///   pulling the whole app to the foreground every time it's clicked
/// - `.fullScreenAuxiliary` so the panel shows up in fullscreen spaces too
final class ChatPanel: NSPanel, NSWindowDelegate {
    private weak var controller: ChatController?

    init(controller: ChatController) {
        self.controller = controller
        let frame = controller.restoreFrame()
        super.init(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = "Chat"
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.worksWhenModal = true
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.delegate = self

        let hosting = NSHostingView(rootView: ChatView(controller: controller))
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func windowDidMove(_ notification: Notification) {
        controller?.persist()
    }

    func windowDidResize(_ notification: Notification) {
        controller?.persist()
    }
}
