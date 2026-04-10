import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Claude API") {
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                Text("Get your key from console.anthropic.com")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Company Context") {
                TextEditor(text: $settings.companyContext)
                    .frame(minHeight: 120)
                    .font(.body)
                Text("Paste info about your company here. This helps generate more relevant definitions. E.g., company overview, product descriptions, team structure.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }
}
