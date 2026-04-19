import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Frame color")
                Spacer()
                ColorPicker("", selection: $settings.borderColor, supportsOpacity: true)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Frame thickness")
                    Spacer()
                    Text("\(Int(settings.borderThickness)) px")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.borderThickness, in: 1...20, step: 1)
            }

            HStack {
                Spacer()
                Button("Reset to defaults") {
                    settings.borderColor = AppSettings.defaultColor
                    settings.borderThickness = AppSettings.defaultThickness
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
