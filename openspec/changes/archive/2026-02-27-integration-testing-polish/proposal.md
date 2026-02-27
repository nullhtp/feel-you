## Why

Changes 1–3 delivered all feature code for Phase 1 (session state, teaching loop, touch UI) with comprehensive unit and widget tests. However, no test validates the full end-to-end learning flow — from app launch through letter playback, user input, feedback, and navigation. Integration tests are needed to catch wiring issues between layers, verify the real provider graph, and build confidence before shipping to real devices. Additionally, timing constants are scattered across three config classes, making real-device tuning difficult.

## What Changes

- Add Flutter `integration_test` package and write integration tests covering the full learning flow (start → play letter → user taps back → success/error feedback → navigate to next letter)
- Add integration test scenarios for edge cases: rapid navigation, double taps during playback, quick swipe-then-tap sequences
- Create a centralized tuning configuration that documents all timing constants (gesture thresholds, vibration durations, teaching loop timing) in one place, with TODO markers for values needing real-device validation
- Verify clean release builds for both iOS and Android platforms

## Non-goals

- Real-device vibration tuning (requires physical devices; we prepare the config but don't calibrate values)
- Background/foreground transition testing (requires real device lifecycle)
- App Store / Play Store submission or signing setup
- Adding a start button UI (keeping current auto-start behavior)
- App icons or store metadata

## Capabilities

### New Capabilities
- `integration-testing`: End-to-end integration tests validating the full learning flow and edge cases using Flutter's integration_test package
- `tuning-config`: Centralized timing configuration documenting all adjustable constants across gesture recognition, vibration engine, and teaching loop for easy real-device calibration

### Modified Capabilities
_None — no existing spec-level requirements are changing._

## Impact

- **New dependency**: `integration_test` (Flutter SDK) in dev_dependencies
- **New directory**: `app/integration_test/` with test files
- **New file**: Centralized tuning config referencing existing `GestureTimingConfig`, `MorseTimingConfig`, and `TeachingTimingConfig`
- **Build verification**: Both `flutter build apk` and `flutter build ios --no-codesign` must succeed cleanly
- **Existing code**: No modifications to existing feature code; timing config values remain unchanged
