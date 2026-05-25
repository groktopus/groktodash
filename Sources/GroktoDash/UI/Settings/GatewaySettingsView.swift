import SwiftUI

/// Stub — Settings view for entering gateway URL (M3).
struct GatewaySettingsView: View {
    @Binding var gatewayURL: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Connect to Hermes")
                .font(.title)

            TextField("Gateway URL (e.g. http://auriga.local:8642)", text: $gatewayURL)
                .textFieldStyle(.roundedBorder)
                .frame(width: 350)

            Button("Connect") {
                UserDefaults.standard.set(gatewayURL, forKey: "gatewayURL")
            }
            .keyboardShortcut(.return)
            .disabled(gatewayURL.isEmpty)
        }
        .padding(60)
        .frame(width: 500, height: 300)
    }
}
