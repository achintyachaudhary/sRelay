import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: MessageFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false

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

                Section("Notifications") {
                    Toggle("Notify on new messages", isOn: notificationsBinding)

                    if permissionDenied {
                        Text("Notifications are disabled in iOS Settings. Enable them for Stock Tracker to receive alerts.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if settings.notificationsEnabled {
                        Text("You'll get a notification whenever the server pushes a new message.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            .task {
                await refreshPermissionStatus()
            }
        }
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                if newValue {
                    Task { await enableNotifications() }
                } else {
                    settings.notificationsEnabled = false
                    permissionDenied = false
                }
            }
        )
    }

    private func enableNotifications() async {
        let granted = await NotificationService.shared.requestPermission()
        if granted {
            settings.notificationsEnabled = true
            permissionDenied = false
        } else {
            settings.notificationsEnabled = false
            permissionDenied = true
        }
    }

    private func refreshPermissionStatus() async {
        let status = await NotificationService.shared.authorizationStatus()
        permissionDenied = settings.notificationsEnabled && status == .denied
        if status == .denied {
            settings.notificationsEnabled = false
        }
    }
}
