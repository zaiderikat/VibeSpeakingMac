import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var startStopMenuItem: NSMenuItem?
    private var micStatusItem: NSMenuItem?
    private var accessibilityStatusItem: NSMenuItem?
    private var defaultsObserver: NSObjectProtocol?
    private var isRecording = false
    private let recordingController = RecordingController()
    private let transcriptionService = TranscriptionService.shared
    private let insertionService = TextInsertionService()
    private weak var appState: AppState?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSLog("App bundle path: \(Bundle.main.bundlePath)")
        _ = PermissionsService.shared.requestAccessibility()
        setupStatusItem()
        setupShortcuts()
        observeShortcutChanges()
        refreshPermissionsMenu()
    }

    func attach(appState: AppState) {
        self.appState = appState
        if appState.showOnboarding {
            showOnboarding()
        }
        warmModel()
    }

    private func warmModel() {
        let modelName = UserDefaults.standard.string(forKey: "modelName") ?? "tiny"
        let modelPath = ModelPaths.modelPath(for: modelName).path
        let threads = min(4, ProcessInfo.processInfo.processorCount)
        if FileManager.default.fileExists(atPath: modelPath) {
            _ = transcriptionService.loadModel(path: modelPath, threads: threads)
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoiceVibing")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        let startStop = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "")
        menu.addItem(startStop)
        menu.addItem(NSMenuItem.separator())

        let micStatus = NSMenuItem(title: "Microphone: Unknown", action: nil, keyEquivalent: "")
        micStatus.isEnabled = false
        let accessibilityStatus = NSMenuItem(title: "Accessibility: Unknown", action: nil, keyEquivalent: "")
        accessibilityStatus.isEnabled = false
        menu.addItem(micStatus)
        menu.addItem(accessibilityStatus)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        item.menu = menu
        statusItem = item
        startStopMenuItem = startStop
        micStatusItem = micStatus
        accessibilityStatusItem = accessibilityStatus
        updateShortcutMenuTitle()
    }

    private func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            self?.toggleRecording()
        }
    }

    func toggleRecordingFromOnboarding() {
        toggleRecording()
    }

    @objc private func toggleRecording() {
        if appState?.isTranscribing == true {
            appState?.cancelTranscription = true
        }
        isRecording.toggle()
        updateStatusUI()
        if isRecording {
            recordingController.start()
            appState?.isRecording = true
        } else {
            let url = recordingController.stop()
            appState?.isRecording = false
            startTranscription(for: url)
        }
    }

    private func startTranscription(for url: URL?) {
        guard let url = url else {
            return
        }

        appState?.cancelTranscription = false
        appState?.isTranscribing = true

        let modelName = UserDefaults.standard.string(forKey: "modelName") ?? "tiny"
        let language = UserDefaults.standard.string(forKey: "languageCode") ?? "en"
        let prompt = UserDefaults.standard.string(forKey: "promptText") ?? ""
        let outputMode = UserDefaults.standard.string(forKey: "outputMode") ?? OutputMode.paste.rawValue
        let modelPath = ModelPaths.modelPath(for: modelName).path
        let threads = min(4, ProcessInfo.processInfo.processorCount)

        DispatchQueue.global(qos: .userInitiated).async {
            if !FileManager.default.fileExists(atPath: modelPath) {
                NSLog("Model missing at \(modelPath)")
                DispatchQueue.main.async {
                    self.appState?.isTranscribing = false
                }
                return
            }

            guard self.transcriptionService.loadModel(path: modelPath, threads: threads) else {
                NSLog("Failed to load whisper model")
                DispatchQueue.main.async {
                    self.appState?.isTranscribing = false
                }
                return
            }

            let text = self.transcriptionService.transcribe(wavURL: url, language: language, prompt: prompt) {
                self.appState?.cancelTranscription == true
            }

            DispatchQueue.main.async {
                self.appState?.isTranscribing = false
                if self.appState?.cancelTranscription == true {
                    NSLog("Transcription canceled")
                    return
                }
                if let text = text {
                    if outputMode == OutputMode.paste.rawValue {
                        self.insertionService.insert(text: text, restoreClipboard: true)
                    } else {
                        NSLog("Type mode not implemented yet")
                    }
                } else {
                    NSLog("Transcription failed")
                }
            }
        }
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appState: appState)
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboarding() {
        guard let appState = appState else { return }
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController(appState: appState)
        }
        onboardingWindowController?.showWindow(nil)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func refreshPermissionsMenu() {
        let micStatus = PermissionsService.shared.microphoneStatus()
        let accessibilityStatus = PermissionsService.shared.accessibilityStatus()
        micStatusItem?.title = "Microphone: \(micStatus.rawValue.capitalized)"
        accessibilityStatusItem?.title = "Accessibility: \(accessibilityStatus.rawValue.capitalized)"
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateStatusUI() {
        if let button = statusItem?.button {
            let name = isRecording ? "record.circle.fill" : "waveform"
            let image = NSImage(systemSymbolName: name, accessibilityDescription: "VoiceVibing")
            image?.isTemplate = true
            button.image = image
        }
        updateShortcutMenuTitle()
        refreshPermissionsMenu()
    }

    private func observeShortcutChanges() {
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            self?.updateShortcutMenuTitle()
        }
    }

    private func updateShortcutMenuTitle() {
        let baseTitle = isRecording ? "Stop Recording" : "Start Recording"
        let shortcutSuffix = formattedShortcutSuffix()
        startStopMenuItem?.title = baseTitle + shortcutSuffix
    }

    private func formattedShortcutSuffix() -> String {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .pushToTalk) else {
            return ""
        }
        return " (\(shortcut))"
    }
}
