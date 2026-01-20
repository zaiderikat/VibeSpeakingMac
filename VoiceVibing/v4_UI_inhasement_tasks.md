## Reference

This plan is based on `v4_ui_enhancments.md` and aligns with `v4_ui_implementation_plan.md`.

---

## Implementation plan

### 1) Permissions page should trigger real permission prompts

- Add a simple “Start Recording” → “Stop Recording” flow inside the first onboarding page.
- When the user taps “Start Recording”:
  - call the same recording start path used by the main app, so macOS prompts for microphone permission.
- When the user taps “Stop Recording”:
  - stop recording and immediately run a short transcription flow.
  - attempt the paste action to trigger Accessibility permission.
- If permissions are denied:
  - keep the “Open System Settings” buttons as a fallback.
- Acceptance:
  - user sees the system permission prompts the first time they tap Start / Stop.
  - app appears in Microphone and Accessibility lists afterward.

### 2) Add shortcut recorder to onboarding page 2

- Replace the static instruction-only page with the same KeyboardShortcuts recorder control used in Settings.
- Show a clear status indicator:
  - “Listening / Recording” when the shortcut is active.
  - “Idle” when not recording.
- Add a short helper line: “Press the shortcut again to stop and paste.”
- Acceptance:
  - user can set the shortcut during onboarding.
  - shortcut selection persists and is reflected in app settings.

### 3) Remove third onboarding page

- Delete the “Test” page from onboarding.
- Update the onboarding state machine to two steps:
  - Step 1: Permissions (record/paste trigger).
  - Step 2: Shortcut setup.
- Ensure the “Finish” action closes onboarding and does not leave dangling state.
- Acceptance:
  - onboarding is two pages total.
  - no references remain to the old test page.

### 4) Menubar shortcut label should update to user-defined shortcut

- Replace the static “Start Recording” menu item label with a label that includes the current shortcut.
- Subscribe to shortcut changes (KeyboardShortcuts or UserDefaults) and update the menu item title on change.
- Acceptance:
  - menu item shows the current shortcut after user changes it.
  - label updates without restarting the app.

---

## Dependencies / touchpoints

- Onboarding UI: `OnboardingView`, `OnboardingWindowController`, `AppState`
- Recording + transcription: `RecordingController`, `AudioRecorderService`, `TranscriptionService`
- Paste action: `TextInsertionService` (to trigger Accessibility prompt)
- Shortcuts: `KeyboardShortcuts` integration in Settings + AppDelegate
- Status menu: `AppDelegate` menu item labeling

---

## Risks / notes

- Reinstalling or changing bundle ID will reset TCC permissions (expected in dev).
- Permission prompts must be triggered by real API usage; system panes alone are not sufficient.
