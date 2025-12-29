## V4 Goals and non-goals

### Goals

1. Menubar app runs in background.
2. User holds a global shortcut → app records audio.
3. Releasing shortcut stops recording → transcribe offline.
4. Show small UI near caret: 🎤 while recording, ⏳ while transcribing.
5. Paste/type final text into the currently focused input.

### Non-goals (for V4 MVP)

* Perfect diarization / speaker separation
* Full “live streaming” transcription
* Advanced noise suppression (can be later)

---

## Tech choices (recommended for your constraints)

### UI + app shell

* **SwiftUI + AppKit bridge**
* **NSStatusItem** for menubar icon + menu
* A small **Settings** window (SwiftUI)

### Shortcut handling

Use a well-known Swift package that supports global shortcuts:

* **KeyboardShortcuts** (popular, SwiftUI-friendly), or
* MASShortcut (older, AppKit-ish)

This avoids writing low-level global key hooks.

### Recording audio

* **AVAudioEngine** or **AVAudioRecorder**
* Save to a temporary WAV/PCM file for Whisper.

### Transcription engine (offline)

Two paths:

**Path A (recommended for offline + predictable): whisper.cpp**

* Keep your existing Whisper/whisper.cpp investment.
* Build/compile whisper.cpp as a native library and call it from Swift.

**Path B (fastest to ship but not “true offline” depending on model availability/settings): Apple Speech**

* `SFSpeechRecognizer` can be “on-device” for some languages/devices, but it’s not as deterministic as whisper.cpp and often prompts permissions differently.

Given your earlier direction: **use whisper.cpp**.

### Typing into any app

Use **Accessibility APIs** to insert text, typically via:

* “Paste” approach: put text in clipboard then simulate Cmd+V
* Or “type” approach: generate key events for each character (more work, less reliable for non-ASCII)

For MVP reliability: **clipboard + Cmd+V** is usually best.

### Caret overlay (mic icon near cursor)

This is the trickiest part.

* You’ll likely need **AX (Accessibility) APIs** to query caret position in the focused UI element.
* Then show a small **floating NSPanel** (borderless, non-activating) at that screen coordinate.

---

## V4 Work Breakdown (AI-agent-friendly)

### V4-0: Repo + project setup

**Tasks**

1. Create a new repo folder: `VoiceToTextMac/`.
2. Xcode → “App” → **macOS** → SwiftUI.
3. Bundle ID, signing, automatic signing enabled.

**Outputs**

* A buildable macOS app that launches.

---

### V4-1: Menubar app skeleton

**Tasks**

1. Create `AppDelegate` (or `@main` SwiftUI app with AppKit adaptor).
2. Add `NSStatusItem` with an icon.
3. Add menu items:

   * “Start Recording” (for manual test)
   * “Settings…”
   * “Quit”

**Success criteria**

* App shows icon in the top bar and menu opens instantly.

---

### V4-2: Settings UI (shortcut + options)

**Tasks**

1. Add a Settings window with:

   * Shortcut recorder control (KeyboardShortcuts)
   * Model selection (dropdown: tiny/base/small etc.)
   * Language setting (optional)
   * Output mode: “Paste” vs “Type”
2. Persist settings using `UserDefaults`.

**Success criteria**

* User can set shortcut and it persists after relaunch.

---

### V4-3: Global push-to-talk flow (hold to record)

**Tasks**

1. Register global shortcut.
2. On shortcut **down**:

   * Start recording audio to a file.
   * Show mic overlay near caret.
3. On shortcut **up**:

   * Stop recording.
   * Switch overlay to loading indicator.
   * Kick transcription.

**Success criteria**

* Holding shortcut records.
* Releasing triggers transcription.

Notes:

* “key up” support depends on library. If the shortcut library doesn’t support press-and-hold well, implement:

  * Shortcut toggles “recording start”
  * Another event (e.g., same shortcut) stops recording
  * OR use a lower-level event monitor just for “up” detection.

But for your exact UX (“lift fingers”), plan for either:

* A shortcut library that supports press/release, or
* A small low-level event tap for that specific key combo.

---

### V4-4: Audio recording module

**Tasks**

1. Implement `AudioRecorderService`:

   * start() → prepares mic permission, starts capture
   * stop() → returns file URL
2. Output format:

   * 16kHz mono PCM WAV (ideal for whisper)
3. Handle edge cases:

   * If mic permission denied → show alert + open System Settings

**Success criteria**

* Produces playable WAV file.
* File size scales with recording duration.

---

### V4-5: Whisper.cpp integration in Swift (offline transcription)

**Tasks**

1. Add whisper.cpp as a dependency:

   * Option 1: Build as static library in Xcode
   * Option 2: Build via CMake and link binary
2. Create a thin C wrapper (`whisper_bridge.h/.c`) exposing:

   * init(modelPath)
   * transcribe(audioPath) → String
3. In Swift, create `TranscriptionService` that calls the wrapper.
4. Ensure transcription runs off the main thread.

**Success criteria**

* Given an audio file, returns text reliably without UI freezing.

**What to standardize**

* Where models live:

  * `~/Library/Application Support/<AppName>/models/`
* First-run behavior:

* If model missing, prompt user to download/copy.

**Implementation notes (added)**

* The tiny model is bundled in the app resources (`VoiceVibing/Models/ggml-tiny.en.bin`).
* App Support remains a fallback location for larger models.

---

### V4-6: Caret-position overlay (mic + loading)

**Tasks**

1. Implement `CaretLocator` using Accessibility:

   * Get focused UI element (`AXUIElementCreateSystemWide` → focused element)
   * Ask for caret bounds / selected text range bounds
2. Create `OverlayPanelController`:

   * Borderless, non-activating floating `NSPanel`
   * Mic icon view while recording
   * Spinner/loading view while transcribing
3. Position panel near caret each time you show it.

**Success criteria**

* Overlay appears close to cursor in common apps (TextEdit, Notes, Chrome, VS Code).
* Overlay does not steal focus.

**Important**

* You’ll need **Accessibility permission** for:

  * reading focused element / caret
  * injecting paste events

**Status (skipped for now)**

We are skipping V4-6 because the current UX (menubar indicator + push-to-talk flow)
is sufficient for local testing, and the caret overlay adds complexity without
blocking core functionality. We can revisit this later if the UX needs more
visual feedback near the cursor.

---

### V4-7: Insert transcription into any app

**Tasks**

1. Implement `TextInsertionService`:

   * Save current clipboard content
   * Put transcription into clipboard
   * Send Cmd+V keystroke to system (CGEvent)
   * Restore clipboard (optional but nice)
2. Optionally add “type mode” later.

**Success criteria**

* Cursor stays in target app.
* Text is inserted at cursor position.

**Implementation notes (added)**

* Clipboard is restored after paste with a 200ms delay to avoid pasting the
  previous clipboard contents.
* Output mode defaults to paste; type mode remains a future option.

---

### V4-8: Permissions + onboarding

**Tasks**

1. On first launch, show a tiny onboarding screen:

   * Request mic permission
   * Explain Accessibility permission + button to open System Settings
2. Add status indicators in menu:

   * Mic: granted/denied
   * Accessibility: granted/denied

**Success criteria**

* A new user can get it working without guessing what permission is missing.

**Implementation notes (added)**

* Onboarding is a 3-step window:
  1) Permissions: buttons to open Microphone and Accessibility settings.
  2) Shortcut: explains press-to-start, press-again-to-stop behavior.
  3) Test: focused text field where the user triggers the shortcut and sees
     pasted output.
* Continue/Back navigation; Finish closes onboarding.
* Permission status shown in the menubar menu (Microphone / Accessibility).

---

### V4-9: Performance hardening for “feels instant”

**Tasks**

1. Warm start:

   * Load whisper model once at app start (or lazily then keep in memory)
2. Use a queue:

   * If user triggers again while transcribing, either queue or cancel prior job.
3. Limit CPU spikes:

   * Optionally set whisper threads to `min(4, coreCount)`.

**Success criteria**

* Transition from release → transcription start is immediate.
* UI never hangs.

---

## What you need to do from your end (bootstrap checklist)

1. **Install Xcode** (latest stable).
2. Xcode → Settings:

   * Command Line Tools set to latest.
3. Create macOS SwiftUI app project.
4. Enable signing (your Apple ID).
5. Choose / download a Whisper model file and decide where you want it stored locally.
6. Be ready to enable macOS permissions during testing:

   * **Microphone**
   * **Accessibility**

---

## Cleanup from V1/V2/V3 (so agents don’t drag old complexity forward)

Since V4 becomes a native app, you can mark these as “legacy”:

* Any **terminal UI / cursor typing logic** built around the old MVP runtime
* Any **streaming audio plumbing**
* Any “preview vs commit streaming” logic from V2 if it existed for live dictation

Keep/reuse:

* Your **prompting + post-processing ideas** (like grammar correction) can be reused later
* Your **whisper.cpp setup knowledge**, model choices, and transcription tuning

---

## Your specific question: can whisper.cpp be used here?

Yes — **whisper.cpp is a good match** for exactly this:

* local macOS app
* offline transcription
* predictable cost (no API calls)
* fast enough if you preload the model and keep audio short (push-to-talk)

Where it’s “hard” is not whisper.cpp — it’s the **macOS system integration**:

* caret location
* overlay UI
* accessibility permissions
* global shortcut press/release

But those are solvable and very standard for menubar utilities.

---

## Today (completed)

* V4-0 through V4-5, V4-7, V4-8, V4-9 completed.
* V4-6 skipped (documented) due to sufficient UX without caret overlay.
* Model bundling: `ggml-tiny.en.bin` included in app resources; App Support is fallback.
* Shortcut behavior is toggle (press to start, press again to stop), documented in onboarding.
* Clipboard restore delay set to 200ms to avoid pasting old clipboard contents.

## Final V4 steps (pending)

* Bundle additional models (base/small) or limit selector to bundled models.
* Optional: add Type mode (key events) for output mode.
* Optional: persist onboarding completion so it only shows once.
