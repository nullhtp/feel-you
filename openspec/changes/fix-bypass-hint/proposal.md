## Why

The debug-only button on the No vibration screen tells a screen reader *"Opens the language picker although nothing will vibrate"* ([#95](https://github.com/nullhtp/feel-you/issues/95)). Since the home menu (#41, #104), the bypass starts the app over from its first screen, which is the language picker only when no language is saved; with a saved language it is the home menu. The hint is the one thing a screen-reader user on a simulator hears about the button, and on the saved-language path it is wrong. The wording is pinned in `vibration-capability-gate` (*Debug builds can bypass the gate*), so the spec changes with it.

## What Changes

- The button's screen-reader hint becomes *"Continues into the app although nothing will vibrate"*: it names no screen, so it holds on both launch paths and for whatever the first screen becomes.
- `vibration-capability-gate`: *Debug builds can bypass the gate* gets the new hint and says it names no screen.
- Tests pin the hint on both launch paths (no saved language → the picker, a saved language → the menu), in a widget test and end to end.

## Accessibility

Debug builds only: release and profile builds have no button. A developer or tester using VoiceOver or TalkBack on a simulator now hears what the button really does. The visible label, *Continue anyway (debug build)*, is unchanged.

## Non-goals

- No change to the visible label, to what the bypass does, or to release builds.
- No change to the No vibration screen's heading and explanation.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `vibration-capability-gate`: the bypass button's screen-reader hint.
- `integration-testing`: the vibration gate end-to-end test also checks that hint, with and without a saved language.

## Impact

- **UI**: `app/lib/ui/no_vibration_screen.dart` (the hint, now the constant `noVibrationBypassHint`).
- **Tests**: `app/test/ui/no_vibration_screen_test.dart` (the hint on the picker, and through `FeelYouApp` on both launch paths with where the bypass lands), `app/integration_test/vibration_gate_test.dart` (the hint on both paths).
- **Docs**: CHANGELOG. README and `app/README.md` do not quote the hint.
