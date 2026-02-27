# Phase 1 Roadmap: Learn Vibro Morse

## Foundation (Complete)

- [x] Monorepo + Flutter scaffold
- [x] Morse data model (A-Z alphabet, encode/decode, validation)
- [x] Gesture recognition (tap/swipe/hold classifier, stream-based)
- [x] Vibration engine (Morse pattern, success/error signal playback)

## Remaining Changes

### Change 1: Learning Session State

Core state machine tracking the user's learning session.

- [ ] Current letter index tracking (A-Z position)
- [ ] Session state enum: `playing`, `listening`, `feedback`
- [ ] Navigation handling (swipe right/left moves between letters, long hold resets to A)
- [ ] Riverpod providers for session state
- [ ] In-memory only, no persistence needed

### Change 2: Teaching Loop (Orchestrator)

The brain that connects gesture input, vibration output, and session state.

- [ ] Play-wait-repeat loop: continuously vibrate the current letter's Morse pattern with pauses, infinitely, until the user taps
- [ ] Input evaluation: on `InputComplete`, compare user's pattern against current letter via `patternsEqual`
- [ ] Correct answer: play success vibration (`· · ·`), resume repeat loop
- [ ] Wrong answer: play error vibration (`−−−−−`), replay correct pattern, resume loop
- [ ] Interrupt handling: stop playback when user starts tapping, resume after feedback
- [ ] Navigation integration: on `NavigateNext`/`NavigatePrevious`/`Reset`, update letter, restart loop

### Change 3: Touch UI Layer

Single full-screen widget connecting real touch events to the gesture classifier.

- [ ] Full-screen `GestureDetector` capturing all taps, holds, and swipes
- [ ] Feed raw touch events (`onPanDown`/`onPanEnd`/`onPanUpdate`) into `RawTouchEvent` for the classifier
- [ ] No visual elements (blank screen — the user is deaf-blind)
- [ ] Start button: one large tap target for a sighted person to press once to begin
- [ ] Accessibility metadata / semantics

### Change 4: Integration Testing & Polish

End-to-end validation and platform-specific tuning.

- [ ] Integration tests: full learning flow (start → play A → user taps → success → swipe to B → ...)
- [ ] Vibration tuning on real iOS and Android devices
- [ ] Timing calibration: adjust gesture thresholds and vibration durations from real-device feedback
- [ ] Edge cases: rapid swipes, double taps, background/foreground transitions
- [ ] Clean release builds for both platforms

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
