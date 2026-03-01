## 1. Composition Utility

- [x] 1.1 Add `composeWordPattern(String word, Map<String, List<MorseSymbol>> alphabet)` function to `morse_utils.dart`. Looks up each character in the alphabet map, concatenates patterns with `MorseSymbol.charGap` between letters. Throws `ArgumentError` for empty word or unknown character.
- [x] 1.2 Add `buildWordPatterns(List<String> words, Map<String, List<MorseSymbol>> alphabet)` function to `morse_utils.dart`. Calls `composeWordPattern` for each word and returns a `Map<String, List<MorseSymbol>>`.
- [x] 1.3 Add unit tests for `composeWordPattern` in `morse_utils_test.dart`: two-letter word, three-letter word, single-letter word (no charGap), custom alphabet map, unknown character throws `ArgumentError`, empty word throws `ArgumentError`.
- [x] 1.4 Add unit tests for `buildWordPatterns` in `morse_utils_test.dart`: batch composition, empty list returns empty map.

## 2. Refactor English Word Data

- [x] 2.1 Refactor `morse_words.dart`: remove hardcoded `morseWords` const map. Import `morse_alphabet.dart` and `morse_utils.dart`. Replace with `final Map<String, List<MorseSymbol>> morseWords = buildWordPatterns(morseWordsList, morseAlphabet)`. Keep `morseWordsList` as `const`.
- [x] 2.2 Update `morse_words_test.dart`: remove exhaustive letter-composition checks. Keep spot-check tests for specific words (e.g., IT, THE, THERE). Add test that `morseWords` has 20 entries and all `morseWordsList` entries have patterns. Verify word list ordering tests remain.

## 3. Refactor Arabic Word Data

- [x] 3.1 Ensure Arabic alphabet map handles character variants: verify `أ` (hamza on alif) and `ى` (alif maqsura) resolve to `ا` pattern when looking up word characters. Add alias entries to `morseArabicAlphabet` in `morse_arabic.dart` if needed, or add a normalization map in `morse_arabic_words.dart`.
- [x] 3.2 Refactor `morse_arabic_words.dart`: remove hardcoded `morseArabicWords` const map. Import `morse_arabic.dart` and `morse_utils.dart`. Replace with `final Map<String, List<MorseSymbol>> morseArabicWords = buildWordPatterns(morseArabicWordsList, morseArabicAlphabet)` (with character normalization as needed). Keep `morseArabicWordsList` as `const`.
- [x] 3.3 Update `morse_arabic_words_test.dart`: remove exhaustive letter-composition checks. Keep spot-check tests for specific Arabic words. Add test that `morseArabicWords` has 20 entries and all `morseArabicWordsList` entries have patterns.

## 4. Verification

- [x] 4.1 Run full test suite (`flutter test`) and verify all tests pass. Fix any failures.
- [x] 4.2 Verify no downstream code is broken: confirm `levels.dart`, `teaching_orchestrator.dart`, and `companion_overlay.dart` work without changes (they consume the same exported symbols and types).
