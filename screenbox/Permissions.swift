import AppKit
import CoreGraphics

enum Permissions {
    static func requestScreenCaptureIfNeeded() {
        if CGPreflightScreenCaptureAccess() { return }

        // Triggers the system prompt; if already denied, this just returns false and the prompt will not show again.
        _ = CGRequestScreenCaptureAccess()

        if CGPreflightScreenCaptureAccess() { return }

        let alert = NSAlert()
        alert.messageText = "Screen Recording permission required"
        alert.informativeText = """
        Screenbox needs Screen Recording permission to capture the area inside the frame.

        1. Click "Open Settings" below
        2. Enable Screenbox under Screen Recording
        3. Quit and relaunch Screenbox
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
