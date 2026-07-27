import SwiftUI

struct EditorView: View {
    @StateObject private var editor = EditorController()
    @AppStorage("fontSize") private var fontSize: Double = 24
    @AppStorage("appearance") private var appearance: Appearance = .system

    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    private let fontSizeRange: ClosedRange<Double> = 14...60
    private let fontStep: Double = 4
    /// 下部バーの通常ボタンの径。
    private let actionButtonSize: CGFloat = 52
    /// 主操作（Copy & Clear）だけこの径にして中央に置く。
    private let primaryButtonSize: CGFloat = 60

    var body: some View {
        EditorTextView(controller: editor, fontSize: fontSize)
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .overlay(alignment: .center) { toastView }
            .preferredColorScheme(appearance.colorScheme)
    }

    // MARK: - 上部バー（親指が届きにくい＝誤タップさせたくないもの）
    //
    // 左は表示設定（本文を変えない）、右は編集操作（本文を変える）。
    // 本文を壊しうる2つを片側に寄せておくと、設定をいじるつもりで誤爆しにくい。

    private var topBar: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { mode in
                        Label(mode.label, systemImage: mode.symbolName).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: appearance.symbolName)
            }
            .accessibilityLabel("Appearance")
            .buttonStyle(.bordered)
            .onChange(of: appearance) { _, _ in Haptics.tap() }

            // 区切り線・長押しリピート・上下限のグレーアウトが標準で付く。
            Stepper(value: $fontSize, in: fontSizeRange, step: fontStep) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: fontSize) { _, _ in Haptics.tap() }

            Text("\(Int(fontSize))pt")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            // 選択メニューから作文ツールに辿り着くまでの手数を省くだけのボタン。
            // 何をさせるかは Apple の UI 側で毎回選ぶ。
            if #available(iOS 18.2, *) {
                Button {
                    Haptics.tap()
                    editor.showWritingTools()
                } label: {
                    Image(systemName: "wand.and.sparkles")
                }
                .accessibilityLabel("Writing Tools")
                .buttonStyle(.bordered)
                .disabled(editor.text.isEmpty)
            }

            Button {
                clear(copyFirst: false)
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Clear")
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(editor.text.isEmpty)
        }
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - 下部バー（親指の一等地＝頻繁に押すもの）

    private var bottomBar: some View {
        // 左右のグループを等幅にして、主操作を画面中央へ固定する。
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    editor.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .accessibilityLabel("Undo")
                .disabled(!editor.canUndo)

                Button {
                    Haptics.tap()
                    editor.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .accessibilityLabel("Redo")
                .disabled(!editor.canRedo)
            }
            .buttonStyle(ActionButtonStyle(size: actionButtonSize))
            .frame(maxWidth: .infinity, alignment: .leading)

            // 主操作。唯一の大サイズ＋塗り反転。
            Button {
                clear(copyFirst: true)
            } label: {
                Image(systemName: "scissors")
            }
            .accessibilityLabel("Copy & Clear")
            .buttonStyle(ActionButtonStyle(size: primaryButtonSize, filled: true))
            .disabled(editor.text.isEmpty)

            HStack(spacing: 12) {
                pasteButton

                Button {
                    copyAll()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy")
                .buttonStyle(ActionButtonStyle(size: actionButtonSize))
                .disabled(editor.text.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    /// 他のボタンと同じ淡いグレーの円。径だけは指定できないので拡大して合わせる。
    private var pasteButton: some View {
        PasteControl(
            controller: editor,
            backgroundColor: .secondarySystemFill,
            foregroundColor: .tintColor
        )
        .frame(width: 40, height: 40)
        .scaleEffect(actionButtonSize / 40)
        .frame(width: actionButtonSize, height: actionButtonSize)
        .accessibilityLabel("Paste")
    }

    // MARK: - トースト

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }

    // MARK: - 操作

    private func copyAll() {
        Clipboard.copy(editor.text)
        Haptics.success()
        show("コピーしました")
    }

    private func clear(copyFirst: Bool) {
        if copyFirst {
            Clipboard.copy(editor.text)
        }
        editor.clear()
        Haptics.success()
        show(copyFirst ? "コピーして消去しました" : "消去しました（Undoで戻せます）")
    }

    private func show(_ message: String) {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) { toast = message }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { toast = nil }
        }
    }
}

/// 下部バーの円ボタン。径をここで固定して5つの見た目を揃える。
/// `.bordered` はアイコンの字幅で径が変わるため使わない。
private struct ActionButtonStyle: ButtonStyle {
    let size: CGFloat
    /// 主操作だけ塗りを反転させる（青地に白アイコン）。
    var filled: Bool = false
    @Environment(\.isEnabled) private var isEnabled

    private var foreground: AnyShapeStyle {
        guard isEnabled else { return AnyShapeStyle(.tertiary) }
        return filled ? AnyShapeStyle(.white) : AnyShapeStyle(.tint)
    }

    private var background: AnyShapeStyle {
        guard filled, isEnabled else { return AnyShapeStyle(Color(uiColor: .secondarySystemFill)) }
        return AnyShapeStyle(.tint)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: filled ? 24 : 20, weight: .medium))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(Circle().fill(background))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

#Preview {
    EditorView()
}
