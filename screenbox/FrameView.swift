import SwiftUI
import AppKit

struct FrameView: View {
    @ObservedObject var controller: FrameController

    private let thickness: CGFloat = FrameController.borderThickness
    private let handle: CGFloat = 14
    private let borderColor = Color.red.opacity(0.85)
    private let handleColor = Color.red.opacity(0.95)

    // Drag anchor: mouse position in global screen coords at mouseDown, and the window frame at that moment.
    // NSEvent.mouseLocation is stable regardless of window movement, unlike SwiftUI .global coords on macOS.
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

                cornerHandle(.topLeft)
                    .position(x: handle / 2, y: handle / 2)
                cornerHandle(.topRight)
                    .position(x: geo.size.width - handle / 2, y: handle / 2)
                cornerHandle(.bottomLeft)
                    .position(x: handle / 2, y: geo.size.height - handle / 2)
                cornerHandle(.bottomRight)
                    .position(x: geo.size.width - handle / 2, y: geo.size.height - handle / 2)

                shutterButton
                    .position(x: geo.size.width - 18, y: 18)

                if controller.isFlashing {
                    Rectangle()
                        .stroke(Color.white, lineWidth: thickness)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                }
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

    private func cornerHandle(_ corner: Corner) -> some View {
        Rectangle()
            .fill(handleColor)
            .frame(width: handle, height: handle)
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
