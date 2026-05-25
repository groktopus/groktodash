import SwiftUI

/// Main chat interface — message list with streaming + tool timeline.
struct ChatView: View {
    @Environment(EventBus.self) private var bus

    var body: some View {
        HSplitView {
            ConversationList()
                .frame(minWidth: 220)

            VStack(spacing: 0) {
                // Message area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if let conv = bus.currentConversation {
                                ForEach(conv.messages.sorted(by: { $0.timestamp < $1.timestamp })) { msg in
                                    MessageBubbleView(message: msg)
                                        .id(msg.id)
                                }
                            }

                            // Streaming message
                            if let streaming = bus.streamingMessage {
                                MessageBubbleView(message: streaming)
                                    .id("streaming")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: bus.streamingMessage?.content ?? "") { _, _ in
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                    .onChange(of: bus.currentConversation?.messages.count ?? 0) { _, _ in
                        if let last = bus.currentConversation?.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()

                // Tool timeline (collapsible)
                if !bus.toolCalls.isEmpty {
                    RunTimelineView()
                        .frame(height: 120)
                    Divider()
                }

                // Input
                InputBar()

                // Status bar
                HStack {
                    Circle()
                        .fill(bus.connectionStatus == .connected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if bus.isRunning {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Running…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .sheet(item: approvalBinding) { approval in
            ApprovalSheet(
                runId: approval.runId,
                tool: approval.tool,
                choices: approval.choices
            )
        }
    }

    private var statusText: String {
        switch bus.connectionStatus {
        case .connected: return "Connected"
        case .connecting: return "Connecting…"
        case .disconnected: return "Disconnected"
        }
    }

    private var approvalBinding: Binding<ApprovalData?> {
        Binding(
            get: {
                guard let a = bus.pendingApproval else { return nil }
                return ApprovalData(runId: a.runId, tool: a.tool, choices: a.choices)
            },
            set: { _ in }
        )
    }
}

struct ApprovalData: Identifiable {
    let runId: String
    let tool: String
    let choices: [String]
    var id: String { runId }
}
