## 1. Add Dependencies

- [x] 1.1 Add `equatable` package to `app/pubspec.yaml` and run `flutter pub get`

## 2. Eliminate DRY Violations in Production Code

- [x] 2.1 Replace private `_listEquals` in `gesture_event.dart` with `listEquals` from `package:flutter/foundation.dart`
- [x] 2.2 Replace private `_listEquals` in `vibration_service.dart` (will become `signal_pattern.dart`) with `listEquals` from `package:flutter/foundation.dart`
- [x] 2.3 Add `postFeedbackPause` field to `TeachingTimingConfig` (default: `Duration(milliseconds: 500)`)
- [x] 2.4 Merge `_handleCorrectAnswer` and `_handleWrongAnswer` in `TeachingOrchestrator` into a shared `_handleFeedback(Future<void> Function() playFeedback)` method that uses `config.postFeedbackPause`

## 3. Apply Equatable to Value Classes

- [x] 3.1 Make `GestureEvent` sealed class extend `Equatable`; update all subtypes (`MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`) to use `props` getter instead of manual `==`/`hashCode`. Keep manual `toString` for custom formatting.
- [x] 3.2 Make `SessionState` extend `Equatable` with `props` returning `[letterIndex, phase]`. Keep manual `copyWith` and `toString`.
- [x] 3.3 Make `TeachingOrchestratorState` extend `Equatable` with `props` returning `[isRunning, isInterrupted]`. Keep manual `copyWith` and `toString`.
- [x] 3.4 Make `SignalPattern` extend `Equatable` with `props` returning `[pattern, intensities]`. Keep manual `toString`.

## 4. Split `vibration_service.dart` (SRP)

- [x] 4.1 Extract `buildMorseVibrationPattern()` into `lib/vibration/morse_vibration_pattern.dart`
- [x] 4.2 Extract `SignalPattern`, `successSignal`, and `errorSignal` into `lib/vibration/signal_pattern.dart`
- [x] 4.3 Keep `VibrationService` abstract class in `lib/vibration/vibration_service.dart` (remove everything else from it)
- [x] 4.4 Extract `DeviceVibrationService` into `lib/vibration/device_vibration_service.dart`
- [x] 4.5 Update all imports across production code to reference the new file locations (or use barrel exports)

## 5. Remove Dead Code

- [x] 5.1 Delete `lib/tuning/tuning_reference.dart` and remove the `tuning/` directory

## 6. Add Barrel Exports

- [x] 6.1 Create `lib/morse/morse.dart` re-exporting `morse_symbol.dart`, `morse_alphabet.dart`, `morse_utils.dart`
- [x] 6.2 Create `lib/gestures/gestures.dart` re-exporting `gesture_event.dart`, `gesture_classifier.dart`, `gesture_timing_config.dart`, `gesture_providers.dart`
- [x] 6.3 Create `lib/session/session.dart` re-exporting `session_phase.dart`, `session_state.dart`, `session_notifier.dart`, `session_providers.dart`
- [x] 6.4 Create `lib/vibration/vibration.dart` re-exporting all vibration files (`morse_vibration_pattern.dart`, `signal_pattern.dart`, `vibration_service.dart`, `device_vibration_service.dart`, `morse_timing_config.dart`, `vibration_providers.dart`)
- [x] 6.5 Create `lib/teaching/teaching.dart` re-exporting `teaching_orchestrator.dart`, `teaching_timing_config.dart`, `teaching_providers.dart`
- [x] 6.6 Update all production code imports to use barrel exports where possible

## 7. Consolidate Test Doubles

- [x] 7.1 Create `test/test_doubles/mock_vibration_service.dart` with a single `MockVibrationService` that records typed calls (based on the `RecordingVibrationService` pattern from integration tests) and exposes both typed call log and string-based call names
- [x] 7.2 Create `test/test_doubles/fake_gesture_classifier.dart` with a single `FakeGestureClassifier` that exposes a `StreamController<GestureEvent>` for test control and records raw touch events
- [x] 7.3 Update `test/teaching/teaching_orchestrator_test.dart` to use shared test doubles
- [x] 7.4 Update `test/teaching/teaching_providers_test.dart` to use shared `MockVibrationService`
- [x] 7.5 Update `test/ui/touch_surface_test.dart` to use shared test doubles
- [x] 7.6 Update `test/vibration/vibration_service_test.dart` to use shared `MockVibrationService`
- [x] 7.7 Update `test/widget_test.dart` to use shared test doubles
- [x] 7.8 Update test imports to use barrel exports where possible

## 8. Verify

- [x] 8.1 Run `dart analyze` in `app/` — zero warnings/errors
- [x] 8.2 Run `flutter test` in `app/` — all tests pass
