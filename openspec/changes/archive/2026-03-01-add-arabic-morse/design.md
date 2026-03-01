## Context

The app currently supports only International Morse Code for Latin script — 26 letters (A-Z), 10 digits (0-9), and 20 English words. All levels live in a flat `List<Level>` indexed by integer. The session system tracks a `levelIndex` and `positionIndex` to navigate within this flat list. There is no concept of language grouping.

We need to add Arabic Morse code support (28 letters + 20 Arabic words) and introduce a language selection mechanism so users choose their language at app start.

## Goals / Non-Goals

**Goals:**
- Add standard Arabic Morse code data (28 letters, 20 common words)
- Introduce a language grouping model so levels belong to a language
- Add a language picker on app start (touch/vibration accessible)
- Keep digits as a shared/universal level across all languages
- Make the architecture extensible for future languages
- Update encode/decode utilities to support Arabic characters

**Non-Goals:**
- Persisting language selection between app restarts
- Arabic-Indic numerals (٠١٢٣...)
- RTL text rendering (app is vibration-based, companion overlay is for sighted observers only)
- UI localization / translated strings
- Any changes to gesture recognition, vibration timing, or teaching loop logic

## Decisions

### 1. Language model: enum + filtered level list

**Decision**: Introduce a `MorseLanguage` enum (`english`, `arabic`) and a `language` field on `Level`. Provide a function `levelsForLanguage(MorseLanguage)` that returns the filtered list of levels for a given language. Digits get a special `null` language (universal) and are included in every language's level list.

**Why not a nested map (`Map<Language, List<Level>>`)**: A flat list with a language tag keeps the `Level` class simple and allows a single source of truth. The filtering function is trivial and avoids duplicating the digits level across multiple lists.

**Why not separate registries per language**: Would scatter related data and make it harder to add shared levels (digits, punctuation) in the future.

### 2. Level class gains optional `language` field

**Decision**: Add an optional `MorseLanguage? language` field to `Level`. When `null`, the level is universal (included for all languages). When set, it belongs to that specific language.

**Why optional**: Digits are universal. Making it optional with `null` meaning "universal" avoids needing a separate `Language.universal` enum value and keeps existing level definitions backward-compatible.

### 3. Session state tracks selected language

**Decision**: Add a `MorseLanguage language` field to `SessionState`. The session operates on `levelsForLanguage(language)` instead of the global `levels` list. `levelIndex` indexes into the filtered list. A new `selectLanguage(MorseLanguage)` method on `SessionNotifier` resets the session to the first level/position of the selected language.

**Why in session state**: The session already owns all navigation state. Language selection naturally belongs here since it determines which levels are available. No new provider needed.

### 4. Language picker as a pre-session screen

**Decision**: Add a `LanguagePickerSurface` widget that presents language choices via vibration patterns. The user taps to cycle between languages (each identified by a distinct vibration — e.g., "E" in Morse for English, "ع" in Arabic Morse for Arabic). A confirming gesture (double-tap or swipe right) selects the language and navigates to the main `TouchSurface`.

**Why a separate screen**: Keeps the main touch surface focused on learning. The picker is shown on every app start (no persistence), so it's lightweight. The interaction is simple — cycle and confirm — fitting the instrument-like design philosophy.

**Alternative considered — in-session level navigation**: Could add Arabic levels to the flat list and let users swipe to them. Rejected because it would mix languages in a confusing way and doesn't scale to many languages.

### 5. Arabic data files follow existing conventions

**Decision**: Create `morse_arabic.dart` (28 letters + ordered list) and `morse_arabic_words.dart` (20 words + ordered list) following the exact same patterns as `morse_alphabet.dart` and `morse_words.dart`. Use the standard Arabic Morse code mappings.

**Why same conventions**: Consistency. The existing pattern of `const Map` + `const List` + shorthand aliases (`_d`, `_s`, `_g`) works well and keeps everything compile-time constant.

### 6. morse_utils encode/decode extended for Arabic

**Decision**: The reverse lookup map `_patternToCharacter` will include Arabic alphabet entries. `encodeLetter` will check Arabic alphabet in addition to Latin. Since some Arabic letters share Morse patterns with Latin letters (they are the same standard), the Arabic-specific decode will use a separate lookup or the caller provides context.

**Approach**: Add a `morseArabicAlphabet` map to the imports. For decode, since Arabic and Latin may share patterns, provide a `decodePatternForLanguage(symbols, language)` function that uses the correct alphabet. The existing `decodePattern` remains for backward compatibility and defaults to Latin+digits.

## Risks / Trade-offs

- **[Pattern collisions]** Some Arabic Morse patterns are identical to Latin ones (by design — Arabic Morse is an extension of International Morse). → Mitigation: Language-scoped decode function; the session always knows which language is active.
- **[Increased app size]** Two additional data files with ~48 new character maps. → Negligible — these are tiny const maps, a few KB at most.
- **[Testing surface]** More levels mean more test combinations. → Mitigation: Arabic tests follow the exact same pattern as Latin tests; parametric where possible.
- **[Language picker accessibility]** The picker must work entirely through vibration. → Mitigation: Use distinct Morse patterns to identify each language. Keep the interaction to a simple cycle-and-confirm pattern.
