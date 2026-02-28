## 1. Expose Input Buffer State

- [x] 1.1 Add a `ValueNotifier<List<MorseSymbol>>` field (`inputBufferNotifier`) to `GestureClassifier` that emits an unmodifiable copy of `_inputBuffer` on every change (in `_addSymbol`, `insertCharGap`, `_clearBuffer`, `submitInput`, and silence timer callback)
- [x] 1.2 Add a Riverpod provider (`inputBufferProvider`) in `gesture_providers.dart` that exposes the classifier's `inputBufferNotifier` for widget consumption
- [x] 1.3 Dispose the `ValueNotifier` in `GestureClassifier.dispose()`
- [x] 1.4 Write unit tests for `inputBufferNotifier`: verify it updates on dot/dash input, charGap insertion, submission, navigation clear, and silence timeout

## 2. Companion Overlay Widget

- [x] 2.1 Create `app/lib/ui/companion_overlay.dart` with a `CompanionOverlay` `ConsumerWidget` that builds the full overlay layout inside a `Stack` of `Positioned` widgets, all wrapped in `IgnorePointer`
- [x] 2.2 Implement the current symbol/word display: large bold white `Text` centered on screen (~72sp for single chars, scaled down for words), reading `currentCharacter` from `sessionNotifierProvider`
- [x] 2.3 Implement the Morse pattern display: render the current character's pattern as "· — ·" notation below the symbol, using "/" to separate letters in words. Read pattern from `levels` data via session state
- [x] 2.4 Implement zone boundary dividers: vertical line at screen center (top to 85% height), horizontal line at 85% height (full width). Use `Container` with thin white border at ~10-20% opacity
- [x] 2.5 Implement zone labels: "DOT" centered-left, "DASH" centered-right, "SUBMIT"/"GAP" centered-bottom (label switches based on `levelIndex == 2`). White text at ~30% opacity
- [x] 2.6 Implement level indicator: current level name in uppercase, top-left corner. Read from `sessionNotifierProvider` → `currentLevel.name`
- [x] 2.7 Implement position progress indicator: "current/total" format (1-indexed), top-right corner. Read `positionIndex` and level character count from session state
- [x] 2.8 Implement input buffer display: render accumulated symbols as "· — /" notation, centered horizontally above the bottom zone. Watch `inputBufferProvider`
- [x] 2.9 Implement phase indicator: session phase as uppercase text ("PLAYING" / "LISTENING" / "FEEDBACK"), top-center. Read `phase` from `sessionNotifierProvider`

## 3. Integrate Overlay into TouchSurface

- [x] 3.1 Modify `TouchSurface.build()` to wrap the `Listener` and `CompanionOverlay` in a `Stack`. The `Listener` with `SizedBox.expand()` remains the base layer; the `CompanionOverlay` (wrapped in `IgnorePointer`) sits on top
- [x] 3.2 Verify that all existing touch handling (dot/dash, swipes, long hold, bottom zone, multi-touch rejection) works identically with the overlay present

## 4. Testing

- [x] 4.1 Write widget tests for `CompanionOverlay`: verify correct text is displayed for each element (symbol, morse pattern, level, progress, phase, zone labels) given known session state
- [x] 4.2 Write widget tests verifying zone labels switch between "SUBMIT" and "GAP" based on level
- [x] 4.3 Write widget tests verifying the input buffer display updates as symbols are added and clears on submission
- [x] 4.4 Write widget tests verifying the overlay does not intercept touch events (tap through `IgnorePointer` reaches the `Listener`)
- [x] 4.5 Run existing integration tests to confirm no regressions in touch handling or teaching loop behavior
