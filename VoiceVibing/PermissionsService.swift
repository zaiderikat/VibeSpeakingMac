import AppKit
import AVFoundation
import ApplicationServices

enum PermissionStatus: String {
    case granted
    case denied
    case notDetermined
}

final class PermissionsService {
    static let shared = PermissionsService()

    func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestMicrophone(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func accessibilityStatus() -> PermissionStatus {
        return AXIsProcessTrusted() ? .granted : .denied
    }

    func requestAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettingsPrivacy(path: String) {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?" + path
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
