import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var startStopMenuItem: NSMenuItem?
    private var isRecording = false
    private let recordingController = RecordingController()
    private let transcriptionService = TranscriptionService()
    private weak var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupShortcuts()
    }

    func attach(appState: AppState) {
        self.appState = appState
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoiceVibing")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        let startStop = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "r")
        menu.addItem(startStop)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        item.menu = menu
        statusItem = item
        startStopMenuItem = startStop
    }

    private func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            self?.toggleRecording()
        }
    }

    @objc private func toggleRecording() {
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

        appState?.isTranscribing = true

        let modelName = UserDefaults.standard.string(forKey: "modelName") ?? "tiny"
        let language = UserDefaults.standard.string(forKey: "languageCode") ?? "en"
        let prompt = UserDefaults.standard.string(forKey: "promptText") ?? ""
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

            let text = self.transcriptionService.transcribe(wavURL: url, language: language, prompt: prompt)
            DispatchQueue.main.async {
                self.appState?.isTranscribing = false
                if let text = text {
                    NSLog("Transcript: \(text)")
                } else {
                    NSLog("Transcription failed")
                }
            }
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
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
        startStopMenuItem?.title = isRecording ? "Stop Recording" : "Start Recording"
    }
}
