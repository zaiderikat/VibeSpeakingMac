import AppKit
import Combine
import SwiftUI

final class OnboardingWindowController: NSWindowController {
    private var cancellable: AnyCancellable?

    init(appState: AppState) {
        let view = OnboardingView().environmentObject(appState)
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 300),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = "VoiceVibing Setup"
        window.contentView = hostingView
        window.center()
        super.init(window: window)

        cancellable = appState.$showOnboarding.sink { [weak self] show in
            if !show {
                self?.close()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
