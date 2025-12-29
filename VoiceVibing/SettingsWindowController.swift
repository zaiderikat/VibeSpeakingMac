import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(appState: AppState?) {
        let view = SettingsView().environmentObject(appState ?? AppState())
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = "Settings"
        window.contentView = hostingView
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
