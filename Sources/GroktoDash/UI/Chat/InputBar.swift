import SwiftUI

/// Prompt input bar with send button and keyboard shortcut.
struct InputBar: View {
    @Environment(EventBus.self) private var bus
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ask Hermes anything…", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isFocused)
                .onSubmit { send() }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(bus.isRunning)
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your prompt and press Return to send")

            if bus.isRunning {
                Button(action: { bus.stopRun() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Stop run")
                .accessibilityLabel("Stop Hermes")
                .accessibilityHint("Stop the currently running Hermes task")
            } else {
                Button(action: { send() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(text.isEmpty ? .secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty || bus.connectionStatus != .connected)
                .keyboardShortcut(.return, modifiers: [])
                .help("Send (Return)")
                .accessibilityLabel("Send message")
                .accessibilityHint("Send your prompt to Hermes")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .onAppear { isFocused = true }
    }

    private func send() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        bus.send(text)
        text = ""
    }
}
