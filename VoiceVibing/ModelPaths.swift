import Foundation

enum ModelPaths {
    static func bundledModelURL(for name: String) -> URL? {
        let filename: String
        switch name {
        case "base":
            filename = "ggml-base.en"
        case "small":
            filename = "ggml-small.en"
        default:
            filename = "ggml-tiny.en"
        }
        return Bundle.main.url(forResource: filename, withExtension: "bin", subdirectory: "Models")
    }

    static func modelsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("VoiceVibing", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func modelPath(for name: String) -> URL {
        if let bundled = bundledModelURL(for: name) {
            return bundled
        }

        let filename: String
        switch name {
        case "base":
            filename = "ggml-base.en.bin"
        case "small":
            filename = "ggml-small.en.bin"
        default:
            filename = "ggml-tiny.en.bin"
        }
        return modelsDirectory().appendingPathComponent(filename)
    }
}
