import SwiftUI
import AppKit

@main
struct ScreenboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FramePanel?
    private var controller: FrameController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Permissions.requestScreenCaptureIfNeeded()

        let controller = FrameController()
        let panel = FramePanel(controller: controller)
        controller.panel = panel
        panel.orderFront(nil)

        self.controller = controller
        self.panel = panel

        installStatusItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.persist()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenbox")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Screenbox", action: #selector(quit), keyEquivalent: "q"))
        menu.items.last?.target = self
        item.menu = menu
        self.statusItem = item
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
