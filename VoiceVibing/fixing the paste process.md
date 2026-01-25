## Fixing the paste process

### Goals
- Keep auto-paste as the only insertion mode.
- Add a user-visible fallback when auto-paste cannot run (copy-only + “Press ⌘V”).
- Add basic paste failure feedback in UI.
- Add onboarding permission verification cues.
- Add dev-build trust guidance for Accessibility in onboarding.

---

## Plan and execution order

1) Fallback message when Accessibility is missing
   - If Accessibility isn’t trusted, still copy the transcript to the clipboard.
   - Show a small alert: “Copied to clipboard. Press ⌘V to paste.”

2) Basic paste feedback
   - After an auto-paste attempt, show a short status in onboarding (“Paste attempted” vs “Copied only”).
   - Log a note when paste is skipped because Accessibility isn’t granted.

3) Onboarding verification
   - On permissions page, show status text that confirms whether a paste attempt was made.
   - Keep the Start/Stop flow as the trigger for real permission prompts.

4) Dev-build trust messaging
   - Add a short note: Accessibility trust is tied to the exact build path.
   - Add a “Reveal app in Finder” button so the user can add the correct build in System Settings.
