import SwiftUI
import UIKit

/// 本文とエディタ操作の単一の情報源。
///
/// SwiftUI の `TextEditor` は UndoManager を外に出さないため、
/// `UITextView` を自前で包んでその undoManager を直接操作する。
@MainActor
final class EditorController: ObservableObject {
    private static let draftKey = "draft"

    @Published var text: String = UserDefaults.standard.string(forKey: draftKey) ?? "" {
        didSet {
            guard text != oldValue else { return }
            UserDefaults.standard.set(text, forKey: Self.draftKey)
        }
    }

    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    fileprivate weak var textView: UITextView?
    private var observers: [NSObjectProtocol] = []

    /// UIPasteControl のペースト先。UITextView に渡すと挿入も Undo 登録も標準の経路で行われる。
    var pasteTarget: UIResponder? { textView }

    deinit {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
    }

    func attach(_ textView: UITextView) {
        guard self.textView !== textView else { return }
        self.textView = textView
        observeUndoManager()
        refreshUndoState()
    }

    // MARK: - 編集操作

    /// 全文を置き換える。`textView.text = ...` の直接代入だと Undo に積まれないため、
    /// UITextInput 経由で置換して Clear も取り消せるようにする。
    func replaceAll(with newText: String) {
        guard let textView,
              let range = textView.textRange(from: textView.beginningOfDocument,
                                             to: textView.endOfDocument)
        else { return }
        textView.replace(range, withText: newText)
        syncFromTextView()
    }

    /// カーソル位置に挿入する（選択中なら置き換え）。
    func insert(_ string: String) {
        guard let textView else { return }
        textView.insertText(string)
        syncFromTextView()
    }

    func clear() {
        replaceAll(with: "")
    }

    /// 全文を選択して作文ツールを開く。
    ///
    /// 選択メニューから辿るのと同じ状態を作るだけで、何をさせるかは Apple の UI 側で選ぶ。
    /// このアプリが存在する理由は iPhone 上の選択操作が苦痛だからなので、
    /// 既存の選択は見ずに常に全文を対象にする。
    @available(iOS 18.2, *)
    func showWritingTools() {
        guard let textView else { return }
        // 標準の編集アクションなので first responder であることが前提。
        textView.becomeFirstResponder()
        // String.count は書記素クラスタ単位で NSRange と食い違う。
        textView.selectedRange = NSRange(location: 0, length: (textView.text as NSString).length)
        textView.showWritingTools(textView)
    }

    func undo() {
        textView?.undoManager?.undo()
        syncFromTextView()
    }

    func redo() {
        textView?.undoManager?.redo()
        syncFromTextView()
    }

    // MARK: - 内部

    /// UITextView 側の変更を `text` に取り込む。
    func syncFromTextView() {
        if let current = textView?.text, current != text {
            text = current
        }
        refreshUndoState()
    }

    private func refreshUndoState() {
        let manager = textView?.undoManager
        canUndo = manager?.canUndo ?? false
        canRedo = manager?.canRedo ?? false
    }

    private func observeUndoManager() {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers = []

        guard let manager = textView?.undoManager else { return }
        let names: [Notification.Name] = [
            .NSUndoManagerDidCloseUndoGroup,
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: manager, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshUndoState() }
            }
        }
    }
}

/// SwiftUI の `PasteButton` は形・径・色を一切指定できないため、他のボタンと揃えられない。
/// UIKit の `UIPasteControl` なら cornerStyle と色を指定できるのでこちらを包む。
/// 代わりにペースト先を明示する必要があり、タップごとにペースト許可の確認が出る（承知の上）。
struct PasteControl: UIViewRepresentable {
    let controller: EditorController
    var backgroundColor: UIColor
    var foregroundColor: UIColor

    func makeUIView(context: Context) -> UIPasteControl {
        var configuration = UIPasteControl.Configuration()
        configuration.displayMode = .iconOnly
        // 正方形なので capsule = 真円になる。
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = foregroundColor

        let control = UIPasteControl(configuration: configuration)
        // UITextView は SwiftUI の別サブツリーにあり responder chain を辿れないため、
        // ペースト先を明示する。生成直後は未接続なので次のループで繋ぐ。
        let controller = controller
        DispatchQueue.main.async { control.target = controller.pasteTarget }
        return control
    }

    func updateUIView(_ control: UIPasteControl, context: Context) {
        if control.target == nil {
            control.target = controller.pasteTarget
        }
    }
}

/// 大きいフォントで編集するためのテキストビュー。
struct EditorTextView: UIViewRepresentable {
    @ObservedObject var controller: EditorController
    var fontSize: Double

    /// 本文と typingAttributes で共有する表示属性。行間はフォントサイズに連動させる。
    private static func attributes(fontSize: Double) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = fontSize * 0.35
        return [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor.label,
        ]
    }

    /// フォントサイズ変更を既存本文と入力中の属性の両方へ反映する。
    /// `attributedText` の丸ごと代入は Undo スタックとカーソル位置を壊すので使わない。
    private static func applyAttributes(to textView: UITextView, fontSize: Double) {
        let attributes = attributes(fontSize: fontSize)
        textView.typingAttributes = attributes
        let all = NSRange(location: 0, length: textView.textStorage.length)
        if all.length > 0 {
            textView.textStorage.addAttributes(attributes, range: all)
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = controller.text
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        // 本文を下にドラッグするとキーボードが指に追従して下がる。
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        Self.applyAttributes(to: textView, fontSize: fontSize)

        let controller = controller
        DispatchQueue.main.async {
            controller.attach(textView)
            textView.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // 外から text を書き戻すと Undo スタックとカーソル位置が壊れるので差分がある時だけ。
        if textView.text != controller.text {
            textView.text = controller.text
            Self.applyAttributes(to: textView, fontSize: fontSize)
        }
        // 本文が空だと textView.font が nil になるため typingAttributes 側で判定する。
        let currentSize = (textView.typingAttributes[.font] as? UIFont)?.pointSize
        if currentSize != CGFloat(fontSize) {
            Self.applyAttributes(to: textView, fontSize: fontSize)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let controller: EditorController

        init(controller: EditorController) {
            self.controller = controller
        }

        func textViewDidChange(_ textView: UITextView) {
            MainActor.assumeIsolated {
                controller.attach(textView)
                controller.syncFromTextView()
            }
        }
    }
}
