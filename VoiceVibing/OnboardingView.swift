import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .permissions
    @State private var testInput: String = ""
    @FocusState private var testFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.title)
                .font(.title2)

            Text(step.subtitle)
                .foregroundStyle(.secondary)

            switch step {
            case .permissions:
                VStack(alignment: .leading, spacing: 8) {
                    Label("Microphone access", systemImage: "mic")
                    Label("Accessibility access", systemImage: "lock")
                }

                HStack(spacing: 12) {
                    Button("Open Microphone Settings") {
                        PermissionsService.shared.openSystemSettingsPrivacy(path: "Privacy_Microphone")
                    }
                    Button("Request Accessibility") {
                        let granted = PermissionsService.shared.requestAccessibility()
                        if !granted {
                            PermissionsService.shared.openSystemSettingsPrivacy(path: "Privacy_Accessibility")
                        }
                    }
                }

            case .shortcut:
                VStack(alignment: .leading, spacing: 8) {
                    Text("1) Click the shortcut field in Settings and set your key.")
                    Text("2) Press the shortcut once to start recording.")
                    Text("3) Press it again to stop and transcribe.")
                }

            case .test:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alright, it’s all set. Let’s test it now.")
                    Text("Click the shortcut and speak. I’ll paste the output into the active input below.")

                    TextField("Test output will appear here…", text: $testInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($testFieldFocused)
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
                    if step == .test {
                        appState.showOnboarding = false
                    } else {
                        step = step.next()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
        .onAppear {
            if step == .test {
                testFieldFocused = true
            }
        }
        .onChange(of: step) { newValue in
            if newValue == .test {
                testFieldFocused = true
            }
        }
    }
}

enum OnboardingStep {
    case permissions
    case shortcut
    case test

    var title: String {
        switch self {
        case .permissions:
            return "Welcome to VoiceVibing"
        case .shortcut:
            return "Set your shortcut"
        case .test:
            return "Test it"
        }
    }

    var subtitle: String {
        switch self {
        case .permissions:
            return "To record and paste text into other apps, please grant permissions."
        case .shortcut:
            return "You’ll use the shortcut to start and stop recording."
        case .test:
            return "We’ll paste into the field below."
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .test:
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
            return .test
        case .test:
            return .test
        }
    }

    func previous() -> OnboardingStep {
        switch self {
        case .permissions:
            return .permissions
        case .shortcut:
            return .permissions
        case .test:
            return .shortcut
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
