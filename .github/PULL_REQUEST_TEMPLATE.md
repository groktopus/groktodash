## Description

<!-- Brief summary of the change -->

## Type of Change

- [ ] Bug fix (`fix:`)
- [ ] New feature (`feat:`)
- [ ] Documentation (`docs:`)
- [ ] Refactor (`refactor:`)
- [ ] Test (`test:`)
- [ ] CI/CD (`ci:`)
- [ ] Chore (`chore:`)

## Related Issues

<!-- Link to issues this PR addresses: Closes #N -->

## Checklist

- [ ] Code compiles: `xcodebuild -scheme GroktoDash build`
- [ ] Tests pass: `xcodebuild -scheme GroktoDash test`
- [ ] New tests added for new functionality
- [ ] No new third-party dependencies without explicit approval
- [ ] If adding a dependency: license is MIT or Apache 2.0 (no GPL)
- [ ] Architecture decisions documented in `docs/architecture.md` if applicable
- [ ] User-facing strings use `String(localized:)` for future localization
- [ ] Accessibility: new views work with VoiceOver
- [ ] DCO sign-off present on all commits

## macOS Compatibility

- [ ] Minimum deployment target is macOS 26.0
- [ ] New APIs have `@available(macOS 26, *)` guards where needed
- [ ] Sandbox entitlements reviewed (no new network/read/write without audit)
