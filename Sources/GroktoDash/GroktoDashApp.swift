import SwiftUI

@main
struct GroktoDashApp: App {
    @State private var gatewayURL: String = UserDefaults.standard.string(forKey: "gatewayURL") ?? ""

    var body: some Scene {
        WindowGroup {
            if gatewayURL.isEmpty {
                GatewaySettingsView(gatewayURL: $gatewayURL)
            } else {
                ChatView(gatewayURL: gatewayURL)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)

        MenuBarExtra("GroktoDash", systemImage: "brain.head.profile") {
            MenuBarPopover()
        }
    }
}
