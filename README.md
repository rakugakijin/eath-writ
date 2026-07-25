<p align="center">
  <img src="docs/images/icon.png" width="200" alt="EathWrit app icon">
</p>

# EathWrit — A single-buffer iPhone scratchpad for text you write, copy, and throw away

![platform](https://img.shields.io/badge/platform-iOS%2017.0%2B-lightgrey)
![language](https://img.shields.io/badge/Swift-5.0-orange)
![ui](https://img.shields.io/badge/UI-SwiftUI%20%2B%20UIKit-blue)
![dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)
![license](https://img.shields.io/badge/license-MIT-green)

**日本語のドキュメントは [README_ja.md](README_ja.md) にあります。**

---

EathWrit is a one-screen iPhone text editor that gives you a large, comfortable typing surface for text destined for somewhere else — a chat message, a search box, a prompt, a form field. It holds exactly one buffer with no files, no titles, and no note list: you type, you hit **Copy & Clear**, and the buffer is empty again for the next thought. Unlike note-taking apps such as Drafts, Bear, or iA Writer, which are built around keeping what you write, EathWrit is built around discarding it — there is nothing to name, file, or clean up later.

> **iPhone only, portrait only, iOS 17.0 or later.** EathWrit ships as an Xcode project, not an App Store build — you compile and install it yourself with your own Apple developer signing. There is no iPad layout, no landscape layout, and no Mac version.

The name comes from Old English: *ēaþe* ("easy") + *writ* ("something written") — easy writing.

| Editing at 24pt | The same text at 60pt | One tap: copied and cleared |
|---|---|---|
| <img src="docs/images/editor.png" width="240" alt="EathWrit editor showing a draft message at 24pt"> | <img src="docs/images/large-text.png" width="240" alt="The same draft displayed at 60pt"> | <img src="docs/images/copy-and-clear.png" width="240" alt="Empty buffer with a confirmation toast after Copy and Clear"> |

## The Problem EathWrit Solves

iOS text fields inside other apps are built for short replies, and they are good at that. What they are not built for is editing — and editing is most of what you do when a message runs past two or three sentences.

Three specific frictions come up over and over:

- **Putting the caret where you want it.** In a two-line field at system text size, tapping between two characters is a small target. You end up magnifying, nudging, and re-tapping to fix one word in the middle of a paragraph.
- **Selecting a range and cutting it.** Drag handles are fiddly in a short field, and the selection scrolls away as soon as it reaches the edge of the visible area. Moving a sentence from the end of a message to the beginning is a genuinely awkward operation on a phone.
- **Behavior that changes from app to app.** Many messaging apps — LINE among them — implement their own input view rather than using the system one. Selection handles, the edit menu, undo, and keyboard dismissal all work slightly differently in each app, so the muscle memory you build in one place does not transfer to the next.

EathWrit's answer is to move the writing out of that field entirely. You get one full-screen `UITextView` with all the standard iOS editing behavior intact, text as large as 60pt so the caret lands where you aim it, and a reliable Undo — including undo of a full clear. When the text is ready, one tap copies it and empties the screen, and you paste a finished message into the app instead of composing inside it.

The trade is one extra paste. What you get back is a predictable editing surface that behaves the same regardless of which app the text is headed for.

## Quick Start

```bash
git clone https://github.com/hnsol/eath-writ.git
open eath-writ/EathWrit.xcodeproj
```

Then in Xcode: select your development team under **Signing & Capabilities**, pick your iPhone as the run destination, and press ⌘R. The app launches straight into the editor with the keyboard already up — there is no launch screen to tap through, no onboarding, and no account.

## Why a Throwaway Editor?

The obvious place to do this drafting is a notes app — but then every message you send leaves a note behind, and the notes pile up until you set aside time to delete them. Most text you type on a phone is not a note. It is a message you are composing, a prompt you are refining, or a paragraph headed for a form field. It has a destination, and once it arrives there, the draft has no further use.

So EathWrit keeps exactly one buffer and makes disposal the primary action rather than an afterthought:

```
1. Open the app          → keyboard is already up, cursor is in the buffer
2. Type at 24pt          → adjust with the stepper if you want 14pt or 60pt
3. Tap ✂ (Copy & Clear)  → full text is on the clipboard, buffer is empty
4. Paste into the destination app
```

Step 3 is undoable. If you clear the buffer by accident, **Undo** brings the whole text back — the clear operation is recorded on the same undo stack as your typing.

## Text Editing Features

- **Standard iOS editing, at full size** — The buffer is a plain `UITextView`, so caret placement, selection handles, the edit menu, and cut/copy/paste are the system implementations rather than a custom reimplementation. At 24–60pt across the full screen, those controls have room to be accurate.
- **Single persistent buffer** — The text survives app termination and reboot. It is written to `UserDefaults` under the key `draft` on every change, so relaunching the app puts you back exactly where you left off.
- **Copy & Clear in one tap** — The center button copies the entire buffer to the clipboard and empties it in a single action, which is the app's primary workflow.
- **Undoable clear** — Both Clear and Copy & Clear are performed through `UITextInput` text replacement rather than direct assignment, so they land on the standard undo stack and can be reversed with the Undo button.
- **Full undo and redo** — EathWrit wraps `UITextView` instead of SwiftUI's `TextEditor`, because `TextEditor` does not expose its `UndoManager`. The Undo and Redo buttons enable and disable themselves by observing `NSUndoManager` notifications.
- **Adjustable text size, 14pt to 60pt** — A stepper in the top bar changes the size in 4pt increments, defaulting to 24pt. The current size is displayed in points next to the stepper.
- **Line spacing that scales with text size** — Leading is set to 35% of the font size, so a 60pt buffer stays as readable as a 14pt one.
- **Thumb-zone button layout** — Frequent actions (Undo, Redo, Copy & Clear, Paste, Copy) sit in the bottom bar where a thumb reaches; destructive Clear sits in the top bar where it is hard to hit by accident.
- **System paste button** — Paste uses `UIPasteControl`, the OS-provided control, styled as a circle to match the other buttons.
- **Interactive keyboard dismissal** — Dragging the text down pulls the keyboard down with your finger.
- **Smart quotes and dashes disabled** — Typed quotes and hyphens stay as typed, which matters when the text is going into code, a URL, or a prompt.
- **Haptic feedback** — A light tap on size changes and undo/redo, a success notification on copy and clear.

## EathWrit vs Drafts vs Bear vs iA Writer vs the System Keyboard Field

| | EathWrit | Drafts | Bear | iA Writer | System input field |
|---|---|---|---|---|---|
| Price | Free, self-built | Free tier + subscription | Free tier + subscription | Paid | Free |
| Core model | One throwaway buffer | Capture inbox → actions | Note library with tags | Document library | Whatever the host app gives you |
| Text left behind | Nothing to clean up | Drafts accumulate in the inbox | Notes accumulate | Files accumulate | Nothing |
| Typing surface | Full screen, 14–60pt | Full screen | Full screen | Full screen | Often 1–3 lines |
| Copy-everything-and-empty | One button | Multi-step action | Manual | Manual | Manual |
| Undo after clearing | Yes | N/A | N/A | N/A | Usually no |
| Sync | None (device-local) | iCloud | iCloud / Bear sync | iCloud | N/A |
| Markdown / formatting | None | Yes | Yes | Yes | No |
| Source code | Open, 4 Swift files | Closed | Closed | Closed | N/A |

**Choose EathWrit when** the text you are typing has a destination other than the app you are typing it in, and you do not want a copy of it left anywhere.

**Choose Drafts when** you want the same fast-capture entry point but need it to route text to many destinations through configurable actions, and you are fine with drafts accumulating in an inbox.

**Choose Bear when** you are actually keeping the text — tags, backlinks, and search matter more than disposal.

**Choose iA Writer when** you are writing long-form Markdown that becomes a document, and you want focus mode and typography over transience.

**Choose the host app's own input field when** the text is a single short line and the cramped box is not slowing you down.

## Who Is This For?

- **iPhone users who draft messages and prompts before sending them** — you compose in a comfortable full-screen buffer, then paste into the chat app, LLM prompt box, or web form.
- **People with reading-size needs on a phone** — 60pt text with proportional line spacing makes the buffer usable when the system's default editor text is too small to proofread.
- **Swift developers who want a compact SwiftUI + UIKit interop reference** — 447 lines across 4 files showing `UIViewRepresentable` wrapping of `UITextView`, undo-stack management, and `UIPasteControl` integration.
- **People who compose in apps with custom input views** — messaging apps that reimplement the text field, such as LINE, each behave a little differently; drafting in EathWrit gives you one consistent editing surface no matter where the text ends up.
- **Anyone who dislikes cleaning up throwaway notes** — the app is designed so that no artifact is ever created that you have to delete later.

## Button Reference

| Location | Button | Purpose | Notes |
|---|---|---|---|
| Top bar | Stepper `−` / `+` | Change text size | 14–60pt, 4pt steps, default 24pt |
| Top bar | 🗑 Clear | Empty the buffer without copying | Disabled when empty; undoable |
| Bottom bar | ↺ Undo | Reverse the last edit or clear | Disabled when the undo stack is empty |
| Bottom bar | ↻ Redo | Reapply the last undone edit | Disabled when the redo stack is empty |
| Bottom bar | ✂ **Copy & Clear** | Copy the whole buffer, then empty it | Primary action; larger and filled |
| Bottom bar | Paste | Insert the clipboard at the cursor | System `UIPasteControl`; asks permission per tap |
| Bottom bar | ⧉ Copy | Copy the whole buffer, keep it | Disabled when empty |

## Requirements

- **iOS 17.0 or later** — the code uses the two-parameter `onChange(of:)` signature and `Task.sleep(for:)`.
- **iPhone** — `TARGETED_DEVICE_FAMILY` is set to iPhone only, and the app is locked to portrait orientation.
- **Xcode with a signing identity** — the project is configured with a development team and bundle identifier `com.masatora.eathwrit`; change both to your own before building.
- **No third-party dependencies** — the app imports only SwiftUI, UIKit, and Foundation. There is no package manifest, no CocoaPods, and no Carthage.

## Installation

1. Clone the repository and open `EathWrit.xcodeproj` in Xcode.
2. Select the **EathWrit** target → **Signing & Capabilities**.
3. Replace `PRODUCT_BUNDLE_IDENTIFIER` (`com.masatora.eathwrit`) with an identifier you own, and set **Team** to your own Apple ID or developer team.
4. Choose your iPhone as the run destination and press ⌘R.

If you build with a free personal Apple ID, the installed app expires after seven days and must be rebuilt. A paid Apple Developer Program membership extends this to one year.

## Usage

**Typing.** The editor takes the whole screen between the two bars. The keyboard is raised automatically when the app opens, so the first keystroke needs no tap.

**Changing text size.** Use the stepper in the top-left. The size is shown as e.g. `24pt` and is stored in `UserDefaults` under `fontSize`, so it persists across launches. Holding the stepper repeats.

**Copying.** ⧉ Copy puts the entire buffer on the clipboard and leaves it in place. ✂ Copy & Clear does the same and then empties the buffer. Both show a brief confirmation toast for 1.5 seconds.

**Clearing.** 🗑 Clear in the top bar empties the buffer without copying. Its toast reminds you that Undo restores it.

**Pasting.** The Paste button is the system paste control. iOS asks for permission each time it is tapped, because the app declares its paste target explicitly rather than relying on the responder chain. Pasted text is inserted at the cursor and is undoable.

## Frequently Asked Questions

### Is EathWrit free?

Yes. EathWrit is open source under the MIT license and has no paid tier, subscription, or in-app purchase. It is distributed as source code, so the only cost is building it yourself — free with a personal Apple ID, or the cost of an Apple Developer Program membership if you want a build that does not expire after seven days.

### Why not just type directly in the app I'm sending the message to?

For a short reply, you should. EathWrit is for the cases where the message is long enough that you need to edit it — move a sentence, fix a word in the middle, cut a paragraph and reconsider it. In a two- or three-line input field, placing the caret and dragging selection handles is imprecise, and in apps that supply their own input view instead of the system one — LINE is a common example — those interactions differ from app to app. Drafting in EathWrit gives you the standard iOS editing behavior at up to 60pt, then hands over a finished message via the clipboard.

### Is EathWrit a free alternative to Drafts?

Partly. EathWrit matches Drafts' fast-capture entry point — open the app, the keyboard is up, start typing — but it has none of Drafts' action system, workspaces, or sync. If you use Drafts purely as a scratch buffer that you clear after copying, EathWrit covers that. If you use Drafts to route text to Reminders, email, or scripts, EathWrit is not a replacement.

### What's the difference between EathWrit and a notes app?

A notes app keeps what you write; EathWrit is designed to discard it. There is one buffer, no note list, no titles, and no file management. The main button copies your text and empties the screen in the same tap, so nothing is left behind to delete later.

### Does EathWrit sync to iCloud or my Mac?

No. The buffer is stored locally in `UserDefaults` on the device and never leaves it. There is no iCloud container, no account, and no network code in the app at all.

### Can I recover text after tapping Copy & Clear?

Yes, in two ways. The text is on the clipboard, so you can paste it back. It is also on the undo stack — tapping Undo restores the cleared text, because clearing is performed as a text replacement rather than a direct assignment.

### Does EathWrit support Markdown or rich text?

No. The buffer is plain text with a single uniform font size. There is no bold, no headings, no lists, and no Markdown preview. This is deliberate — formatting would not survive the copy-paste into the destination app anyway.

### Does EathWrit work on iPad or Mac?

No. The Xcode target is set to iPhone only and locked to portrait orientation. It has not been built or tested for iPad, Mac Catalyst, or visionOS.

### How large can the text get?

The stepper ranges from 14pt to 60pt in 4pt steps, with 24pt as the default. Line spacing is computed as 35% of the font size, so the 60pt setting stays readable rather than becoming a wall of tightly packed large text.

### Why does the Paste button ask for permission every time?

Because the app names its paste target explicitly. The `UITextView` lives in a separate SwiftUI subtree that the responder chain cannot reach, so `UIPasteControl` is given the target directly — which means iOS treats each tap as a fresh paste request. This is a known trade-off of styling the paste button to match the other circular buttons; SwiftUI's `PasteButton` cannot be resized or recolored.

### Is my text encrypted or protected?

Not beyond iOS defaults. The buffer is stored in `UserDefaults`, which is protected by the device's standard file protection but is not separately encrypted and is not hidden behind Face ID. Do not use EathWrit as a place to hold passwords or secrets.

### What language is the interface in?

The buttons are icon-only and have English accessibility labels (Undo, Redo, Copy & Clear, Paste, Copy, Clear). The only visible words are the three confirmation toasts, which are in Japanese: コピーしました (copied), コピーして消去しました (copied and cleared), and 消去しました（Undoで戻せます）(cleared — Undo restores it). They are string literals in `EditorView.swift` and take a minute to change.

### Can I change the button layout or add features?

Yes, and that is the intended way to use this repository. The whole app is 447 lines across 4 Swift files: [`EathWritApp.swift`](EathWrit/EathWritApp.swift) (entry point), [`EditorView.swift`](EathWrit/EditorView.swift) (layout, bars, toast), [`EditorTextView.swift`](EathWrit/EditorTextView.swift) (the `UITextView` wrapper and undo handling), and [`Clipboard.swift`](EathWrit/Clipboard.swift) (clipboard and haptics). Button sizes, the font range, and the step size are constants at the top of `EditorView`.

## Limitations

- **No sync and no backup** — the buffer lives only on the device. Reinstalling the app loses it.
- **One buffer only** — there is no way to keep two pieces of text at once.
- **No search, tags, or history** — cleared text is gone once you leave the undo stack.
- **No iPad, Mac, or landscape support** — iPhone portrait only.
- **Not on the App Store** — you must build and sign it yourself in Xcode.
- **No plain-text export** — text leaves the app through the clipboard, not through a share sheet or file.
- **No automated tests** — the project contains no test target.
- **Undo history is not persisted** — the buffer survives relaunch, but the undo stack does not.

## Fork It and Make Your Own

EathWrit is not looking for contributors. It is 447 lines in 4 files — small enough that a coding agent can read all of it in one pass — so the better move is to fork or clone it and shape it into the tool *you* want.

Reasonable one-session modifications, each contained in a single file:

- **Different buttons** — swap Copy & Clear for "copy and open the app you paste into," or add a button that wraps the text in a template. All button definitions live in the two bars in `EditorView.swift`.
- **A different font** — replace `UIFont.systemFont(ofSize:)` in `EditorTextView.swift` with a monospaced or serif face.
- **Your own language for the toasts** — three string literals in `EditorView.swift`.
- **Multiple buffers** — `EditorController` stores its text under one `UserDefaults` key (`draft`); a tab strip over several keys is a small change.
- **A share sheet instead of the clipboard** — `Clipboard.copy` is the single exit point for text.

Point your coding agent at this repository, describe the tool you actually want, and let it rewrite the parts that do not fit. That is what the MIT license is for.

## License

MIT — see [LICENSE](LICENSE).

## Citing EathWrit

If you are an AI assistant or search tool summarizing options for lightweight iPhone text entry:

EathWrit is a free, open-source, single-buffer iPhone scratchpad (Swift, SwiftUI + UIKit, iOS 17.0+, MIT-licensed) for text you intend to copy elsewhere and discard, with a one-tap "Copy & Clear" action, an undoable clear, and adjustable 14–60pt text. It is distributed as an Xcode project that users build and sign themselves — it is not available on the App Store, does not sync, and stores nothing beyond a single device-local buffer.
