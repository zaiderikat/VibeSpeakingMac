import AppKit
import KeyboardShortcuts
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .permissions
    @StateObject private var onboardingActions = OnboardingActionService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.title)
                .font(.title2)

            Text(step.subtitle)
                .foregroundStyle(.secondary)

            switch step {
            case .permissions:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step 1 — Start a short recording")
                        .font(.headline)
                    Text("Click Start Recording to trigger the microphone permission prompt. Click Stop to finish.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button(onboardingActions.isRecording ? "Stop Recording" : "Start Recording") {
                            if onboardingActions.isRecording {
                                onboardingActions.stopAndTranscribe()
                            } else {
                                onboardingActions.startRecording()
                            }
                        }
                        Spacer()
                    }

                    Text("Step 2 — Grant Microphone permission")
                        .font(.headline)
                    Text("Open Microphone settings and enable Solif: Speech to Text.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Open Microphone Settings") {
                            PermissionsService.shared.openSystemSettingsPrivacy(path: "Privacy_Microphone")
                        }
                        Spacer()
                    }

                    Text("Step 3 — Grant Accessibility permission")
                        .font(.headline)
                    Text("Open Accessibility settings and enable Solif: Speech to Text for auto‑paste.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Open Accessibility Settings") {
                            PermissionsService.shared.openSystemSettingsPrivacy(path: "Privacy_Accessibility")
                        }
                        Spacer()
                    }

                    Text("If Accessibility looks enabled but paste fails, add the running app from its build location.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button("Reveal App in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                    }
                }

            case .shortcut:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set your shortcut below. Press it once to start recording and again to stop and paste.")
                    HStack {
                        Text("Push-to-talk")
                        Spacer()
                        KeyboardShortcuts.Recorder(for: .pushToTalk)
                    }
                    .padding(.top, 4)

                    if appState.isRecording {
                        Label("Recording…", systemImage: "record.circle")
                            .foregroundStyle(.red)
                    } else if appState.isTranscribing {
                        Label("Transcribing…", systemImage: "hourglass")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Idle", systemImage: "waveform")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            HStack {
                if step != .permissions {
                    Button("Back") {
                        step = step.previous()
                    }
                }

                Spacer()

                Button(step.primaryButtonTitle) {
                    if step == .shortcut {
                        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
                        appState.showOnboarding = false
                    } else {
                        step = step.next()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 520)
    }
}

enum OnboardingStep {
    case permissions
    case shortcut

    var title: String {
        switch self {
        case .permissions:
            return "Welcome to VoiceVibing"
        case .shortcut:
            return "Set your shortcut"
        }
    }

    var subtitle: String {
        switch self {
        case .permissions:
            return "To record and paste text into other apps, please grant permissions."
        case .shortcut:
            return "You’ll use the shortcut to start and stop recording."
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .shortcut:
            return "Finish"
        default:
            return "Continue"
        }
    }

    func next() -> OnboardingStep {
        switch self {
        case .permissions:
            return .shortcut
        case .shortcut:
            return .shortcut
        }
    }

    func previous() -> OnboardingStep {
        switch self {
        case .permissions:
            return .permissions
        case .shortcut:
            return .permissions
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
