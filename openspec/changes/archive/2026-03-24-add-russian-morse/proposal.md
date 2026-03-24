## Why

Russian is the 8th most spoken language worldwide with ~250 million speakers. Adding a Russian Morse code alphabet expands the app's reach to deaf-blind users in Russian-speaking communities who want to learn Morse code using their native script. Russian Morse code (based on the standard Russian telegraphic code) has well-established patterns for all 33 Cyrillic letters, making it a natural addition alongside the existing English and Arabic alphabets.

## What Changes

- Add a new `russian` value to the `MorseLanguage` enum
- Create `russian_alphabet.dart` with all 33 Russian Cyrillic letter Morse patterns (А-Я) and 20 common Russian words
- Register the Russian alphabet in `MorseAlphabetRegistry` so it participates in encode/decode and level lookup
- Add `russian-letters` and `russian-words` levels within the Russian alphabet
- Add Russian as a third option in the language picker with label "Русский"
- Add a vibration identifier for Russian in the language picker (Morse pattern for "Р")
- Update the companion overlay to correctly display Russian level names

## Non-goals

- UI localization (translating DOT/DASH/SUBMIT labels into Russian) — the app's UI strings are for sighted companions and remain English
- Adding Russian store listing metadata — can be done separately
- Restructuring the language picker layout (three buttons in a row is sufficient)

## Capabilities

### New Capabilities
- `russian-morse-data`: Russian Cyrillic Morse code alphabet data — 33 letter patterns, character ordering, 20 word patterns, and word list

### Modified Capabilities
- `language-selection`: Add Russian as a third selectable language with its vibration identifier pattern
- `level-system`: Include Russian letters and words levels in the registry's level list for the Russian language

## Impact

- **Morse data layer**: New file `russian_alphabet.dart` + enum extension in `morse_language.dart`
- **Registry**: `morse_alphabet_registry.dart` adds Russian alphabet to the global registry
- **UI**: `language_picker_surface.dart` adds Russian button, identifier, and label
- **Companion overlay**: Will show `RUSSIAN-LETTERS` / `RUSSIAN-WORDS` level names from the level's `name` field (no code change needed, driven by data)
- **Tests**: New unit tests for Russian alphabet data, encode/decode, and level filtering; updates to existing tests that assert on `MorseLanguage.values.length` or total level counts
