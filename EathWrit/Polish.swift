import FoundationModels

/// 音声入力で書き散らした本文を、端末内モデルで整える。
///
/// Apple の Writing Tools（`UIResponder.showWritingTools(_:)`）は使わない。
/// 開くプリセットが固定で、自前の指示文を渡す API がないため。
/// 用途が「音声入力の後始末」に固定されている以上、指示文を保持できないことは致命的。
@MainActor
enum Polisher {
    /// 直すのは表記だけで、書き手の言い回しには触れさせない。
    /// 「本文だけを出力」を明示しないと「以下が修正版です」のような前置きが混ざる。
    private static let instructions = """
        あなたは日本語の校正者です。渡されるのは音声入力で書かれた文章で、\
        変換ミス・脱字・句読点の乱れ・「えーと」のようなフィラーが混じっています。

        直すのは次の 4 つだけです。
        - 変換ミス
        - 脱字
        - 句読点
        - フィラーの除去

        文体・語彙・言い回し・情報は変えないでください。要約も補足もしません。\
        改行の位置はそのまま保ちます。
        修正後の本文だけを出力してください。前置きも説明も付けないでください。
        """

    /// ユーザー自身の文章を書き換えるだけなので、既定の guardrails では過剰に拒否されうる。
    /// SDK がこの用途向けに用意している緩い設定を使う。
    private static let model = SystemLanguageModel(
        useCase: .general,
        guardrails: .permissiveContentTransformations
    )

    /// 校正に振れ幅はいらないので、サンプリングを止めて決定的に動かす。
    private static let options = GenerationOptions(sampling: .greedy)

    /// 対応端末か、Apple Intelligence が有効かをまとめて判定する。
    static var isAvailable: Bool { model.isAvailable }

    /// 整形して全文を返す。生成途中の断片は `onPartial` に流れる。
    ///
    /// 端末内生成は数秒かかることがあり、空のスピナーで待たせたくないので逐次受け取る。
    /// ストリームをそのまま返さないのは、セッションを関数内に閉じ込めて
    /// 生成が終わるまで確実に生かしておくため。
    /// セッションは呼び出しごとに作り直す（履歴を残すと前回の本文が次回の結果に混ざる）。
    static func polish(_ text: String, onPartial: (String) -> Void) async throws -> String {
        let session = LanguageModelSession(model: model, instructions: instructions)
        var latest = ""
        for try await snapshot in session.streamResponse(to: text, options: options) {
            latest = snapshot.content
            onPartial(latest)
        }
        return latest
    }
}
