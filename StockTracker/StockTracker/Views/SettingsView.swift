import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: MessageFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.goldiumPalette) private var palette
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                serverSection
                connectionSection
                notificationsSection
                advancedSection
                applySection
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
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
        .environment(\.goldiumPalette, palette)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.colorScheme) {
                ForEach(AppColorScheme.allCases) { scheme in
                    Text(scheme.displayName).tag(scheme)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var serverSection: some View {
        Section("Server") {
            TextField("Server URL", text: $settings.serverBaseURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            if !settings.isServerURLValid {
                Text("Invalid URL. Use https://srelay.onrender.com")
                    .font(.caption)
                    .foregroundStyle(palette.loss)
            }

            Button("Reset to default (srelay.onrender.com)") {
                settings.resetServerURLToDefault()
            }
            .font(.caption)
        }
    }

    private var connectionSection: some View {
        Section("Connection") {
            Picker("Mode", selection: $settings.connectionMode) {
                ForEach(ConnectionMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Toggle("Use dummy data (offline testing)", isOn: $settings.useDummyData)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Notify on new messages", isOn: notificationsBinding)

            if permissionDenied {
                Text("Enable notifications for Goldium in iOS Settings.")
                    .font(.caption)
                    .foregroundStyle(palette.loss)
            }
        }
    }

    private var advancedSection: some View {
        Section("Advanced") {
            Toggle("Dev Mode", isOn: $settings.devModeEnabled)

            if settings.devModeEnabled {
                Text("Swipe left on any feed card to delete it.")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }

            LabeledContent("Keepalive") {
                Text("GET /health every 7 min")
                    .font(.caption)
            }
            Button("Clear feed", role: .destructive) {
                viewModel.clearMessages()
            }
        }
    }

    private var applySection: some View {
        Section {
            Button("Apply & Restart Connection") {
                viewModel.restart()
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
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
