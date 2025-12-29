import AVFoundation
import Combine

final class RecordingController: ObservableObject {
    @Published private(set) var isRecording = false

    private let recorder = AudioRecorderService()
    private var lastRecordingURL: URL?

    func start() {
        do {
            try recorder.startRecording()
            isRecording = true
        } catch {
            NSLog("Failed to start recording: \(error)")
        }
    }

    @discardableResult
    func stop() -> URL? {
        let url = recorder.stopRecording()
        lastRecordingURL = url
        isRecording = false
        return url
    }

    func consumeLastRecording() -> URL? {
        return lastRecordingURL
    }
}
