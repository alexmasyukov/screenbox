import SwiftUI
import AppKit

struct ChatView: View {
    @ObservedObject var controller: ChatController
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messagesScroll
            Divider()
            inputBar
        }
        .frame(minWidth: 280, minHeight: 320)
        .background(.ultraThinMaterial)
        .onAppear { inputFocused = true }
    }

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if controller.messages.isEmpty && !controller.isTyping {
                        emptyState
                            .padding(.top, 60)
                    }
                    ForEach(controller.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if controller.isTyping {
                        HStack(spacing: 0) {
                            TypingIndicator()
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 12)
                        .id("typing")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: controller.messages.count) { _, _ in
                if let last = controller.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: controller.isTyping) { _, typing in
                if typing {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Напиши что-нибудь — ответит рандомной заготовкой")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message…", text: $controller.input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($inputFocused)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                // Enter = send; Shift+Enter = newline. onKeyPress intercepts before TextField inserts the newline.
                .onKeyPress(phases: .down) { press in
                    guard press.key == .return else { return .ignored }
                    if press.modifiers.contains(.shift) { return .ignored }
                    controller.send()
                    return .handled
                }

            Button {
                controller.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(sendButtonEnabled ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!sendButtonEnabled)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(10)
    }

    private var sendButtonEnabled: Bool {
        !controller.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct MessageBubble: View {
    let message: ChatController.Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .textSelection(.enabled)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .background(bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            if message.role == .bot { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }

    private var bubbleColor: Color {
        message.role == .user ? Color.accentColor : Color.secondary.opacity(0.22)
    }
}

private struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1.0 : 0.3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.secondary.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
