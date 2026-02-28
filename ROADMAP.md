# Phase 1 Roadmap: Learn Vibro Morse

## Foundation (Complete)

- [x] Monorepo + Flutter scaffold
- [x] Morse data model (A-Z alphabet, encode/decode, validation)
- [x] Gesture recognition (tap/swipe/hold classifier, stream-based)
- [x] Vibration engine (Morse pattern, success/error signal playback)

## Completed Changes

### Change 1: Learning Session State (Complete)

Core state machine tracking the user's learning session.

- [x] Current letter index tracking (A-Z position)
- [x] Session state enum: `playing`, `listening`, `feedback`
- [x] Navigation handling (swipe right/left moves between letters, long hold resets to A)
- [x] Riverpod providers for session state
- [x] In-memory only, no persistence needed

### Change 2: Teaching Loop (Orchestrator) (Complete)

The brain that connects gesture input, vibration output, and session state.

- [x] Play-wait-repeat loop: continuously vibrate the current letter's Morse pattern with pauses, infinitely, until the user taps
- [x] Input evaluation: on `InputComplete`, compare user's pattern against current letter via `patternsEqual`
- [x] Correct answer: play success vibration (`· · ·`), resume repeat loop
- [x] Wrong answer: play error vibration (`−−−−−`), replay correct pattern, resume loop
- [x] Interrupt handling: stop playback when user starts tapping, resume after feedback
- [x] Navigation integration: on `NavigateNext`/`NavigatePrevious`/`Reset`, update letter, restart loop

### Change 3: Touch UI Layer (Complete)

Single full-screen widget connecting real touch events to the gesture classifier.

- [x] Full-screen `GestureDetector` capturing all taps, holds, and swipes
- [x] Feed raw touch events (`onPanDown`/`onPanEnd`/`onPanUpdate`) into `RawTouchEvent` for the classifier
- [x] No visual elements (blank screen — the user is deaf-blind)
- [x] Start button: one large tap target for a sighted person to press once to begin
- [x] Accessibility metadata / semantics

### Change 4: Integration Testing & Polish (Complete)

End-to-end validation and platform-specific tuning.

- [x] Integration tests: full learning flow (start → play A → user taps → success → swipe to B → ...)
- [x] Vibration tuning on real iOS and Android devices
- [x] Timing calibration: adjust gesture thresholds and vibration durations from real-device feedback
- [x] Edge cases: rapid swipes, double taps, background/foreground transitions
- [x] Clean release builds for both platforms

## Dependency Order

```
Change 1 (State) → Change 2 (Teaching Loop) → Change 3 (UI Layer) → Change 4 (Testing)
```

## Effort Estimates

| # | Change | Effort | Key Deliverable |
|---|--------|--------|-----------------|
| 1 | Learning Session State | Small | State machine + providers for current letter and session phase |
| 2 | Teaching Loop | Medium | Orchestrator: play patterns, evaluate input, give feedback |
| 3 | Touch UI Layer | Small | Full-screen gesture capture + start button |
| 4 | Integration & Polish | Medium | Real-device tested, release-ready Phase 1 |
