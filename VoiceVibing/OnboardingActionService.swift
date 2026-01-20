import Foundation

final class OnboardingActionService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isTranscribing = false

    private let recordingController = RecordingController()
    private let transcriptionService = TranscriptionService.shared
    private let insertionService = TextInsertionService()

    func startRecording() {
        recordingController.start()
        isRecording = true
    }

    func stopAndTranscribe() {
        let url = recordingController.stop()
        isRecording = false
        guard let url = url else {
            return
        }

        _ = PermissionsService.shared.requestAccessibility()
        isTranscribing = true

        let modelName = UserDefaults.standard.string(forKey: "modelName") ?? "tiny"
        let language = UserDefaults.standard.string(forKey: "languageCode") ?? "en"
        let prompt = UserDefaults.standard.string(forKey: "promptText") ?? ""
        let modelPath = ModelPaths.modelPath(for: modelName).path
        let threads = min(4, ProcessInfo.processInfo.processorCount)

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                DispatchQueue.main.async {
                    self.isTranscribing = false
                }
            }

            if !FileManager.default.fileExists(atPath: modelPath) {
                NSLog("Model missing at \(modelPath)")
                return
            }

            guard self.transcriptionService.loadModel(path: modelPath, threads: threads) else {
                NSLog("Failed to load whisper model")
                return
            }

            let text = self.transcriptionService.transcribe(wavURL: url, language: language, prompt: prompt) {
                false
            }

            if let text = text, !text.isEmpty {
                DispatchQueue.main.async {
                    self.insertionService.insert(text: text, restoreClipboard: true)
                }
            } else {
                NSLog("Transcription failed")
            }
        }
    }
}
