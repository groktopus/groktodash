# AGENTS.md

Guide for AI coding agents working on the GroktoDash codebase.

## Project Overview

GroktoDash is a native macOS desktop client for Hermes Agent. It communicates
with a Hermes gateway via the API Server's standardized HTTP endpoints,
using the Runs API (`/v1/runs`) with SSE event streaming for real-time
interaction. **No Hermes runtime is embedded** — GroktoDash is a thin native
shell around the existing gateway.

**License:** MIT
**Organisation:** groktopus
**macOS Target:** 26.0 (Tahoe) minimum
**Swift:** 6.3+

## Architecture

```
GroktoDash.app (SwiftUI)
  └─ GroktoDashKit.framework
       ├─ HermesClient     → URLSession HTTP client
       ├─ SSESession       → Pure Swift SSE byte-stream parser
       ├─ AuthManager      → macOS Keychain wrapper
       └─ Models           → Codable API types
  └─ GroktoDashWidgets.appex   → WidgetKit extension
  └─ GroktoDashIntents.appex   → App Intents extension
         ↓ HTTP
  Hermes API Server (external gateway)
```

## Repo Structure

```
groktodash/
├── GroktoDash.xcodeproj/     # Xcode project (required for extension targets)
├── Sources/
│   ├── GroktoDash/           # App target — @main entry point, SwiftUI views
│   ├── GroktoDashKit/        # Framework — API client, models, services
│   ├── GroktoDashWidgets/    # Widget extension
│   └── GroktoDashIntents/    # App Intents extension
├── Tests/
│   └── GroktoDashKitTests/   # Unit tests
├── docs/
│   ├── prd.md                # Product Requirements Document
│   └── architecture.md       # Architecture Design Document
├── .github/
│   ├── workflows/ci.yml      # CI: build + test
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── AGENTS.md                 # This file
├── CONTRIBUTING.md           # Contribution guide
├── README.md                 # Project overview
└── LICENSE                   # MIT
```

## Key Architecture Decisions

### Thin-client model
GroktoDash does not embed Python, Hermes Agent, or any model runtime. It
communicates exclusively over HTTP with a running Hermes API Server. This
keeps the app sandbox-friendly and eliminates Python/GPL supply-chain surface.

### Runs API as primary protocol
The app drives Hermes through `/v1/runs` (asynchronous submission + SSE event
stream), not just `/v1/chat/completions`. This gives the UI structured events
for tool progress, approval requests, and streaming text.

### `.xcodeproj` (not pure SPM)
SPM packages cannot host Widget and App Intents extension targets. The Xcode
project uses SPM for dependencies (Swift AsyncAlgorithms) but the project
format itself is `.xcodeproj`.

### Apple frameworks first
Dependencies are minimised to zero where possible. The dependency policy is:
1. Apple frameworks (SwiftUI, SwiftData, WidgetKit, App Intents, etc.)
2. Apple open-source packages (Swift AsyncAlgorithms)
3. Established, audited third-party SPM packages (requires explicit approval)

### Supply chain security
- SPM with hash-pinned `Package.resolved`
- No CocoaPods, no Carthage, no binary frameworks
- App Sandbox + Hardened Runtime from day one
- Keychain for credentials (never UserDefaults or plain files)

## Making Changes

1. Create a branch from `main`
2. Make changes
3. Run CI locally: `xcodebuild -scheme GroktoDash build test`
4. Open a PR against `main`
5. Merge after review (squash-merge)

## Testing

```bash
# Build all targets
xcodebuild -scheme GroktoDash -destination 'platform=macOS' build

# Run tests
xcodebuild -scheme GroktoDash -destination 'platform=macOS' test
```

## Adding a Dependency

1. Justify in the PR description: what problem does this solve that Apple
   frameworks cannot?
2. Audit: MIT or Apache 2.0 license only. No GPL.
3. Pin to a specific commit hash in SPM.
4. Add to the dependency manifest in `docs/architecture.md`.

## Xcode Project Setup

GroktoDash uses `Package.swift` for SPM-based building and testing.  To
build and run the full app (including Widget and App Intents extensions,
which require an `.xcodeproj`), follow these steps:

1. **Open Xcode 26.5+** on macOS Tahoe.
2. **File → Open** and select `Package.swift`.  Xcode generates a workspace
   from the SPM manifest, but this only builds the library and app targets —
   not the extensions.
3. **Create the Xcode project** for extension targets:
   a. File → New → Project → macOS → App.  Name it `GroktoDash`,
      bundle ID `com.groktopus.groktodash`.
   b. Delete the generated `ContentView.swift` and `GroktoDashApp.swift` —
      our source files replace them.
   c. Add existing files: drag `Sources/GroktoDash/` into the project.
   d. Add extension targets:
      - File → New → Target → Widget Extension → name `GroktoDashWidgets`
      - File → New → Target → App Intents Extension → name `GroktoDashIntents`
      - Delete generated stub files in both extensions.
      - Add `Sources/GroktoDashWidgets/` and `Sources/GroktoDashIntents/`
        to their respective targets.
4. **Add GroktoDashKit framework target**:
   - File → New → Target → Framework → name `GroktoDashKit`
   - Add `Sources/GroktoDashKit/` to this target.
   - Mark GroktoDashKit as a dependency of the app and extension targets.
5. **Configure build settings** for each target:
   - Deployment target: macOS 26.0
   - Swift Language Version: 6
   - Enable Hardened Runtime: YES
   - Code Signing Identity: "Sign to Run Locally" (development)
6. **Assign entitlements** from `Config/`:
   - App: `GroktoDash.entitlements`
   - Widgets: `GroktoDashWidgets.entitlements`
   - Intents: `GroktoDashIntents.entitlements`
7. **Set Info.plist** for the app target to `Config/Info.plist`.
8. **Enable App Groups** in Signing & Capabilities for all three targets:
   `group.com.groktopus.groktodash`
9. **Build & Run** (⌘R).

### Entitlements Summary

| Target | Entitlements |
|--------|-------------|
| GroktoDash (app) | App Sandbox, Network Client, Keychain Access |
| GroktoDashWidgets | App Groups (`group.com.groktopus.groktodash`) |
| GroktoDashIntents | App Groups (`group.com.groktopus.groktodash`) |
| GroktoDashKit | None (framework inherits host entitlements) |

### Code Signing for Development

For local development, use "Sign to Run Locally" (no Apple Developer account
needed for basic functionality).  Keychain access, notifications, and
Spotlight require a valid signing identity — create one in Xcode → Settings
→ Accounts.

### Notarization

Notarization is handled by `.github/workflows/release.yml`.  It requires
three GitHub Actions secrets:

| Secret | Description |
|--------|-------------|
| `APPLE_ID` | Apple Developer account email |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password generated at appleid.apple.com |
| `APPLE_TEAM_ID` | 10-character team ID from developer.apple.com |

### Performance Profiling

Streaming latency is instrumented with `os_signpost` in
`EventBus+Signpost.swift`.  To profile:

1. Build with `swift build -c release`
2. Open Instruments (Xcode → Open Developer Tool → Instruments)
3. Select "os_signpost" template
4. Filter by subsystem `com.groktopus.groktodash`
5. Observe "Run Streaming" begin/end intervals and "Text Delta" events
