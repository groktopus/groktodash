import SwiftUI

/// Initial setup — enter gateway URL and optional API key.
struct GatewaySettingsView: View {
    let onConnect: (URL, String) -> Void

    @State private var urlString = "http://localhost:8642"
    @State private var apiKey = ""
    @State private var isValid = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Connect to Hermes")
                .font(.title)
                .fontWeight(.semibold)

            Text("Enter the URL of your Hermes API Server")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Gateway URL (e.g. http://auriga.local:8642)", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 360)
                    .onChange(of: urlString) { _, newValue in
                        isValid = URL(string: newValue)?.host != nil
                    }

                SecureField("API Key (optional)", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 360)
            }

            Button("Connect") {
                guard let url = URL(string: urlString) else { return }
                onConnect(url, apiKey)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            .keyboardShortcut(.return)

            Text("Hermes API Server must be running with API_SERVER_ENABLED=true")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(60)
        .frame(width: 480, height: 380)
    }
}
