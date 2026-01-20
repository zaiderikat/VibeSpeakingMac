## Reference

The existing onboarding plan and UI decisions are documented in `v4_ui_implementation_plan.md`. This document extends that plan and captures current onboarding behavior plus the issues to address.

---

## Current onboarding UI (as implemented)

1. Page 1: Permissions
   - Text prompts for microphone and accessibility access.
   - Buttons open System Settings privacy panes.
2. Page 2: Shortcut
   - Instructional text only.
   - No shortcut recorder control.
3. Page 3: Test
   - Test field for paste output.
   - Focuses the text field for trial paste.

---

## Issues / gaps to address

1. Permissions flow does not trigger system prompts
   - Onboarding asks for mic and accessibility before the app has initiated actions that trigger system permission prompts.
   - Result: when users open System Settings, the app is not listed yet, so they cannot grant access.
   - Desired behavior: the first onboarding page should trigger a real recording attempt and a paste attempt so macOS prompts for mic and accessibility, and the app appears in the privacy lists.
    - it should ask the customer to  Click the button and start recording and then click the stop button. And once the customer click the start button, they should be asked for permissions. That should resolve that issue. I think this may be will be acceptable.

2. Shortcut selection is missing in onboarding
   - The second page only shows instructional text.
   - Users cannot set the global hotkey during onboarding.
   - Desired behavior: page 2 should include the KeyboardShortcuts recorder control used in Settings so the user can set the shortcut immediately.
     -  The customer is then asked to enter the keyboard shortcut and the page will show if the application is active and it's recording. And then once the customer clicks the hotkey again, then it should paste whatever content or whatever text the model had processed. 

3. Third onboarding page is unnecessary
   - The current “Test” page is not needed.
   - Desired behavior: remove this page and adjust onboarding flow to two pages total.

4. Menubar shortcut label does not update
   - The status menu item still displays the default `Cmd+R` even after the user changes the shortcut.
   - Desired behavior: the menu label should reflect the currently configured shortcut.

---

## Additional notes

- Bundle identity changes or reinstalling the app will reset TCC privacy permissions. In dev builds, this can require re‑granting mic and accessibility frequently. The onboarding flow should be robust to that reality.
