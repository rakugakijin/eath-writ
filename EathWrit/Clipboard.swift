import UIKit

/// UIKit 依存をここに閉じ込めて View 側を素直に保つ。
enum Clipboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
