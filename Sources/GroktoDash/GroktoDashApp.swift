import SwiftUI
import SwiftData

@main
struct GroktoDashApp: App {
    @State private var eventBus: EventBus?

    var body: some Scene {
        WindowGroup {
            if let bus = eventBus {
                ContentView()
                    .environment(bus)
            } else {
                GatewaySettingsView { url, apiKey in
                    let schema = Schema([Conversation.self, Message.self, ToolCall.self, Run.self])
                    let config = ModelConfiguration(isStoredInMemoryOnly: false)
                    guard let container = try? ModelContainer(for: schema, configurations: config) else {
                        return
                    }
                    let context = container.mainContext
                    let bus = EventBus(modelContext: context)
                    bus.connect(baseURL: url, apiKey: apiKey.isEmpty ? nil : apiKey)
                    eventBus = bus
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    eventBus?.newConversation()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            SidebarCommands()
        }

        MenuBarExtra("GroktoDash", systemImage: "brain.head.profile") {
            if let bus = eventBus {
                MenuBarPopover()
                    .environment(bus)
            }
        }
    }
}

/// Post-connection content — sidebar + chat.
struct ContentView: View {
    @Environment(EventBus.self) private var bus

    var body: some View {
        Group {
            if bus.connectionStatus == .disconnected {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Gateway Unreachable")
                        .font(.title2)
                    if let error = bus.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Retry") {
                        // Reconnect would need stored URL
                    }
                    .buttonStyle(.bordered)
                }
                .frame(width: 400, height: 300)
            } else {
                ChatView()
            }
        }
    }
}
