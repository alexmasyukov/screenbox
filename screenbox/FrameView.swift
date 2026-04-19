import SwiftUI
import AppKit

struct FrameView: View {
    @ObservedObject var controller: FrameController

    private let thickness: CGFloat = FrameController.borderThickness
    private let cornerZone: CGFloat = 14
    private let borderColor = Color(red: 0.35, green: 0.6, blue: 0.95).opacity(0.85)

    @State private var anchorMouse: CGPoint? = nil
    @State private var anchorFrame: NSRect? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(borderColor)
                    .frame(width: geo.size.width, height: thickness)
                    .position(x: geo.size.width / 2, y: thickness / 2)
                    .gesture(moveGesture())

                Rectangle().fill(borderColor)
                    .frame(width: geo.size.width, height: thickness)
                    .position(x: geo.size.width / 2, y: geo.size.height - thickness / 2)
                    .gesture(moveGesture())

                Rectangle().fill(borderColor)
                    .frame(width: thickness, height: geo.size.height)
                    .position(x: thickness / 2, y: geo.size.height / 2)
                    .gesture(moveGesture())

                Rectangle().fill(borderColor)
                    .frame(width: thickness, height: geo.size.height)
                    .position(x: geo.size.width - thickness / 2, y: geo.size.height / 2)
                    .gesture(moveGesture())

                // Invisible corner zones — resize from the closest corner. Kept transparent per spec:
                // no visible handles, but resize behavior is preserved.
                invisibleCorner(.topLeft)
                    .position(x: cornerZone / 2, y: cornerZone / 2)
                invisibleCorner(.topRight)
                    .position(x: geo.size.width - cornerZone / 2, y: cornerZone / 2)
                invisibleCorner(.bottomLeft)
                    .position(x: cornerZone / 2, y: geo.size.height - cornerZone / 2)
                invisibleCorner(.bottomRight)
                    .position(x: geo.size.width - cornerZone / 2, y: geo.size.height - cornerZone / 2)

                shutterButton
                    .position(x: geo.size.width - 18, y: 18)

                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(controller.savedIndicator ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: controller.savedIndicator)
                    .position(x: geo.size.width - 40, y: 18)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var shutterButton: some View {
        Button {
            Task { await controller.capture() }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.black.opacity(0.55))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func invisibleCorner(_ corner: Corner) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: cornerZone, height: cornerZone)
            .gesture(resizeGesture(corner: corner))
    }

    private func moveGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                ensureAnchor()
                guard let anchorMouse, let anchorFrame else { return }
                let current = NSEvent.mouseLocation
                let delta = CGSize(width: current.x - anchorMouse.x, height: current.y - anchorMouse.y)
                controller.setOrigin(from: anchorFrame, delta: delta)
            }
            .onEnded { _ in
                clearAnchor()
                controller.persist()
            }
    }

    private func resizeGesture(corner: Corner) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                ensureAnchor()
                guard let anchorMouse, let anchorFrame else { return }
                let current = NSEvent.mouseLocation
                let delta = CGSize(width: current.x - anchorMouse.x, height: current.y - anchorMouse.y)
                controller.setFrame(from: anchorFrame, corner: corner, delta: delta)
            }
            .onEnded { _ in
                clearAnchor()
                controller.persist()
            }
    }

    private func ensureAnchor() {
        if anchorMouse == nil {
            anchorMouse = NSEvent.mouseLocation
            anchorFrame = controller.panel?.frame
        }
    }

    private func clearAnchor() {
        anchorMouse = nil
        anchorFrame = nil
    }
}
