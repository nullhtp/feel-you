## 1. Test Infrastructure Setup

- [x] 1.1 Add `integration_test` (Flutter SDK) to `dev_dependencies` in `app/pubspec.yaml`
- [x] 1.2 Create `app/integration_test/` directory
- [x] 1.3 Create `RecordingVibrationService` test helper — a mock `VibrationService` that records all calls (`playMorsePattern`, `playSuccess`, `playError`, `cancel`) with their arguments for assertion. Completes immediately (no real delays).
- [x] 1.4 Create test helper functions for simulating gestures via `GestureClassifier`: `simulateDot()`, `simulateDash()`, `simulateSwipeRight()`, `simulateSwipeLeft()`, `simulateLongHold()`, and `waitForSilenceTimeout()` — each injecting appropriate `RawTouchEvent` sequences with correct timing
- [x] 1.5 Create fast timing config constants for tests: `GestureTimingConfig`, `MorseTimingConfig`, and `TeachingTimingConfig` with 1-10ms durations

## 2. Happy Path Integration Tests

- [x] 2.1 Write `learning_flow_test.dart` — test setup: create `ProviderContainer` with real providers, override `vibrationServiceProvider` with `RecordingVibrationService`, override timing configs with fast test values
- [x] 2.2 Test: app start plays letter A — verify orchestrator calls `playMorsePattern` with A's pattern (dot, dash) after start
- [x] 2.3 Test: correct input for A — simulate dot + dash input, wait for silence timeout, verify `playSuccess` called, verify orchestrator resumes loop
- [x] 2.4 Test: wrong input triggers error + replay — simulate incorrect pattern, verify `playError` called, then `playMorsePattern` with correct pattern, then loop resumes
- [x] 2.5 Test: navigate next — simulate swipe right, verify session advances to B, verify `playMorsePattern` called with B's pattern
- [x] 2.6 Test: navigate previous — simulate swipe left from B, verify session goes back to A
- [x] 2.7 Test: reset — navigate to C, simulate long hold, verify session resets to A
- [x] 2.8 Test: multi-letter sequence — learn A (correct input), swipe to B, learn B (correct input), verify full sequence of vibration calls

## 3. Edge Case Integration Tests

- [x] 3.1 Write `edge_cases_test.dart` — same test infrastructure as learning_flow_test, shared helpers
- [x] 3.2 Test: rapid navigation — three consecutive swipe-right gestures, verify session on letter D and orchestrator playing D's pattern
- [x] 3.3 Test: rapid swipe right then left — swipe right then immediately swipe left, verify session back on original letter
- [x] 3.4 Test: tap during playback interrupts — start orchestrator playing A, inject a tap during playback, verify `cancel` called and session phase becomes `listening`
- [x] 3.5 Test: double tap during playback — inject two quick taps, verify only first triggers interrupt, second is accumulated as input
- [x] 3.6 Test: navigation during feedback — trigger correct answer feedback, swipe right during feedback, verify feedback cancelled and session advances to next letter
- [x] 3.7 Test: navigate previous at letter A — verify session stays on A, orchestrator continues playing A
- [x] 3.8 Test: navigate next at letter Z — advance session to Z, swipe right, verify session stays on Z

## 4. Tuning Configuration

- [x] 4.1 Create `app/lib/tuning/tuning_reference.dart` — centralized documentation file with doc comments for every timing constant across all three config classes
- [x] 4.2 Add `// TODO(tuning):` markers to all device-dependent values: gesture thresholds (`dotMaxDuration`, `dashMaxDuration`, `resetMinDuration`, `silenceTimeout`), vibration durations (`dotDuration`, `dashDuration`, `interSymbolGap`, `successPulseDuration`, `successPulseGap`, `errorBuzzDuration`), and teaching timing (`repeatPause`)
- [x] 4.3 Expose default config instances from the tuning reference for easy single-point adjustment

## 5. Build Verification & Cleanup

- [x] 5.1 Run all existing unit/widget tests (`flutter test`) — verify they still pass with no regressions
- [x] 5.2 Run integration tests (`flutter test integration_test/`) — verify all new tests pass
- [x] 5.3 Verify clean Android release build (`flutter build apk`) — fix any warnings or errors
- [x] 5.4 Verify clean iOS release build (`flutter build ios --no-codesign`) — fix any warnings or errors (macOS only)
