import SwiftUI

/// Stub — main chat view (M3).
struct ChatView: View {
    let gatewayURL: String

    var body: some View {
        HSplitView {
            ConversationList()
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Chat area — M3")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                InputBar()
            }
        }
    }
}
