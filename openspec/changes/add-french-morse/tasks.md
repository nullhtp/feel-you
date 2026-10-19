# Tasks

## 1. French alphabet data

- [x] 1.1 Append `french` to `MorseLanguage` after `spanish`, with the doc comment "French Morse Code — Latin letters A-Z, À, Ç, É and È"; verify `MorseLanguage.values` ends with `[spanish, french]` in a test
- [x] 1.2 Create `app/lib/morse/french_alphabet.dart`: the letters map built from `englishAlphabet.characters` plus À `[dot, dash, dash, dot, dash]`, Ç `[dash, dot, dash, dot, dot]`, É `[dot, dot, dash, dot, dot]`, È `[dot, dash, dot, dot, dash]`, unmodifiable; the 30-letter order A–Z, À, Ç, É, È; the 20 words of the `french-morse-data` spec; word patterns via `buildWordPatterns`; levels `french-letters` and `french-words`. Check that the file has no combining marks; verify with the tests of 1.4
- [x] 1.3 Register `frenchAlphabet` after `spanishAlphabet` in `morse_alphabet_registry.dart` and export it from `morse.dart`; verify `morseRegistry.forLanguage(MorseLanguage.french)` returns it
- [x] 1.4 Add `app/test/morse/french_alphabet_test.dart` (30 letters, A–Z equal to English, the four accented patterns, unique patterns with the digits, order with A–Z at 0–25 and À Ç É È at 26–29, single code units, the exact word list grouped 2/3/4/5, words only use letters of the level, every accented letter used in a word, ÇA and OUI token patterns, CharGap rules, the two levels); the test passes
- [x] 1.5 Add `app/test/morse/morse_utils_french_test.dart` (encode É and é, decode Ç, accented letters unknown in English, round trip of all 30 letters, digits decode in French); the test passes

## 2. Registry and levels

- [x] 2.1 Extend `levels_test.dart` (French levels list, `french-words` in the word-level names, French letters level of 30 with É at 28, French words level of 20), `morse_alphabet_registry_test.dart` (`forLanguage(french)`, registry order), the item counts in `morse_codec_test.dart` (50 digits, 26 + 28 + 32 + 27 + 30 letters, 100 words) and the alphabets without aliases in `morse_alphabet_aliases_test.dart`; `flutter test test/morse` passes, including `morse_punctuation_test.dart` (all French letters have 5 elements or fewer)

## 3. Language picker

- [x] 3.1 Add French to the identifier letter map (`É`, encoded by the French Morse codec like the other identifiers), the label map (`Français`) and the locale map (`Locale('fr')`) in `language_picker_surface.dart`, and to the doc comments listing identifiers; verify with 3.2
- [x] 3.2 Add a French row to the picker test table in `language_picker_non_visual_test.dart` and a test that Français plays É and starts French; add Français to `language_picker_surface_test.dart` and to the button and locale tables in `semantics_test.dart` (hint "Starts Morse lessons in French", locale `fr`); add a stored `french` round trip in `language_preference_test.dart`. Haptics are asserted through the mock vibration service. `flutter test test/ui test/settings` passes

## 4. End-to-end flow

- [x] 4.1 Add the French row to `app/integration_test/language_flow_test.dart`: tap Français → É vibrates → hold → digit 0 → letters → swipe past Z to É → `··−··` plays → tap it back → success, É learned → words → ÇA spelled Ç, A, then played → tap it back with a bottom-strip gap → success. Verify with `flutter test integration_test -d <iOS simulator>`

## 5. Documentation

- [x] 5.1 Update README (languages and levels table, words table, the order rule for accented letters, identifiers, picker columns), `app/README.md`, ROADMAP, `store/store-info.md`, `store/description-en.md`, `store/description-ar.md`, `store/privacy-policy.md` and add a CHANGELOG line saying the French word list awaits a native-speaker review; verify a grep for the four-language lists ("Russian and Spanish", "Russian, and Spanish", "Russian or Spanish") finds nothing stale

## 6. Checks

- [x] 6.1 From `app/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` (no new warnings or errors, no infos in new files) and `flutter test` pass; `openspec validate add-french-morse --strict` passes, and in a scratch copy of `openspec/` the Spanish and French changes archive in that order and `openspec validate --specs --strict` passes

## Workflow follow-up

- Archive after the PR is merged, after `add-spanish-morse` and before `add-german-morse`, then run `openspec validate --specs --strict`.
