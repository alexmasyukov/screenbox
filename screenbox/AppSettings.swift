import SwiftUI
import AppKit

@MainActor
final class AppSettings: ObservableObject {
    @Published var borderColor: Color {
        didSet { saveColor() }
    }
    @Published var borderThickness: CGFloat {
        didSet { UserDefaults.standard.set(Double(borderThickness), forKey: Keys.thickness) }
    }

    private enum Keys {
        static let r = "screenbox.color.r"
        static let g = "screenbox.color.g"
        static let b = "screenbox.color.b"
        static let a = "screenbox.color.a"
        static let thickness = "screenbox.thickness"
    }

    static let defaultColor = Color(red: 0.35, green: 0.6, blue: 0.95, opacity: 0.85)
    static let defaultThickness: CGFloat = 3

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.r) != nil {
            self.borderColor = Color(
                red: d.double(forKey: Keys.r),
                green: d.double(forKey: Keys.g),
                blue: d.double(forKey: Keys.b),
                opacity: d.double(forKey: Keys.a)
            )
        } else {
            self.borderColor = Self.defaultColor
        }
        let t = d.double(forKey: Keys.thickness)
        self.borderThickness = t > 0 ? t : Self.defaultThickness
    }

    // Color components live in sRGB so round-tripping through the ColorPicker stays stable.
    private func saveColor() {
        let ns = NSColor(borderColor).usingColorSpace(.sRGB) ?? NSColor.systemBlue
        let d = UserDefaults.standard
        d.set(Double(ns.redComponent), forKey: Keys.r)
        d.set(Double(ns.greenComponent), forKey: Keys.g)
        d.set(Double(ns.blueComponent), forKey: Keys.b)
        d.set(Double(ns.alphaComponent), forKey: Keys.a)
    }
}
