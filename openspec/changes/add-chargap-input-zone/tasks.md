## 1. Gesture Event & Classifier Changes

- [x] 1.1 Add `BottomZoneAction` sealed subtype to `GestureEvent` in `gesture_event.dart` with Equatable support
- [x] 1.2 Add `emitEvent(GestureEvent)` public method to `GestureClassifier` so `TouchSurface` can emit `BottomZoneAction` onto the event stream
- [x] 1.3 Add `insertCharGap()` method to `GestureClassifier` — adds `charGap` to input buffer if non-empty, restarts silence timer
- [x] 1.4 Add `submitInput()` method to `GestureClassifier` — emits `InputComplete` with current buffer contents, clears buffer, cancels timers
- [x] 1.5 Remove `_charGapTimer` and charGap auto-insertion logic from `_startSilenceTimer()` in `gesture_classifier.dart` (keep only the silence timeout for `InputComplete`)
- [x] 1.6 Remove `charGapThreshold` field from `GestureTimingConfig`

## 2. Touch Surface Bottom Zone Routing

- [x] 2.1 Update `TouchSurface` to obtain screen height from `MediaQuery` and calculate the bottom zone boundary (`screenHeight * 0.85`)
- [x] 2.2 Add swipe detection logic to `TouchSurface._onPointerUp` — track press start position/time and compute displacement/velocity to distinguish taps from swipes in the bottom zone
- [x] 2.3 On touch-up in the bottom zone: if non-swipe and non-reset, trigger haptic feedback (~50ms vibration pulse) and emit `BottomZoneAction` via `GestureClassifier.emitEvent()`; otherwise forward to classifier normally
- [x] 2.4 On touch-up in the upper zone: forward to `GestureClassifier.handleTouch()` as before (no behavior change)

## 3. Teaching Orchestrator BottomZoneAction Handling

- [x] 3.1 Add `BottomZoneAction` case to the gesture event handler in `TeachingOrchestrator`
- [x] 3.2 On words level (index 2): call `gestureClassifier.insertCharGap()` when `BottomZoneAction` is received and session phase is `playing` or `listening`
- [x] 3.3 On other levels (digits, letters): call `gestureClassifier.submitInput()` when `BottomZoneAction` is received and session phase is `listening` (input in progress)
- [x] 3.4 Ignore `BottomZoneAction` during `feedback` phase (consistent with existing MorseInput/InputComplete behavior)

## 4. Tests — Gesture Classifier

- [x] 4.1 Update existing charGap timer tests — remove or replace tests that verify automatic charGap insertion after 400ms silence
- [x] 4.2 Add tests for `insertCharGap()`: inserts charGap when buffer non-empty, does nothing when empty, restarts silence timer
- [x] 4.3 Add tests for `submitInput()`: emits InputComplete with buffer contents, clears buffer, does nothing when empty
- [x] 4.4 Add tests for `emitEvent()`: emits the provided event on the stream
- [x] 4.5 Verify silence timeout (1000ms) still works as fallback for InputComplete after removing charGap timer

## 5. Tests — Touch Surface & Integration

- [ ] 5.1 Add tests for bottom zone detection: taps at y >= 85% boundary trigger `BottomZoneAction`, taps above do not
- [ ] 5.2 Add tests for swipe-through-bottom-zone: swipes starting in bottom zone are forwarded to classifier as navigation events
- [ ] 5.3 Add tests for haptic feedback: verify vibration is triggered on bottom zone tap
- [ ] 5.4 Add integration tests for level-aware behavior: bottom zone tap inserts charGap on words level, triggers InputComplete on digits/letters levels
- [ ] 5.5 Add tests for edge cases: empty buffer on bottom zone tap (no event emitted), bottom zone tap during feedback phase (ignored)
