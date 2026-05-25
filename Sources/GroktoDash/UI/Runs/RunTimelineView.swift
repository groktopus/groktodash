import SwiftUI

/// Real-time tool execution timeline — driven by EventBus.
struct RunTimelineView: View {
    @Environment(EventBus.self) private var bus

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(bus.toolCalls) { tc in
                    ToolCallCard(toolCall: tc)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}

/// Individual tool call card in the timeline.
struct ToolCallCard: View {
    let toolCall: ToolCall

    var body: some View {
        HStack(spacing: 6) {
            // Status icon
            Group {
                switch toolCall.status {
                case .running:
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(toolCall.toolName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(toolCall.preview)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let duration = toolCall.duration {
                Text(String(format: "%.1fs", duration))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statusLabel) \(toolCall.toolName)")
        .accessibilityHint(toolCall.preview)
    }

    private var statusLabel: String {
        switch toolCall.status {
        case .running: return "Running"
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }
}
