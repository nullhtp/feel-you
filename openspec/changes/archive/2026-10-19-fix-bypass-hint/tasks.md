# Tasks

## 1. The hint

- [x] 1.1 Change the bypass button's screen-reader hint in `app/lib/ui/no_vibration_screen.dart` to "Continues into the app although nothing will vibrate", as the constant `noVibrationBypassHint` next to `noVibrationBypassLabel`. Verify by updating `app/test/ui/no_vibration_screen_test.dart` (the hint on the motorless picker) and adding a test per launch path through `FeelYouApp` (no saved language, a saved language): the button's semantics carry the label and the new hint, and tapping it opens the picker or the menu. Verify they pass, and fail with the old hint
- [x] 1.2 Add a `CHANGELOG.md` line under Fixed. Verify `grep -rn "Opens the language picker although" app/lib app/test app/integration_test openspec/specs README.md app/README.md` finds nothing once the change is archived (until then, only the main spec)

## 2. Integration checks

- [x] 2.1 In `app/integration_test/vibration_gate_test.dart`, with semantics on, assert the bypass button's hint on both launch paths before tapping it. Verify `flutter test integration_test/vibration_gate_test.dart -d <simulator>` passes on the iOS simulator, and fails with the old hint
- [x] 2.2 Run `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, `flutter test` and the full `flutter test integration_test -d <simulator>` in `app/`; `openspec validate fix-bypass-hint --strict`; in a scratch copy of `openspec/`, archive `fix-picker-lifecycle`, then `fix-bypass-hint`, and run `openspec validate --specs --strict`. Verify all pass

## Workflow follow-up

- Archive the change with `/opsx:archive` after the pull request is merged, after `fix-picker-lifecycle`, then run `openspec validate --specs --strict`.
