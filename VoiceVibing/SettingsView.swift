import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VoiceVibing Settings")
                .font(.headline)
            Text("Configure shortcut, model, and output preferences here.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 360, minHeight: 200)
    }
}

#Preview {
    SettingsView()
}
