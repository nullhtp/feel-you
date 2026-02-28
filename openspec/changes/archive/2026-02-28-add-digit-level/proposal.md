## Why

The app currently only teaches the 26 letters A-Z. Morse code includes digits 0-9, which are essential for communicating numbers (addresses, phone numbers, times). Adding a digit level expands the learning tool toward full Morse code coverage and introduces an expandable level system that can accommodate future character sets (punctuation, etc.).

## What Changes

- Introduce an expandable **level system** where each level is an ordered set of characters to learn (digits 0-9, letters A-Z, and potentially more in the future).
- Add **digit level** (0-9) with full Morse code patterns as the first level in the sequence.
- Add **swipe up/down gestures** to navigate between levels (swipe up = next level, swipe down = previous level). No-op at boundaries.
- Add **phone shake gesture** as a "home" action — always resets to the first level (digits), position 0.
- Change **long tap** behavior: resets position to the start of the *current* level only (digits→0, letters→A), no longer switches levels.
- App now **starts on digits** (level 0, position 0) instead of letter A.
- Each level starts at position 0 when entered — no position memory across level switches.
- Within a level, swipe left/right navigates characters and long tap resets to the first character, same as today.

## Non-goals

- Persistence of progress across app restarts.
- Unlocking/locking levels or characters.
- Scoring, achievements, or completion tracking.
- Adding punctuation or other character sets (future change).

## Capabilities

### New Capabilities
- `digit-morse-data`: Morse code patterns for digits 0-9, ordered list for learning sequence.
- `level-system`: Expandable level abstraction — ordered list of levels, each with a character set. Navigation between levels (up/down), boundary behavior, and home reset via shake.
- `shake-gesture`: Phone shake detection that emits a "home" gesture event, resetting to the first level and first character.

### Modified Capabilities
- `gesture-recognition`: Add swipe up/down classification for level navigation. Add shake detection integration point. Existing swipe left/right and long hold behavior unchanged within a level.
- `learning-session`: Session state expands from a single `letterIndex` to a `levelIndex` + `positionIndex` model. Navigation methods updated to work within the current level. Reset scoped to current level (long tap) vs. global home (shake).
- `teaching-loop`: Orchestrator handles new gesture events (NavigateUp, NavigateDown, Home). Level switching stops current vibration and restarts the teaching loop for the new level's character. Character lookup uses the level system instead of hardcoded `morseLetters`.

## Impact

- **Session state**: `SessionState` gains `levelIndex` field; `currentLetter` becomes `currentCharacter` derived from the active level.
- **Gesture system**: `GestureClassifier` adds vertical swipe detection. New `GestureEvent` subtypes: `NavigateUp`, `NavigateDown`, `Home`. `gesture_event.dart`, `gesture_classifier.dart` modified.
- **Morse data**: New `morse_digits.dart` (or extend `morse_alphabet.dart`) with digit patterns. `morse_utils.dart` encode/decode must cover digits.
- **Teaching orchestrator**: New event handlers for level navigation and home. Character resolution via level system instead of direct `morseLetters` access.
- **Platform integration**: Shake detection requires accelerometer access — new dependency (`sensors_plus` or similar Flutter package).
- **Tests**: All existing tests for gesture classification, session state, and teaching orchestrator need updates to account for the level dimension.
