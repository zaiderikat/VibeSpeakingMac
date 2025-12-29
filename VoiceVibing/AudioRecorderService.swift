import AVFoundation

final class AudioRecorderService: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    func startRecording() throws {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                semaphore.signal()
            }
            semaphore.wait()
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("voicevibing_recording.wav")
        NSLog("Recording to: \(fileURL.path)")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.prepareToRecord()
        let ok = recorder?.record() ?? false
        if !ok {
            NSLog("AVAudioRecorder failed to start recording")
        }
        currentURL = fileURL
    }

    func stopRecording() -> URL? {
        guard let recorder = recorder else {
            return nil
        }
        recorder.stop()
        self.recorder = nil
        if let url = currentURL {
            let exists = FileManager.default.fileExists(atPath: url.path)
            NSLog("Recording stopped. File exists: \(exists) at \(url.path)")
        }
        return currentURL
    }
}
