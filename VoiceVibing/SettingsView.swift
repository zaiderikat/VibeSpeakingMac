import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    private let models = ["tiny", "base", "small"]

    @AppStorage("modelName") private var modelName: String = "tiny"
    @AppStorage("languageCode") private var languageCode: String = "en"
    @AppStorage("outputMode") private var outputMode: String = OutputMode.paste.rawValue
    @AppStorage("promptText") private var promptText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VoiceVibing Settings")
                .font(.headline)

            GroupBox(label: Text("Shortcut")) {
                HStack {
                    Text("Push-to-talk")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .pushToTalk)
                }
                .padding(.top, 4)
            }

            GroupBox(label: Text("Model")) {
                Picker("Model", selection: $modelName) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.segmented)
            }

            GroupBox(label: Text("Language")) {
                TextField("Language code", text: $languageCode)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 180)
            }

            GroupBox(label: Text("Prompt (optional)")) {
                TextField("Initial prompt", text: $promptText)
                    .textFieldStyle(.roundedBorder)
            }

            GroupBox(label: Text("Output")) {
                Picker("Output mode", selection: $outputMode) {
                    ForEach(OutputMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 360)
    }
}

enum OutputMode: String, CaseIterable, Identifiable {
    case paste
    case type

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paste:
            return "Paste (clipboard + Cmd+V)"
        case .type:
            return "Type (key events)"
        }
    }
}

#Preview {
    SettingsView()
}
