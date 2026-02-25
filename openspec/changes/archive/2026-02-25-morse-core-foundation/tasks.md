## 1. Morse Data Model

- [x] 1.1 Create `app/lib/morse/morse_symbol.dart` with `MorseSymbol` enum (`dot`, `dash`)
- [x] 1.2 Create `app/lib/morse/morse_alphabet.dart` with const A-Z Morse pattern map and ordered letter list
- [x] 1.3 Create `app/lib/morse/morse_utils.dart` with encode (letter→pattern), decode (pattern→letter), and validate functions
- [x] 1.4 Write unit tests for Morse alphabet completeness (all 26 letters, correct patterns for known letters)
- [x] 1.5 Write unit tests for encode/decode/validate (valid letters, lowercase, invalid input, empty input, round-trip)

## 2. Vibration Engine

- [x] 2.1 Add `vibration` package to `app/pubspec.yaml` and run `flutter pub get`
- [x] 2.2 Create `app/lib/vibration/morse_timing_config.dart` with `MorseTimingConfig` class (dot/dash/gap durations, success/error signal timing, all with defaults)
- [x] 2.3 Create `app/lib/vibration/vibration_service.dart` with abstract `VibrationService` class defining `playMorsePattern()`, `playSuccess()`, `playError()` methods
- [x] 2.4 Add pure function for converting `List<MorseSymbol>` + config into vibration duration pattern (list of ms on/off values)
- [x] 2.5 Implement `DeviceVibrationService` concrete class using `vibration` package
- [x] 2.6 Create `app/lib/vibration/vibration_providers.dart` with Riverpod providers for `MorseTimingConfig` and `VibrationService`
- [x] 2.7 Write unit tests for vibration pattern generation (dot, dash, sequences, success pattern, error pattern — pure logic, no device needed)
- [x] 2.8 Write unit tests for timing config (default values, custom overrides)

## 3. Gesture Recognition

- [x] 3.1 Create `app/lib/gestures/gesture_timing_config.dart` with `GestureTimingConfig` class (dot/dash/reset thresholds, silence timeout, swipe distance/velocity, all with defaults)
- [x] 3.2 Create `app/lib/gestures/gesture_event.dart` with sealed `GestureEvent` class and subtypes: `MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`
- [x] 3.3 Create `app/lib/gestures/gesture_classifier.dart` with `GestureClassifier` — stream-based classifier that accepts raw pointer events and emits `GestureEvent`s
- [x] 3.4 Implement tap classification logic (dot <150ms, dash 150-500ms, dead zone 500-2000ms, reset >2000ms)
- [x] 3.5 Implement silence timeout for input completion (1000ms default, emits `InputComplete` with accumulated symbols)
- [x] 3.6 Implement swipe detection (horizontal distance >50px and velocity >200px/s, left/right classification)
- [x] 3.7 Implement input buffer reset on navigation and reset events
- [x] 3.8 Create `app/lib/gestures/gesture_providers.dart` with Riverpod providers for `GestureTimingConfig` and `GestureClassifier`
- [x] 3.9 Write unit tests for tap classification (dot, dash, dead zone, reset boundary cases)
- [x] 3.10 Write unit tests for silence timeout and input completion (accumulation, timer reset, no completion without input)
- [x] 3.11 Write unit tests for swipe detection (valid swipes, too slow, too short, direction)
- [x] 3.12 Write unit tests for input buffer reset on navigation/reset events

## 4. Integration & Verification

- [x] 4.1 Run `dart analyze` from `app/` and fix any lint warnings
- [x] 4.2 Run all tests and verify they pass
- [x] 4.3 Verify app still builds and runs on both iOS and Android (no regressions to existing scaffold)
