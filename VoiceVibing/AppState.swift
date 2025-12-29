import Combine

final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
}
