## Why

Currently, charGap (inter-character separator in word-level practice) is inserted automatically after a 400ms silence between taps. This is unreliable — the user has no explicit control over when a character boundary is placed, leading to accidental charGaps or missed ones. Adding a dedicated bottom input zone gives users explicit, tactile control over character separation (words level) and input submission (other levels), making the interaction more intentional and predictable.

## What Changes

- Add a full-width bottom zone (~15% of screen height) to the touch surface that acts as an explicit input action area
- On **words level**: tapping the bottom zone inserts a `charGap` symbol into the input buffer
- On **digits and letters levels**: tapping the bottom zone immediately triggers `InputComplete` (submit input without waiting for silence timeout)
- **BREAKING**: Remove the automatic charGap insertion based on the 400ms silence timer — charGap is now only inserted via explicit tap on the bottom zone
- Keep the 1000ms silence timeout as a fallback for `InputComplete`
- The bottom zone is invisible (black) and provides haptic feedback on tap, consistent with the app's no-visual design for deaf-blind users
- The dot/dash input zones are reduced to the upper ~85% of the screen

## Non-goals

- No visual indicators or separator lines for the bottom zone — the app remains fully black
- No changes to swipe gestures or navigation — they continue to work across the full screen
- No changes to the vibration engine or teaching loop logic beyond accepting the new input method
- No changes to the shake gesture behavior

## Capabilities

### New Capabilities
- `bottom-input-zone`: A full-width bottom touch zone that provides level-aware input actions (charGap on words level, InputComplete on other levels) with haptic feedback

### Modified Capabilities
- `gesture-recognition`: Remove automatic charGap insertion via 400ms silence timer; add support for receiving explicit charGap and InputComplete events from the bottom zone; the `charGapThreshold` config parameter becomes unused
- `touch-surface`: Split the screen into two vertical regions — upper area for dot/dash input and lower ~15% for the bottom input zone; forward touch events to the appropriate handler based on Y position
- `split-input`: Dot/dash position-based classification now only applies to taps in the upper region (above the bottom zone boundary)

## Impact

- **UI layer** (`touch_surface.dart`): Must detect whether a tap is in the bottom zone or the dot/dash zone based on Y position, and route events accordingly
- **Gesture system** (`gesture_classifier.dart`, `gesture_timing_config.dart`): Remove charGap silence timer logic; accept new event type or method for explicit charGap/submit
- **Gesture events** (`gesture_event.dart`): May need a new event type for the bottom zone action, or reuse existing `InputComplete` and add charGap insertion method
- **Vibration**: Haptic feedback for bottom zone taps (short vibration pulse on tap)
- **Teaching orchestrator** (`teaching_orchestrator.dart`): No direct changes — it already handles `InputComplete` and charGap in input patterns
- **Tests**: Gesture classifier tests need updating for removed charGap timer; new tests for bottom zone behavior
