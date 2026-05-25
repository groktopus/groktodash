import SwiftUI
import SwiftData

/// Sidebar conversation list — SwiftData-backed, searchable.
struct ConversationList: View {
    @Environment(EventBus.self) private var bus
    @State private var searchText = ""

    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return bus.conversations
        }
        return bus.conversations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List(selection: Binding(
            get: { bus.currentConversation?.id },
            set: { id in
                if let id, let conv = bus.conversations.first(where: { $0.id == id }) {
                    bus.selectConversation(conv)
                }
            }
        )) {
            Section {
                Button(action: { bus.newConversation() }) {
                    Label("New Conversation", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }

            Section("Conversations") {
                if filteredConversations.isEmpty {
                    Text("No conversations yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(filteredConversations) { conv in
                        ConversationRow(conversation: conv)
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    bus.deleteConversation(conv)
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "Search conversations…")
    }
}

/// Single row in the conversation list.
struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(conversation.title)
                .font(.body)
                .lineLimit(1)

            HStack {
                Text(conversation.messages.last?.content.prefix(60) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .tag(conversation.id)
    }
}
