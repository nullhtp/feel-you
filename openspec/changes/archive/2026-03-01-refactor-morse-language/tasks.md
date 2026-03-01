## 1. New Type System (MorseSignal + MorseToken)

- [x] 1.1 Create `morse_signal.dart` with `MorseSignal` enum (`dot`, `dash`) — replaces `MorseSymbol` for user-facing signals
- [x] 1.2 Create `morse_token.dart` with sealed `MorseToken` class (`Signal(MorseSignal)`, `CharGap()`) with value equality — used for word-level patterns
- [x] 1.3 Write tests for `MorseSignal` enum (exactly 2 values, no charGap)
- [x] 1.4 Write tests for `MorseToken` sealed class (equality, exhaustive switch, Signal wrapping, CharGap distinctness)

## 2. MorseAlphabet Data Class

- [x] 2.1 Create `morse_alphabet.dart` with `MorseAlphabet` class containing `language`, `characters`, `characterOrder`, `wordList`, `wordPatterns`, and `levels` fields
- [x] 2.2 Write tests for `MorseAlphabet` construction and field access

## 3. Alphabet Data Files

- [x] 3.1 Create `digit_alphabet.dart` — universal `MorseAlphabet` with digits 0-9 patterns using `MorseSignal`, `characterOrder`, and a single "digits" `Level`
- [x] 3.2 Create `english_alphabet.dart` — English `MorseAlphabet` with A-Z patterns using `MorseSignal`, `characterOrder`, word list, word patterns (computed via `buildWordPatterns`), and "letters"/"words" `Level` instances
- [x] 3.3 Create `arabic_alphabet.dart` — Arabic `MorseAlphabet` with 28 Arabic letter patterns using `MorseSignal`, `characterOrder`, word list, word patterns, and "arabic-letters"/"arabic-words" `Level` instances
- [x] 3.4 Write tests for digit alphabet (10 entries, correct patterns, no collisions with letters)
- [x] 3.5 Write tests for English alphabet (26 letters, correct patterns, 20 words, word patterns with CharGap)
- [x] 3.6 Write tests for Arabic alphabet (28 letters, correct patterns, 20 words, word patterns with CharGap)

## 4. MorseAlphabetRegistry

- [x] 4.1 Create `morse_alphabet_registry.dart` with `MorseAlphabetRegistry` class — holds all alphabets, provides `all`, `forLanguage()`, `universal`, `levelsForLanguage()`, `encodeLetter()`, `decodePattern()` methods
- [x] 4.2 Register digit, English, and Arabic alphabets in the registry
- [x] 4.3 Write tests for registry lookup (`forLanguage`, `universal`, unregistered language returns null)
- [x] 4.4 Write tests for `levelsForLanguage` (correct order, correct count, unmodifiable list)
- [x] 4.5 Write tests for registry `encodeLetter` and `decodePattern` (symmetric, language-aware, digits via universal, unknown returns null)

## 5. Focused Utility Modules

- [x] 5.1 Create `morse_encoder.dart` with `encodeLetter(String, MorseLanguage)` and `decodePattern(List<MorseSignal>, MorseLanguage)` — delegates to registry
- [x] 5.2 Create `morse_pattern.dart` with `patternsEqual(List<MorseSignal>, List<MorseSignal>)`, `isValidPattern(List<MorseSignal>, MorseLanguage)`, and `tokenPatternsEqual(List<MorseToken>, List<MorseToken>)`
- [x] 5.3 Create `morse_word_builder.dart` with `composeWordPattern(String, Map<String, List<MorseSignal>>)` returning `List<MorseToken>` and `buildWordPatterns(List<String>, Map<String, List<MorseSignal>>)` returning `Map<String, List<MorseToken>>`
- [x] 5.4 Write tests for `morse_encoder.dart` (encode/decode symmetric, language-aware, empty/null cases)
- [x] 5.5 Write tests for `morse_pattern.dart` (equality, validation, token equality)
- [x] 5.6 Write tests for `morse_word_builder.dart` (composition, charGap insertion, error cases, batch building)

## 6. Level Model Update

- [x] 6.1 Update `Level` class to use `MorseSignal` in `patterns` field (type: `Map<String, List<MorseSignal>>`) and equality using all fields (`name`, `characters`, `patterns`, `language`)
- [x] 6.2 Write tests for Level equality (same name different content = not equal, identical = equal)

## 7. Barrel Export and Old File Cleanup

- [x] 7.1 Update `morse.dart` barrel export to re-export new modules (`morse_signal.dart`, `morse_token.dart`, `morse_alphabet.dart`, `morse_alphabet_registry.dart`, `morse_encoder.dart`, `morse_pattern.dart`, `morse_word_builder.dart`, `level.dart`, `morse_language.dart`) and remove old exports
- [x] 7.2 Delete old files: `morse_symbol.dart`, `morse_utils.dart`, `morse_alphabet.dart` (old one), `morse_digits.dart`, `morse_arabic.dart`, `morse_words.dart`, `morse_arabic_words.dart`, `levels.dart`

## 8. Consumer Updates — Gestures

- [x] 8.1 Update `gesture_event.dart`: `MorseInput.symbol` type from `MorseSymbol` to `MorseSignal`, `InputComplete.symbols` type from `List<MorseSymbol>` to `List<MorseToken>`
- [x] 8.2 Update `gesture_classifier.dart`: input buffer type from `List<MorseSymbol>` to `List<MorseToken>`, `inputBufferNotifier` type, dot/dash classification to use `MorseSignal.dot`/`MorseSignal.dash`, `insertCharGap` inserts `CharGap` token
- [x] 8.3 Update gesture tests to use `MorseToken`/`MorseSignal` types

## 9. Consumer Updates — Vibration

- [x] 9.1 Update `morse_vibration_pattern.dart`: `buildMorseVibrationPattern` to accept `List<MorseToken>` for word patterns (handling `Signal` and `CharGap`) with a convenience `buildMorseVibrationPatternFromSignals` for `List<MorseSignal>` (single-character patterns)
- [x] 9.2 Update vibration tests to use new types

## 10. Consumer Updates — Session, Teaching, UI

- [x] 10.1 Update `session_state.dart` and `session_notifier.dart` to use registry's `levelsForLanguage()` instead of standalone function
- [x] 10.2 Update `teaching_orchestrator.dart` to use `patternsEqual` from `morse_pattern.dart`, pattern lookups using `MorseSignal` types, and word-level pattern handling with `MorseToken`
- [x] 10.3 Update `language_picker_surface.dart` to look up identifier patterns from registry via `encodeLetter` instead of hardcoded pattern lists
- [x] 10.4 Update session, teaching, and UI tests to use new types and registry

## 11. Final Verification

- [x] 11.1 Run `flutter analyze` — zero errors, zero warnings (only info-level hints)
- [x] 11.2 Run full test suite (`flutter test`) — 393 tests passing
- [x] 11.3 Verify no references to `MorseSymbol` remain in production code
