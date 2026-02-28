## 1. Morse Digit Data

- [x] 1.1 Create `app/lib/morse/morse_digits.dart` with `morseDigits` map (0-9 patterns) and `morseDigitsList` ordered list
- [x] 1.2 Update `morse_utils.dart` to support digit lookup in `encodeLetter`, `decodePattern`, and `isValidPattern` (merge digit patterns into the lookup)
- [x] 1.3 Export `morse_digits.dart` from `morse.dart` barrel file
- [x] 1.4 Write unit tests for digit Morse patterns (all 10 digits correct, distinct from letters, encode/decode round-trip)

## 2. Level System

- [x] 2.1 Create `app/lib/morse/level.dart` with `Level` class (name, characters list, patterns map)
- [x] 2.2 Create `app/lib/morse/levels.dart` with top-level `levels` list — digits at index 0, letters at index 1, using existing `morseLetters`/`morseAlphabet` and new `morseDigitsList`/`morseDigits`
- [x] 2.3 Export level files from `morse.dart` barrel
- [x] 2.4 Write unit tests for Level data model and levels registry (order, character counts, pattern lookups)

## 3. Gesture Events Expansion

- [x] 3.1 Add `NavigateUp`, `NavigateDown`, and `Home` subtypes to the `GestureEvent` sealed class in `gesture_event.dart`
- [x] 3.2 Add `y` position field to `TouchDown` and `TouchUp` in `gesture_classifier.dart`
- [x] 3.3 Update all existing `TouchDown`/`TouchUp` call sites (touch_surface.dart, tests) to pass `y` parameter

## 4. Vertical Swipe Detection

- [x] 4.1 Implement dominant-axis swipe discrimination in `GestureClassifier._onTouchUp` — compare abs(dx) vs abs(dy), classify based on dominant axis
- [x] 4.2 Add vertical swipe classification: swipe up emits `NavigateUp`, swipe down emits `NavigateDown`, using same distance/velocity thresholds as horizontal
- [x] 4.3 Clear input buffer on vertical swipe (same as horizontal swipe behavior)
- [x] 4.4 Write unit tests for vertical swipe detection (up, down, threshold boundaries, diagonal disambiguation, buffer clearing)

## 5. Shake Detection

- [x] 5.1 Add `sensors_plus` dependency to `app/pubspec.yaml`
- [x] 5.2 Create `app/lib/gestures/shake_config.dart` with `ShakeConfig` class (threshold default 15 m/s^2, cooldown default 1000ms)
- [x] 5.3 Create `app/lib/gestures/shake_detector.dart` with `ShakeDetector` class — subscribes to accelerometer, computes magnitude, emits `Home` events with cooldown, handles missing sensor gracefully
- [x] 5.4 Add `shakeConfigProvider` and `shakeDetectorProvider` to `gesture_providers.dart`
- [x] 5.5 Export shake files from `gestures.dart` barrel
- [x] 5.6 Write unit tests for ShakeDetector (threshold detection, cooldown enforcement, graceful failure on missing sensor)

## 6. Session State Expansion

- [x] 6.1 Add `levelIndex` field to `SessionState`, rename `letterIndex` to `positionIndex`, replace `currentLetter` getter with `currentCharacter` getter that reads from `levels[levelIndex]`
- [x] 6.2 Update `SessionNotifier`: rename `nextLetter`/`previousLetter` to `nextPosition`/`previousPosition`, update boundary logic to use current level's character count, update `reset()` to only reset position (not level), add `nextLevel()`, `previousLevel()`, and `home()` methods
- [x] 6.3 Update default initial state: levelIndex=0 (digits), positionIndex=0, phase=playing
- [x] 6.4 Update all existing references to `letterIndex`, `currentLetter`, `nextLetter`, `previousLetter` throughout the codebase (teaching orchestrator, tests)
- [x] 6.5 Write unit tests for session state: level navigation (up/down/home), position navigation within levels, boundary clamping for both levels and positions, initial state is digit 0

## 7. Teaching Orchestrator Updates

- [x] 7.1 Update orchestrator to resolve current character's Morse pattern via the level system (`levels[state.levelIndex]`) instead of hardcoded `morseLetters`/`morseAlphabet`
- [x] 7.2 Add event handlers for `NavigateUp`, `NavigateDown`, and `Home` gesture events — call corresponding `SessionNotifier` methods, cancel vibration, restart loop
- [x] 7.3 Subscribe orchestrator to `ShakeDetector.events` stream in addition to `GestureClassifier.events`, clean up both subscriptions on dispose
- [x] 7.4 Update orchestrator provider to inject `ShakeDetector` dependency
- [x] 7.5 Update existing orchestrator tests to use new session API (`nextPosition`/`previousPosition`, `positionIndex`/`levelIndex`)
- [x] 7.6 Write new tests for level navigation events and home event handling in orchestrator
- [x] 7.7 Write tests for dual-stream subscription (touch + shake) and cleanup

## 8. Touch Surface & Entry Point

- [x] 8.1 Update `TouchSurface` pointer handlers to pass `y` position to `GestureClassifier` (extract from `PointerEvent.localPosition.dy`)
- [x] 8.2 Start `ShakeDetector` alongside `TeachingOrchestrator` in `TouchSurface.initState`, dispose in `dispose`
- [ ] 8.3 Verify app starts on digit 0 (level 0, position 0) — manual smoke test on device/emulator

## 9. Integration & Edge Cases

- [x] 9.1 Update existing integration tests to account for the level dimension (initial state is now digit 0 instead of letter A)
- [x] 9.2 Write integration test: full flow from digit level through level switch to letter level and back
- [x] 9.3 Write edge case tests: shake during feedback, vertical swipe at level boundary, rapid level switching, shake cooldown during teaching loop
- [x] 9.4 Run full test suite, fix any regressions
