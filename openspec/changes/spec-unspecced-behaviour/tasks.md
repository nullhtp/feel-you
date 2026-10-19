# Tasks

No task changes `app/lib/`. Each group checks its delta against the code, maps its scenarios to the unit and widget tests that already pin them, and adds the tests that are missing.

## 1. Signals and tap feedback (`vibration-engine`, `bottom-input-zone`)

- [x] 1.1 Check every scenario of the `vibration-engine` and `bottom-input-zone` deltas against `signal_pattern.dart`, `device_vibration_service.dart`, `morse_vibration_pattern.dart`, `vibration_providers.dart` and `TeachingOrchestrator._onBottomZoneAction`. Verify that `test/vibration/signal_selection_test.dart`, `device_vibration_service_test.dart`, `morse_vibration_intensities_test.dart`, `test/teaching/teaching_orchestrator_bottom_zone_race_test.dart` and `test/ui/touch_surface_bottom_zone_test.dart` pass with `flutter test`
- [x] 1.2 Add `app/integration_test/feedback_signals_test.dart`. It runs `FeelYouApp` with its real `DeviceVibrationService`, catches the `vibration` channel and answers `feel_you/vibrator`. It covers: a bottom-strip tap while listening sends the 50 ms tap feedback before the success signal; a bottom-strip tap while the item plays sends none and the item keeps repeating; a correct and a wrong answer send the intensity signals with amplitude control and the duration-only signals without it. Platform note: the Dart side sends the same patterns on iOS and Android. The duration-only versions exist for Android motors without amplitude control and iPhones without Core Haptics. Verify on the iOS simulator

## 2. Russian word list (`russian-morse-data`)

- [x] 2.1 Add a test of the 20 words in order to `test/morse/russian_alphabet_test.dart`, which today checks only lengths. Verify with `flutter test test/morse/russian_alphabet_test.dart`

## 3. Double shake and gesture events (`shake-gesture`, `gesture-recognition`, `touch-surface`)

- [x] 3.1 Check the `shake-gesture`, `gesture-recognition` and double-shake `touch-surface` deltas against `shake_detector.dart`, `shake_config.dart`, `gesture_event.dart`, `gesture_classifier.dart`, `gesture_timing_config.dart` and `touch_surface.dart`. Verify that `test/gestures/shake_detector_double_shake_test.dart`, `shake_detector_pause_test.dart`, `shake_detector_test.dart`, `gesture_classifier_cancel_test.dart`, `test/ui/touch_surface_change_language_test.dart` and `touch_surface_cancel_test.dart` pass
- [x] 3.2 Add `app/integration_test/double_shake_test.dart`. It feeds the app's real `ShakeDetector` a broadcast accelerometer stream in real time with the default `ShakeConfig`. It covers: two shakes 0.9 s apart in a Russian lesson open the picker, stop the loop and play Morse Р; two shakes 1.8 s apart only go home, and the lesson keeps running. Verify on the iOS simulator

## 4. Background suspension (`app-lifecycle`)

- [x] 4.1 Check the `app-lifecycle` delta against `TouchSurface._suspendTeaching`, `_resumeTeaching` and `_abandonActivePress`, and `TeachingOrchestrator.start` and `stop`. Verify that `test/ui/touch_surface_lifecycle_test.dart` and `test/teaching/teaching_orchestrator_stopped_test.dart` pass
- [x] 4.2 Add `app/integration_test/app_lifecycle_test.dart` with the real wakelock plugin. It covers: going to the background stops the loop, disables the wakelock and keeps the phone silent; coming back enables the wakelock and replays the item from its first element; a finger held across the trip produces no dot and no reset; a half-entered answer is never judged. Platform note: frames stop while the app is hidden or paused, so the test waits in real time and pumps only after the resume. Both platforms use the same `WakelockPlus` API (iOS idle timer, Android keep-screen-on flag). Verify on the iOS simulator

## 5. Vibration gate (`vibration-capability-gate`)

- [x] 5.1 Check the `vibration-capability-gate` delta against `vibration_capabilities.dart`, `vibration_capability_probe.dart`, `vibration_providers.dart`, `vibration_gate.dart`, `no_vibration_screen.dart`, `vibration_diagnostics.dart`, `app.dart` and `AppDelegate.swift` / `MainActivity.kt`. Verify that `test/ui/launch_screen_test.dart`, `no_vibration_screen_test.dart`, `vibration_diagnostics_test.dart`, `language_picker_surface_test.dart`, `test/vibration/vibration_capability_probe_test.dart` and `vibration_capabilities_test.dart` pass
- [x] 5.2 Add `app/integration_test/vibration_gate_test.dart`. It covers: with the device's own probe, with and without a saved language, the iOS simulator shows the No vibration screen and neither the picker nor the lessons (on any other device the gate must follow the detected motor); the debug button opens the first screen; a detection that ends after a language was started in the picker replaces the lessons and stops the loop. Verify on the iOS simulator

## 6. Screen readers and the picker (`touch-surface`, `companion-overlay`, `language-selection`)

- [x] 6.1 Check the screen-reader deltas against `touch_surface.dart` and `companion_overlay.dart`, including the exact hint text and summary format, and the picker delta against `language_picker_surface.dart`. Verify that `test/ui/semantics_test.dart` and `test/ui/language_picker_non_visual_test.dart` (swipe plays the identifier) pass

## 7. Teaching loop and integration-testing corrections (`teaching-loop`, `integration-testing`)

- [x] 7.1 Check the `teaching-loop` delta against `teaching_orchestrator.dart`: the feedback sequences, ignored events, boundary swipes, discarded input, start and stop, and that no charGap threshold exists. Verify that `test/teaching/teaching_orchestrator_test.dart`, `teaching_orchestrator_boundary_test.dart`, `teaching_orchestrator_stale_input_test.dart`, `teaching_orchestrator_stopped_test.dart` and `teaching_orchestrator_change_language_test.dart` pass
- [x] 7.2 Check the corrected `integration-testing` scenarios against `integration_test/learning_flow_test.dart` and `edge_cases_test.dart` (start on digit 0, left/right taps, Z enters the quiz). Verify by reading the tests named in each scenario

## 8. Docs

- [x] 8.1 Add a line under `[Unreleased]` in `CHANGELOG.md` saying the specs now cover the behaviour shipped without a change (#32). Verify with `grep -n "#32" CHANGELOG.md`
- [x] 8.2 Update the ROADMAP "After Phase 1" sentence "Behaviour still missing from the specs: #32" to name the change. Verify with `grep -n "#32" ROADMAP.md`

## 9. Integration checks

- [x] 9.1 Run `openspec validate spec-unspecced-behaviour --strict`. Verify it reports the change valid
- [x] 9.2 Rehearse the archive on a copy of `openspec/` in a scratch directory: run `openspec archive spec-unspecced-behaviour --yes` and then `openspec validate --specs --strict`. Diff the resulting main specs against the originals. Verify that both commands pass and that every requirement and scenario name of the original specs is still present, except the three REMOVED requirements and their scenarios
- [x] 9.3 From `app/`, run `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` and `flutter test`. Verify all pass, with no new warnings and no infos in the new files
- [x] 9.4 Run every integration test on the iOS simulator with `flutter test integration_test -d <simulator>`. Verify all pass

## Workflow follow-up

- Archive the change with `/opsx:archive` after the pull request is merged (CONTRIBUTING.md), then run `openspec validate --specs --strict`.
- File follow-up issues for the specs left out (design.md, Decision 6) and for the bypass hint that names the picker when the lessons open (design.md, Risks).
