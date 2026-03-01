## Why

Word Morse pattern files (`morse_words.dart`, `morse_arabic_words.dart`) manually hardcode flat patterns that duplicate information already defined in the alphabet files. This creates a maintenance burden — every alphabet change requires manually updating word patterns — and risks drift between letter patterns and word patterns. Computing word patterns from the alphabet at runtime eliminates this duplication and makes the word data a pure function of the alphabet.

## What Changes

- Add a `composeWordPattern()` utility function to `morse_utils.dart` that builds a word's Morse pattern by looking up each letter in the alphabet map and joining with `charGap` separators.
- Refactor `morse_words.dart` to derive `morseWords` from `morseAlphabet` using `composeWordPattern()` instead of hardcoding patterns. The word list (`morseWordsList`) remains hardcoded. The exported API (`morseWords` map + `morseWordsList` list) stays the same.
- Apply the same refactor to `morse_arabic_words.dart`, deriving `morseArabicWords` from `morseArabicAlphabet` using `composeWordPattern()`.
- Update unit tests: add tests for `composeWordPattern()`, keep spot-check tests for specific words, remove exhaustive letter-composition checks that become tautological.

## Non-goals

- Changing the word lists themselves (the 20 English and 20 Arabic words stay the same).
- Changing the Level system, TeachingOrchestrator, or any UI/gesture behavior.
- Making word patterns compile-time const (runtime computation is acceptable).
- Adding new words or dynamic word generation.

## Capabilities

### New Capabilities

- `word-pattern-composition`: A utility function that composes a word's Morse pattern from alphabet letter patterns, used by both English and Arabic word data files.

### Modified Capabilities

- `word-morse-data`: Requirements change from "define a hardcoded `morseWords` map" to "derive `morseWords` from alphabet patterns using the composition utility." The exported API and word list content remain identical.

## Impact

- **Code**: `morse_utils.dart` (new function), `morse_words.dart` (refactored), `morse_arabic_words.dart` (refactored)
- **Tests**: `morse_words_test.dart` (updated), `morse_arabic_words_test.dart` (updated), new tests for `composeWordPattern()` in `morse_utils_test.dart`
- **Dependencies**: `morse_words.dart` now imports `morse_alphabet.dart` and `morse_utils.dart`; `morse_arabic_words.dart` now imports `morse_arabic.dart` and `morse_utils.dart`
- **No breaking changes**: All exported symbols, types, and runtime behavior remain identical
