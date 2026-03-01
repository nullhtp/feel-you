## Why

The app currently only supports International Morse Code for Latin script (English). To serve Arabic-speaking deaf-blind users, we need Arabic Morse code support. Arabic has a well-established Morse code standard covering its 28-letter alphabet, and adding it now establishes the multi-language architecture that future languages will build on.

## What Changes

- Add a new `morse_arabic.dart` data file with standard Arabic Morse code mappings for all 28 Arabic letters
- Add a new `morse_arabic_words.dart` data file with 20 common Arabic words and their Morse patterns (using `charGap` between letters, same pattern as English words)
- Introduce a **language group** concept: levels now belong to a language (e.g., English, Arabic). Digits are shared across all languages.
- Add a **language picker screen** shown on app start where the user selects a language (English or Arabic). After selection, only that language's levels are shown.
- Refactor the `levels` registry from a flat list to a language-aware structure so the session system filters levels by the selected language
- Update `morse_utils.dart` to include Arabic alphabet in encode/decode/validate operations
- Architecture designed to be extensible — adding more languages in the future should follow the same pattern

## Non-goals

- Persisting language selection across restarts (always shows picker on launch)
- Arabic-Indic numeral display (digits remain 0-9 universal)
- RTL text rendering concerns (the app is vibration-based, not visual text-based)
- Speech-to-Morse or text-to-Morse for Arabic (future phase)

## Capabilities

### New Capabilities
- `arabic-morse-data`: Standard Arabic Morse code alphabet (28 letters) and 20 common Arabic words with Morse patterns
- `language-selection`: Language picker screen on app start and language-aware level filtering

### Modified Capabilities
- `level-system`: Levels gain a language group property; the flat `levels` list is replaced with a language-aware registry where digits are shared and other levels are filtered by selected language
- `learning-session`: Session state tracks selected language; initial state depends on language selection; home/reset behavior respects language context

## Impact

- **morse/ module**: New data files (`morse_arabic.dart`, `morse_arabic_words.dart`), updated `levels.dart` with language grouping, updated `morse_utils.dart` for Arabic encode/decode, updated barrel export
- **session/ module**: `SessionState` and `SessionNotifier` updated to track selected language and filter levels accordingly
- **ui/ module**: New language picker screen added to the app flow before the main learning screen
- **Tests**: New test files for Arabic data, updated tests for level system and session to cover language selection
