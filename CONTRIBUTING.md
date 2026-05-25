# Contributing to GroktoDash

## Workflow

1. **File an issue** — all changes (features, fixes, docs) start with an issue.
   Use the issue templates in `.github/ISSUE_TEMPLATE/`.
2. **Branch** from `main` — use a descriptive branch name: `fix/sse-parsing`,
   `feat/menu-bar-popover`, `docs/prd`.
3. **Implement** — follow the architecture decisions in `docs/architecture.md`.
4. **Test** — `xcodebuild -scheme GroktoDash -destination 'platform=macOS' test`
5. **PR** — open a pull request against `main`. Fill out the PR template.
6. **Review** — at least one review is required before merge.
7. **Squash-merge** — all PRs are squashed into a single commit on `main`.

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type: concise subject line

Optional body explaining the why, not the what.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`

Examples:
- `feat: add SSESession with pure Swift byte-stream parser`
- `fix: handle SSE connection timeout with exponential backoff`
- `docs: add data flow diagram for tool call approval path`

## DCO

All commits must be signed off:

```
Signed-off-by: Name <email>
```

## Dependency Policy

GroktoDash aims for zero third-party dependencies. Any addition must:

1. Be MIT or Apache 2.0 licensed — **no GPL**
2. Be available via SPM with a stable tag or commit hash
3. Have a written justification explaining why an Apple framework cannot
   solve the same problem
4. Be listed in `docs/architecture.md` under the Dependency Manifest

Pre-approved dependencies:
- `swift-async-algorithms` (Apple OSS, Apache 2.0) — only if SSE splitting
  requires it beyond what URLSession + manual parsing can do

## Code Style

- Swift 6.3+, macOS 26.0 minimum deployment
- `@MainActor` for all UI code
- `async/await` for all networking (no completion handlers)
- `Codable` for all API models
- `@Observable` macro for view models (SwiftData compatible)
- No force-unwrapping in production code

## License

By contributing, you agree that your contributions will be licensed under
the MIT License.
