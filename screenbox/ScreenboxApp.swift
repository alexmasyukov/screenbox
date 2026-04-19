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
    private var settings: AppSettings?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Permissions.requestScreenCaptureIfNeeded()

        let settings = AppSettings()
        let controller = FrameController(settings: settings)
        let panel = FramePanel(controller: controller, settings: settings)
        controller.panel = panel
        panel.orderFront(nil)

        self.settings = settings
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

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Screenbox", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    @objc private func openSettings() {
        if settingsWindow == nil, let settings {
            let hosting = NSHostingController(rootView: SettingsView(settings: settings))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Screenbox Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
