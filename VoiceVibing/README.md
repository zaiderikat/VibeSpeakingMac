# VoiceVibing (V4)

## Progress

- V4-0: Xcode SwiftUI project exists.
- V4-1: Menubar app skeleton with status item and menu.
- V4-2: Settings UI with KeyboardShortcuts and persisted options.
- V4-3: Shortcut toggle + menubar recording indicator.
- V4-4: AudioRecorderService using AVAudioRecorder.
- V4-5: Whisper.cpp bridge + build script (CMake static libs).

## Decisions

- Menubar-only app (activation policy: accessory).
- Menubar icon uses SF Symbols ("waveform") for now.
- Text insertion default will be paste (clipboard + Cmd+V).
- Typing mode (key events) is a possible future option.
- Whisper.cpp integration via CMake-built library (Option B).
- Recordings are saved in temp and kept until the next recording.
- Models live in ~/Library/Application Support/VoiceVibing/models/.
- Model files will be bundled in the app for release (next step).

## Known Issues

- Settings window does not appear when selecting Settings… from the menubar.
  We will revisit after the next steps.

## Build whisper.cpp (V4)

```bash
./scripts/build_whisper.sh
```

This script outputs static libs into:

- `VoiceVibing/Whisper/lib`
- `VoiceVibing/Whisper/include`

## Model setup

Place models at:

- `~/Library/Application Support/VoiceVibing/models/`

Expected filenames:

- `ggml-tiny.en.bin`
- `ggml-base.en.bin`
- `ggml-small.en.bin`

## Notes

- Settings are stored in UserDefaults via AppStorage.
- Start/Stop Recording now starts/stops AVAudioRecorder and triggers transcription.
