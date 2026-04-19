import AppKit
import SwiftUI

@MainActor
final class ChatController: ObservableObject {
    struct Message: Identifiable, Equatable {
        enum Role { case user, bot }
        let id = UUID()
        let role: Role
        let text: String
        let date: Date
    }

    @Published var messages: [Message] = []
    @Published var input: String = ""
    @Published var isTyping: Bool = false

    weak var panel: ChatPanel?

    static let defaultsKey = "screenbox.chat.frame"

    private static let cannedReplies: [String] = [
        "Интересно, расскажи подробнее.",
        "Согласен на все сто.",
        "А если взглянуть с другой стороны?",
        "Хм, дай подумать…",
        "Звучит разумно.",
        "Можешь уточнить, что имеешь в виду?",
        "Я тебя услышал.",
        "Давай двигаться дальше.",
        "Это звучит как хорошая идея.",
        "Точно.",
        "Тут есть нюанс — уточни контекст.",
        "Хороший вопрос, сам об этом думал."
    ]

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(Message(role: .user, text: text, date: Date()))
        input = ""

        isTyping = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64.random(in: 350_000_000...1_200_000_000))
            guard let self else { return }
            let reply = Self.cannedReplies.randomElement() ?? "OK"
            self.messages.append(Message(role: .bot, text: reply, date: Date()))
            self.isTyping = false
        }
    }

    func clear() {
        messages.removeAll()
    }

    func restoreFrame() -> NSRect {
        if let arr = UserDefaults.standard.array(forKey: Self.defaultsKey) as? [Double], arr.count == 4 {
            return NSRect(x: arr[0], y: arr[1], width: arr[2], height: arr[3])
        }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = CGSize(width: 380, height: 520)
        return NSRect(
            x: screen.maxX - size.width - 40,
            y: screen.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func persist() {
        guard let frame = panel?.frame else { return }
        UserDefaults.standard.set(
            [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height],
            forKey: Self.defaultsKey
        )
    }
}
