import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: MessageFeedViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Host / IP", text: $settings.serverHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("Port", text: $settings.serverPort)
                        .keyboardType(.numberPad)
                }

                Section("Connection") {
                    Picker("Mode", selection: $settings.connectionMode) {
                        ForEach(ConnectionMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    Toggle("Use dummy data (until BE is ready)", isOn: $settings.useDummyData)
                }

                Section("API Reference") {
                    LabeledContent("Polling") {
                        Text("GET /api/v1/messages?since_id={id}")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("WebSocket") {
                        Text("ws://host:port/ws/messages")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("See API_CONTRACT.md in the project for full request/response samples.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Apply & Restart Connection") {
                        viewModel.restart()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
