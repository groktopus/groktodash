import SwiftUI

/// Stub — menu bar popover for quick prompts (M3).
struct MenuBarPopover: View {
    @State private var text = ""

    var body: some View {
        VStack(spacing: 8) {
            TextField("Quick prompt...", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Button("Send") {
                    // M3: send to EventBus
                    text = ""
                }
                .keyboardShortcut(.return)
                .disabled(text.isEmpty)

                Button("Open in App") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
            }
        }
        .padding()
    }
}
