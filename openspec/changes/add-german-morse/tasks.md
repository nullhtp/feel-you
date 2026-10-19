# Tasks

## 1. German alphabet data

- [x] 1.1 Append `german` to `MorseLanguage` after `french`, with the doc comment "German Morse Code — Latin letters A-Z, Ä, Ö and Ü"; verify `MorseLanguage.values` ends with `[french, german]` in a test
- [x] 1.2 Create `app/lib/morse/german_alphabet.dart`: the letters map built from `englishAlphabet.characters` plus Ä `[dot, dash, dot, dash]`, Ö `[dash, dash, dash, dot]`, Ü `[dot, dot, dash, dash]`, unmodifiable, with a doc comment saying why ß is not taught; the 29-letter order A–Z, Ä, Ö, Ü; the 20 words of the `german-morse-data` spec; word patterns via `buildWordPatterns`; levels `german-letters` and `german-words`. Check that the file has no combining marks; verify with the tests of 1.4
- [x] 1.3 Register `germanAlphabet` after `frenchAlphabet` in `morse_alphabet_registry.dart` and export it from `morse.dart`; verify `morseRegistry.forLanguage(MorseLanguage.german)` returns it
- [x] 1.4 Add `app/test/morse/german_alphabet_test.dart` (29 letters, A–Z equal to English, the three umlaut patterns, ß and ẞ not in the map, unique patterns with the digits, order with A–Z at 0–25 and Ä Ö Ü at 26–28, single code units, the exact word list grouped 2/3/4/5, words only use letters of the level, JA and MÜDE token patterns, CharGap rules, the two levels); the test passes
- [x] 1.5 Add `app/test/morse/morse_utils_german_test.dart` (encode Ü and ü, decode Ö, `encodeLetter('ß')` is null, the German codec rejects ß and the ß extension code decodes to nothing, umlauts unknown in English, round trip of all 29 letters, digits decode in German); the test passes

## 2. Registry, levels and the quiz marker

- [x] 2.1 Extend `levels_test.dart` (German levels list, `german-words` in the word-level names, German letters level of 29 with Ö at 27, German words level of 20), `morse_alphabet_registry_test.dart` (`forLanguage(german)`, registry order), the item counts in `morse_codec_test.dart` (60 digits, 26 + 28 + 32 + 27 + 30 + 29 letters, 120 words) and the alphabets without aliases in `morse_alphabet_aliases_test.dart`; `flutter test test/morse` passes
- [x] 2.2 Leave `morse_punctuation.dart` and `morse_punctuation_test.dart` as they are: the test already checks that `?` (6 elements) is longer than every digit and letter of every language, and passes with German (the umlauts have 4 elements)

## 3. Language picker

- [x] 3.1 Add German to the identifier letter map (`Ü`, encoded by the German Morse codec like the other identifiers), the label map (`Deutsch`) and the locale map (`Locale('de')`) in `language_picker_surface.dart`, and to the doc comments listing identifiers; verify with 3.2
- [x] 3.2 Add a German row to the picker test table in `language_picker_non_visual_test.dart` and a test that Deutsch plays Ü and starts German; add Deutsch to `language_picker_surface_test.dart` and to the button and locale tables in `semantics_test.dart` (hint "Starts Morse lessons in German", locale `de`); add a stored `german` round trip in `language_preference_test.dart` and German learned letters (umlauts) in `learned_items_store_test.dart`. Haptics are asserted through the mock vibration service. `flutter test test/ui test/settings` passes

## 4. End-to-end flow

- [x] 4.1 Add the German row to `app/integration_test/language_flow_test.dart`: tap Deutsch → Ü vibrates → hold → digit 0 → letters → swipe past Z to Ö → `−−−·` plays → tap it back → success, Ö learned → words → MÜDE spelled M, Ü, D, E, then played → tap it back with bottom-strip gaps → success. Run every integration test with `flutter test integration_test -d <iOS simulator>`; all pass

## 5. Documentation

- [x] 5.1 Update README (languages and levels table, the ß decision, words table, identifiers, picker columns), `openspec/config.yaml` context (six languages), `app/README.md`, ROADMAP, `store/store-info.md`, `store/description-en.md`, `store/description-ar.md`, `store/privacy-policy.md` and add a CHANGELOG line saying ß is not taught and the German word list awaits a native-speaker review; verify a grep for "Three languages", "five columns" and the five-language lists finds nothing stale, and that the README's sentence about the `?` marker is unchanged

## 6. Checks

- [x] 6.1 From `app/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` (no new warnings or errors, no infos in new files) and `flutter test` pass; `openspec validate add-german-morse --strict` passes, and in a scratch copy of `openspec/` the Spanish, French and German changes archive in that order and `openspec validate --specs --strict` passes

## Workflow follow-up

- Archive after the PR is merged, after `add-spanish-morse` and `add-french-morse`, then run `openspec validate --specs --strict`.
