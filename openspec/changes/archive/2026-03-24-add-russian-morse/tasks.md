## 1. Extend MorseLanguage Enum

- [x] 1.1 Add `russian` value to `MorseLanguage` enum in `app/lib/morse/morse_language.dart` with doc comment "Russian Morse Code — Cyrillic letters"

## 2. Create Russian Alphabet Data

- [x] 2.1 Create `app/lib/morse/russian_alphabet.dart` with the `_russianCharacters` const map containing all 33 Cyrillic letter Morse patterns (А-Я) per the standard Russian telegraphic code
- [x] 2.2 Add `_russianOrder` const list with all 33 letters in standard Russian alphabetical order (А, Б, В, ... Э, Ю, Я)
- [x] 2.3 Add `_russianWithAliases` extended map that includes Ё as an alias for Е (same pattern: dot), following the same pattern as Arabic's `_arabicWithAliases`
- [x] 2.4 Add `_russianWordList` const list with 20 common Russian words for deaf-blind daily communication, sorted by length (5x 2-letter, 5x 3-letter, 5x 4-letter, 5x 5-letter), all uppercase Cyrillic
- [x] 2.5 Create the `russianAlphabet` final `MorseAlphabet` instance with language `MorseLanguage.russian`, wiring characters, characterOrder, wordList, wordPatterns (using `buildWordPatterns` with aliases map), and two levels: "russian-letters" and "russian-words"

## 3. Register Russian Alphabet

- [x] 3.1 Import `russian_alphabet.dart` in `app/lib/morse/morse_alphabet_registry.dart` and add `russianAlphabet` to the `morseRegistry` constructor list
- [x] 3.2 Export `russian_alphabet.dart` from the barrel file `app/lib/morse/morse.dart`

## 4. Update Language Picker

- [x] 4.1 Add Russian vibration identifier to `_languageIdentifiers` map in `app/lib/ui/language_picker_surface.dart`: `MorseLanguage.russian` → `encodeLetter('Р', MorseLanguage.russian)` with fallback `[MorseSignal.dot, MorseSignal.dash, MorseSignal.dot]`
- [x] 4.2 Add Russian label to `_languageLabels` map: `MorseLanguage.russian: 'Русский'`

## 5. Unit Tests for Russian Alphabet

- [x] 5.1 Create `app/test/morse/russian_alphabet_test.dart` with tests for: 33 characters mapped, patterns match standard Russian Morse code (spot-check А, Щ, Ъ, Я), characterOrder length is 33 and starts with А / ends with Я, characters map is compile-time constant
- [x] 5.2 Add word tests: wordList has exactly 20 entries, every word has a non-null wordPatterns entry, word patterns use CharGap between letters and not at start/end, words are uppercase Cyrillic
- [x] 5.3 Add Ё alias test: Ё is not in main characters map, extended alias map resolves Ё to same pattern as Е

## 6. Unit Tests for Registry and Encode/Decode

- [x] 6.1 Add tests in `app/test/morse/morse_alphabet_registry_test.dart` (or create if needed) for: `levelsForLanguage(MorseLanguage.russian)` returns 3 levels (digits, russian-letters, russian-words), list is unmodifiable
- [x] 6.2 Add encode/decode tests: `encodeLetter('С', MorseLanguage.russian)` returns `[dot, dot, dot]`, `decodePattern([dot, dash], MorseLanguage.russian)` returns 'А', lowercase 'а' encodes same as uppercase 'А'
- [x] 6.3 Add cross-language decode test: same pattern `[dot, dash]` returns 'A' for English, 'ا' for Arabic, 'А' for Russian

## 7. Update Existing Tests

- [x] 7.1 Review and update any existing tests that assert on `MorseLanguage.values.length` (should now be 3 instead of 2)
- [x] 7.2 Review and update any tests that assert on total alphabet count or total level count in the registry
- [x] 7.3 Run full test suite (`flutter test`) and fix any failures caused by the new enum value or registry changes
