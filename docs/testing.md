# Testing

English · [繁體中文](zh-TW/testing.md)

Berth keeps operating-system integration in the `Berth` executable and testable decisions in `BerthCore`. The automated baseline protects display-edge geometry and guard reconciliation without mocking Accessibility, AppKit, or Core Graphics event delivery.

## Automated baseline

Run the same checks used by the `Test baseline` GitHub Actions job:

```sh
swift build
swift test --enable-code-coverage
./Scripts/check_coverage.sh 90
./Scripts/build.sh
```

`BerthCore` must maintain at least 90% line coverage. The executable and its operating-system adapters must compile, but they are excluded from the percentage gate. Every `BerthCore` behavior change and bug fix should add or update a test through a public `BerthCore` interface.

`Scripts/build.sh` also rejects missing keys and incomplete declared locales before compiling the String Catalog. It then checks the assembled App bundle for English and Taiwan Traditional Chinese resources, exact lookups, formatted values, and English fallback from an unsupported locale. This finished-bundle check covers the same main-bundle resource path used by Launch at Login.

The workflow runs for every pull request and every push to `main`. Configure `Test baseline` as a required check in the repository ruleset after its first successful run.

## Localization verification

For each supported App language (`English` and `繁體中文（台灣）`), select the language in macOS, restart Berth, and verify these menu states:

- Not pinned.
- Pinned to a connected display.
- Pinned Display disconnected.
- Accessibility permission not granted.

Keep macOS-provided display names unchanged in both languages. Also enable Launch at Login, restart the login session, and confirm Berth launches with the selected language. Record any state that could not be exercised as outstanding pull-request verification; automated bundle lookup does not replace this UI evidence.

## Release smoke test

Automated coverage cannot prove real Accessibility, display, or Dock behavior. Before release, exercise this checklist on an Apple Silicon Mac:

- Launch the packaged App and grant Accessibility permission.
- Pin each connected display in turn and confirm the menu reports the selected display.
- Verify bottom, left, and right Dock orientations.
- Try to summon the Dock from a non-pinned display and confirm it stays pinned.
- Confirm the pointer can cross every shared edge between adjacent displays.
- Enable display mirroring and confirm Berth doesn't treat the mirrored copy as an independent edge.
- Disconnect and reconnect the pinned display, then confirm Berth recovers after the display returns.
- Revoke Accessibility permission and confirm interception stops; restore it and confirm Berth resumes.
- Use the immediate summon action and confirm the pointer returns to its original location.
- Toggle the launch-at-login action, restart the session, and confirm Berth launches.
