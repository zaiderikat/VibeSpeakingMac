# VoiceVibing (V4)

## Progress

- V4-0: Xcode SwiftUI project exists.
- V4-1: Menubar app skeleton with status item and menu.

## Decisions

- Menubar-only app (activation policy: accessory).
- Menubar icon uses SF Symbols ("waveform") for now.
- Text insertion default will be paste (clipboard + Cmd+V).
- Typing mode (key events) is a possible future option.
- Whisper.cpp integration via CMake-built library (Option B).

## Notes

- Settings window is a placeholder; will be wired in V4-2.
- Start Recording menu item is a stub for now.
