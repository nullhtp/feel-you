## Context

The Feel You app has a running Flutter scaffold with Riverpod wired up, but zero feature code. Phase 1 requires a Morse code learning experience delivered entirely through touch and vibration. Before building the learning loop itself, we need three foundation layers: a Morse data model, a vibration engine, and a gesture recognition system. These are independent capabilities that the learning loop (a future change) will orchestrate.

Current state: empty `Scaffold`, `ProviderScope` at root, `flutter_riverpod` + `riverpod_annotation` as dependencies, `very_good_analysis` for linting. No feature code, no additional packages.

## Goals / Non-Goals

**Goals:**
- Pure Dart Morse code data model with full A-Z coverage and utilities
- Vibration engine that can play arbitrary Morse patterns and signal vibrations on both iOS and Android
- Gesture recognition that classifies touch input into Morse symbols, navigation commands, and reset
- All timing parameters configurable through a central configuration
- Clean Riverpod provider interfaces for downstream consumption
- Comprehensive unit tests for all logic

**Non-Goals:**
- No learning loop or teacher orchestration — just the primitives
- No UI screens or widgets (gesture detection attaches to the existing scaffold in a future change)
- No letter navigation state (which letter the user is on)
- No persistence or analytics
- No platform channels — we rely on the `vibration` package abstraction

## Decisions

### 1. Morse data as an immutable, compile-time map

**Choice**: A-Z Morse patterns defined as a `const Map<String, List<MorseSymbol>>` where `MorseSymbol` is an enum (`dot`, `dash`).

**Rationale**: The Morse alphabet is fixed and well-defined — there's no reason to load it dynamically. A const map gives compile-time safety, zero runtime cost, and is trivially testable. Using a typed enum instead of strings (`'.'` / `'-'`) prevents typos and enables exhaustive switch matching.

**Alternatives considered**:
- String representation (`'.-'` for A): Simpler but loses type safety. Easy to pass invalid characters.
- Class-per-letter: Over-engineered for a static lookup table.

### 2. `vibration` package for haptic output

**Choice**: Use the [`vibration`](https://pub.dev/packages/vibration) Flutter package.

**Rationale**: Supports custom vibration patterns with millisecond-level duration control on both iOS and Android. Provides `Vibration.vibrate(pattern: [...], intensities: [...])` which maps directly to our needs (play a sequence of on/off durations). It's mature, well-maintained, and avoids the complexity of writing platform channels.

**Alternatives considered**:
- `HapticFeedback` (Flutter built-in): Only supports predefined patterns (light/medium/heavy impact). No custom durations — useless for encoding dot vs dash.
- Custom platform channels (`CoreHaptics` on iOS, `Vibrator` on Android): Maximum control but significant implementation cost. We'd need to write and maintain native code in Swift and Kotlin. The `vibration` package already wraps these APIs adequately.

### 3. Vibration engine as an abstract service with Riverpod provider

**Choice**: Define a `VibrationService` abstract class with concrete implementation using the `vibration` package, exposed via a Riverpod provider. The service takes a `MorseTimingConfig` for all duration parameters.

**Rationale**: Abstraction enables testing (mock vibrations in unit tests), and Riverpod provides DI/lifecycle management. The timing config being injectable means thresholds can be tuned without code changes — critical since optimal vibration timing will require real-device experimentation.

**Structure**:
```
VibrationService (abstract)
  ├── playMorsePattern(List<MorseSymbol>) → Future<void>
  ├── playSuccess() → Future<void>
  └── playError() → Future<void>

DeviceVibrationService (concrete, uses vibration package)
```

### 4. Gesture classification as a stream-based state machine

**Choice**: A `GestureClassifier` that takes raw touch events (pointer down/up with timestamps) and emits classified `GestureEvent`s via a stream.

**Rationale**: Touch gestures are inherently temporal — classifying a tap as dot vs dash requires measuring duration, and detecting input completion requires a silence timer. A stream-based approach fits naturally: raw events flow in, classified events flow out, and consumers (the future learning loop) subscribe reactively. This also decouples gesture detection from the widget tree.

**Event types**:
```
GestureEvent
  ├── MorseInput(symbol: dot | dash)
  ├── InputComplete(symbols: List<MorseSymbol>)  // after silence timeout
  ├── NavigateNext
  ├── NavigatePrevious
  └── Reset
```

**Timing thresholds** (all configurable via `GestureTimingConfig`):
- Dot: tap < 150ms
- Dash: 150ms <= tap <= 500ms
- Reset: hold > 2000ms
- Input complete: 1000ms silence after last tap
- Swipe: minimum 50px distance, minimum 200px/s velocity

### 5. Configurable timing through dedicated config classes

**Choice**: Two config classes — `MorseTimingConfig` (vibration durations) and `GestureTimingConfig` (input thresholds) — injected via Riverpod providers with sensible defaults.

**Rationale**: Every timing value in this system will need tuning through real-device testing with actual users. Hardcoding values would require code changes for each adjustment. Config classes with defaults provide a single place to adjust all timing, and Riverpod injection means tests can use different timing without modifying production code.

**Default values**:

| Parameter | Value | Config class |
|-----------|-------|-------------|
| Dot vibration | 100ms | `MorseTimingConfig` |
| Dash vibration | 300ms | `MorseTimingConfig` |
| Inter-symbol gap | 100ms | `MorseTimingConfig` |
| Success signal pulse | 80ms x3 | `MorseTimingConfig` |
| Success signal gap | 80ms | `MorseTimingConfig` |
| Error signal buzz | 600ms | `MorseTimingConfig` |
| Dot tap max | 150ms | `GestureTimingConfig` |
| Dash tap max | 500ms | `GestureTimingConfig` |
| Reset hold min | 2000ms | `GestureTimingConfig` |
| Silence timeout | 1000ms | `GestureTimingConfig` |
| Min swipe distance | 50px | `GestureTimingConfig` |
| Min swipe velocity | 200px/s | `GestureTimingConfig` |

### 6. Directory structure within app/lib/

**Choice**: Feature-based directories under `app/lib/`:

```
app/lib/
  main.dart
  app.dart
  morse/
    morse_symbol.dart       # MorseSymbol enum
    morse_alphabet.dart     # A-Z const map
    morse_utils.dart        # encode/decode/validate helpers
  vibration/
    morse_timing_config.dart
    vibration_service.dart  # abstract + concrete
    vibration_providers.dart
  gestures/
    gesture_timing_config.dart
    gesture_event.dart      # GestureEvent types
    gesture_classifier.dart # stream-based classifier
    gesture_providers.dart
```

**Rationale**: Mirrors the three capabilities from the proposal. Each directory is self-contained with clear boundaries. Providers live alongside their feature code rather than in a central `providers/` directory — this keeps related code together and makes it easier to reason about dependencies.

## Risks / Trade-offs

- **[Risk] `vibration` package may not produce distinguishable dot/dash on all devices** → Mitigation: Timing config is injectable, so we can tune per-device if needed. If the package proves inadequate, the abstract `VibrationService` lets us swap to platform channels without changing consumers.
- **[Risk] Gesture timing thresholds feel wrong in practice** → Mitigation: All thresholds are configurable. The defaults are starting points; real-device testing will refine them. The dead zone between dash max (500ms) and reset min (2000ms) is intentionally large (1500ms gap) to avoid ambiguity.
- **[Risk] Silence timeout conflicts with slow users** → Mitigation: 1000ms is a starting point. The config is injectable, and future changes could add adaptive timeout based on user pace.
- **[Risk] iOS vibration behavior differs from Android** → Mitigation: The `vibration` package abstracts this. If platform differences are severe, we can subclass `DeviceVibrationService` per platform. The abstract service boundary makes this straightforward.
- **[Trade-off] No gesture detection widget in this change** → The `GestureClassifier` processes raw pointer events but doesn't include a `GestureDetector` widget to capture them. This keeps the change focused on logic, but means you can't demo gestures until the next change wires it to the UI.
- **[Trade-off] Stream-based gesture classification adds complexity** → A simpler callback approach would work for Phase 1, but streams compose better for future features (buffering, debouncing, combining with vibration state). Worth the small upfront cost.
