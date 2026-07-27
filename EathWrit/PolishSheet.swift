import SwiftUI

/// 整形結果を本文に反映する前に見せるプレビュー。
///
/// 採用すれば Undo で戻せるとはいえ、壊れたことに気づかなければ戻しようがない。
/// 全文が黙って入れ替わるより、確認して選ぶほうがバッファに対して誠実。
struct PolishSheet: View {
    let original: String
    /// 採用されたときだけ呼ばれる。破棄・失敗では呼ばれない。
    let onAccept: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var polished = ""
    @State private var isGenerating = true
    @State private var failure: String?
    /// 元の文と見比べるための切り替え。整形後を既定にする。
    @State private var showsOriginal = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("整形")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("破棄") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("採用") {
                            onAccept(polished)
                            dismiss()
                        }
                        // 生成途中の欠けた文を本文に入れさせない。
                        .disabled(isGenerating || failure != nil || polished.isEmpty)
                    }
                }
        }
        .task {
            do {
                polished = try await Polisher.polish(original) { partial in
                    polished = partial
                }
            } catch {
                failure = error.localizedDescription
            }
            isGenerating = false
        }
    }

    @ViewBuilder
    private var content: some View {
        if let failure {
            // 失敗しても本文には触れていないので、伝えて閉じるだけでよい。
            ContentUnavailableView {
                Label("整形できませんでした", systemImage: "exclamationmark.triangle")
            } description: {
                Text(failure)
            }
        } else {
            VStack(spacing: 0) {
                // 整形の主目的は誤変換の修正なので、情報が落ちていないかを
                // 往復して確かめられることがこの画面の中心になる。
                Picker("表示", selection: $showsOriginal) {
                    Text("整形後").tag(false)
                    Text("元の文").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                ScrollView {
                    Text(showsOriginal ? original : polished)
                        .font(.body)
                        // 生成中の空白期間に高さが潰れないよう左上に寄せておく。
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                }

                if isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("整形中…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.bar)
                }
            }
        }
    }
}
