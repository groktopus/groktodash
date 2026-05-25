# GroktoDash — Product Requirements Document

**Status:** Draft
**Version:** 0.1.0
**Last updated:** 2026-05-25

---

## Overview

GroktoDash is a native macOS desktop client for Hermes Agent. It provides a
rich, accessible, and secure graphical interface for interacting with a
Hermes gateway — supporting real-time streaming responses, tool execution
visibility, approval workflows, and deep macOS integration.

**What GroktoDash is:** A thin native SwiftUI shell that connects to an
external Hermes API Server over HTTP. No embedded runtime.

**What GroktoDash is not:** A replacement for Hermes Agent. A model runner.
An Electron app. A web wrapper. A cloud service. A multi-platform tool.

---

## Target User

**Primary user:** Magnus Hedemark (creator / daily driver)

**Secondary users:** macOS power users who run Hermes Agent and want a
native desktop experience instead of:
- Terminal CLI (`hermes chat`)
- Messaging gateway (Telegram, Discord)
- Web-based frontends (Open WebUI, LobeChat)

**Persona:** Technical, self-hosted, values privacy and supply chain
security. Runs a Hermes gateway on local infrastructure. Uses macOS Tahoe
as their primary workstation.

---

## Core User Stories

### P0 — Essential (must ship in M3)

**US-01: Send a prompt and see streaming responses**
> As a Hermes user, I want to type a prompt and watch the response stream
> in real time, so I can see what Hermes is doing as it thinks.

**US-02: See tool execution in real time**
> As a Hermes user, I want to see what tools Hermes runs — search queries,
> file reads, terminal commands — and their results as they happen, so I
> understand the agent's reasoning.

**US-03: Persist conversations locally**
> As a Hermes user, I want conversations to survive app restarts, so I can
> pick up where I left off.

**US-04: Connect to my gateway**
> As a Hermes user, I want to enter my gateway URL on first launch and have
> it remembered securely, so I don't re-enter it every time.

### P1 — Important (must ship in M4)

**US-05: Quick-prompt from the menu bar**
> As a Hermes user, I want to send a one-shot prompt from the menu bar
> without opening the full app, so I can get quick answers without context
> switching.

**US-06: Approve tool calls via notification**
> As a Hermes user, I want to receive a notification when Hermes wants to
> run a dangerous command, and approve or deny it inline, so I can keep
> working while Hermes handles my task.

**US-07: Search past conversations via Spotlight**
> As a Hermes user, I want to find old conversations by typing their content
> into Spotlight, so I can recover information without digging through the app.

**US-08: Siri integration**
> As a Hermes user, I want to say "Ask Hermes to summarize my inbox" and
> have the app open with the prompt loaded, so I can use voice for quick queries.

### P2 — Nice to have (M5+)

**US-09: Desktop widget showing active runs**
> As a Hermes user, I want a widget on my desktop showing my current active
> Hermes runs, so I can monitor progress at a glance.

**US-10: Conversation export**
> As a Hermes user, I want to export conversations as Markdown or JSONL
> files, for archival or sharing.

**US-11: Multiple gateway profiles**
> As a Hermes user with multiple Hermes profiles (work, personal), I want to
> switch between gateways without re-entering URLs.

### P3 — Future

**US-12: iCloud sync for conversations**
> As a multi-Mac user, I want conversations to sync across my devices.

---

## Non-Goals (Explicit Exclusions)

These are things GroktoDash will **not** do. They are excluded to prevent
scope creep and keep the project aligned with its thin-client philosophy.

| Non-goal | Rationale |
|----------|-----------|
| Embed a Hermes Agent runtime | Thin client only. Hermes lives on the gateway. |
| Run AI models locally | No model runtime. Not an inference client. |
| Support Windows or Linux | macOS only. SwiftUI is platform-locked. |
| Provide a web UI | No Electron, no WebKit views. Native only. |
| Cloud account system | No user accounts, no telemetry, no backend. |
| Plugin system (beyond Hermes skills) | Hermes skills run on the gateway. No app plugin SDK. |
| Collaboration features | Single-user app. |
| Custom theme engine | macOS system appearance only (light/dark). |
| Manage Hermes process lifecycle | The gateway is assumed to be running. App doesn't start/stop it. |
| File browser or terminal pane | Hermes tools execute on the gateway. No local file/terminal UI. |

---

## Success Criteria

| Criterion | Metric | Target |
|-----------|--------|--------|
| Streaming responsiveness | Time from SSE `text_delta` event to on-screen text | < 100ms |
| Approval UX | Time from gateway approval request to notification delivery | < 500ms |
| Conversation search | Spotlight result return after indexing | < 1s for recent conversations |
| Memory footprint | App memory usage (idle, one active conversation) | < 200 MB |
| Launch time | Cold launch to usable state | < 2s on Apple Silicon |
| Build time | `xcodebuild build` from clean | < 120s |
| Accessibility | VoiceOver audits | 0 critical issues |

---

## Functional Requirements

### FR-01: Gateway Connectivity

- User enters a gateway base URL (e.g. `http://auriga.local:8642`) on first launch
- URL stored in macOS Keychain (not UserDefaults, not a config file)
- App tests connectivity via `GET /health`
- Connection status shown in the UI (connected / unreachable / unauthorized)
- Error states: network timeout, DNS failure, auth rejection, API version mismatch

### FR-02: Chat Interface

- Scrollable message list with auto-scroll to bottom on new messages
- Input bar with send button and Enter-key binding
- Streaming text: response text accumulates token-by-token from SSE events
- Markdown rendering: bold, italic, code blocks, lists, blockquotes (via `AttributedString`)
- Code blocks rendered with a monospace font and distinct visual treatment
- Message metadata: timestamp, tool call count

### FR-03: Tool Execution Visibility

- Tool calls displayed in a timeline panel alongside the chat view
- Each tool call shows:
  - Tool name and arguments
  - Execution status (running / complete / error)
  - Result preview (expandable)
- Approval-required tool calls highlighted visually
- Tool errors shown with distinct styling

### FR-04: Approval Workflow

- When a tool call requires approval, the app receives an `approval_request` SSE event
- A native macOS notification is delivered with Approve and Deny action buttons
- Clicking the notification opens the app to the approval sheet
- User can approve once, approve for the session, or deny
- Decision is sent back to the gateway via `POST /v1/runs/{id}/approval`

### FR-05: Conversation Persistence

- Conversations stored locally via SwiftData
- Model entities: Conversation, Message, ToolCall, Run
- Conversations can be renamed, deleted, and searched (in-app)
- Conversation list in sidebar: searchable, sortable by date
- Messages are attributed to user or Hermes

### FR-06: Menu Bar Quick-Prompt

- MenuBarExtra shows an icon in the macOS menu bar
- Clicking opens a popover with a text input
- Submitting a prompt creates a new run and streams the response in the popover
- Popover can be expanded to the full app window
- Option to run in background (app doesn't come to foreground)

### FR-07: macOS Integration

- **WidgetKit:** Medium and large widgets showing recent conversations and active runs
- **App Intents:** "Ask Hermes" intent available in Shortcuts and Siri
- **CoreSpotlight:** Conversations indexed with content, title, and date
- **UserNotifications:** Approval requests delivered as actionable notifications
- **NSDocument (future):** Conversation file format for Finder integration

### FR-08: Security

- API key and gateway URL stored exclusively in macOS Keychain
- App runs in App Sandbox (network client entitlement only)
- Hardened Runtime enabled for Gatekeeper notarization
- No telemetry, no analytics, no crash reporting service (crashes stay local)
- No embedded web views (no JavaScript execution surface)
- All network requests go to the configured gateway URL only (no other outbound)

---

## macOS Tahoe (26) Feature Map

| Apple Technology | User Story Served | Priority |
|-----------------|-------------------|----------|
| SwiftUI + `@Observable` | US-01, US-02, US-03 | P0 |
| SwiftData | US-03 | P0 |
| URLSession async/await | US-01, US-04 | P0 |
| Security.framework (Keychain) | US-04, FR-08 | P0 |
| MenuBarExtra | US-05 | P1 |
| UserNotifications + UNNotificationAction | US-06 | P1 |
| CoreSpotlight + CSSearchableItem | US-07 | P1 |
| App Intents + SiriKit | US-08 | P1 |
| WidgetKit | US-09 | P2 |
| CloudKit (via SwiftData) | US-12 | P3 |

---

## Dependency Policy

GroktoDash is a **zero-dependency project by default**. Any addition must:

1. Be licensed MIT or Apache 2.0 (no GPL, no AGPL, no SSPL)
2. Be available via Swift Package Manager
3. Have a written justification in the PR and in `docs/architecture.md`
4. Be approved explicitly — no silent dependency addition

**Pre-approved (if needed):**
- `swift-async-algorithms` (Apple, Apache 2.0) — only if SSE splitting requires
  `AsyncSequence` combinators beyond what URLSession + manual parsing provides

**Explicitly prohibited:**
- Any package with a GPL-family license
- CocoaPods (supply chain surface)
- Carthage (binary distribution, impairs auditability)
- Binary `.xcframework` packages
- Any package that phones home or includes analytics
