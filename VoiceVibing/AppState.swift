import Combine
import Foundation

private let onboardingCompletedKey = "didCompleteOnboarding"

final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var showOnboarding: Bool
    @Published var cancelTranscription = false

    init() {
        let completed = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        let micGranted = PermissionsService.shared.microphoneStatus() == .granted
        let accessibilityGranted = PermissionsService.shared.accessibilityStatus() == .granted
        showOnboarding = !(completed && micGranted && accessibilityGranted)
    }
}
