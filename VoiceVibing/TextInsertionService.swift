import AppKit

final class TextInsertionService {
    func insert(text: String, restoreClipboard: Bool = true) {
        guard !text.isEmpty else {
            return
        }

        if PermissionsService.shared.accessibilityStatus() != .granted {
            let granted = PermissionsService.shared.requestAccessibility()
            if !granted {
                PermissionsService.shared.openSystemSettingsPrivacy(path: "Privacy_Accessibility")
                return
            }
        }

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
