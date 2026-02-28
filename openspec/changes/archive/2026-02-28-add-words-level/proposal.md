## Why

Users who have learned individual letters and digits need a natural next step: practicing common short English words. This bridges the gap between recognizing single characters and real-world Morse communication, building fluency by combining letters into meaningful sequences.

## What Changes

- Add a `charGap` value to `MorseSymbol` to represent the silence between letters within a word
- Create a word-pattern data file with 20 common English words (2–5 letters), sorted by length then usage frequency
- Register a new "words" level at index 2 (after digits and letters)
- Update the vibration engine to handle `charGap` as a longer silence in vibration patterns
- Update input evaluation to recognize `charGap` in user input (via silence duration between taps)

## Non-goals

- Sentence-level Morse (multi-word sequences with word gaps) — future phase
- Word selection UI or customizable word lists
- Visual or audio feedback for word boundaries
- Automatic progression or spaced repetition

## Capabilities

### New Capabilities

- `word-morse-data`: Defines the 20-word dataset, `charGap` symbol, and flat Morse patterns for multi-character words

### Modified Capabilities

- `vibration-engine`: Must handle the new `charGap` symbol as an inter-character silence (longer than `interSymbolGap`)
- `teaching-loop`: Input evaluation must accept `charGap` in user-submitted patterns when comparing against word patterns
- `level-system`: Register the new "words" level at index 2

## Impact

- **`MorseSymbol` enum**: Adds `charGap` variant — affects `buildMorseVibrationPattern`, `patternsEqual`, and the switch expressions in the vibration pattern builder
- **`MorseTimingConfig`**: Needs a new `interCharGap` duration parameter (standard Morse: 3× dot duration = 300ms)
- **`GestureTimingConfig`**: May need a `charGapTimeout` to distinguish inter-character silence from input-complete silence during word input
- **`morse_utils.dart`**: `encodeLetter`/`decodePattern` are single-character utilities — no change needed, but `patternsEqual` must handle `charGap`
- **Tests**: Existing level count assertions, vibration pattern tests, and integration tests need updates
