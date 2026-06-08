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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        GoldiumStatusAvatar(isConnected: viewModel.isServerConnected)
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
        List {
            if let error = viewModel.lastError {
                errorBanner(error)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.messages) { message in
                FeedCardView(
                    message: message,
                    isNew: viewModel.isNewMessage(message.id)
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: settings.devModeEnabled) {
                    if settings.devModeEnabled {
                        Button(role: .destructive) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                viewModel.deleteMessage(id: message.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(settings.palette.background)
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
            GoldiumStatusAvatar(isConnected: viewModel.isServerConnected, size: 56)
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
