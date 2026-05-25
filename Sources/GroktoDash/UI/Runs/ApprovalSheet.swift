import SwiftUI

/// Inline tool call approval sheet.
struct ApprovalSheet: View {
    @Environment(EventBus.self) private var bus

    let runId: String
    let tool: String
    let choices: [String]

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Approve Tool Call")
                .font(.headline)

            Text("Hermes wants to run **\(tool)**")
                .font(.body)
                .multilineTextAlignment(.center)

            Text("This action may modify files or execute commands.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if choices.contains("once") {
                    Button("Allow Once") {
                        bus.resolveApproval(choice: .once)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if choices.contains("session") {
                    Button("Allow Session") {
                        bus.resolveApproval(choice: .session)
                    }
                    .buttonStyle(.bordered)
                }
                if choices.contains("deny") {
                    Button("Deny") {
                        bus.resolveApproval(choice: .deny)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }

            if choices.contains("always") {
                Button("Always Allow") {
                    bus.resolveApproval(choice: .always)
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
        .padding(30)
        .frame(width: 350)
    }
}
