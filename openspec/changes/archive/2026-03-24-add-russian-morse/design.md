## Context

The app currently supports two Morse code alphabets: English (26 Latin letters + 20 words) and Arabic (28 Arabic letters + 20 words), plus universal digits (0-9). Each alphabet is a standalone Dart file that defines character patterns, character ordering, a word list, and levels. Alphabets are registered in a global `MorseAlphabetRegistry` which handles encode/decode lookups and level filtering by language.

The architecture is intentionally data-driven: adding a new language primarily means adding a new data file and wiring it into the registry and enum. The language picker, session management, and teaching loop all operate on `MorseLanguage` values and `Level` objects — they are language-agnostic.

## Goals / Non-Goals

**Goals:**
- Add Russian Cyrillic Morse code as a third learnable language
- Follow the exact same patterns as English and Arabic alphabets for consistency
- Include 33 Russian letters with standard Russian Morse code patterns
- Include 20 common Russian words suitable for deaf-blind daily communication
- Make Russian selectable from the language picker with a distinctive vibration identifier

**Non-Goals:**
- UI localization (companion overlay labels remain English)
- Store listing in Russian
- Any changes to teaching loop, gesture recognition, or vibration engine
- Supporting the letter Ё separately (it shares the same Morse code as Е in Russian telegraphic practice)

## Decisions

### 1. Russian Morse code source: Russian telegraphic code standard

Russian Morse code is based on the standard Russian telegraphic alphabet, where each Cyrillic letter maps to a pattern that often (but not always) matches the Latin letter equivalent in International Morse Code. For example, А = dot-dash (same as Latin A), but Ц = dash-dot-dash-dot (same as Latin C, reflecting the phonetic similarity Ц/C in telegraphy).

**Alternative considered**: Using a phonetic transliteration mapping (e.g., map each Russian letter to the Morse code of its closest-sounding Latin letter). Rejected because the established Russian telegraphic code is the universally recognized standard and what any Russian Morse code resource teaches.

### 2. Ё handling: Alias to Е

The letter Ё is not assigned a separate Morse code in the standard Russian telegraphic alphabet — it uses the same pattern as Е (dot). Rather than adding Ё to the main 33-character alphabet (which would create an ambiguous reverse lookup), it will be handled as an alias in the extended character map (like Arabic's أ/ى aliases for ا). This alias is only used during word pattern composition.

**Alternative considered**: Including Ё as a 34th letter in the learning sequence. Rejected because it would break `decodePattern` (two characters with the same pattern) and departs from standard practice.

### 3. Vibration identifier: Morse pattern for "Р" (dot-dash-dot)

Each language's vibration identifier in the language picker uses a distinctive letter from that alphabet. English uses "E" (dot), Arabic uses "ع" (dot-dash-dot-dash). For Russian, the letter "Р" (dot-dash-dot) provides a recognizable, medium-length pattern that is distinct from both existing identifiers.

**Alternative considered**: "Р" shares the same Morse code as Latin "R" and Arabic "ر". While the patterns overlap between alphabets, the identifier is always played in the context of a specific language button, so there is no ambiguity for the user.

### 4. Word selection: 20 common words for deaf-blind daily communication

Following the same approach as English and Arabic, the 20 Russian words will be chosen for practical daily communication needs of deaf-blind users. Sorted by length (shortest first), grouped as 5 two-letter, 5 three-letter, 5 four-letter, and 5 five-letter words. Preference for basic needs vocabulary: greetings, yes/no, help, pain, food, water, etc.

### 5. Level naming: "russian-letters" and "russian-words"

Follows the established convention: English uses "letters"/"words", Arabic uses "arabic-letters"/"arabic-words". Russian will use "russian-letters"/"russian-words". These names appear in the companion overlay via `level.name.toUpperCase()`.

### 6. Language picker: Add third button in existing Row layout

The language picker currently uses `MorseLanguage.values.map(...)` to create buttons in a `Row` with `Expanded` children. Adding `russian` to the enum automatically creates a third button. The only explicit changes needed are adding the label ("Русский") and vibration identifier entries to the picker's maps.

**Alternative considered**: Switching to a scrollable list or grid layout. Rejected because three evenly-spaced buttons in landscape orientation remain usable, and the current `MorseLanguage.values.map(...)` pattern handles it automatically.

## Risks / Trade-offs

- **[Risk] Font rendering for Cyrillic on all devices** → Mitigation: Cyrillic is part of the default system fonts on both iOS and Android. No custom font needed.
- **[Risk] Three-button picker may feel cramped on small phones** → Mitigation: The app runs in landscape orientation with large font (48sp). Three buttons at ~33% width each still provide comfortable tap targets. Monitor during testing.
- **[Risk] Pattern collisions between Russian and other alphabets** → Mitigation: The registry already handles this by checking language-specific alphabets first, falling back to universal (digits) only. Same pattern in different language contexts decodes to different characters correctly.
- **[Trade-off] Ё excluded from main alphabet** → Users cannot learn Ё as a separate character, but this matches standard Russian telegraphic practice and avoids decode ambiguity.
