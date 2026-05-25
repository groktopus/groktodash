import SwiftUI
import GroktoDashKit

/// Menu bar popover for quick one-shot Hermes prompts.
struct MenuBarPopover: View {
    @Environment(EventBus.self) private var bus
    @State private var text = ""
    @State private var response = ""
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 8) {
            if !response.isEmpty {
                ScrollView {
                    Text(response)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(.horizontal, 8)
            }

            HStack(spacing: 6) {
                TextField("Quick prompt…", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                    .disabled(isRunning)
                    .onSubmit { send() }

                if isRunning {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Button("Send") { send() }
                        .buttonStyle(.borderedProminent)
                        .disabled(text.isEmpty)
                }
            }

            HStack {
                Button("Open Full App") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.link)
                .font(.caption)

                Spacer()

                if !response.isEmpty {
                    Button("Clear") {
                        response = ""
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func send() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let client = bus.client else { return }

        isRunning = true
        let prompt = text
        text = ""
        response = ""

        Task {
            do {
                let runRequest = CreateRunRequest(prompt: prompt)
                let run = try await client.createRun(runRequest)
                let events = client.events(for: run.id)
                for await event in events {
                    if case .textDelta(_, let text) = event {
                        response += text
                    }
                    if case .runCompleted = event { break }
                    if case .runFailed = event { break }
                }
            } catch {
                response = "Error: \(error.localizedDescription)"
            }
            isRunning = false
        }
    }
}
