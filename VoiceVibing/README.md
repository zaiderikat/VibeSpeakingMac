# VoiceVibing (V4)

## Progress

- V4-0: Xcode SwiftUI project exists.
- V4-1: Menubar app skeleton with status item and menu.
- V4-2: Settings UI with KeyboardShortcuts and persisted options.
- V4-3: Shortcut toggle + menubar recording indicator.
- V4-4: AudioRecorderService using AVAudioRecorder.
- V4-5: Whisper.cpp bridge + build script (CMake static libs).
- V4-7: Insert transcription via clipboard paste (restore clipboard by default).
- V4-8: Onboarding window + permission status menu.
- V4-9: Performance hardening (warm model + cancel-on-new-recording).
- Model bundling: ggml-tiny.en.bin included in app resources.

## Decisions

- Menubar-only app (activation policy: accessory).
- Menubar icon uses SF Symbols ("waveform") for now.
- Text insertion default will be paste (clipboard + Cmd+V).
- Typing mode (key events) is a possible future option.
- Whisper.cpp integration via CMake-built library (Option B).
- Recordings are saved in temp and kept until the next recording.
- Models are bundled in the app for release; App Support is fallback.

## Known Issues

- None tracked currently.

## Build whisper.cpp (V4)

```bash
./scripts/build_whisper.sh
```

This script outputs static libs into:

- `VoiceVibing/Whisper/lib`
- `VoiceVibing/Whisper/include`

## Model setup

Bundled model location in app resources:

- `VoiceVibing/Models/ggml-tiny.en.bin`

Fallback location (sandbox App Support):

- `~/Library/Containers/zerekat.VoiceVibing/Data/Library/Application Support/VoiceVibing/models/`

Expected filenames:

- `ggml-tiny.en.bin`
- `ggml-base.en.bin`
- `ggml-small.en.bin`

## Notes

- Settings are stored in UserDefaults via AppStorage.
- Start/Stop Recording now starts/stops AVAudioRecorder and triggers transcription.
- Clipboard contents are restored after paste by default.
- New recordings cancel an in-flight transcription (latest wins).
