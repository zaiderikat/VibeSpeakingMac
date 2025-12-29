import Combine

final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var showOnboarding = true
    @Published var cancelTranscription = false
}
