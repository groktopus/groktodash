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
