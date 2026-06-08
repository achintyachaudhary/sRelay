import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel = MessageFeedViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }
            }
            .navigationTitle("Stock Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.isRunning {
                        Button("Stop") { viewModel.stop() }
                    } else {
                        Button("Start") { viewModel.start() }
                    }

                    Menu {
                        Button("Clear messages", role: .destructive) {
                            viewModel.clearMessages()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                statusBar
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, viewModel: viewModel)
            }
            .onAppear {
                viewModel.configure(settings: settings)
                viewModel.start()
            }
            .onChange(of: settings.connectionMode) { _, _ in
                viewModel.restart()
            }
            .onChange(of: settings.useDummyData) { _, _ in
                viewModel.restart()
            }
        }
    }

    private var statusBar: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(viewModel.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if settings.useDummyData {
                    Text("DUMMY")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else {
                    Text(settings.connectionMode == .polling ? "POLL 5s" : "WS")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }

            if let lastID = viewModel.lastMessageID {
                Text("Last ID: \(lastID)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let error = viewModel.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.messages) { message in
                    MessageCardView(message: message)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Waiting for messages…")
                .font(.headline)
            Text("The app polls or listens via WebSocket every 5 seconds. Dummy data is enabled by default.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
