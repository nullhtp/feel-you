## 1. Language Model & Level System Updates

- [x] 1.1 Create `MorseLanguage` enum (`english`, `arabic`) in `app/lib/morse/morse_language.dart`
- [x] 1.2 Add optional `MorseLanguage? language` field to `Level` class in `level.dart` (defaults to `null` for universal levels)
- [x] 1.3 Create `levelsForLanguage(MorseLanguage)` function that returns filtered level list (universal + language-specific levels)
- [x] 1.4 Update `levels.dart` to assign `language: null` for digits, `language: MorseLanguage.english` for English letters/words
- [x] 1.5 Export `morse_language.dart` from the `morse.dart` barrel file
- [x] 1.6 Write tests for `MorseLanguage` enum, `Level` with language field, and `levelsForLanguage` filtering

## 2. Arabic Morse Data

- [x] 2.1 Create `morse_arabic.dart` with `morseArabicAlphabet` map (28 Arabic letters to Morse patterns) and `morseArabicLetters` ordered list
- [x] 2.2 Create `morse_arabic_words.dart` with `morseArabicWords` map (20 common Arabic words with charGap patterns) and `morseArabicWordsList` ordered list
- [x] 2.3 Register Arabic levels in `levels.dart`: Arabic letters level (`language: MorseLanguage.arabic`) and Arabic words level (`language: MorseLanguage.arabic`)
- [x] 2.4 Export `morse_arabic.dart` and `morse_arabic_words.dart` from the `morse.dart` barrel file
- [x] 2.5 Write tests for `morseArabicAlphabet` (28 entries, pattern correctness, const), `morseArabicLetters` (28 items, order), `morseArabicWords` (20 entries, charGap correctness), and `morseArabicWordsList` (20 items, order)

## 3. Morse Utilities Update

- [x] 3.1 Add `morseArabicAlphabet` import to `morse_utils.dart`
- [x] 3.2 Create `decodePatternForLanguage(List<MorseSymbol> symbols, MorseLanguage language)` that uses the correct alphabet for the given language
- [x] 3.3 Update `encodeLetter` to check Arabic alphabet in addition to Latin and digits (or create a language-aware variant)
- [x] 3.4 Update `isValidPattern` to include Arabic patterns
- [x] 3.5 Write tests for Arabic encode/decode, language-aware decode (same pattern returns different characters for different languages), and updated validation

## 4. Session State Updates

- [x] 4.1 Add `MorseLanguage language` field to `SessionState` (remove default — require language to be set)
- [x] 4.2 Update `currentLevel` getter to use `levelsForLanguage(language)` instead of global `levels`
- [x] 4.3 Update `currentCharacter` getter to use the language-filtered level list
- [x] 4.4 Add `selectLanguage(MorseLanguage)` method to `SessionNotifier` that sets language and resets level/position/phase
- [x] 4.5 Update `nextLevel`, `previousLevel`, `home` in `SessionNotifier` to use `levelsForLanguage(state.language)` for boundary checks
- [x] 4.6 Update `SessionState.copyWith` to include `language` parameter
- [x] 4.7 Write tests: session with Arabic language navigates Arabic levels, level boundaries respect filtered list, home preserves language, selectLanguage resets state

## 5. Language Picker UI

- [x] 5.1 Create `LanguagePickerSurface` widget in `app/lib/ui/language_picker_surface.dart` — full-screen black surface like `TouchSurface`
- [x] 5.2 Implement tap-to-cycle behavior: tapping cycles between English and Arabic, vibrating the identifier pattern (Morse "E" for English, Morse "ع" for Arabic)
- [x] 5.3 Implement swipe-right-to-confirm: swipe right selects the current language, calls `selectLanguage()` on the session notifier, and navigates to `TouchSurface`
- [x] 5.4 Update app routing/main to show `LanguagePickerSurface` as the initial screen instead of `TouchSurface`
- [x] 5.5 Write widget tests for language picker: tap cycles languages, swipe right confirms and navigates, vibration patterns play on cycle

## 6. Update Existing Tests

- [x] 6.1 Update `levels_test.dart`: expect 5 total levels, verify language fields, test `levelsForLanguage` returns correct 3 levels per language
- [x] 6.2 Update `session_notifier_test.dart` and `session_state_test.dart`: all tests pass language parameter, test Arabic language navigation, test selectLanguage
- [x] 6.3 Run full test suite (`flutter test`) and fix any failures from the Level/Session refactoring
