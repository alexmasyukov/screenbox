import SwiftUI
import AppKit

struct FrameView: View {
    @ObservedObject var controller: FrameController
    @ObservedObject var settings: AppSettings

    @State private var anchorMouse: CGPoint? = nil
    @State private var anchorFrame: NSRect? = nil
    @State private var buttonDidDrag: Bool = false

    var body: some View {
        let thickness = settings.borderThickness
        let cornerZone = max(CGFloat(14), thickness + 4)
        let color = settings.borderColor

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(color)
                    .frame(width: geo.size.width, height: thickness)
                    .position(x: geo.size.width / 2, y: thickness / 2)
                    .gesture(moveGesture())

                Rectangle().fill(color)
                    .frame(width: geo.size.width, height: thickness)
                    .position(x: geo.size.width / 2, y: geo.size.height - thickness / 2)
                    .gesture(moveGesture())

                Rectangle().fill(color)
                    .frame(width: thickness, height: geo.size.height)
                    .position(x: thickness / 2, y: geo.size.height / 2)
                    .gesture(moveGesture())

                Rectangle().fill(color)
                    .frame(width: thickness, height: geo.size.height)
                    .position(x: geo.size.width - thickness / 2, y: geo.size.height / 2)
                    .gesture(moveGesture())

                invisibleCorner(.topLeft, size: cornerZone)
                    .position(x: cornerZone / 2, y: cornerZone / 2)
                invisibleCorner(.topRight, size: cornerZone)
                    .position(x: geo.size.width - cornerZone / 2, y: cornerZone / 2)
                invisibleCorner(.bottomLeft, size: cornerZone)
                    .position(x: cornerZone / 2, y: geo.size.height - cornerZone / 2)
                invisibleCorner(.bottomRight, size: cornerZone)
                    .position(x: geo.size.width - cornerZone / 2, y: geo.size.height - cornerZone / 2)

                shutterButton(color: color)
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

    // Click without noticeable motion → capture. Drag past a 4 px threshold → move the window instead.
    private func shutterButton(color: Color) -> some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        ensureAnchor()
                        guard let anchorMouse, let anchorFrame else { return }
                        let current = NSEvent.mouseLocation
                        let dx = current.x - anchorMouse.x
                        let dy = current.y - anchorMouse.y
                        if !buttonDidDrag, abs(dx) > 4 || abs(dy) > 4 {
                            buttonDidDrag = true
                        }
                        if buttonDidDrag {
                            controller.setOrigin(from: anchorFrame, delta: CGSize(width: dx, height: dy))
                        }
                    }
                    .onEnded { _ in
                        let didDrag = buttonDidDrag
                        clearAnchor()
                        buttonDidDrag = false
                        if didDrag {
                            controller.persist()
                        } else {
                            Task { await controller.capture() }
                        }
                    }
            )
    }

    private func invisibleCorner(_ corner: Corner, size: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: size, height: size)
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
