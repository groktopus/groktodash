import SwiftUI

/// Individual message bubble — user vs Hermes styling.
struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .hermes {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                if message.role == .hermes && message.isStreaming {
                    StreamingRenderer(text: message.content)
                } else {
                    MarkdownText(content: message.content)
                }

                // Tool call badges
                if !message.toolCalls.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.toolCalls) { tc in
                            ToolCallBadge(toolCall: tc)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(10)
            .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if message.role == .user {
                Spacer(minLength: 40)
            } else {
                Spacer()
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Live streaming text — shows content with a blinking cursor.
struct StreamingRenderer: View {
    let text: String

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            MarkdownText(content: text)
            if cursorVisible {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 16)
                    .opacity(0.8)
                    .padding(.leading, 1)
            }
        }
        .onAppear {
            cursorVisible = true
        }
    }
}

/// Basic Markdown rendering via AttributedString.
struct MarkdownText: View {
    let content: String

    var body: some View {
        if let attributed = try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attributed)
                .textSelection(.enabled)
        } else {
            Text(content)
                .textSelection(.enabled)
        }
    }
}

/// Compact badge for a tool call in the message bubble.
struct ToolCallBadge: View {
    let toolCall: ToolCall

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(toolCall.toolName)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var icon: String {
        switch toolCall.status {
        case .running: return "hourglass"
        case .completed: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch toolCall.status {
        case .running: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
}
