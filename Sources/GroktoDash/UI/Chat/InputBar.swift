import SwiftUI

/// Stub — prompt input bar (M3).
struct InputBar: View {
    @State private var text = ""

    var body: some View {
        HStack {
            TextField("Ask Hermes anything...", text: $text)
                .textFieldStyle(.roundedBorder)
            Button("Send") {
                // M3: send to EventBus
                text = ""
            }
            .keyboardShortcut(.return)
            .disabled(text.isEmpty)
        }
        .padding()
    }
}
