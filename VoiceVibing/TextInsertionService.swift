import AppKit

final class TextInsertionService {
    func insert(text: String, restoreClipboard: Bool = true) {
        guard !text.isEmpty else {
            return
        }

        if PermissionsService.shared.accessibilityStatus() != .granted {
            let granted = PermissionsService.shared.requestAccessibility()
            if !granted {
                copyToClipboard(text: text)
                notifyAccessibilityRequiredIfOnboardingCompleted()
                return
            }
            // Accessibility can become active after user action; fall back to copy-only if not active yet.
            if PermissionsService.shared.accessibilityStatus() != .granted {
                copyToClipboard(text: text)
                notifyAccessibilityRequiredIfOnboardingCompleted()
                return
            }
        }

        performPaste(text: text, restoreClipboard: restoreClipboard)
    }

    private func performPaste(text: String, restoreClipboard: Bool) {
        let pasteboard = NSPasteboard.general
        let previousTypes = pasteboard.types ?? []
        var previousData: [NSPasteboard.PasteboardType: Data] = [:]
        for type in previousTypes {
            if let data = pasteboard.data(forType: type) {
                previousData[type] = data
            }
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        sendPasteCommand()

        if restoreClipboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pasteboard.clearContents()
                for (type, data) in previousData {
                    pasteboard.setData(data, forType: type)
                }
            }
        }
    }

    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func notifyAccessibilityRequiredIfOnboardingCompleted() {
        if UserDefaults.standard.bool(forKey: "didCompleteOnboarding") {
            NotificationCenter.default.post(name: .accessibilityPermissionRequired, object: nil)
        }
    }


    private func sendPasteCommand() {
        let keyCode: CGKeyCode = 9 // V
        let cmdKey: CGEventFlags = .maskCommand

        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = cmdKey
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = cmdKey
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
