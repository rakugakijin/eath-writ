# docs 更新の申し送り

日付: 2026-07-27
対象コミット: `ed08aa5` 時点の `main`

> **完了しました**（2026-07-27, コミット `2391bfc`）。この文書は経緯の記録として残しています。
> 継続中の申し送りは [docs/HANDOFF.md](../../HANDOFF.md) を参照してください。

## 何が起きたか

作文ツール（iOS の Writing Tools）へのショートカットボタンを追加し、あわせて上部バーの並びを組み替えた。**コードだけ先に進めて docs を後回しにしたため、README / README_ja / llms.txt とスクリーンショット 6 枚が現状と食い違っている。** その解消がこの申し送りの目的。

経緯は [2026-07-27-ai-polish-design.md](2026-07-27-ai-polish-design.md) に残してある。当初 FoundationModels でカスタムプロンプトによる整形を実装したが、狙った誤変換が直らず指示していない書き換えをするため撤回し、Apple の作文ツールを開くだけのボタンに置き換えた。**docs には FoundationModels や「AI 整形」の話は一切書かないこと。** 現在の機能は「全文を選択して作文ツールを開く」だけで、何をさせるかは Apple の UI 側で毎回選ぶ。

## 直すもの

### 1. 上部バーの並びが変わった

変更前は左にステッパー、右に外観・ゴミ箱だった。現在はこう:

```
左  [◐ 外観] [− │ +] [24pt]      （余白）      [✨ 作文ツール] [🗑 Clear]  右
```

**分類の軸は「左＝表示設定（本文を変えない）／右＝編集操作（本文を変える）」。** 本文を壊しうるものを片側に固めてある。README の「Thumb-zone button layout」「親指の届く位置にボタンを配置」の節は下部バーの話が中心だが、上部バーの左右の意味にも触れる余地がある。

### 2. 作文ツールボタンが増えた

- アイコン `wand.and.sparkles`、accessibility label は `Writing Tools`
- 押すと**本文全体を選択して iOS の作文ツールを開く**。校正・書き直し・要約など何をさせるかはそこで毎回選ぶ
- **iOS 18.2 以降でのみ表示される。** 17.0〜18.1 では単に出ない。Apple Intelligence 非対応端末での挙動は未確認
- 本文が空のときは無効
- 適用結果は `UITextView` の標準経路を通るので既存の Undo で戻せる
- **シミュレータでは動かない。** `canPerformAction(showWritingTools:)` が false を返す。実機 iPhone 15 Pro では動作確認済み

「ボタン一覧」の表（README.md / README_ja.md）に 1 行足す。位置は上部バー、ゴミ箱の直前。

### 3. 数字の更新

`llms.txt` の冒頭に「496 lines across 5 source files」とある。**現在は 535 行 / 5 ファイル。**

`iOS 17.0+` の記述は**そのままでよい**。deployment target は 17.0 のままで、作文ツールボタンだけを `if #available(iOS 18.2, *)` で囲んでいる。ただし「iOS 18.2 以降だと作文ツールボタンが増える」ことはどこかに書いたほうが親切。

### 4. スクリーンショット 6 枚の撮り直し

`docs/images/` の以下 6 枚がすべて旧レイアウト。アイコン 2 枚（`icon-light.png` / `icon-dark.png`）は影響なし。

- `editor-light.png` / `editor-dark.png` — 24pt の編集画面
- `appearance-menu.png` — 外観メニューを開いた状態
- `large-text-light.png` / `large-text-dark.png` — 60pt 表示
- `copy-and-clear.png` — 消去直後のトースト

参照箇所は README.md:26,30 と README_ja.md:26,30。alt テキストも英日それぞれ付いているので、内容が変わるなら合わせて直す。

作文ツールのパネルを写した 7 枚目を足すかは任意。ただし**シミュレータでは開かないので、撮るなら実機が要る**。

## 撮影メモ

シミュレータは iPhone 17 Pro（udid `95FA9EF5-5F54-47DB-BD72-61444C17A4C8`）を使ってきた。日本語テキストは直接打てないので、`xcrun simctl pbcopy` でクリップボードに入れてアプリの Paste ボタンから流し込む。**`LANG=en_US.UTF-8` を付けないと encoding エラーになる。**

既存 6 枚に写っている本文と揃えると差分が読みやすい。

## やらないこと

- 機能そのものの変更。docs をコードに合わせるだけ
- `DEVELOPMENT_TEAM` は空のまま。実機ビルドのたびに Xcode が書き込むので、コミットに混ぜない
