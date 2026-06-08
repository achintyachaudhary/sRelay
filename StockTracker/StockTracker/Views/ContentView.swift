import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel = MessageFeedViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                settings.palette.background.ignoresSafeArea()

                Group {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        feedList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    GoldiumWordmark()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(settings.palette.secondaryText)
                    }
                }
            }
            .toolbarBackground(settings.palette.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, viewModel: viewModel)
                    .environment(\.goldiumPalette, settings.palette)
            }
            .environment(\.goldiumPalette, settings.palette)
            .preferredColorScheme(settings.colorScheme.swiftUIColorScheme)
            .onAppear {
                viewModel.configure(settings: settings)
                viewModel.start()
            }
            .onChange(of: settings.connectionMode) { _, _ in viewModel.restart() }
            .onChange(of: settings.useDummyData) { _, _ in viewModel.restart() }
            .onChange(of: settings.serverBaseURL) { _, _ in viewModel.restart() }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let error = viewModel.lastError {
                    errorBanner(error)
                }

                ForEach(viewModel.messages) { message in
                    FeedCardView(
                        message: message,
                        isNew: viewModel.isNewMessage(message.id)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider()
                        .overlay(settings.palette.divider)
                        .padding(.leading, 16)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .refreshable {
            viewModel.restart()
        }
    }

    private func errorBanner(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error)
                .font(.caption)
            Spacer()
            Button("Retry") { viewModel.restart() }
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(settings.palette.loss)
        .padding(12)
        .background(settings.palette.mutedLoss)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            GoldiumLogo(size: 64)
            Text("Your market feed")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(settings.palette.primaryText)
            Text("Alerts and end-of-day summaries will appear here as they arrive over WebSocket.")
                .font(.subheadline)
                .foregroundStyle(settings.palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            if !settings.useDummyData {
                Text(viewModel.keepaliveStatus)
                    .font(.caption)
                    .foregroundStyle(settings.palette.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
