import SwiftUI

/// Stub — conversation sidebar (M3).
struct ConversationList: View {
    var body: some View {
        List {
            Text("No conversations yet")
                .foregroundStyle(.secondary)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}
