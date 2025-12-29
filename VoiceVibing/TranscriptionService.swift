import Foundation

final class TranscriptionService {
    static let shared = TranscriptionService()

    private var bridge: OpaquePointer?
    private var loadedModelPath: String?
    private var threads: Int = 4

    func loadModel(path: String, threads: Int) -> Bool {
        if loadedModelPath == path, bridge != nil {
            return true
        }
        if let bridge = bridge {
            whisper_bridge_free(bridge)
            self.bridge = nil
        }

        guard let newBridge = whisper_bridge_init(path, Int32(threads)) else {
            return false
        }
        self.bridge = newBridge
        self.loadedModelPath = path
        self.threads = threads
        return true
    }

    func transcribe(wavURL: URL, language: String, prompt: String, cancelCheck: () -> Bool) -> String? {
        guard let bridge = bridge else {
            return nil
        }
        if cancelCheck() {
            return nil
        }

        let langCString = (language as NSString).utf8String
        let promptCString = prompt.isEmpty ? nil : (prompt as NSString).utf8String

        let resultPtr = whisper_bridge_transcribe_wav(bridge, wavURL.path, langCString, promptCString)
        if resultPtr == nil {
            return nil
        }
        let result = String(cString: resultPtr!)
        whisper_bridge_free_string(resultPtr)
        return cancelCheck() ? nil : result
    }

    deinit {
        if let bridge = bridge {
            whisper_bridge_free(bridge)
        }
    }
}
