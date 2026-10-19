# Tasks

## 1. Spanish alphabet data

- [x] 1.1 Append `spanish` to `MorseLanguage` in `app/lib/morse/morse_language.dart` with the doc comment "Spanish Morse Code — Latin letters A-Z and Ñ"; verify `MorseLanguage.values` is `[english, arabic, russian, spanish]` in a test
- [x] 1.2 Create `app/lib/morse/spanish_alphabet.dart`: the letters map built from `englishAlphabet.characters` plus Ñ (`[dash, dash, dot, dash, dash]`), unmodifiable; the 27-letter order with Ñ after N; the 20-word list from the `spanish-morse-data` spec; word patterns via `buildWordPatterns`; levels `spanish-letters` and `spanish-words` (`LevelKind.words`). Check that every non-ASCII letter is one precomposed code unit (no combining marks in the file); verify with the tests of 1.4
- [x] 1.3 Register `spanishAlphabet` after `russianAlphabet` in `morse_alphabet_registry.dart` (and its doc comment) and export it from `morse.dart`; verify `morseRegistry.forLanguage(MorseLanguage.spanish)` returns it
- [x] 1.4 Add `app/test/morse/spanish_alphabet_test.dart` mirroring `russian_alphabet_test.dart`: 27 letters, every pattern from the spec table, A–Z equal to English, Ñ pattern, no two letters or digits share a pattern, the order (Ñ at 14 between N and O), 20 words grouped 2/3/4/5, the exact word list, every word only uses letters of the letters level, word patterns (NO, BAÑO, CharGap rules); `flutter test test/morse/spanish_alphabet_test.dart` passes
- [x] 1.5 Add `app/test/morse/morse_utils_spanish_test.dart`: encode Ñ and ñ, decode Ñ, Ñ unknown in English (encode and decode), round trip of all 27 letters, digits still decode in Spanish, cross-language decode of `[dot, dash]`; the test passes

## 2. Registry and levels

- [x] 2.1 Update `app/test/morse/levels_test.dart` (total level count 9, Spanish levels list, `spanish-words` in the word-level names, Spanish letters level of 27 with Ñ at 14, Spanish words level of 20) and `morse_alphabet_registry_test.dart` (`forLanguage(spanish)`, registry order, every language has an alphabet); `flutter test test/morse` passes
- [x] 2.2 Update the item counts in `morse_codec_test.dart` (every digit, letter and word of every language encodes to its level pattern: 40 digits, 26 + 28 + 32 + 27 letters, 80 words), add Spanish to the alphabets without aliases in `morse_alphabet_aliases_test.dart`, and check that `morse_punctuation_test.dart` still holds (Ñ has 5 elements, the quiz `?` has 6); verify they pass

## 3. Language picker

- [x] 3.1 In `app/lib/ui/language_picker_surface.dart` add Spanish to the identifier letter map (`Ñ`, encoded by the Spanish Morse codec like the other identifiers), the label map (`Español`) and the locale map (`Locale('es')`), and update the doc comments that list the identifiers; verify with the tests of 3.2
- [x] 3.2 Rewrite the column- and count-dependent tests in `test/ui/language_picker_non_visual_test.dart` against a table of label and identifier per language and `MorseLanguage.values` (wrap from the last language, swipe left from English, the top-right corner, the column under the hint), and add: tapping Español plays Ñ, all identifiers are distinct and equal `encodeLetter` of their letter. Update `language_picker_surface_test.dart` (Español shown) and `semantics_test.dart` (Español button with hint "Starts Morse lessons in Spanish" and locale `es`). Haptics: the identifier is asserted through the mock vibration service's `playMorsePattern` calls. `flutter test test/ui` passes
- [x] 3.3 Add saved-data tests: `test/settings/language_preference_test.dart` reads a stored `spanish`; `test/settings/learned_items_store_test.dart` saves and reads Spanish letters under `learned_items.spanish.spanish-letters`; `test/ui/launch_screen_test.dart` launches straight into Spanish from a stored `spanish`; verify they pass

## 4. End-to-end flow

- [x] 4.1 Add `app/integration_test/language_flow_test.dart` (`testWidgets` on the `E2EApp` harness: the whole app from the launch screen, `RecordingVibrationService`, the motor answered by `FakeVibrationPlatform`, end-to-end timings): tap Español → Ñ identifier vibrates → hold → lesson on digit 0 (pattern `−−−−−` plays, `spanish` saved) → swipe up → swipe right to Ñ → `−−·−−` plays → tap it back → success and Ñ learned → swipe up → swipe right to BAÑO → its letters are spelled one by one, then the word token pattern plays → tap it back with bottom-strip gaps → success. Same on iOS and Android: pointer positions come from the live surface size. Verify with `flutter test integration_test -d <iOS simulator>`

## 5. Documentation

- [x] 5.1 Update README (languages and levels table, words table, the identifier row of the signals table, the picker columns), `app/README.md` (alphabet list), ROADMAP (language count), `store/store-info.md`, `store/description-en.md`, `store/description-ar.md`, `store/privacy-policy.md` (taught languages) and add a CHANGELOG line under `[Unreleased]` saying the Spanish word list awaits a native-speaker review; verify `grep -rn "English, Arabic and Russian\|English, Arabic, Russian\|Arabic or Russian" README.md store app/README.md` finds nothing stale

## 6. Checks

- [x] 6.1 From `app/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` (no new warnings or errors, no infos in new files) and `flutter test` all pass; `openspec validate add-spanish-morse --strict` passes

## Workflow follow-up

- Archive the change after the PR is merged (`openspec archive add-spanish-morse`), before `add-french-morse` and `add-german-morse`, then run `openspec validate --specs --strict`.
